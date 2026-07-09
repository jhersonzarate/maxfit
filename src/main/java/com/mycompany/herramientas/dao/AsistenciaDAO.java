package com.mycompany.herramientas.dao;

import com.mycompany.herramientas.config.DatabaseConnection;
import com.mycompany.herramientas.model.*;

import java.sql.*;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.logging.Logger;

// DAO para la tabla Asistencia (RF-05)
// restricción clave: UNIQUE (id_contrato, fecha) → un registro por contrato por día
// el cliente se obtiene navegando: asistencia → contrato → cliente (no hay FK directa)
// estados válidos: 'asistio', 'falto', 'pendiente'
public class AsistenciaDAO {

    private static final Logger LOGGER = Logger.getLogger(AsistenciaDAO.class.getName());

    // ─── SQL ───────────────────────────────────────────────────

    private static final String SQL_SELECT_BASE =
        "SELECT a.id, a.fecha, a.estado, a.hora_ingreso, " +
        // contrato completo para obtener cliente y membresía
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

    // filtro combinado para RF-05: parámetros opcionales pasados como NULL
    private static final String SQL_FILTER =
        SQL_SELECT_BASE +
        "WHERE (? IS NULL OR cli.nombre LIKE ? OR cli.apellido LIKE ?) " +
        "AND   (? IS NULL OR a.fecha >= ?) " +
        "AND   (? IS NULL OR a.fecha <= ?) " +
        "ORDER BY a.fecha DESC, a.hora_ingreso DESC";

    private static final String SQL_FIND_RECIENTES =
        SQL_SELECT_BASE +
        "ORDER BY a.fecha DESC, a.hora_ingreso DESC " +
        "OFFSET 0 ROWS FETCH NEXT ? ROWS ONLY";

    // verifica si ya existe un registro para (id_contrato, fecha) — respeta el UNIQUE
    private static final String SQL_EXISTE_HOY =
        "SELECT COUNT(*) FROM Asistencia WHERE id_contrato = ? AND fecha = ?";

    private static final String SQL_COUNT_HOY =
        "SELECT COUNT(*) FROM Asistencia " +
        "WHERE fecha = CAST(GETDATE() AS DATE) AND estado = 'asistio'";

    private static final String SQL_INSERT =
        "INSERT INTO Asistencia (id, id_contrato, fecha, estado, hora_ingreso) " +
        "VALUES (?, ?, ?, ?, ?)";

    private static final String SQL_CONTEO_POR_RANGO =
        "SELECT fecha, COUNT(*) AS total FROM Asistencia " +
        "WHERE fecha >= ? AND fecha <= ? AND estado = 'asistio' " +
        "GROUP BY fecha ORDER BY fecha ASC";

    // ─── métodos públicos ──────────────────────────────────────

    public List<Asistencia> findAll() throws SQLException {
        List<Asistencia> lista = new ArrayList<>();
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_FIND_ALL);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) lista.add(mapRow(rs));
        }
        return lista;
    }

    public Map<LocalDate, Integer> getConteoAsistenciaPorRango(LocalDate inicio, LocalDate fin) throws SQLException {
        Map<LocalDate, Integer> conteo = new LinkedHashMap<>();
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_CONTEO_POR_RANGO)) {
            ps.setDate(1, java.sql.Date.valueOf(inicio));
            ps.setDate(2, java.sql.Date.valueOf(fin));
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    conteo.put(rs.getDate("fecha").toLocalDate(), rs.getInt("total"));
                }
            }
        }
        return conteo;
    }

    public String[] getDiaPicoAsistencia() throws SQLException {
        String sql = "SELECT fecha, COUNT(*) as total FROM Asistencia WHERE estado = 'asistio' GROUP BY fecha";
        java.util.Map<java.time.DayOfWeek, Integer> totalPorDia = new java.util.HashMap<>();
        java.util.Map<java.time.DayOfWeek, Integer> diasDistintos = new java.util.HashMap<>();
        
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                LocalDate date = rs.getDate("fecha").toLocalDate();
                int total = rs.getInt("total");
                java.time.DayOfWeek dow = date.getDayOfWeek();
                
                totalPorDia.put(dow, totalPorDia.getOrDefault(dow, 0) + total);
                diasDistintos.put(dow, diasDistintos.getOrDefault(dow, 0) + 1);
            }
        }
        
        java.time.DayOfWeek peakDay = null;
        int maxTotal = -1;
        for (java.util.Map.Entry<java.time.DayOfWeek, Integer> entry : totalPorDia.entrySet()) {
            if (entry.getValue() > maxTotal) {
                maxTotal = entry.getValue();
                peakDay = entry.getKey();
            }
        }
        
        if (peakDay == null) {
            return new String[]{"Ninguno", "0"};
        }
        
        int average = maxTotal / diasDistintos.get(peakDay);
        String dayName = peakDay.getDisplayName(java.time.format.TextStyle.FULL, new java.util.Locale("es", "ES"));
        dayName = dayName.substring(0, 1).toUpperCase() + dayName.substring(1);
        
        return new String[]{dayName, String.valueOf(average)};
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

    // historial completo de asistencias de un cliente (RF-05)
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

    // filtro combinado para RF-05 — cualquier parámetro puede ser null para ignorarlo
    public List<Asistencia> filter(String clienteBusqueda,
                                    LocalDate desde,
                                    LocalDate hasta) throws SQLException {
        List<Asistencia> lista = new ArrayList<>();
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_FILTER)) {

            // clienteBusqueda aparece tres veces en el WHERE
            if (clienteBusqueda != null && !clienteBusqueda.trim().isEmpty()) {
                String term = clienteBusqueda.trim() + "%";
                ps.setString(1, term);
                ps.setString(2, term);
                ps.setString(3, term);
            } else {
                ps.setNull(1, Types.VARCHAR);
                ps.setNull(2, Types.VARCHAR);
                ps.setNull(3, Types.VARCHAR);
            }
            // límite inferior del rango de fechas
            if (desde != null) {
                ps.setDate(4, Date.valueOf(desde));
                ps.setDate(5, Date.valueOf(desde));
            } else {
                ps.setNull(4, Types.DATE);
                ps.setNull(5, Types.DATE);
            }
            // límite superior del rango de fechas
            if (hasta != null) {
                ps.setDate(6, Date.valueOf(hasta));
                ps.setDate(7, Date.valueOf(hasta));
            } else {
                ps.setNull(6, Types.DATE);
                ps.setNull(7, Types.DATE);
            }

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) lista.add(mapRow(rs));
            }
        }
        return lista;
    }

    // últimos N check-ins para el widget de actividad reciente del dashboard
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

    // verifica si ya existe asistencia para (id_contrato, fecha) antes del INSERT
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

    // total de check-ins del día para el widget "Atendidos Hoy" del dashboard
    public int countHoy() throws SQLException {
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_COUNT_HOY);
             ResultSet rs = ps.executeQuery()) {
            if (rs.next()) return rs.getInt(1);
        }
        return 0;
    }

    // guarda una nueva asistencia sin transacción — abre su propia conexión
    // no usar cuando hay una transacción activa en el Service; usar save(Connection, Asistencia)
    public void save(Asistencia asistencia) throws SQLException {
        if (asistencia.getId() == null || asistencia.getId().trim().isEmpty()) {
            asistencia.setId(IdGenerator.parAsistencia());
        }
        try (Connection con = DatabaseConnection.getConnection()) {
            doInsert(con, asistencia);
        }
    }

    // guarda una nueva asistencia dentro de una transacción activa del Service
    // recibe la Connection para no cerrarla — el Service hace commit/rollback después
    public void save(Connection con, Asistencia asistencia) throws SQLException {
        if (asistencia.getId() == null || asistencia.getId().trim().isEmpty()) {
            asistencia.setId(IdGenerator.parAsistencia());
        }
        doInsert(con, asistencia);
    }

    // ─── privados ──────────────────────────────────────────────

    // ejecuta el INSERT — el PreparedStatement se cierra aquí; la Connection no
    private void doInsert(Connection con, Asistencia asistencia) throws SQLException {
        try (PreparedStatement ps = con.prepareStatement(SQL_INSERT)) {
            ps.setString(1, asistencia.getId());
            ps.setString(2, asistencia.getContrato().getId());
            ps.setDate(3, Date.valueOf(asistencia.getFecha()));
            ps.setString(4, asistencia.getEstado());
            // hora_ingreso es NULL-able (null si es 'falto' o 'pendiente')
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
        // membresía (mínima — solo nombre para el widget)
        Membresia mem = new Membresia();
        mem.setId(rs.getString("mem_id"));
        mem.setNombreMembresia(rs.getString("nombre_membresia"));

        // cliente (mínimo para mostrar en la tabla de asistencias)
        Cliente cli = new Cliente();
        cli.setId(rs.getString("cli_id"));
        cli.setNombre(rs.getString("cli_nom"));
        cli.setApellido(rs.getString("cli_ap"));
        cli.setNumeroDocumento(rs.getString("cli_doc"));

        // contrato parcial — solo los datos necesarios para Asistencia
        Contrato contrato = new Contrato();
        contrato.setId(rs.getString("con_id"));
        contrato.setFechaInicio(rs.getDate("fecha_inicio").toLocalDate());
        contrato.setFechaFin(rs.getDate("fecha_fin").toLocalDate());
        contrato.setEstado(rs.getString("con_estado"));
        contrato.setCliente(cli);
        contrato.setMembresia(mem);

        // asistencia
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