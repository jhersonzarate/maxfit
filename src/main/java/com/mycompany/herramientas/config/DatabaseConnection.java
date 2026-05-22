package com.mycompany.herramientas.config;

import java.io.IOException;
import java.io.InputStream;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.Properties;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * Maneja la conexión a la base de datos gimnasio_db en SQL Server.
 *
 * Implementa un pool manual liviano usando ThreadLocal para que cada
 * hilo de Tomcat tenga su propia conexión, evitando problemas de
 * concurrencia entre requests simultáneos.
 *
 * Uso en los DAOs:
 *   Connection con = DatabaseConnection.getConnection();
 *   // ... usar con ...
 *   DatabaseConnection.closeConnection();   // siempre en finally
 *
 * @author MaxFit
 */
public class DatabaseConnection {

    // Logger para registrar errores sin exponer datos al cliente
    private static final Logger LOGGER =
            Logger.getLogger(DatabaseConnection.class.getName());

    // Datos de conexión leídos una sola vez al cargar la clase
    private static String url;
    private static String user;
    private static String password;

    // Indica si la carga de propiedades fue exitosa
    private static boolean configured = false;

    /*
     * Una conexión por hilo de Tomcat.
     * Evita compartir conexiones entre requests (thread-safe sin synchronized).
     */
    private static final ThreadLocal<Connection> connectionHolder =
            new ThreadLocal<>();

    // -----------------------------------------------------------------------
    // Bloque estático: se ejecuta una sola vez cuando Tomcat carga la clase
    // -----------------------------------------------------------------------
    static {
        loadProperties();
    }

    // Constructor privado: nadie debe instanciar esta clase
    private DatabaseConnection() {}

    // -----------------------------------------------------------------------
    // Carga db.properties desde el classpath (src/main/resources/)
    // -----------------------------------------------------------------------
    private static void loadProperties() {
        /*
         * db.properties está en src/main/resources/ y Maven lo copia a
         * WEB-INF/classes/ automáticamente. Nunca se sube al repo (está
         * en .gitignore). Usar db.properties.example como plantilla.
         */
        try (InputStream input =
                DatabaseConnection.class
                        .getClassLoader()
                        .getResourceAsStream("db.properties")) {

            if (input == null) {
                LOGGER.severe("No se encontró db.properties en el classpath. "
                        + "Copia db.properties.example y completa los valores.");
                return;
            }

            Properties props = new Properties();
            props.load(input);

            url      = props.getProperty("jdbc.url");
            user     = props.getProperty("jdbc.user");
            password = props.getProperty("jdbc.password");

            // Verificar que ningún campo esté vacío (trim().isEmpty() funciona desde Java 6)
            if (url == null || url.trim().isEmpty()
                    || user == null || user.trim().isEmpty()
                    || password == null || password.trim().isEmpty()) {
                LOGGER.severe("db.properties tiene campos vacíos. "
                        + "Revisa jdbc.url, jdbc.user y jdbc.password.");
                return;
            }

            // Cargar el driver de SQL Server explícitamente (por si acaso)
            Class.forName("com.microsoft.sqlserver.jdbc.SQLServerDriver");

            configured = true;
            LOGGER.info("DatabaseConnection configurado correctamente.");

        } catch (IOException e) {
            LOGGER.log(Level.SEVERE, "Error al leer db.properties", e);
        } catch (ClassNotFoundException e) {
            LOGGER.log(Level.SEVERE,
                    "Driver SQL Server no encontrado. "
                    + "Verifica la dependencia mssql-jdbc en pom.xml", e);
        }
    }

    // -----------------------------------------------------------------------
    // Obtener conexión (reutiliza la del hilo actual si ya está abierta)
    // -----------------------------------------------------------------------

    /**
     * Devuelve la conexión activa del hilo actual.
     * Si no existe o está cerrada, crea una nueva.
     *
     * @return Connection lista para usar
     * @throws SQLException si no se puede conectar a la BD
     * @throws IllegalStateException si db.properties no está configurado
     */
    public static Connection getConnection() throws SQLException {
        if (!configured) {
            throw new IllegalStateException(
                    "La conexión a la BD no está configurada. "
                    + "Revisa db.properties en src/main/resources/");
        }

        Connection con = connectionHolder.get();

        // Crear nueva conexión si no existe o si fue cerrada / está caída
        if (con == null || con.isClosed()) {
            con = DriverManager.getConnection(url, user, password);

            /*
             * AutoCommit en true para operaciones simples (SELECT, INSERT...).
             * En los servicios que necesiten transacción (ej: guardar contrato
             * y asistencia juntos) se llama a con.setAutoCommit(false) y
             * luego con.commit() / con.rollback() manualmente.
             */
            con.setAutoCommit(true);

            connectionHolder.set(con);
            LOGGER.fine("Nueva conexión creada para el hilo: "
                    + Thread.currentThread().getName());
        }

        return con;
    }

    // -----------------------------------------------------------------------
    // Cerrar y limpiar la conexión del hilo actual
    // -----------------------------------------------------------------------

    /**
     * Cierra la conexión del hilo actual y la elimina del ThreadLocal.
     * Llamar siempre en un bloque finally en los DAOs.
     */
    public static void closeConnection() {
        Connection con = connectionHolder.get();
        if (con != null) {
            try {
                if (!con.isClosed()) {
                    con.close();
                }
            } catch (SQLException e) {
                LOGGER.log(Level.WARNING, "Error al cerrar la conexión", e);
            } finally {
                // Siempre limpiar el ThreadLocal aunque falle el close()
                connectionHolder.remove();
            }
        }
    }

    // -----------------------------------------------------------------------
    // Helpers para manejo de transacciones en los Services
    // -----------------------------------------------------------------------

    /**
     * Inicia una transacción manual en la conexión del hilo actual.
     * Usar solo en los Services cuando se necesite atomicidad entre
     * dos o más operaciones de BD (ej: crear contrato + registrar asistencia).
     *
     * Ejemplo de uso en un Service:
     *   try {
     *       DatabaseConnection.beginTransaction();
     *       contratoDAO.save(contrato);
     *       asistenciaDAO.save(asistencia);
     *       DatabaseConnection.commit();
     *   } catch (Exception e) {
     *       DatabaseConnection.rollback();
     *       throw e;
     *   } finally {
     *       DatabaseConnection.closeConnection();
     *   }
     */
    public static void beginTransaction() throws SQLException {
        getConnection().setAutoCommit(false);
    }

    /**
     * Confirma la transacción actual y restaura autoCommit a true.
     */
    public static void commit() throws SQLException {
        Connection con = connectionHolder.get();
        if (con != null && !con.isClosed()) {
            con.commit();
            con.setAutoCommit(true);
        }
    }

    /**
     * Revierte la transacción actual y restaura autoCommit a true.
     * Llamar en el catch de cualquier operación transaccional.
     */
    public static void rollback() {
        Connection con = connectionHolder.get();
        if (con != null) {
            try {
                if (!con.isClosed()) {
                    con.rollback();
                    con.setAutoCommit(true);
                }
            } catch (SQLException e) {
                LOGGER.log(Level.SEVERE, "Error al hacer rollback", e);
            }
        }
    }

    // -----------------------------------------------------------------------
    // Diagnóstico rápido (útil en el arranque o para tests manuales)
    // -----------------------------------------------------------------------

    /**
     * Verifica que la conexión funcione abriendo y cerrando una de prueba.
     * Se puede llamar desde AppConfig al iniciar la aplicación.
     *
     * @return true si la BD responde, false en caso contrario
     */
    public static boolean testConnection() {
        if (!configured) {
            LOGGER.warning("testConnection() llamado sin configuración.");
            return false;
        }
        try (Connection con = DriverManager.getConnection(url, user, password)) {
            boolean ok = con != null && !con.isClosed();
            LOGGER.info("Test de conexión a gimansio_db: " + (ok ? "OK" : "FALLÓ"));
            return ok;
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE,
                    "No se pudo conectar a la BD en testConnection()", e);
            return false;
        }
    }

    /**
     * Devuelve si la clase se configuró correctamente al cargar.
     * Útil para mostrar un mensaje en el dashboard si la BD no está disponible.
     */
    public static boolean isConfigured() {
        return configured;
    }
}