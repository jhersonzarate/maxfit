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

// generador central de IDs del sistema
public final class IdGenerator {

    private static final Logger LOGGER =
            Logger.getLogger(IdGenerator.class.getName());

    // whitelist de tablas permitidas
    private static final Set<String> TABLAS_VALIDAS;

    // ─── inicialización estática ───────────────────────────────

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
        tablas.add("MetodosPago");

        TABLAS_VALIDAS = Collections.unmodifiableSet(tablas);
    }

    // evitar instancias de clase utilitaria
    private IdGenerator() {}

    // ─── generar IDs ───────────────────────────────────────────

    // genera el siguiente ID disponible para una tabla
    public static String generar(String prefijo, String nombreTabla) {

        // validar tabla permitida antes de concatenar al SQL
        if (nombreTabla == null
                || !TABLAS_VALIDAS.contains(nombreTabla)) {

            throw new IllegalArgumentException(
                "Nombre de tabla no permitido en IdGenerator: '"
                + nombreTabla + "'. "
                + "Solo se permiten tablas definidas en TABLAS_VALIDAS."
            );
        }

        int año = LocalDate.now().getYear();

        // patrón para filtrar IDs del año actual
        String patron = prefijo + "-" + año + "-%";

        // prefijo usado para calcular el SUBSTRING
        String prefYear = prefijo + "-" + año + "-";

        /*
         * ejemplo:
         * CLI-2026-0042
         *
         * substring -> 0042
         * cast      -> 42
         */
        String sql =
            "SELECT ISNULL(MAX(CAST(SUBSTRING(id, LEN(?) + 1, LEN(id)) AS INT)), 0) + 1 " +
            "FROM " + nombreTabla + " " +
            "WHERE id LIKE ?";

        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {

            // offset para el substring
            ps.setString(1, prefYear);

            // filtro LIKE
            ps.setString(2, patron);

            try (ResultSet rs = ps.executeQuery()) {

                int siguiente = rs.next()
                        ? rs.getInt(1)
                        : 1;

                // formato final: CLI-2026-0042
                return String.format(
                        "%s-%d-%04d",
                        prefijo,
                        año,
                        siguiente
                );
            }

        } catch (SQLException e) {

            LOGGER.log(
                    Level.SEVERE,
                    "Error al generar ID para tabla '"
                            + nombreTabla
                            + "' con prefijo '"
                            + prefijo + "'",
                    e
            );

            // fallback usando timestamp
            return prefijo
                    + "-"
                    + año
                    + "-"
                    + System.currentTimeMillis();
        }
    }

    // ─── helpers por entidad ───────────────────────────────────

    // genera ID para cliente
    public static String parCliente() {
        return generar(AppConfig.PREFIX_CLIENTE, "Clientes");
    }

    // genera ID para empleado
    public static String parEmpleado() {
        return generar(AppConfig.PREFIX_EMPLEADO, "Empleados");
    }

    // genera ID para contrato
    public static String parContrato() {
        return generar(AppConfig.PREFIX_CONTRATO, "Contratos");
    }

    // genera ID para asistencia
    public static String parAsistencia() {
        return generar(AppConfig.PREFIX_ASISTENCIA, "Asistencia");
    }

    // genera ID para clase
    public static String parClase() {
        return generar(AppConfig.PREFIX_CLASE, "Clases");
    }

    // genera ID para horario
    public static String parHorario() {
        return generar(AppConfig.PREFIX_HORARIO, "Horarios");
    }

    // genera ID para inscripción
    public static String parInscripcion() {
        return generar(
                AppConfig.PREFIX_INSCRIPCION,
                "Inscripcion_Clases"
        );
    }

    // genera ID para usuario
    public static String parUsuario() {
        return generar(AppConfig.PREFIX_USUARIO, "Usuarios");
    }

    // genera ID para metodo de pago
    public static String parMetodoPago() {
        return generar(AppConfig.PREFIX_METODO_PAGO, "MetodosPago");
    }
}