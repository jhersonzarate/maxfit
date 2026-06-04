package com.mycompany.herramientas.config;
import java.io.IOException;
import java.io.InputStream;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.Properties;

//Se elimino el LOGGER pq eso manteniene la session corriendo si hay un error, la cosa es que no te devuelve como tal un mensaje
//claro del error, por ende se usa RuntimeException.
/*
La diferencia clave es que el Logger solo avisa pero el programa sigue corriendo — y si URL, USER o PASSWORD quedaron en null,
 el servidor arranca pero explota misteriosamente cuando alguien intenta hacer login.
 La RuntimeException en cambio para el servidor de inmediato con un mensaje claro.
*/
public class DatabaseConnection {

    private static final String URL;
    private static final String USER;
    private static final String PASSWORD;

    private static boolean configured = false;

    private static final ThreadLocal<Connection> connectionHolder = new ThreadLocal<>();

    static {
        try (InputStream input = DatabaseConnection.class
                .getClassLoader()
                .getResourceAsStream("db.properties")) {

            if (input == null)
                throw new RuntimeException("No se encontró db.properties. " +
                        "Copia db.properties.example y completa los valores.");

            Properties props = new Properties();
            props.load(input);

            URL      = props.getProperty("jdbc.url");
            USER     = props.getProperty("jdbc.user");
            PASSWORD = props.getProperty("jdbc.password");

            configured = true;

        } catch (IOException e) {
            throw new RuntimeException("Error al leer db.properties", e);
        }
    }

    private DatabaseConnection() {}

    public static Connection getConnection() throws SQLException {
        if (!configured)
            throw new IllegalStateException(
                    "La conexión a la BD no está configurada. Revisa db.properties.");

        Connection con = connectionHolder.get();

        if (con == null || con.isClosed()) {
            try {
                Class.forName("com.microsoft.sqlserver.jdbc.SQLServerDriver");
            } catch (ClassNotFoundException e) {
                throw new RuntimeException("Driver SQL Server no encontrado. " +
                        "Verifica la dependencia mssql-jdbc en pom.xml", e);
            }
            con = DriverManager.getConnection(URL, USER, PASSWORD);
            con.setAutoCommit(true);
            connectionHolder.set(con);
        }

        return con;
    }

    public static void closeConnection() {
        Connection con = connectionHolder.get();
        if (con != null) {
            try {
                if (!con.isClosed()) con.close();
            } catch (SQLException ignored) {}
            finally {
                connectionHolder.remove();
            }
        }
    }

    public static void beginTransaction() throws SQLException {
        getConnection().setAutoCommit(false);
    }

    public static void commit() throws SQLException {
        Connection con = connectionHolder.get();
        if (con != null && !con.isClosed()) {
            con.commit();
            con.setAutoCommit(true);
        }
    }

    public static void rollback() {
        Connection con = connectionHolder.get();
        if (con != null) {
            try {
                if (!con.isClosed()) {
                    con.rollback();
                    con.setAutoCommit(true);
                }
            } catch (SQLException ignored) {}
        }
    }

    public static boolean isConfigured() {
        return configured;
    }

    public static boolean testConnection() {
        if (!configured) return false;
        try (Connection con = DriverManager.getConnection(URL, USER, PASSWORD)) {
            return con != null && !con.isClosed();
        } catch (SQLException e) {
            return false;
        }
    }
}


/*
import java.io.IOException;
import java.io.InputStream;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.Properties;
import java.util.logging.Level;
import java.util.logging.Logger;

// manejo centralizado de conexiones SQL Server
public class DatabaseConnection {

    // logger para errores y diagnósticos
    private static final Logger LOGGER =
            Logger.getLogger(DatabaseConnection.class.getName());

    // datos de conexión
    private static String url;
    private static String user;
    private static String password;

    // indica si db.properties cargó correctamente
    private static boolean configured = false;

    // conexión por hilo usando ThreadLocal
    private static final ThreadLocal<Connection> connectionHolder =
            new ThreadLocal<>();

    // ─── bloque estático ───────────────────────────────────────

    // cargar propiedades al iniciar la clase
    static {
        loadProperties();
    }

    // evitar instancias de esta clase utilitaria
    private DatabaseConnection() {}

    // ─── carga de configuración ────────────────────────────────

    // leer db.properties desde resources
    private static void loadProperties() {

        try (InputStream input =
                     DatabaseConnection.class
                             .getClassLoader()
                             .getResourceAsStream("db.properties")) {

            // archivo no encontrado
            if (input == null) {

                LOGGER.severe(
                        "No se encontró db.properties en el classpath. "
                        + "Copia db.properties.example y completa los valores."
                );

                return;
            }

            Properties props = new Properties();

            props.load(input);

            // leer propiedades JDBC
            url      = props.getProperty("jdbc.url");
            user     = props.getProperty("jdbc.user");
            password = props.getProperty("jdbc.password");

            // validar campos vacíos
            if (url == null || url.trim().isEmpty()
                    || user == null || user.trim().isEmpty()
                    || password == null || password.trim().isEmpty()) {

                LOGGER.severe(
                        "db.properties tiene campos vacíos. "
                        + "Revisa jdbc.url, jdbc.user y jdbc.password."
                );

                return;
            }

            // cargar driver SQL Server
            Class.forName(
                    "com.microsoft.sqlserver.jdbc.SQLServerDriver"
            );

            configured = true;

            LOGGER.info(
                    "DatabaseConnection configurado correctamente."
            );

        } catch (IOException e) {

            LOGGER.log(
                    Level.SEVERE,
                    "Error al leer db.properties",
                    e
            );

        } catch (ClassNotFoundException e) {

            LOGGER.log(
                    Level.SEVERE,
                    "Driver SQL Server no encontrado. "
                    + "Verifica la dependencia mssql-jdbc en pom.xml",
                    e
            );
        }
    }

    // ─── obtener conexión ──────────────────────────────────────

    // devolver conexión activa del hilo actual
    public static Connection getConnection()
            throws SQLException {

        // validar configuración
        if (!configured) {

            throw new IllegalStateException(
                    "La conexión a la BD no está configurada. "
                    + "Revisa db.properties en src/main/resources/"
            );
        }

        Connection con = connectionHolder.get();

        // crear conexión si no existe
        if (con == null || con.isClosed()) {

            con = DriverManager.getConnection(
                    url,
                    user,
                    password
            );

            // activar autocommit por defecto
            con.setAutoCommit(true);

            connectionHolder.set(con);

            LOGGER.fine(
                    "Nueva conexión creada para el hilo: "
                    + Thread.currentThread().getName()
            );
        }

        return con;
    }

    // ─── cerrar conexión ───────────────────────────────────────

    // cerrar conexión del hilo actual
    public static void closeConnection() {

        Connection con = connectionHolder.get();

        if (con != null) {

            try {

                // cerrar conexión activa
                if (!con.isClosed()) {
                    con.close();
                }

            } catch (SQLException e) {

                LOGGER.log(
                        Level.WARNING,
                        "Error al cerrar la conexión",
                        e
                );

            } finally {

                // limpiar ThreadLocal
                connectionHolder.remove();
            }
        }
    }

    // ─── transacciones ─────────────────────────────────────────

    // iniciar transacción manual
    public static void beginTransaction()
            throws SQLException {

        getConnection().setAutoCommit(false);
    }

    // confirmar transacción
    public static void commit() throws SQLException {

        Connection con = connectionHolder.get();

        if (con != null && !con.isClosed()) {

            con.commit();

            // restaurar autocommit
            con.setAutoCommit(true);
        }
    }

    // revertir transacción
    public static void rollback() {

        Connection con = connectionHolder.get();

        if (con != null) {

            try {

                if (!con.isClosed()) {

                    con.rollback();

                    // restaurar autocommit
                    con.setAutoCommit(true);
                }

            } catch (SQLException e) {

                LOGGER.log(
                        Level.SEVERE,
                        "Error al hacer rollback",
                        e
                );
            }
        }
    }

    // ─── diagnóstico ───────────────────────────────────────────

    // probar conexión a la BD
    public static boolean testConnection() {

        // validar configuración
        if (!configured) {

            LOGGER.warning(
                    "testConnection() llamado sin configuración."
            );

            return false;
        }

        try (Connection con =
                     DriverManager.getConnection(
                             url,
                             user,
                             password
                     )) {

            boolean ok =
                    con != null
                    && !con.isClosed();

            LOGGER.info(
                    "Test de conexión a gimansio_db: "
                    + (ok ? "OK" : "FALLÓ")
            );

            return ok;

        } catch (SQLException e) {

            LOGGER.log(
                    Level.SEVERE,
                    "No se pudo conectar a la BD en testConnection()",
                    e
            );

            return false;
        }
    }

    // verificar si la configuración cargó correctamente
    public static boolean isConfigured() {
        return configured;
    }
}
*/
