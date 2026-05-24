package com.mycompany.herramientas.dao;

import com.mycompany.herramientas.config.DatabaseConnection;
import com.mycompany.herramientas.model.*;

import java.sql.*;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.logging.Logger;

/**
 * DAO para la tabla Asistencia (RF-05).
 *
 * Restricción clave de la BD:
 *   CONSTRAINT UQ_Asistencia_Dia UNIQUE (id_contrato, fecha)
 *   → Solo puede existir UN registro de asistencia por contrato por día.
 *   → existeHoy() verifica esto ANTES de hacer el INSERT.
 *
 * Nota sobre el modelo:
 *   La tabla Asistencia solo tiene FK a Contratos (id_contrato).
 *   El cliente se obtiene navegando: asistencia → contrato → cliente.
 *   No hay FK directa a Clientes en esta tabla.
 *
 * Estados válidos (según BD): 'asistio', 'falto', 'pendiente'
 *
 * ← CORRECCIÓN 3 (Corrección 3 del análisis):
 *   Se eliminó el método privado generarId() y la constante SQL_NEXT_ID
 *   que duplicaban la lógica de IdGenerator.parAsistencia().
 *   Ahora save() llama directamente a IdGenerator.parAsistencia(),
 *   que ya tiene la misma lógica y está correctamente encapsulada
 *   con la whitelist de tablas.
 *
 * ← CORRECCIÓN transacciones:
 *   Los métodos save() y cualquier método llamado desde un Service con
 *   transacción activa reciben la Connection como parámetro (overload)
 *   para no romper la transacción cerrándola con try-with-resources.
 *   La versión sin Connection es para uso simple (sin transacción del Service).
 *
 * @author MaxFit
 */
public class AsistenciaDAO {

    private static final Logger LOGGER = Logger.getLogger(AsistenciaDAO.class.getName());

    // ─── SQL ─────────────────────────────────────────────────────────────────

    private static final String SQL_SELECT_BASE =
        "SELECT a.id, a.fecha, a.estado, a.hora_ingreso, " +
        // Contrato completo (para obtener el cliente y membresía)
        "  con.id AS con_id, con.fecha_inicio, con.fecha_fin, " +
        "  con.monto_pagado, con.estado AS con_estado, " +
        "  cli.id AS cli_id, cli.nombre AS cli_nom, cli.apellido AS cli_ap, " +
        "  cli.numero_documento AS cli_doc, " +
        "  mem.id AS mem_id, mem.nombre_membresia " +
        "FROM Asistencia a " +
        "INNER JOIN Contratos con ON a.id_contrato = con.id " +
        "INNER JOIN Clientes  cli ON con.id_cliente = cli.id " +
        "INNER JOIN Membresias mem ON con.id_membresia = mem.id ";

    private static final String SQL_FIND_ALL =
        SQL_SELECT_BASE + "ORDER BY a.fecha DESC, a.hora_ingreso DESC";

    private static final String SQL_FIND_BY_CONTRATO =
        SQL_SELECT_BASE + "WHERE a.id_contrato = ? ORDER BY a.fecha DESC";

    private static final String SQL_FIND_BY_CLIENTE =
        SQL_SELECT_BASE +
        "WHERE con.id_cliente = ? ORDER BY a.fecha DESC, a.hora_ingreso DESC";

    /**
     * Filtro combinado para RF-05: historial por cliente y/o rango de fechas.
     * Los parámetros opcionales se pasan como NULL → la BD ignora ese filtro.
     */
    private static final String SQL_FILTER =
        SQL_SELECT_BASE +
        "WHERE (? IS NULL OR con.id_cliente = ?) " +
        "AND   (? IS NULL OR a.fecha >= ?) " +
        "AND   (? IS NULL OR a.fecha <= ?) " +
        "ORDER BY a.fecha DESC, a.hora_ingreso DESC";

    private static final String SQL_FIND_RECIENTES =
        SQL_SELECT_BASE +
        "ORDER BY a.fecha DESC, a.hora_ingreso DESC " +
        "OFFSET 0 ROWS FETCH NEXT ? ROWS ONLY";

    /** Verifica si ya existe un registro para (id_contrato, fecha) — respeta el UNIQUE */
    private static final String SQL_EXISTE_HOY =
        "SELECT COUNT(*) FROM Asistencia WHERE id_contrato = ? AND fecha = ?";

    private static final String SQL_COUNT_HOY =
        "SELECT COUNT(*) FROM Asistencia " +
        "WHERE fecha = CAST(GETDATE() AS DATE) AND estado = 'asistio'";

    private static final String SQL_INSERT =
        "INSERT INTO Asistencia (id, id_contrato, fecha, estado, hora_ingreso) " +
        "VALUES (?, ?, ?, ?, ?)";

    // ─── Métodos públicos ─────────────────────────────────────────────────────

    public List<Asistencia> findAll() throws SQLException {
        List<Asistencia> lista = new ArrayList<>();
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_FIND_ALL);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) lista.add(mapRow(rs));
        }
        return lista;
    }

    public List<Asistencia> findByContratoId(String contratoId) throws SQLException {
        List<Asistencia> lista = new ArrayList<>();
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_FIND_BY_CONTRATO)) {
            ps.setString(1, contratoId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) lista.add(mapRow(rs));
            }
        }
        return lista;
    }

    /** Historial completo de asistencias de un cliente (RF-05). */
    public List<Asistencia> findByClienteId(String clienteId) throws SQLException {
        List<Asistencia> lista = new ArrayList<>();
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_FIND_BY_CLIENTE)) {
            ps.setString(1, clienteId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) lista.add(mapRow(rs));
            }
        }
        return lista;
    }

    /**
     * Filtro combinado para RF-05.
     * Cualquier parámetro puede ser null para ignorarlo.
     *
     * @param clienteId  ID del cliente (null = todos los clientes)
     * @param desde      fecha de inicio del rango (null = sin límite inferior)
     * @param hasta      fecha de fin del rango    (null = sin límite superior)
     */
    public List<Asistencia> filter(String clienteId,
                                    LocalDate desde,
                                    LocalDate hasta) throws SQLException {
        List<Asistencia> lista = new ArrayList<>();
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_FILTER)) {

            // clienteId (doble porque aparece dos veces en WHERE)
            if (clienteId != null) {
                ps.setString(1, clienteId);
                ps.setString(2, clienteId);
            } else {
                ps.setNull(1, Types.VARCHAR);
                ps.setNull(2, Types.VARCHAR);
            }
            // desde
            if (desde != null) {
                ps.setDate(3, Date.valueOf(desde));
                ps.setDate(4, Date.valueOf(desde));
            } else {
                ps.setNull(3, Types.DATE);
                ps.setNull(4, Types.DATE);
            }
            // hasta
            if (hasta != null) {
                ps.setDate(5, Date.valueOf(hasta));
                ps.setDate(6, Date.valueOf(hasta));
            } else {
                ps.setNull(5, Types.DATE);
                ps.setNull(6, Types.DATE);
            }

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) lista.add(mapRow(rs));
            }
        }
        return lista;
    }

    /**
     * Últimos N check-ins, para el widget de "Actividad Reciente" del dashboard.
     * @param limite número máximo de filas a devolver (ej: 5 o 10)
     */
    public List<Asistencia> findRecientes(int limite) throws SQLException {
        List<Asistencia> lista = new ArrayList<>();
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_FIND_RECIENTES)) {
            ps.setInt(1, limite);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) lista.add(mapRow(rs));
            }
        }
        return lista;
    }

    /**
     * Verifica si ya existe un registro de asistencia para el par
     * (id_contrato, fecha). Respeta el UNIQUE (id_contrato, fecha) de la BD.
     * AsistenciaService llama esto ANTES de hacer el INSERT.
     */
    public boolean existeHoy(String contratoId, LocalDate fecha) throws SQLException {
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_EXISTE_HOY)) {
            ps.setString(1, contratoId);
            ps.setDate(2, Date.valueOf(fecha));
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getInt(1) > 0;
            }
        }
        return false;
    }

    /**
     * Total de check-ins ('asistio') del día de hoy.
     * Para el widget "Atendidos Hoy" del dashboard de Recepcionista.
     */
    public int countHoy() throws SQLException {
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_COUNT_HOY);
             ResultSet rs = ps.executeQuery()) {
            if (rs.next()) return rs.getInt(1);
        }
        return 0;
    }

    /**
     * Guarda una nueva asistencia (versión sin transacción del Service).
     * Abre su propia conexión con try-with-resources — NO usar cuando
     * hay una transacción activa en el Service; usar save(Connection, Asistencia).
     *
     * ← CORRECCIÓN 3: El ID se genera con IdGenerator.parAsistencia()
     *   en lugar del antiguo generarId() privado que duplicaba esa lógica.
     */
    public void save(Asistencia asistencia) throws SQLException {
        if (asistencia.getId() == null || asistencia.getId().trim().isEmpty()) {
            asistencia.setId(IdGenerator.parAsistencia());
        }
        try (Connection con = DatabaseConnection.getConnection()) {
            doInsert(con, asistencia);
        }
    }

    /**
     * Guarda una nueva asistencia DENTRO de una transacción activa.
     *
     * ← CORRECCIÓN transacciones: cuando AsistenciaService llama a este DAO
     *   dentro de un beginTransaction() / commit(), la Connection debe ser
     *   la misma que ya tiene la transacción abierta. Al recibir la Connection
     *   como parámetro, este método NO la cierra (no usa try-with-resources
     *   sobre ella), de modo que el Service puede hacer commit() o rollback()
     *   después sin perder el contexto transaccional.
     *
     * El ID se genera con IdGenerator.parAsistencia() si no trae uno.
     *
     * @param con        la Connection con transacción ya iniciada
     *                   (DatabaseConnection.beginTransaction() ya fue llamado)
     * @param asistencia objeto a persistir
     */
    public void save(Connection con, Asistencia asistencia) throws SQLException {
        if (asistencia.getId() == null || asistencia.getId().trim().isEmpty()) {
            asistencia.setId(IdGenerator.parAsistencia());
        }
        doInsert(con, asistencia);
    }

    // ─── Privados ─────────────────────────────────────────────────────────────

    /**
     * Ejecuta el INSERT sobre la Connection proporcionada.
     * El PreparedStatement se cierra con try-with-resources;
     * la Connection NO se cierra aquí (la gestiona el llamador).
     */
    private void doInsert(Connection con, Asistencia asistencia) throws SQLException {
        try (PreparedStatement ps = con.prepareStatement(SQL_INSERT)) {
            ps.setString(1, asistencia.getId());
            ps.setString(2, asistencia.getContrato().getId());
            ps.setDate(3, Date.valueOf(asistencia.getFecha()));
            ps.setString(4, asistencia.getEstado());
            // hora_ingreso NULL-able (null si es 'falto' o 'pendiente')
            if (asistencia.getHoraIngreso() != null) {
                ps.setTime(5, Time.valueOf(asistencia.getHoraIngreso()));
            } else {
                ps.setNull(5, Types.TIME);
            }
            ps.executeUpdate();
            LOGGER.info("Asistencia registrada: " + asistencia.getId()
                    + " | contrato: " + asistencia.getContrato().getId());
        }
    }

    private Asistencia mapRow(ResultSet rs) throws SQLException {
        // Membresía (mínima, solo nombre para mostrar en el widget)
        Membresia mem = new Membresia();
        mem.setId(rs.getString("mem_id"));
        mem.setNombreMembresia(rs.getString("nombre_membresia"));

        // Cliente (mínimo para mostrar en la tabla de asistencias)
        Cliente cli = new Cliente();
        cli.setId(rs.getString("cli_id"));
        cli.setNombre(rs.getString("cli_nom"));
        cli.setApellido(rs.getString("cli_ap"));
        cli.setNumeroDocumento(rs.getString("cli_doc"));

        // Contrato (parcial — solo datos necesarios para Asistencia)
        Contrato contrato = new Contrato();
        contrato.setId(rs.getString("con_id"));
        contrato.setFechaInicio(rs.getDate("fecha_inicio").toLocalDate());
        contrato.setFechaFin(rs.getDate("fecha_fin").toLocalDate());
        contrato.setEstado(rs.getString("con_estado"));
        contrato.setCliente(cli);
        contrato.setMembresia(mem);

        // Asistencia
        Asistencia a = new Asistencia();
        a.setId(rs.getString("id"));
        a.setContrato(contrato);
        a.setFecha(rs.getDate("fecha").toLocalDate());
        a.setEstado(rs.getString("estado"));

        // hora_ingreso NULL-able
        Time hora = rs.getTime("hora_ingreso");
        a.setHoraIngreso(rs.wasNull() ? null : hora.toLocalTime());

        return a;
    }
}