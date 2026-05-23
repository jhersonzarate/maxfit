package com.mycompany.herramientas.dao;

import com.mycompany.herramientas.config.DatabaseConnection;
import com.mycompany.herramientas.model.*;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * DAO para la tabla Clases (RF-08).
 *
 * Tablas involucradas:
 *   Clases → Empleados (el entrenador, FK id_empleado)
 *   Clases → TipoClases (FK id_tipoClase)
 *
 * Estados válidos para Clases (columna estado):
 *   'vigente'    → disponible para inscripciones y horarios
 *   'suspendida' → no aparece en listas activas
 *
 * La columna en la BD se llama nombre_clase (no nombre).
 * El modelo Clase.java ya lo refleja con getNombreClase().
 */
public class ClaseDAO {

    private static final Logger LOGGER = Logger.getLogger(ClaseDAO.class.getName());

    // ─── SQL ─────────────────────────────────────────────────────────────────

    private static final String SQL_SELECT_BASE =
        "SELECT cl.id, cl.nombre_clase, cl.capacidad_maxima, cl.descripcion, cl.estado, " +
        // Empleado (entrenador)
        "       emp.id AS emp_id, emp.nombre AS emp_nombre, emp.apellido AS emp_apellido, " +
        "       emp.email AS emp_email, emp.telefono AS emp_tel, emp.numeroDocumento AS emp_doc, " +
        "       tde.id AS tde_id, tde.nombre_documento AS tde_nd, tde.abreviado AS tde_abrev, " +
        "       tde.tamañoMax AS tde_max, tde.tamañoMin AS tde_min, tde.esAlfanumerico AS tde_alfa, " +
        "       car.id AS car_id, car.nombre AS car_nombre, " +
        // TipoClase
        "       tc.id AS tc_id, tc.nombre AS tc_nombre " +
        "FROM Clases cl " +
        "INNER JOIN Empleados emp       ON cl.id_empleado  = emp.id " +
        "INNER JOIN TipoDocumentos tde  ON emp.id_TipoDocumento = tde.id " +
        "INNER JOIN Cargos car          ON emp.id_Cargo    = car.id " +
        "INNER JOIN TipoClases tc       ON cl.id_tipoClase = tc.id ";

    private static final String SQL_FIND_ALL =
        SQL_SELECT_BASE + "ORDER BY cl.nombre_clase";

    private static final String SQL_FIND_ALL_VIGENTES =
        SQL_SELECT_BASE + "WHERE cl.estado = 'vigente' ORDER BY cl.nombre_clase";

    private static final String SQL_FIND_BY_ID =
        SQL_SELECT_BASE + "WHERE cl.id = ?";

    private static final String SQL_INSERT =
        "INSERT INTO Clases " +
        "(id, nombre_clase, id_empleado, id_tipoClase, capacidad_maxima, descripcion, estado) " +
        "VALUES (?, ?, ?, ?, ?, ?, ?)";

    private static final String SQL_UPDATE =
        "UPDATE Clases SET nombre_clase = ?, id_empleado = ?, id_tipoClase = ?, " +
        "capacidad_maxima = ?, descripcion = ?, estado = ? " +
        "WHERE id = ?";

    private static final String SQL_DELETE =
        "DELETE FROM Clases WHERE id = ?";

    private static final String SQL_COUNT_VIGENTES =
        "SELECT COUNT(*) FROM Clases WHERE estado = 'vigente'";

    // ─── Métodos públicos ─────────────────────────────────────────────────────

    /** Todas las clases independientemente del estado. */
    public List<Clase> findAll() throws SQLException {
        List<Clase> lista = new ArrayList<>();
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_FIND_ALL);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) lista.add(mapRow(rs));
        }
        return lista;
    }

    /** Solo las clases con estado 'vigente'. */
    public List<Clase> findAllVigentes() throws SQLException {
        List<Clase> lista = new ArrayList<>();
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_FIND_ALL_VIGENTES);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) lista.add(mapRow(rs));
        }
        return lista;
    }

    /** Busca una clase por ID. Devuelve null si no existe. */
    public Clase findById(String id) throws SQLException {
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
     * INSERT si es nueva, UPDATE si ya existe.
     * El ID debe venir generado por IdGenerator (prefijo CLA) antes de llamar.
     */
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

    /**
     * Elimina una clase por ID.
     * PRECAUCIÓN: la BD tiene FKs desde Horarios e Inscripcion_Clases.
     * Si hay horarios o inscripciones asociadas, la BD lanzará error de integridad.
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

    /** Número de clases vigentes (para dashboard). */
    public int countVigentes() throws SQLException {
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_COUNT_VIGENTES);
             ResultSet rs = ps.executeQuery()) {
            if (rs.next()) return rs.getInt(1);
        }
        return 0;
    }

    // ─── Privados ─────────────────────────────────────────────────────────────

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
            LOGGER.info("Clase insertada: " + c.getNombreClase());
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
            LOGGER.info("Clase actualizada: " + c.getNombreClase());
        }
    }

    private Clase mapRow(ResultSet rs) throws SQLException {
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
        clase.setId(rs.getString("id"));
        clase.setNombreClase(rs.getString("nombre_clase"));
        clase.setEmpleado(empleado);
        clase.setTipoClase(tipoClase);
        clase.setCapacidadMaxima(rs.getInt("capacidad_maxima"));
        String desc = rs.getString("descripcion");
        clase.setDescripcion(rs.wasNull() ? null : desc);
        clase.setEstado(rs.getString("estado"));

        return clase;
    }

    private void setNullableString(PreparedStatement ps, int i, String val)
            throws SQLException {
        if (val != null && !val.trim().isEmpty()) {
            ps.setString(i, val.trim());
        } else {
            ps.setNull(i, Types.VARCHAR);
        }
    }
}