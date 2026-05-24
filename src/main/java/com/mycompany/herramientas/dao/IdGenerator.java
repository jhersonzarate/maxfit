package com.mycompany.herramientas.dao;

import com.mycompany.herramientas.config.AppConfig;
import com.mycompany.herramientas.config.DatabaseConnection;

import java.sql.*;
import java.time.LocalDate;
import java.util.Collections;
import java.util.HashSet;
import java.util.Set;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * Generador de IDs para todas las entidades del sistema.
 *
 * Formato: PREFIJO-AÑO-CORRELATIVO (con 4 dígitos en el correlativo)
 * Ejemplos:
 *   CLI-2026-0001  → primer cliente registrado en 2026
 *   CON-2026-0042  → contrato número 42 del año 2026
 *   ASI-2026-0150  → asistencia número 150 del año 2026
 *   USR-2026-0003  → usuario número 3 del año 2026
 *
 * Por qué este formato y no IDENTITY de SQL Server:
 *   Los IDs de la BD son VARCHAR(20) según el diagrama del proyecto.
 *   El formato con prefijo hace que un ID como "CON-2026-0001" le diga
 *   al administrador inmediatamente: "contrato, año 2026, número 1".
 *   Es auditable, legible y alineado con el diseño de la BD.
 *
 * Thread-safety:
 *   El correlativo se calcula con MAX()+1 directamente en la BD.
 *   SQL Server garantiza la consistencia bajo concurrencia.
 *
 * ← CORREGIDO (Corrección 2):
 *   Se añadió TABLAS_VALIDAS (whitelist) para que el nombre de tabla
 *   nunca pueda ser inyectado con valores externos. Aunque actualmente
 *   solo se llama con literales del propio código, el patrón de
 *   concatenación directa ("FROM " + nombreTabla) era potencialmente
 *   peligroso si en el futuro se pasara un valor externo.
 *   Ahora se lanza IllegalArgumentException si la tabla no está en la lista.
 *
 * @author MaxFit
 */
public final class IdGenerator {

    private static final Logger LOGGER = Logger.getLogger(IdGenerator.class.getName());

    // ← CORREGIDO: whitelist de tablas permitidas.
    // El nombre de tabla se concatena directamente al SQL (no es posible usar
    // PreparedStatement para nombres de tabla en JDBC estándar), por eso se
    // valida contra este conjunto antes de construir el query.
    private static final Set<String> TABLAS_VALIDAS;

    static {
        Set<String> tablas = new HashSet<>();
        tablas.add("Clientes");
        tablas.add("Empleados");
        tablas.add("Contratos");
        tablas.add("Asistencia");
        tablas.add("Clases");
        tablas.add("Horarios");
        tablas.add("Inscripcion_Clases");
        tablas.add("Usuarios");
        tablas.add("Membresias");
        TABLAS_VALIDAS = Collections.unmodifiableSet(tablas);
    }

    // Constructor privado — nadie debe instanciar esta clase utilitaria
    private IdGenerator() {}

    /**
     * Genera el próximo ID disponible para una tabla dada.
     *
     * Algoritmo:
     *   1. Valida que nombreTabla pertenezca a TABLAS_VALIDAS (whitelist).
     *   2. Filtra los IDs de la tabla que correspondan al año actual
     *      usando LIKE 'PREFIJO-AÑO-%'.
     *   3. Extrae la parte numérica del ID (después del último '-').
     *   4. Toma el MAX de esos números + 1.
     *   5. Si no hay IDs todavía, devuelve 1.
     *   6. Formatea como PREFIJO-AÑO-NNNN (4 dígitos con ceros a la izq.).
     *
     * @param prefijo     constante de AppConfig.PREFIX_* (ej: "CLI")
     * @param nombreTabla nombre exacto de la tabla en SQL Server — DEBE
     *                    estar en TABLAS_VALIDAS, de lo contrario se lanza
     *                    IllegalArgumentException
     * @return ID generado, ej: "CLI-2026-0001"
     * @throws IllegalArgumentException si nombreTabla no está en la whitelist
     */
    public static String generar(String prefijo, String nombreTabla) {

        // ← CORREGIDO: validación de whitelist antes de concatenar al SQL
        if (nombreTabla == null || !TABLAS_VALIDAS.contains(nombreTabla)) {
            throw new IllegalArgumentException(
                "Nombre de tabla no permitido en IdGenerator: '"
                + nombreTabla + "'. "
                + "Solo se permiten tablas definidas en TABLAS_VALIDAS."
            );
        }

        int año = LocalDate.now().getYear();

        // Patrón para filtrar solo los IDs de este año: "CLI-2026-%"
        String patron   = prefijo + "-" + año + "-%";
        // Prefijo con año para calcular el offset del SUBSTRING: "CLI-2026-"
        String prefYear = prefijo + "-" + año + "-";

        /*
         * LEN(prefYear) + 1 = posición donde empieza el correlativo numérico.
         * Ejemplo: "CLI-2026-0042"
         *           LEN("CLI-2026-") = 9
         *           SUBSTRING(id, 10, LEN(id)) = "0042"
         *           CAST como INT = 42
         *
         * NOTA SOBRE SEGURIDAD: nombreTabla ya fue validado contra TABLAS_VALIDAS
         * antes de llegar aquí, por lo que la concatenación es segura.
         */
        String sql =
            "SELECT ISNULL(MAX(CAST(SUBSTRING(id, LEN(?) + 1, LEN(id)) AS INT)), 0) + 1 " +
            "FROM " + nombreTabla + " " +
            "WHERE id LIKE ?";

        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setString(1, prefYear);   // para calcular el offset
            ps.setString(2, patron);     // para el LIKE

            try (ResultSet rs = ps.executeQuery()) {
                int siguiente = rs.next() ? rs.getInt(1) : 1;
                // Formato: CLI-2026-0042 (4 dígitos con ceros a la izquierda)
                return String.format("%s-%d-%04d", prefijo, año, siguiente);
            }

        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE,
                    "Error al generar ID para tabla '" + nombreTabla
                    + "' con prefijo '" + prefijo + "'", e);
            /*
             * Fallback de emergencia: usa el timestamp en milisegundos.
             * Garantiza unicidad aunque el formato no sea tan legible.
             * El log de SEVERE avisará al desarrollador para corregirlo.
             */
            return prefijo + "-" + año + "-" + System.currentTimeMillis();
        }
    }

    // ─── Métodos de conveniencia por entidad ──────────────────────────────────
    //
    // Usan las constantes PREFIX_* de AppConfig y los nombres exactos
    // de las tablas en SQL Server (case-sensitive en algunos servidores).

    /** Genera el próximo ID para un Cliente. Ej: "CLI-2026-0001" */
    public static String parCliente() {
        return generar(AppConfig.PREFIX_CLIENTE, "Clientes");
    }

    /** Genera el próximo ID para un Empleado. Ej: "EMP-2026-0001" */
    public static String parEmpleado() {
        return generar(AppConfig.PREFIX_EMPLEADO, "Empleados");
    }

    /** Genera el próximo ID para un Contrato. Ej: "CON-2026-0001" */
    public static String parContrato() {
        return generar(AppConfig.PREFIX_CONTRATO, "Contratos");
    }

    /** Genera el próximo ID para una Asistencia. Ej: "ASI-2026-0001" */
    public static String parAsistencia() {
        return generar(AppConfig.PREFIX_ASISTENCIA, "Asistencia");
    }

    /** Genera el próximo ID para una Clase. Ej: "CLA-2026-0001" */
    public static String parClase() {
        return generar(AppConfig.PREFIX_CLASE, "Clases");
    }

    /** Genera el próximo ID para un Horario. Ej: "HOR-2026-0001" */
    public static String parHorario() {
        return generar(AppConfig.PREFIX_HORARIO, "Horarios");
    }

    /** Genera el próximo ID para una Inscripcion_Clase. Ej: "INS-2026-0001" */
    public static String parInscripcion() {
        return generar(AppConfig.PREFIX_INSCRIPCION, "Inscripcion_Clases");
    }

    /** Genera el próximo ID para un Usuario. Ej: "USR-2026-0001" */
    public static String parUsuario() {
        return generar(AppConfig.PREFIX_USUARIO, "Usuarios");
    }
}