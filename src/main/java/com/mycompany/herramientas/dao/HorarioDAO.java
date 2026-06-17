package com.mycompany.herramientas.dao;

import com.mycompany.herramientas.config.DatabaseConnection;
import com.mycompany.herramientas.model.Clase;
import com.mycompany.herramientas.model.Horario;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;
import java.util.logging.Logger;

// DAO para la tabla Horarios (RF-09)
// dia_semana → TINYINT 1-7 (1=Lunes … 7=Domingo) | hora_inicio/fin → TIME → LocalTime
// estados válidos: 'programado' | 'cancelado'
public class HorarioDAO {

    private static final Logger LOGGER = Logger.getLogger(HorarioDAO.class.getName());

    // ─── SQL ───────────────────────────────────────────────────


    private static final String SQL_SELECT_BASE =
        "SELECT h.id, h.dia_semana, h.hora_inicio, h.hora_fin, h.estado, " +
        "       cl.id AS cl_id, cl.nombre_clase, cl.estado AS cl_estado " +
        "FROM Horarios h " +
        "INNER JOIN Clases cl ON h.id_clase = cl.id ";

    // todos los horarios ordenados por día y hora de inicio
    private static final String SQL_FIND_ALL =
        SQL_SELECT_BASE +
        "ORDER BY h.dia_semana ASC, h.hora_inicio ASC";

    // horarios de una clase específica
    private static final String SQL_FIND_BY_CLASE =
        SQL_SELECT_BASE +
        "WHERE h.id_clase = ? " +
        "ORDER BY h.dia_semana ASC, h.hora_inicio ASC";

    // solo horarios programados de una clase
    private static final String SQL_FIND_PROGRAMADOS_BY_CLASE =
        SQL_SELECT_BASE +
        "WHERE h.id_clase = ? AND h.estado = 'programado' " +
        "ORDER BY h.dia_semana ASC, h.hora_inicio ASC";

    // SQL nuevo — horarios programados de TODAS las clases para un día específico
    private static final String SQL_FIND_PROGRAMADOS_BY_DIA =
            SQL_SELECT_BASE +
                    "WHERE h.dia_semana = ? AND h.estado = 'programado' " +
                    "ORDER BY h.hora_inicio ASC";

    // horarios del día indicado (ISO: 1=Lunes … 7=Domingo) — se pasa desde Java
    // con LocalDate.now().getDayOfWeek().getValue() para evitar SET DATEFIRST
    private static final String SQL_FIND_HOY =
        SQL_SELECT_BASE +
        "WHERE h.dia_semana = ? AND h.estado = 'programado' " +
        "ORDER BY h.hora_inicio ASC";

    private static final String SQL_FIND_BY_ID =
        SQL_SELECT_BASE + "WHERE h.id = ?";

    private static final String SQL_INSERT =
        "INSERT INTO Horarios (id, id_clase, dia_semana, hora_inicio, hora_fin, estado) " +
        "VALUES (?, ?, ?, ?, ?, ?)";

    private static final String SQL_UPDATE =
        "UPDATE Horarios " +
        "SET dia_semana = ?, hora_inicio = ?, hora_fin = ?, estado = ? " +
        "WHERE id = ?";

    // elimina UN horario por su PK — corrección del bug que usaba deleteByClaseId
    private static final String SQL_DELETE_BY_ID =
        "DELETE FROM Horarios WHERE id = ?";

    // elimina TODOS los horarios de una clase — usar antes de borrar la clase (FK)
    // NUNCA usar para borrar un horario individual
    private static final String SQL_DELETE_BY_CLASE =
        "DELETE FROM Horarios WHERE id_clase = ?";

    private static final String SQL_COUNT_HOY =
        "SELECT COUNT(*) FROM Horarios WHERE dia_semana = ? AND estado = 'programado'";

    // ─── métodos públicos ──────────────────────────────────────

    // devuelve todos los horarios del sistema — para la vista de calendario
    public List<Horario> findAll() throws SQLException {
        List<Horario> lista = new ArrayList<>();
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_FIND_ALL);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) lista.add(mapRow(rs));
        }
        return lista;
    }

    // devuelve todos los horarios de una clase (programados y cancelados)
    public List<Horario> findByClaseId(String claseId) throws SQLException {
        List<Horario> lista = new ArrayList<>();
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_FIND_BY_CLASE)) {
            ps.setString(1, claseId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) lista.add(mapRow(rs));
            }
        }
        return lista;
    }

    // solo los horarios programados de una clase — para la tarjeta en schedules.jsp
    public List<Horario> findProgramadosByClaseId(String claseId) throws SQLException {
        List<Horario> lista = new ArrayList<>();
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_FIND_PROGRAMADOS_BY_CLASE)) {
            ps.setString(1, claseId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) lista.add(mapRow(rs));
            }
        }
        return lista;
    }

    // devuelve todos los horarios programados de ese día — para validar sala única
    public List<Horario> findProgramadosByDia(int diaSemana) throws SQLException {
        List<Horario> lista = new ArrayList<>();
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_FIND_PROGRAMADOS_BY_DIA)) {
            ps.setInt(1, diaSemana);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) lista.add(mapRow(rs));
            }
        }
        return lista;
    }

    // horarios programados para el día indicado (ISO: 1=Lunes … 7=Domingo)
    // para el widget "Clases del Día" del dashboard
    public List<Horario> findByDia(int diaSemana) throws SQLException {
        List<Horario> lista = new ArrayList<>();
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_FIND_HOY)) {
            ps.setInt(1, diaSemana);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) lista.add(mapRow(rs));
            }
        }
        return lista;
    }

    // busca un horario por id — devuelve null si no existe
    public Horario findById(String id) throws SQLException {
        if (id == null || id.trim().isEmpty()) return null;
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_FIND_BY_ID)) {
            ps.setString(1, id.trim());
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapRow(rs);
            }
        }
        return null;
    }

    // INSERT si es nuevo, UPDATE si ya existe — el ID debe venir de IdGenerator.parHorario()
    public void save(Horario h) throws SQLException {
        boolean esNuevo = h.getId() == null || h.getId().trim().isEmpty()
                || findById(h.getId()) == null;
        try (Connection con = DatabaseConnection.getConnection()) {
            if (esNuevo) {
                insert(con, h);
            } else {
                update(con, h);
            }
        }
    }

    // elimina UN horario específico por su PK
    // corrección: antes SchedulesController llamaba a deleteByClaseId() por error
    // devuelve true si se eliminó, false si no existía
    public boolean deleteById(String horarioId) throws SQLException {
        if (horarioId == null || horarioId.trim().isEmpty()) return false;
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_DELETE_BY_ID)) {
            ps.setString(1, horarioId.trim());
            boolean ok = ps.executeUpdate() > 0;
            if (ok) LOGGER.info("Horario eliminado por ID: " + horarioId);
            return ok;
        }
    }

    // elimina TODOS los horarios de una clase — usar al cancelar o borrar una clase
    // NUNCA usar para borrar un horario individual; usar deleteById()
    // devuelve el número de filas eliminadas
    public int deleteByClaseId(String claseId) throws SQLException {
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_DELETE_BY_CLASE)) {
            ps.setString(1, claseId);
            int filas = ps.executeUpdate();
            if (filas > 0) LOGGER.info("Horarios eliminados para clase: "
                    + claseId + " | total: " + filas);
            return filas;
        }
    }

    // cuenta los horarios programados para un día — para el widget "Clases del Día"
    public int countByDia(int diaSemana) throws SQLException {
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_COUNT_HOY)) {
            ps.setInt(1, diaSemana);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getInt(1);
            }
        }
        return 0;
    }

    // ─── privados ──────────────────────────────────────────────

    private void insert(Connection con, Horario h) throws SQLException {
        try (PreparedStatement ps = con.prepareStatement(SQL_INSERT)) {
            ps.setString(1, h.getId());
            ps.setString(2, h.getClase().getId());
            ps.setInt(3, h.getDiaSemana());                   // TINYINT en BD
            ps.setTime(4, Time.valueOf(h.getHoraInicio()));   // TIME en BD
            ps.setTime(5, Time.valueOf(h.getHoraFin()));
            ps.setString(6, h.getEstado());
            ps.executeUpdate();
            LOGGER.info("Horario insertado: " + h.getId()
                    + " | clase: " + h.getClase().getId()
                    + " | día: " + h.getNombreDia());
        }
    }

    private void update(Connection con, Horario h) throws SQLException {
        try (PreparedStatement ps = con.prepareStatement(SQL_UPDATE)) {
            ps.setInt(1, h.getDiaSemana());
            ps.setTime(2, Time.valueOf(h.getHoraInicio()));
            ps.setTime(3, Time.valueOf(h.getHoraFin()));
            ps.setString(4, h.getEstado());
            ps.setString(5, h.getId());
            ps.executeUpdate();
            LOGGER.info("Horario actualizado: " + h.getId());
        }
    }

    // mapea una fila a Horario — hidrata solo id + nombre_clase + estado de Clase
    // para el objeto Clase completo usar ClaseDAO.findById()
    private Horario mapRow(ResultSet rs) throws SQLException {
        Clase cl = new Clase();
        cl.setId(rs.getString("cl_id"));
        cl.setNombreClase(rs.getString("nombre_clase"));
        cl.setEstado(rs.getString("cl_estado"));

        Horario h = new Horario();
        h.setId(rs.getString("id"));
        h.setClase(cl);
        h.setDiaSemana(rs.getInt("dia_semana"));
        h.setHoraInicio(rs.getTime("hora_inicio").toLocalTime());
        h.setHoraFin(rs.getTime("hora_fin").toLocalTime());
        h.setEstado(rs.getString("estado"));
        return h;
    }
}