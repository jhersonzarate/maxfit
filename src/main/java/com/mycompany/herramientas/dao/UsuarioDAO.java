package com.mycompany.herramientas.dao;

import com.mycompany.herramientas.config.DatabaseConnection;
import com.mycompany.herramientas.model.Cargo;
import com.mycompany.herramientas.model.Empleado;
import com.mycompany.herramientas.model.Rol;
import com.mycompany.herramientas.model.TipoDocumento;
import com.mycompany.herramientas.model.Usuario;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;
import java.util.logging.Logger;

// DAO del módulo de usuarios
public class UsuarioDAO {

    private static final Logger LOGGER = Logger.getLogger(UsuarioDAO.class.getName());

    // ─── SQL ───────────────────────────────────────────────────

    // select completo con joins
    private static final String SQL_SELECT_BASE = "SELECT u.id, u.email, u.passwordUsuario, u.estado, " +
            "       r.id AS rol_id, r.nombre_rol, r.descripcion AS rol_desc, " +
            "       e.id AS emp_id, e.nombre AS emp_nombre, e.apellido AS emp_apellido, " +
            "       e.numeroDocumento AS emp_doc, e.email AS emp_email, " +
            "       e.telefono AS emp_tel, " +
            "       td.id AS td_id, td.nombre_documento, td.abreviado, " +
            "       td.tamañoMax, td.tamañoMin, td.esAlfanumerico, " +
            "       c.id AS cargo_id, c.nombre AS cargo_nombre " +
            "FROM Usuarios u " +
            "INNER JOIN Roles r          ON u.id_rol      = r.id " +
            "LEFT  JOIN Empleados e      ON u.id_empleado  = e.id " +
            "LEFT  JOIN TipoDocumentos td ON e.id_TipoDocumento = td.id " +
            "LEFT  JOIN Cargos c         ON e.id_Cargo     = c.id ";

    // buscar usuario por email
    private static final String SQL_FIND_BY_EMAIL = SQL_SELECT_BASE + "WHERE u.email = ?";

    // buscar usuario por ID
    private static final String SQL_FIND_BY_ID = SQL_SELECT_BASE + "WHERE u.id = ?";

    // listar todos los usuarios
    private static final String SQL_FIND_ALL = SQL_SELECT_BASE + "ORDER BY c.id DESC";

    // registrar usuario
    private static final String SQL_INSERT = "INSERT INTO Usuarios (id, email, passwordUsuario, id_rol, id_empleado, estado) "
            +
            "VALUES (?, ?, ?, ?, ?, ?)";

    // actualizar usuario
    private static final String SQL_UPDATE = "UPDATE Usuarios SET email = ?, id_rol = ?, id_empleado = ?, estado = ? " +
            "WHERE id = ?";

    // actualizar contraseña
    private static final String SQL_UPDATE_PASSWORD = "UPDATE Usuarios SET passwordUsuario = ? WHERE id = ?";

    // contar usuarios
    private static final String SQL_COUNT_ALL = "SELECT COUNT(*) FROM Usuarios";

    // eliminar usuario
    private static final String SQL_DELETE = "DELETE FROM Usuarios WHERE id = ?";

    // verificar si el usuario tiene transacciones (contratos o pagos registrados)
    private static final String SQL_HAS_TRANSACCIONES =
            "SELECT ISNULL((SELECT COUNT(*) FROM Contratos WHERE id_empleado = (SELECT id_empleado FROM Usuarios WHERE id = ?)), 0) + " +
            "ISNULL((SELECT COUNT(*) FROM Clases WHERE id_empleado = (SELECT id_empleado FROM Usuarios WHERE id = ?)), 0)";

    // ─── métodos públicos ──────────────────────────────────────

    // buscar usuario por email
    public Usuario findByEmail(String email) throws SQLException {

        try (Connection con = DatabaseConnection.getConnection();
                PreparedStatement ps = con.prepareStatement(SQL_FIND_BY_EMAIL)) {

            ps.setString(1, email.trim().toLowerCase());

            try (ResultSet rs = ps.executeQuery()) {

                if (rs.next()) {
                    return mapRow(rs);
                }
            }
        }

        return null;
    }

    // buscar usuario por ID
    public Usuario findById(String id) throws SQLException {

        try (Connection con = DatabaseConnection.getConnection();
                PreparedStatement ps = con.prepareStatement(SQL_FIND_BY_ID)) {

            ps.setString(1, id);

            try (ResultSet rs = ps.executeQuery()) {

                if (rs.next()) {
                    return mapRow(rs);
                }
            }
        }

        return null;
    }

    // listar todos los usuarios
    public List<Usuario> findAll() throws SQLException {

        List<Usuario> lista = new ArrayList<>();

        try (Connection con = DatabaseConnection.getConnection();
                PreparedStatement ps = con.prepareStatement(SQL_FIND_ALL);
                ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                lista.add(mapRow(rs));
            }
        }

        return lista;
    }

    // guardar o actualizar usuario
    public void save(Usuario usuario) throws SQLException {

        // validar si ya existe
        boolean existe = findById(usuario.getId()) != null;

        try (Connection con = DatabaseConnection.getConnection()) {

            // insertar nuevo usuario
            if (!existe) {

                insert(con, usuario);

            } else {

                // actualizar usuario existente
                update(con, usuario);
            }
        }
    }

    // actualizar contraseña del usuario
    public void actualizarPassword(
            String id,
            String nuevoHash) throws SQLException {

        try (Connection con = DatabaseConnection.getConnection();
                PreparedStatement ps = con.prepareStatement(SQL_UPDATE_PASSWORD)) {

            ps.setString(1, nuevoHash);
            ps.setString(2, id);

            ps.executeUpdate();
        }
    }

    // contar usuarios registrados
    public int count() throws SQLException {

        try (Connection con = DatabaseConnection.getConnection();
                PreparedStatement ps = con.prepareStatement(SQL_COUNT_ALL);
                ResultSet rs = ps.executeQuery()) {

            if (rs.next()) {
                return rs.getInt(1);
            }
        }

        return 0;
    }

    // verificar si el usuario tiene transacciones vinculadas
    public boolean hasTransacciones(String id) throws SQLException {
        try (Connection con = DatabaseConnection.getConnection();
                PreparedStatement ps = con.prepareStatement(SQL_HAS_TRANSACCIONES)) {
            ps.setString(1, id);
            ps.setString(2, id);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() && rs.getInt(1) > 0;
            }
        }
    }

    // eliminar usuario por ID
    public void delete(String id) throws SQLException {
        try (Connection con = DatabaseConnection.getConnection();
                PreparedStatement ps = con.prepareStatement(SQL_DELETE)) {
            ps.setString(1, id);
            ps.executeUpdate();
        }
    }

    // ─── métodos privados ──────────────────────────────────────

    // insertar nuevo usuario
    private void insert(Connection con, Usuario u)
            throws SQLException {

        try (PreparedStatement ps = con.prepareStatement(SQL_INSERT)) {

            ps.setString(1, u.getId());

            // normalizar email
            ps.setString(
                    2,
                    u.getEmail().trim().toLowerCase());

            // password ya viene hasheada
            ps.setString(3, u.getPasswordUsuario());

            ps.setString(4, u.getRol().getId());

            // empleado puede ser null
            if (u.getEmpleado() != null
                    && u.getEmpleado().getId() != null) {

                ps.setString(5, u.getEmpleado().getId());

            } else {

                ps.setNull(5, Types.VARCHAR);
            }

            ps.setString(6, u.getEstado());

            ps.executeUpdate();

            LOGGER.info(
                    "Usuario insertado: "
                            + u.getEmail());
        }
    }

    // actualizar usuario existente
    private void update(Connection con, Usuario u)
            throws SQLException {

        try (PreparedStatement ps = con.prepareStatement(SQL_UPDATE)) {

            // normalizar email
            ps.setString(
                    1,
                    u.getEmail().trim().toLowerCase());

            ps.setString(2, u.getRol().getId());

            // empleado puede ser null
            if (u.getEmpleado() != null
                    && u.getEmpleado().getId() != null) {

                ps.setString(3, u.getEmpleado().getId());

            } else {

                ps.setNull(3, Types.VARCHAR);
            }

            ps.setString(4, u.getEstado());
            ps.setString(5, u.getId());

            ps.executeUpdate();

            LOGGER.info(
                    "Usuario actualizado: "
                            + u.getEmail());
        }
    }

    // mapear fila SQL a objeto Usuario
    private Usuario mapRow(ResultSet rs) throws SQLException {

        Usuario u = new Usuario();

        u.setId(rs.getString("id"));
        u.setEmail(rs.getString("email"));
        u.setPasswordUsuario(rs.getString("passwordUsuario"));
        u.setEstado(rs.getString("estado"));

        // ─── rol ───────────────────────────────────────────────

        Rol rol = new Rol();

        rol.setId(rs.getString("rol_id"));
        rol.setNombreRol(rs.getString("nombre_rol"));
        rol.setDescripcion(rs.getString("rol_desc"));

        u.setRol(rol);

        // ─── empleado ──────────────────────────────────────────

        String empId = rs.getString("emp_id");

        // empleado puede ser null
        if (!rs.wasNull() && empId != null) {

            Empleado emp = new Empleado();

            emp.setId(empId);
            emp.setNombre(rs.getString("emp_nombre"));
            emp.setApellido(rs.getString("emp_apellido"));
            emp.setNumeroDocumento(rs.getString("emp_doc"));
            emp.setEmail(rs.getString("emp_email"));
            emp.setTelefono(rs.getString("emp_tel"));

            // ─── tipo documento ────────────────────────────────

            String tdId = rs.getString("td_id");

            // tipo documento puede ser null
            if (!rs.wasNull() && tdId != null) {

                TipoDocumento td = new TipoDocumento();

                td.setId(tdId);
                td.setNombreDocumento(
                        rs.getString("nombre_documento"));

                td.setAbreviado(rs.getString("abreviado"));

                td.setTamañoMax(rs.getInt("tamañoMax"));
                td.setTamañoMin(rs.getInt("tamañoMin"));

                td.setEsAlfanumerico(
                        rs.getBoolean("esAlfanumerico"));

                emp.setTipoDocumento(td);
            }

            // ─── cargo ─────────────────────────────────────────

            String cargoId = rs.getString("cargo_id");

            // cargo puede ser null
            if (!rs.wasNull() && cargoId != null) {

                Cargo cargo = new Cargo();

                cargo.setId(cargoId);
                cargo.setNombre(
                        rs.getString("cargo_nombre"));

                emp.setCargo(cargo);
            }

            u.setEmpleado(emp);
        }

        return u;
    }
}