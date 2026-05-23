package com.mycompany.herramientas.dao;

import com.mycompany.herramientas.config.AppConfig;
import com.mycompany.herramientas.config.DatabaseConnection;

import java.sql.*;
import java.time.LocalDate;
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
 *   En un sistema con muchas peticiones simultáneas se usaría
 *   una SEQUENCE de SQL Server, pero para este proyecto es correcto.
 *
 * Uso desde los controladores o servicios:
 *   String id = IdGenerator.parCliente();      // "CLI-2026-0001"
 *   String id = IdGenerator.parContrato();     // "CON-2026-0001"
 *   String id = IdGenerator.parAsistencia();   // "ASI-2026-0001"
 *   // … etc.
 */
public final class IdGenerator {

    private static final Logger LOGGER = Logger.getLogger(IdGenerator.class.getName());

    // Constructor privado — nadie debe instanciar esta clase utilitaria
    private IdGenerator() {}

    /**
     * Genera el próximo ID disponible para una tabla dada.
     *
     * Algoritmo:
     *   1. Filtra los IDs de la tabla que correspondan al año actual
     *      usando LIKE 'PREFIJO-AÑO-%'.
     *   2. Extrae la parte numérica del ID (después del último '-').
     *   3. Toma el MAX de esos números + 1.
     *   4. Si no hay IDs todavía, devuelve 1.
     *   5. Formatea como PREFIJO-AÑO-NNNN (4 dígitos con ceros a la izq.).
     *
     * @param prefijo     constante de AppConfig.PREFIX_* (ej: "CLI")
     * @param nombreTabla nombre exacto de la tabla en SQL Server (ej: "Clientes")
     * @return ID generado, ej: "CLI-2026-0001"
     */
    public static String generar(String prefijo, String nombreTabla) {
        int año = LocalDate.now().getYear();

        // Patrón para filtrar solo los IDs de este año: "CLI-2026-%"
        String patron  = prefijo + "-" + año + "-%";
        // Prefijo con año para calcular el offset del SUBSTRING: "CLI-2026"
        String prefYear = prefijo + "-" + año + "-";

        /*
         * LEN(prefYear) + 1 = posición donde empieza el correlativo numérico.
         * Ejemplo: "CLI-2026-0042"
         *           LEN("CLI-2026-") = 9
         *           SUBSTRING(id, 10, LEN(id)) = "0042"
         *           CAST como INT = 42
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