package com.mycompany.herramientas.dao;

import com.mycompany.herramientas.config.DatabaseConnection;
import com.mycompany.herramientas.model.Clase;
import com.mycompany.herramientas.model.Horario;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;
import java.util.logging.Logger;

/**
 * DAO para la tabla Horarios (RF-09).
 *
 * Separado de ClaseDAO porque son entidades distintas:
 *   Una Clase puede tener múltiples Horarios.
 *   Una Clase puede modificarse sin tocar sus Horarios y viceversa.
 *
 * Tipos de datos críticos según el SQL:
 *   dia_semana  → TINYINT CHECK (dia_semana BETWEEN 1 AND 7)
 *                 1=Lunes, 2=Martes, …, 7=Domingo
 *                 En Java es int. El modelo Horario tiene getNombreDia().
 *   hora_inicio → TIME en BD → java.sql.Time → LocalTime en Java
 *   hora_fin    → TIME en BD → java.sql.Time → LocalTime en Java
 *
 * Estados válidos según BD:
 *   CHECK (estado IN ('programado','cancelado')) DEFAULT 'programado'
 *
 * ACTUALIZACIÓN:
 *   Se añadió deleteById(String horarioId) para eliminar un horario
 *   específico por su PK. SchedulesController.eliminarHorario() lo usa
 *   correctamente en lugar del anterior deleteByClaseId que borraba
 *   TODOS los horarios de la clase — bug corregido.
 */
public class HorarioDAO {

    private static final Logger LOGGER = Logger.getLogger(HorarioDAO.class.getName());

    // ─── SQL ─────────────────────────────────────────────────────────────────

    private static final String SQL_SELECT_BASE =
        "SELECT h.id, h.dia_semana, h.hora_inicio, h.hora_fin, h.estado, " +
        "       cl.id AS cl_id, cl.nombre_clase, cl.estado AS cl_estado " +
        "FROM Horarios h " +
        "INNER JOIN Clases cl ON h.id_clase = cl.id ";

    /** Todos los horarios, ordenados por día y hora de inicio. */
    private static final String SQL_FIND_ALL =
        SQL_SELECT_BASE +
        "ORDER BY h.dia_semana ASC, h.hora_inicio ASC";

    /** Horarios de una clase específica. */
    private static final String SQL_FIND_BY_CLASE =
        SQL_SELECT_BASE +
        "WHERE h.id_clase = ? " +
        "ORDER BY h.dia_semana ASC, h.hora_inicio ASC";

    /** Solo horarios activos (estado='programado') de una clase. */
    private static final String SQL_FIND_PROGRAMADOS_BY_CLASE =
        SQL_SELECT_BASE +
        "WHERE h.id_clase = ? AND h.estado = 'programado' " +
        "ORDER BY h.dia_semana ASC, h.hora_inicio ASC";

    /**
     * Horarios del día indicado (ISO: 1=Lunes … 7=Domingo).
     * Se pasa el día desde Java con LocalDate.now().getDayOfWeek().getValue()
     * para evitar dependencias de SET DATEFIRST de SQL Server.
     */
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

    /**
     * Elimina UN horario específico por su PK.
     * Usado por SchedulesController.eliminarHorario() — antes se usaba
     * deleteByClaseId que borraba TODOS los horarios de la clase (bug).
     */
    private static final String SQL_DELETE_BY_ID =
        "DELETE FROM Horarios WHERE id = ?";

    /**
     * Elimina TODOS los horarios de una clase.
     * Llamar antes de borrar una clase para respetar la FK.
     * NO usar para borrar un horario individual.
     */
    private static final String SQL_DELETE_BY_CLASE =
        "DELETE FROM Horarios WHERE id_clase = ?";

    private static final String SQL_COUNT_HOY =
        "SELECT COUNT(*) FROM Horarios WHERE dia_semana = ? AND estado = 'programado'";

    // ─── Métodos públicos ─────────────────────────────────────────────────────

    /**
     * Devuelve todos los horarios del sistema.
     * Usado en la vista de Calendario (calendar.jsp).
     */
    public List<Horario> findAll() throws SQLException {
        List<Horario> lista = new ArrayList<>();
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_FIND_ALL);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) lista.add(mapRow(rs));
        }
        return lista;
    }

    /**
     * Devuelve todos los horarios de una clase (programados y cancelados).
     * Para la vista de edición/gestión de horarios de una clase.
     */
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

    /**
     * Solo los horarios programados de una clase.
     * Para el widget de la tarjeta de clase en schedules.jsp.
     */
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

    /**
     * Horarios programados para el día indicado.
     * El parámetro diaSemana sigue el convenio ISO: 1=Lunes … 7=Domingo.
     * Se obtiene con: LocalDate.now().getDayOfWeek().getValue()
     * Usado en el dashboard para el widget "Clases del Día".
     */
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

    /** Busca un horario por su ID. Devuelve null si no existe. */
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

    /**
     * Guarda (INSERT si es nuevo, UPDATE si ya existe).
     * El ID debe venir generado por IdGenerator.parHorario().
     */
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

    /**
     * Elimina UN horario específico por su PK (id).
     *
     * CORRECCIÓN de bug anterior: SchedulesController.eliminarHorario()
     * llamaba a deleteByClaseId(claseId) que borraba TODOS los horarios
     * de la clase. Ahora usa este método para borrar solo el horario indicado.
     *
     * @param horarioId ID del horario a eliminar (ej: "HOR-2026-0001")
     * @return true si se eliminó, false si no existía
     * @throws SQLException si hay error de BD o violación de FK
     */
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

    /**
     * Elimina TODOS los horarios de una clase.
     * Llamar cuando se cancela o elimina una clase (para respetar la FK).
     * NUNCA usar para borrar un horario individual — usar deleteById().
     *
     * @param claseId ID de la clase cuyos horarios se quieren eliminar
     * @return número de filas eliminadas
     */
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

    /**
     * Cuenta los horarios programados para un día de la semana.
     * Para el widget "Clases del Día" en el dashboard (número rápido).
     *
     * @param diaSemana día ISO (1=Lunes … 7=Domingo)
     */
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

    // ─── Privados ─────────────────────────────────────────────────────────────

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

    /**
     * Mapea una fila del ResultSet a un objeto Horario.
     * Solo hidrata los datos de Clase necesarios (id + nombre_clase + estado),
     * no hace JOIN completo con Empleado/TipoClase para mantener el query liviano.
     * Si se necesita el objeto Clase completo, usar ClaseDAO.findById().
     */
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