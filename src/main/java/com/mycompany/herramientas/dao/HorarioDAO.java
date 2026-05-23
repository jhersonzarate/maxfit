package com.mycompany.herramientas.dao;

import com.mycompany.herramientas.config.DatabaseConnection;
import com.mycompany.herramientas.model.*;

import java.sql.*;
import java.time.LocalTime;
import java.util.ArrayList;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * DAO para la tabla Horarios (RF-09).
 *
 * Tablas involucradas:
 *   Horarios → Clases → Empleados + TipoClases
 *
 * La columna dia_semana es TINYINT (1=Lunes … 7=Domingo).
 * El modelo Horario.java tiene getNombreDia() para convertirlo a español en la vista.
 *
 * Estados válidos (columna estado):
 *   'programado' → horario activo
 *   'cancelado'  → suspendido temporalmente
 *
 * findByDiaSemana() es útil para el dashboard:
 *   muestra cuántas clases hay hoy (RF dashboard).
 */
public class HorarioDAO {

    private static final Logger LOGGER = Logger.getLogger(HorarioDAO.class.getName());

    // ─── SQL ─────────────────────────────────────────────────────────────────

    /**
     * SELECT que une Horarios con Clases y su entrenador.
     * Se reutilizan alias de ClaseDAO donde coinciden.
     */
    private static final String SQL_SELECT_BASE =
        "SELECT h.id, h.dia_semana, h.hora_inicio, h.hora_fin, h.estado, " +
        // Clase
        "       cl.id AS cl_id, cl.nombre_clase, cl.capacidad_maxima, " +
        "       cl.descripcion AS cl_desc, cl.estado AS cl_estado, " +
        // Empleado (entrenador de la clase)
        "       emp.id AS emp_id, emp.nombre AS emp_nombre, emp.apellido AS emp_apellido, " +
        "       emp.email AS emp_email, emp.telefono AS emp_tel, emp.numeroDocumento AS emp_doc, " +
        "       tde.id AS tde_id, tde.nombre_documento AS tde_nd, tde.abreviado AS tde_abrev, " +
        "       tde.tamañoMax AS tde_max, tde.tamañoMin AS tde_min, tde.esAlfanumerico AS tde_alfa, " +
        "       car.id AS car_id, car.nombre AS car_nombre, " +
        // TipoClase
        "       tc.id AS tc_id, tc.nombre AS tc_nombre " +
        "FROM Horarios h " +
        "INNER JOIN Clases cl           ON h.id_clase      = cl.id " +
        "INNER JOIN Empleados emp        ON cl.id_empleado  = emp.id " +
        "INNER JOIN TipoDocumentos tde   ON emp.id_TipoDocumento = tde.id " +
        "INNER JOIN Cargos car           ON emp.id_Cargo    = car.id " +
        "INNER JOIN TipoClases tc        ON cl.id_tipoClase = tc.id ";

    private static final String SQL_FIND_ALL =
        SQL_SELECT_BASE + "ORDER BY h.dia_semana, h.hora_inicio";

    private static final String SQL_FIND_BY_ID =
        SQL_SELECT_BASE + "WHERE h.id = ?";

    private static final String SQL_FIND_BY_CLASE =
        SQL_SELECT_BASE + "WHERE h.id_clase = ? ORDER BY h.dia_semana, h.hora_inicio";

    /** Horarios del día (TINYINT: 1=Lun, 2=Mar … 7=Dom) */
    private static final String SQL_FIND_BY_DIA =
        SQL_SELECT_BASE +
        "WHERE h.dia_semana = ? AND h.estado = 'programado' " +
        "ORDER BY h.hora_inicio";

    private static final String SQL_INSERT =
        "INSERT INTO Horarios (id, id_clase, dia_semana, hora_inicio, hora_fin, estado) " +
        "VALUES (?, ?, ?, ?, ?, ?)";

    private static final String SQL_UPDATE =
        "UPDATE Horarios SET id_clase = ?, dia_semana = ?, hora_inicio = ?, " +
        "hora_fin = ?, estado = ? WHERE id = ?";

    private static final String SQL_DELETE =
        "DELETE FROM Horarios WHERE id = ?";

    private static final String SQL_COUNT_HOY =
        "SELECT COUNT(*) FROM Horarios h " +
        "INNER JOIN Clases cl ON h.id_clase = cl.id " +
        "WHERE h.dia_semana = ? " +
        "  AND h.estado = 'programado' " +
        "  AND cl.estado = 'vigente'";

    // ─── Métodos públicos ─────────────────────────────────────────────────────

    /** Todos los horarios ordenados por día y hora. */
    public List<Horario> findAll() throws SQLException {
        List<Horario> lista = new ArrayList<>();
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_FIND_ALL);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) lista.add(mapRow(rs));
        }
        return lista;
    }

    /** Busca un horario por ID. Devuelve null si no existe. */
    public Horario findById(String id) throws SQLException {
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_FIND_BY_ID)) {
            ps.setString(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapRow(rs);
            }
        }
        return null;
    }

    /**
     * Todos los horarios de una clase específica.
     * Una clase puede tener múltiples horarios (RF-09).
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
     * Horarios programados para un día específico de la semana.
     * Usado en el dashboard para mostrar "Clases del día".
     *
     * @param diaSemana valor TINYINT (1=Lunes … 7=Domingo)
     */
    public List<Horario> findByDiaSemana(int diaSemana) throws SQLException {
        List<Horario> lista = new ArrayList<>();
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_FIND_BY_DIA)) {
            ps.setInt(1, diaSemana);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) lista.add(mapRow(rs));
            }
        }
        return lista;
    }

    /**
     * INSERT si es nuevo, UPDATE si ya existe.
     * El ID debe venir generado por IdGenerator (prefijo HOR) antes de llamar.
     */
    public void save(Horario horario) throws SQLException {
        boolean existe = horario.getId() != null && findById(horario.getId()) != null;
        try (Connection con = DatabaseConnection.getConnection()) {
            if (!existe) {
                insert(con, horario);
            } else {
                update(con, horario);
            }
        }
    }

    /**
     * Elimina un horario por ID.
     *
     * @return true si se eliminó, false si no existía
     */
    public boolean delete(String id) throws SQLException {
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_DELETE)) {
            ps.setString(1, id);
            return ps.executeUpdate() > 0;
        }
    }

    /**
     * Cuenta los horarios programados para el día de la semana dado.
     * Solo cuenta clases vigentes + horarios programados.
     *
     * @param diaSemana valor TINYINT (1=Lunes … 7=Domingo)
     */
    public int countPorDia(int diaSemana) throws SQLException {
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
            ps.setInt(3, h.getDiaSemana());
            ps.setTime(4, Time.valueOf(h.getHoraInicio()));
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
            ps.setString(1, h.getClase().getId());
            ps.setInt(2, h.getDiaSemana());
            ps.setTime(3, Time.valueOf(h.getHoraInicio()));
            ps.setTime(4, Time.valueOf(h.getHoraFin()));
            ps.setString(5, h.getEstado());
            ps.setString(6, h.getId());
            ps.executeUpdate();
            LOGGER.info("Horario actualizado: " + h.getId());
        }
    }

    private Horario mapRow(ResultSet rs) throws SQLException {
        TipoDocumento tdEmp = new TipoDocumento();
        tdEmp.setId(rs.getString("tde_id"));
        tdEmp.setNombreDocumento(rs.getString("tde_nd"));
        tdEmp.setAbreviado(rs.getString("tde_abrev"));
        tdEmp.setTamañoMax(rs.getInt("tde_max"));
        tdEmp.setTamañoMin(rs.getInt("tde_min"));
        tdEmp.setEsAlfanumerico(rs.getBoolean("tde_alfa"));

        Cargo cargo = new Cargo();
        cargo.setId(rs.getString("car_id"));
        cargo.setNombre(rs.getString("car_nombre"));

        Empleado empleado = new Empleado();
        empleado.setId(rs.getString("emp_id"));
        empleado.setNombre(rs.getString("emp_nombre"));
        empleado.setApellido(rs.getString("emp_apellido"));
        empleado.setEmail(rs.getString("emp_email"));
        empleado.setNumeroDocumento(rs.getString("emp_doc"));
        String empTel = rs.getString("emp_tel");
        empleado.setTelefono(rs.wasNull() ? null : empTel);
        empleado.setTipoDocumento(tdEmp);
        empleado.setCargo(cargo);

        TipoClase tipoClase = new TipoClase();
        tipoClase.setId(rs.getString("tc_id"));
        tipoClase.setNombre(rs.getString("tc_nombre"));

        Clase clase = new Clase();
        clase.setId(rs.getString("cl_id"));
        clase.setNombreClase(rs.getString("nombre_clase"));
        clase.setEmpleado(empleado);
        clase.setTipoClase(tipoClase);
        clase.setCapacidadMaxima(rs.getInt("capacidad_maxima"));
        String clDesc = rs.getString("cl_desc");
        clase.setDescripcion(rs.wasNull() ? null : clDesc);
        clase.setEstado(rs.getString("cl_estado"));

        Horario horario = new Horario();
        horario.setId(rs.getString("id"));
        horario.setClase(clase);
        horario.setDiaSemana(rs.getInt("dia_semana"));
        horario.setHoraInicio(rs.getTime("hora_inicio").toLocalTime());
        horario.setHoraFin(rs.getTime("hora_fin").toLocalTime());
        horario.setEstado(rs.getString("estado"));

        return horario;
    }
}