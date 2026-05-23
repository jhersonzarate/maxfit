package com.mycompany.herramientas.dao;

import com.mycompany.herramientas.config.AppConfig;
import com.mycompany.herramientas.config.DatabaseConnection;
import com.mycompany.herramientas.model.*;

import java.sql.*;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.ArrayList;
import java.util.List;
import java.util.logging.Logger;

/**
 * DAO para la tabla Asistencia (RF-04, RF-05).
 *
 * Restricción clave de la BD:
 *   CONSTRAINT UQ_Asistencia_Dia UNIQUE (id_contrato, fecha)
 *   → Solo puede existir UN registro de asistencia por contrato por día.
 *   → existeHoy() verifica esto ANTES de hacer el INSERT.
 *
 * La tabla Asistencia solo tiene FK a Contratos (id_contrato).
 * El cliente se obtiene navegando: asistencia → contrato → cliente.
 *
 * Estados válidos (columna estado): 'asistio', 'falto', 'pendiente'
 * hora_ingreso: TIME NULL — se rellena al hacer check-in.
 *
 * Formato de ID: ASI-AÑO-CORRELATIVO (ej: ASI-2026-0001)
 * El correlativo se calcula directamente en BD para ser thread-safe.
 */
public class AsistenciaDAO {

    private static final Logger LOGGER = Logger.getLogger(AsistenciaDAO.class.getName());

    // ─── SQL ─────────────────────────────────────────────────────────────────

    private static final String SQL_SELECT_BASE =
        "SELECT a.id, a.fecha, a.estado, a.hora_ingreso, " +
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
     * Filtro combinado (RF-05): por cliente y/o rango de fechas.
     * Los parámetros opcionales se pasan como NULL → la BD ignora ese filtro.
     * Cada filtro ocupa dos posiciones porque aparece dos veces en el WHERE.
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

    /** Verifica existencia del par (id_contrato, fecha) — respeta el UNIQUE */
    private static final String SQL_EXISTE_HOY =
        "SELECT COUNT(*) FROM Asistencia WHERE id_contrato = ? AND fecha = ?";

    /** Total de check-ins con estado 'asistio' para el día de hoy */
    private static final String SQL_COUNT_HOY =
        "SELECT COUNT(*) FROM Asistencia " +
        "WHERE fecha = CAST(GETDATE() AS DATE) AND estado = 'asistio'";

    /**
     * INSERT de una nueva asistencia.
     * Posiciones: 1=id, 2=id_contrato, 3=fecha, 4=estado, 5=hora_ingreso
     */
    private static final String SQL_INSERT =
        "INSERT INTO Asistencia (id, id_contrato, fecha, estado, hora_ingreso) " +
        "VALUES (?, ?, ?, ?, ?)";

    /**
     * UPDATE del estado y hora de ingreso de una asistencia existente.
     * Posiciones: 1=estado, 2=hora_ingreso, 3=id
     */
    private static final String SQL_UPDATE_ESTADO =
        "UPDATE Asistencia SET estado = ?, hora_ingreso = ? WHERE id = ?";

    /**
     * Calcula el siguiente correlativo para el formato ASI-AÑO-CORRELATIVO.
     * Extrae el número después del último '-' en IDs que empiecen con 'ASI-'.
     */
    private static final String SQL_NEXT_ID =
        "SELECT ISNULL(MAX(CAST(SUBSTRING(id, CHARINDEX('-', id, 5)+1, 10) AS INT)), 0) + 1 " +
        "FROM Asistencia WHERE id LIKE 'ASI-%'";

    // ─── Métodos públicos ─────────────────────────────────────────────────────

    /** Devuelve todas las asistencias ordenadas por fecha y hora descendente. */
    public List<Asistencia> findAll() throws SQLException {
        List<Asistencia> lista = new ArrayList<>();
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_FIND_ALL);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) lista.add(mapRow(rs));
        }
        return lista;
    }

    /** Historial de asistencias de un contrato específico. */
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
     * @param clienteId  ID del cliente  (null = todos los clientes)
     * @param desde      Fecha de inicio del rango (null = sin límite inferior)
     * @param hasta      Fecha de fin del rango    (null = sin límite superior)
     */
    public List<Asistencia> filter(String clienteId,
                                    LocalDate desde,
                                    LocalDate hasta) throws SQLException {
        List<Asistencia> lista = new ArrayList<>();
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_FILTER)) {

            // Parámetros 1-2: clienteId (aparece dos veces en el WHERE)
            if (clienteId != null) {
                ps.setString(1, clienteId);
                ps.setString(2, clienteId);
            } else {
                ps.setNull(1, Types.VARCHAR);
                ps.setNull(2, Types.VARCHAR);
            }
            // Parámetros 3-4: desde
            if (desde != null) {
                ps.setDate(3, Date.valueOf(desde));
                ps.setDate(4, Date.valueOf(desde));
            } else {
                ps.setNull(3, Types.DATE);
                ps.setNull(4, Types.DATE);
            }
            // Parámetros 5-6: hasta
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
     * Últimas N asistencias — para el widget "Actividad Reciente" del dashboard.
     *
     * @param limite número máximo de filas (ej: 5 o 10)
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
     * Verifica si ya existe un registro para el par (id_contrato, fecha).
     * Respeta el UNIQUE (id_contrato, fecha) de la BD.
     * AsistenciaService llama esto ANTES de hacer el INSERT.
     */
    public boolean existeHoy(String contratoId, LocalDate fecha) throws SQLException {
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_EXISTE_HOY)) {
            ps.setString(1, contratoId);
            ps.setDate(2, Date.valueOf(fecha));
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() && rs.getInt(1) > 0;
            }
        }
    }

    /**
     * Total de check-ins ('asistio') del día de hoy.
     * Para el widget "Atendidos Hoy" del dashboard del Recepcionista.
     */
    public int countHoy() throws SQLException {
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_COUNT_HOY);
             ResultSet rs = ps.executeQuery()) {
            return rs.next() ? rs.getInt(1) : 0;
        }
    }

    /**
     * Guarda una nueva asistencia en la BD.
     * El ID se genera aquí usando el correlativo calculado en la BD.
     *
     * Posiciones del INSERT:
     *   1 = id
     *   2 = id_contrato
     *   3 = fecha
     *   4 = estado
     *   5 = hora_ingreso (puede ser NULL)
     *
     * @param asistencia objeto con todos los campos excepto el id (se genera aquí)
     */
    public void save(Asistencia asistencia) throws SQLException {
        if (asistencia.getId() == null || asistencia.getId().trim().isEmpty()) {
            asistencia.setId(generarId());
        }

        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_INSERT)) {
            ps.setString(1, asistencia.getId());
            ps.setString(2, asistencia.getContrato().getId());
            ps.setDate(3, Date.valueOf(asistencia.getFecha()));
            ps.setString(4, asistencia.getEstado());

            // hora_ingreso es NULL-able — null si estado es 'falto' o 'pendiente'
            if (asistencia.getHoraIngreso() != null) {
                ps.setTime(5, Time.valueOf(asistencia.getHoraIngreso()));
            } else {
                ps.setNull(5, Types.TIME);
            }

            ps.executeUpdate();
            LOGGER.info("Asistencia registrada: " + asistencia.getId()
                    + " | contrato: " + asistencia.getContrato().getId()
                    + " | estado: " + asistencia.getEstado());
        }
    }

    /**
     * Actualiza el estado y la hora_ingreso de una asistencia existente.
     * Útil para pasar de 'pendiente' a 'asistio' o 'falto'.
     *
     * Posiciones del UPDATE:
     *   1 = estado
     *   2 = hora_ingreso (puede ser NULL si estado es 'falto')
     *   3 = id
     *
     * @return true si se actualizó al menos una fila
     */
    public boolean updateEstado(String id, String nuevoEstado, LocalTime horaIngreso)
            throws SQLException {
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_UPDATE_ESTADO)) {
            ps.setString(1, nuevoEstado);
            if (horaIngreso != null) {
                ps.setTime(2, Time.valueOf(horaIngreso));
            } else {
                ps.setNull(2, Types.TIME);
            }
            ps.setString(3, id);
            int filas = ps.executeUpdate();
            if (filas > 0) {
                LOGGER.info("Asistencia actualizada: id=" + id + " → estado=" + nuevoEstado);
            }
            return filas > 0;
        }
    }

    // ─── Privados ─────────────────────────────────────────────────────────────

    /**
     * Genera el ID de la asistencia con formato ASI-AÑO-CORRELATIVO.
     * El correlativo se obtiene de la BD para ser thread-safe en Tomcat.
     * Ejemplo: ASI-2026-0001
     */
    private String generarId() throws SQLException {
        int anio = LocalDate.now().getYear();
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_NEXT_ID);
             ResultSet rs = ps.executeQuery()) {
            int siguiente = rs.next() ? rs.getInt(1) : 1;
            return String.format("%s-%d-%04d", AppConfig.PREFIX_ASISTENCIA, anio, siguiente);
        }
    }

    /**
     * Mapea una fila del ResultSet a un objeto Asistencia completo.
     * Construye el árbol: Asistencia → Contrato → Cliente + Membresia.
     */
    private Asistencia mapRow(ResultSet rs) throws SQLException {
        // Membresía (parcial — solo el nombre para mostrar en widgets)
        Membresia mem = new Membresia();
        mem.setId(rs.getString("mem_id"));
        mem.setNombreMembresia(rs.getString("nombre_membresia"));

        // Cliente (parcial — solo datos necesarios para mostrar en tablas)
        Cliente cli = new Cliente();
        cli.setId(rs.getString("cli_id"));
        cli.setNombre(rs.getString("cli_nom"));
        cli.setApellido(rs.getString("cli_ap"));
        cli.setNumeroDocumento(rs.getString("cli_doc"));

        // Contrato (parcial — sin empleado ni método de pago, no necesarios aquí)
        Contrato contrato = new Contrato();
        contrato.setId(rs.getString("con_id"));
        contrato.setFechaInicio(rs.getDate("fecha_inicio").toLocalDate());
        contrato.setFechaFin(rs.getDate("fecha_fin").toLocalDate());
        contrato.setMontoPagado(rs.getBigDecimal("monto_pagado"));
        contrato.setEstado(rs.getString("con_estado"));
        contrato.setCliente(cli);
        contrato.setMembresia(mem);

        // Asistencia
        Asistencia a = new Asistencia();
        a.setId(rs.getString("id"));
        a.setContrato(contrato);
        a.setFecha(rs.getDate("fecha").toLocalDate());
        a.setEstado(rs.getString("estado"));

        // hora_ingreso es NULL-able — usar wasNull() tras getTime()
        Time hora = rs.getTime("hora_ingreso");
        a.setHoraIngreso(rs.wasNull() ? null : hora.toLocalTime());

        return a;
    }
}