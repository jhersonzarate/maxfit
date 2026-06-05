package com.mycompany.herramientas.dao;

import com.mycompany.herramientas.config.DatabaseConnection;
import com.mycompany.herramientas.model.*;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;
import java.util.logging.Logger;

// DAO para la tabla Clases (RF-08)
// horarios e inscripciones tienen sus propios DAOs (HorarioDAO, InscripcionDAO)
// estados válidos: 'vigente' | 'suspendida'
public class ClaseDAO {

    private static final Logger LOGGER = Logger.getLogger(ClaseDAO.class.getName());

    // ─── SQL ───────────────────────────────────────────────────

    private static final String SQL_SELECT_BASE =
        "SELECT cl.id, cl.nombre_clase, cl.capacidad_maxima, " +
        "       cl.descripcion, cl.estado, " +
        // empleado (entrenador)
        "       emp.id AS emp_id, emp.nombre AS emp_nom, " +
        "       emp.apellido AS emp_ap, emp.email AS emp_email, " +
        "       cargo.id AS cargo_id, cargo.nombre AS cargo_nom, " +
        // tipo de clase
        "       tc.id AS tc_id, tc.nombre AS tc_nom " +
        "FROM Clases cl " +
        "INNER JOIN Empleados emp  ON cl.id_empleado  = emp.id " +
        "INNER JOIN Cargos cargo   ON emp.id_Cargo    = cargo.id " +
        "INNER JOIN TipoClases tc  ON cl.id_tipoClase = tc.id ";

    private static final String SQL_FIND_ALL =
        SQL_SELECT_BASE + "ORDER BY cl.nombre_clase";

    private static final String SQL_FIND_VIGENTES =
        SQL_SELECT_BASE +
        "WHERE cl.estado = 'vigente' ORDER BY cl.nombre_clase";

    private static final String SQL_FIND_BY_ID =
        SQL_SELECT_BASE + "WHERE cl.id = ?";

    // clases asignadas a un instructor — para el dashboard del Trainer
    private static final String SQL_FIND_BY_EMPLEADO =
        SQL_SELECT_BASE +
        "WHERE cl.id_empleado = ? ORDER BY cl.nombre_clase";

    private static final String SQL_INSERT =
        "INSERT INTO Clases " +
        "(id, nombre_clase, id_empleado, id_tipoClase, capacidad_maxima, descripcion, estado) " +
        "VALUES (?, ?, ?, ?, ?, ?, ?)";

    private static final String SQL_UPDATE =
        "UPDATE Clases " +
        "SET nombre_clase = ?, id_empleado = ?, id_tipoClase = ?, " +
        "    capacidad_maxima = ?, descripcion = ?, estado = ? " +
        "WHERE id = ?";

    private static final String SQL_COUNT_VIGENTES =
        "SELECT COUNT(*) FROM Clases WHERE estado = 'vigente'";

    // ─── métodos públicos ──────────────────────────────────────

    // devuelve todas las clases (vigentes y suspendidas)
    public List<Clase> findAll() throws SQLException {
        List<Clase> lista = new ArrayList<>();
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_FIND_ALL);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) lista.add(mapRow(rs));
        }
        return lista;
    }

    // solo clases vigentes — para el formulario de inscripción y la vista de horarios
    public List<Clase> findVigentes() throws SQLException {
        List<Clase> lista = new ArrayList<>();
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_FIND_VIGENTES);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) lista.add(mapRow(rs));
        }
        return lista;
    }

    // busca una clase por id — devuelve null si no existe
    public Clase findById(String id) throws SQLException {
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

    // clases donde id_empleado coincide — para "mis clases" en el dashboard del Trainer
    public List<Clase> findByEmpleadoId(String empleadoId) throws SQLException {
        List<Clase> lista = new ArrayList<>();
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_FIND_BY_EMPLEADO)) {
            ps.setString(1, empleadoId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) lista.add(mapRow(rs));
            }
        }
        return lista;
    }

    // INSERT si es nueva, UPDATE si ya existe — el ID debe venir de IdGenerator.parClase()
    public void save(Clase clase) throws SQLException {
        boolean existe = clase.getId() != null && findById(clase.getId()) != null;
        try (Connection con = DatabaseConnection.getConnection()) {
            if (!existe) {
                insert(con, clase);
            } else {
                update(con, clase);
            }
        }
    }

    // total de clases vigentes para el widget del dashboard
    public int countVigentes() throws SQLException {
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_COUNT_VIGENTES);
             ResultSet rs = ps.executeQuery()) {
            if (rs.next()) return rs.getInt(1);
        }
        return 0;
    }

    public boolean isTipoClaseEnUso(String tipoClaseId) throws SQLException {
        String sql = "SELECT COUNT(*) FROM Clases WHERE id_tipoClase = ?";
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, tipoClaseId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getInt(1) > 0;
            }
        }
        return false;
    }

    // ─── privados ──────────────────────────────────────────────

    private void insert(Connection con, Clase c) throws SQLException {
        try (PreparedStatement ps = con.prepareStatement(SQL_INSERT)) {
            ps.setString(1, c.getId());
            ps.setString(2, c.getNombreClase().trim());
            ps.setString(3, c.getEmpleado().getId());
            ps.setString(4, c.getTipoClase().getId());
            ps.setInt(5, c.getCapacidadMaxima());
            setNullableString(ps, 6, c.getDescripcion());
            ps.setString(7, c.getEstado());
            ps.executeUpdate();
            LOGGER.info("Clase insertada: " + c.getId() + " | " + c.getNombreClase());
        }
    }

    private void update(Connection con, Clase c) throws SQLException {
        try (PreparedStatement ps = con.prepareStatement(SQL_UPDATE)) {
            ps.setString(1, c.getNombreClase().trim());
            ps.setString(2, c.getEmpleado().getId());
            ps.setString(3, c.getTipoClase().getId());
            ps.setInt(4, c.getCapacidadMaxima());
            setNullableString(ps, 5, c.getDescripcion());
            ps.setString(6, c.getEstado());
            ps.setString(7, c.getId());
            ps.executeUpdate();
            LOGGER.info("Clase actualizada: " + c.getId());
        }
    }

    private Clase mapRow(ResultSet rs) throws SQLException {
        // cargo del empleado
        Cargo cargo = new Cargo(
            rs.getString("cargo_id"),
            rs.getString("cargo_nom")
        );
        // empleado (entrenador)
        Empleado emp = new Empleado();
        emp.setId(rs.getString("emp_id"));
        emp.setNombre(rs.getString("emp_nom"));
        emp.setApellido(rs.getString("emp_ap"));
        emp.setEmail(rs.getString("emp_email"));
        emp.setCargo(cargo);

        // tipo de clase
        TipoClase tc = new TipoClase(
            rs.getString("tc_id"),
            rs.getString("tc_nom")
        );

        // clase
        Clase c = new Clase();
        c.setId(rs.getString("id"));
        c.setNombreClase(rs.getString("nombre_clase"));
        c.setEmpleado(emp);
        c.setTipoClase(tc);
        c.setCapacidadMaxima(rs.getInt("capacidad_maxima"));
        String desc = rs.getString("descripcion");
        c.setDescripcion(rs.wasNull() ? null : desc);
        c.setEstado(rs.getString("estado"));
        return c;
    }

    private void setNullableString(PreparedStatement ps, int idx, String val)
            throws SQLException {
        if (val != null && !val.trim().isEmpty()) {
            ps.setString(idx, val.trim());
        } else {
            ps.setNull(idx, Types.VARCHAR);
        }
    }
}