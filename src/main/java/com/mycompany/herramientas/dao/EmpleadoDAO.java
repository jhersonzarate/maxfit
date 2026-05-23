package com.mycompany.herramientas.dao;

import com.mycompany.herramientas.config.DatabaseConnection;
import com.mycompany.herramientas.model.Cargo;
import com.mycompany.herramientas.model.Empleado;
import com.mycompany.herramientas.model.TipoDocumento;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;
import java.util.logging.Logger;

/**
 * DAO para la tabla Empleados (RF-12, RF-13).
 *
 * NOTA IMPORTANTE sobre la BD:
 *   La tabla Empleados NO tiene columna estado.
 *   Si se necesita desactivar empleados en el futuro,
 *   primero se debe agregar la columna a la BD.
 *
 * Tablas involucradas (JOINs):
 *   Empleados → TipoDocumentos, Cargos
 */
public class EmpleadoDAO {

    private static final Logger LOGGER = Logger.getLogger(EmpleadoDAO.class.getName());

    // ─── SQL ─────────────────────────────────────────────────────────────────

    private static final String SQL_SELECT_BASE =
        "SELECT e.id, e.nombre, e.apellido, e.numeroDocumento, " +
        "       e.email, e.telefono, " +
        "       td.id AS td_id, td.nombre_documento, td.abreviado, " +
        "       td.tamañoMax, td.tamañoMin, td.esAlfanumerico, " +
        "       c.id AS cargo_id, c.nombre AS cargo_nombre " +
        "FROM Empleados e " +
        "INNER JOIN TipoDocumentos td ON e.id_TipoDocumento = td.id " +
        "INNER JOIN Cargos c          ON e.id_Cargo         = c.id ";

    private static final String SQL_FIND_ALL =
        SQL_SELECT_BASE + "ORDER BY e.apellido, e.nombre";

    private static final String SQL_FIND_BY_ID =
        SQL_SELECT_BASE + "WHERE e.id = ?";

    private static final String SQL_FIND_BY_CARGO =
        SQL_SELECT_BASE + "WHERE c.id = ? ORDER BY e.apellido, e.nombre";

    private static final String SQL_INSERT =
        "INSERT INTO Empleados " +
        "(id, nombre, apellido, id_TipoDocumento, numeroDocumento, email, telefono, id_Cargo) " +
        "VALUES (?, ?, ?, ?, ?, ?, ?, ?)";

    private static final String SQL_UPDATE =
        "UPDATE Empleados SET nombre = ?, apellido = ?, id_TipoDocumento = ?, " +
        "numeroDocumento = ?, email = ?, telefono = ?, id_Cargo = ? " +
        "WHERE id = ?";

    private static final String SQL_DELETE =
        "DELETE FROM Empleados WHERE id = ?";

    private static final String SQL_COUNT =
        "SELECT COUNT(*) FROM Empleados";

    // ─── Métodos públicos ─────────────────────────────────────────────────────

    public List<Empleado> findAll() throws SQLException {
        List<Empleado> lista = new ArrayList<>();
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_FIND_ALL);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) lista.add(mapRow(rs));
        }
        return lista;
    }

    public Empleado findById(String id) throws SQLException {
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
     * Devuelve empleados filtrando por cargo.
     * Útil para obtener solo entrenadores (CARGO-TRAINER)
     * al crear una clase grupal.
     */
    public List<Empleado> findByCargo(String cargoId) throws SQLException {
        List<Empleado> lista = new ArrayList<>();
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_FIND_BY_CARGO)) {
            ps.setString(1, cargoId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) lista.add(mapRow(rs));
            }
        }
        return lista;
    }

    public void save(Empleado empleado) throws SQLException {
        boolean existe = empleado.getId() != null
                && findById(empleado.getId()) != null;
        try (Connection con = DatabaseConnection.getConnection()) {
            if (!existe) insert(con, empleado);
            else         update(con, empleado);
        }
    }

    /**
     * Elimina un empleado.
     * Si tiene contratos o clases asignadas la BD lanzará
     * un error de integridad referencial — el controlador
     * debe capturarlo y mostrar mensaje amigable.
     */
    public boolean delete(String id) throws SQLException {
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_DELETE)) {
            ps.setString(1, id);
            return ps.executeUpdate() > 0;
        }
    }

    public int count() throws SQLException {
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_COUNT);
             ResultSet rs = ps.executeQuery()) {
            if (rs.next()) return rs.getInt(1);
        }
        return 0;
    }

    // ─── Privados ─────────────────────────────────────────────────────────────

    private void insert(Connection con, Empleado e) throws SQLException {
        try (PreparedStatement ps = con.prepareStatement(SQL_INSERT)) {
            ps.setString(1, e.getId());
            ps.setString(2, e.getNombre().trim());
            ps.setString(3, e.getApellido().trim());
            ps.setString(4, e.getTipoDocumento().getId());
            ps.setString(5, e.getNumeroDocumento().trim());
            ps.setString(6, e.getEmail().trim().toLowerCase());
            // telefono NULL-able
            if (e.getTelefono() != null && !e.getTelefono().trim().isEmpty()) {
                ps.setString(7, e.getTelefono().trim());
            } else {
                ps.setNull(7, Types.VARCHAR);
            }
            ps.setString(8, e.getCargo().getId());
            ps.executeUpdate();
            LOGGER.info("Empleado insertado: " + e.getNombreCompleto());
        }
    }

    private void update(Connection con, Empleado e) throws SQLException {
        try (PreparedStatement ps = con.prepareStatement(SQL_UPDATE)) {
            ps.setString(1, e.getNombre().trim());
            ps.setString(2, e.getApellido().trim());
            ps.setString(3, e.getTipoDocumento().getId());
            ps.setString(4, e.getNumeroDocumento().trim());
            ps.setString(5, e.getEmail().trim().toLowerCase());
            if (e.getTelefono() != null && !e.getTelefono().trim().isEmpty()) {
                ps.setString(6, e.getTelefono().trim());
            } else {
                ps.setNull(6, Types.VARCHAR);
            }
            ps.setString(7, e.getCargo().getId());
            ps.setString(8, e.getId());
            ps.executeUpdate();
            LOGGER.info("Empleado actualizado: " + e.getNombreCompleto());
        }
    }

    private Empleado mapRow(ResultSet rs) throws SQLException {
        TipoDocumento td = new TipoDocumento();
        td.setId(rs.getString("td_id"));
        td.setNombreDocumento(rs.getString("nombre_documento"));
        td.setAbreviado(rs.getString("abreviado"));
        td.setTamañoMax(rs.getInt("tamañoMax"));
        td.setTamañoMin(rs.getInt("tamañoMin"));
        td.setEsAlfanumerico(rs.getBoolean("esAlfanumerico"));

        Cargo cargo = new Cargo();
        cargo.setId(rs.getString("cargo_id"));
        cargo.setNombre(rs.getString("cargo_nombre"));

        Empleado e = new Empleado();
        e.setId(rs.getString("id"));
        e.setNombre(rs.getString("nombre"));
        e.setApellido(rs.getString("apellido"));
        e.setNumeroDocumento(rs.getString("numeroDocumento"));
        e.setEmail(rs.getString("email"));

        String tel = rs.getString("telefono");
        e.setTelefono(rs.wasNull() ? null : tel);

        e.setTipoDocumento(td);
        e.setCargo(cargo);
        return e;
    }
}