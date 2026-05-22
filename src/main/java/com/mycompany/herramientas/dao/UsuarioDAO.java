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
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * DAO para la tabla Usuarios.
 *
 * Reglas que aplica este DAO:
 *  - NUNCA construir SQL con concatenación de strings (SQL injection).
 *  - Siempre usar PreparedStatement con parámetros (?).
 *  - Siempre cerrar Connection, Statement y ResultSet con try-with-resources.
 *  - rs.wasNull() después de getters de columnas NULL-able.
 *  - La contraseña que se guarda aquí ya es el hash BCrypt (PasswordService la genera).
 *    Este DAO no sabe nada de hashing.
 *
 * Tablas involucradas (JOINs en el SELECT):
 *   Usuarios → Roles, Empleados → Cargos + TipoDocumentos
 */
public class UsuarioDAO {

    private static final Logger LOGGER = Logger.getLogger(UsuarioDAO.class.getName());

    // ─── SQL ─────────────────────────────────────────────────────────────────

    /** SELECT completo con JOINs para hidratar el objeto Usuario completo */
    private static final String SQL_SELECT_BASE =
        "SELECT u.id, u.email, u.passwordUsuario, u.estado, " +
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

    private static final String SQL_FIND_BY_EMAIL =
        SQL_SELECT_BASE + "WHERE u.email = ?";

    private static final String SQL_FIND_BY_ID =
        SQL_SELECT_BASE + "WHERE u.id = ?";

    private static final String SQL_FIND_ALL =
        SQL_SELECT_BASE + "ORDER BY u.email";

    private static final String SQL_INSERT =
        "INSERT INTO Usuarios (id, email, passwordUsuario, id_rol, id_empleado, estado) " +
        "VALUES (?, ?, ?, ?, ?, ?)";

    private static final String SQL_UPDATE =
        "UPDATE Usuarios SET email = ?, id_rol = ?, id_empleado = ?, estado = ? " +
        "WHERE id = ?";

    private static final String SQL_UPDATE_PASSWORD =
        "UPDATE Usuarios SET passwordUsuario = ? WHERE id = ?";

    private static final String SQL_COUNT_ALL =
        "SELECT COUNT(*) FROM Usuarios";

    // ─── Métodos públicos ─────────────────────────────────────────────────────

    /**
     * Busca un usuario por email (para el login).
     * Devuelve null si no existe.
     */
    public Usuario findByEmail(String email) throws SQLException {
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_FIND_BY_EMAIL)) {

            ps.setString(1, email.trim().toLowerCase());
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapRow(rs);
            }
        }
        return null;
    }

    /**
     * Busca un usuario por su ID.
     * Devuelve null si no existe.
     */
    public Usuario findById(String id) throws SQLException {
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
     * Devuelve todos los usuarios ordenados por email.
     * Para la vista de gestión de usuarios (RF-14, solo Admin).
     */
    public List<Usuario> findAll() throws SQLException {
        List<Usuario> lista = new ArrayList<>();
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_FIND_ALL);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) lista.add(mapRow(rs));
        }
        return lista;
    }

    /**
     * Guarda un usuario nuevo (INSERT) o actualiza uno existente (UPDATE).
     * El ID debe estar generado antes de llamar a este método (IdGenerator).
     * La contraseña debe ser el hash BCrypt, no el texto plano.
     *
     * @param usuario objeto con todos los campos llenos incluyendo id
     * @throws SQLException si hay error de BD (ej: email duplicado)
     */
    public void save(Usuario usuario) throws SQLException {
        // Verificar si ya existe para decidir INSERT o UPDATE
        boolean existe = findById(usuario.getId()) != null;

        try (Connection con = DatabaseConnection.getConnection()) {
            if (!existe) {
                insert(con, usuario);
            } else {
                update(con, usuario);
            }
        }
    }

    /**
     * Actualiza solo la contraseña (hash BCrypt).
     * Llamado desde AuthService cuando el factor de coste sube.
     */
    public void actualizarPassword(String id, String nuevoHash) throws SQLException {
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_UPDATE_PASSWORD)) {

            ps.setString(1, nuevoHash);
            ps.setString(2, id);
            ps.executeUpdate();
        }
    }

    /**
     * Cuenta el total de usuarios registrados.
     * Útil para el dashboard de Admin.
     */
    public int count() throws SQLException {
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_COUNT_ALL);
             ResultSet rs = ps.executeQuery()) {

            if (rs.next()) return rs.getInt(1);
        }
        return 0;
    }

    // ─── Privados ─────────────────────────────────────────────────────────────

    private void insert(Connection con, Usuario u) throws SQLException {
        try (PreparedStatement ps = con.prepareStatement(SQL_INSERT)) {
            ps.setString(1, u.getId());
            ps.setString(2, u.getEmail().trim().toLowerCase());
            ps.setString(3, u.getPasswordUsuario());  // ya es hash BCrypt
            ps.setString(4, u.getRol().getId());
            // id_empleado puede ser NULL (UNIQUE NULL permitido en la BD)
            if (u.getEmpleado() != null && u.getEmpleado().getId() != null) {
                ps.setString(5, u.getEmpleado().getId());
            } else {
                ps.setNull(5, Types.VARCHAR);
            }
            ps.setString(6, u.getEstado());
            ps.executeUpdate();
            LOGGER.info("Usuario insertado: " + u.getEmail());
        }
    }

    private void update(Connection con, Usuario u) throws SQLException {
        try (PreparedStatement ps = con.prepareStatement(SQL_UPDATE)) {
            ps.setString(1, u.getEmail().trim().toLowerCase());
            ps.setString(2, u.getRol().getId());
            if (u.getEmpleado() != null && u.getEmpleado().getId() != null) {
                ps.setString(3, u.getEmpleado().getId());
            } else {
                ps.setNull(3, Types.VARCHAR);
            }
            ps.setString(4, u.getEstado());
            ps.setString(5, u.getId());
            ps.executeUpdate();
            LOGGER.info("Usuario actualizado: " + u.getEmail());
        }
    }

    /**
     * Mapea una fila del ResultSet a un objeto Usuario completo.
     * Incluye Rol, Empleado (con TipoDocumento y Cargo) si existen.
     * rs.wasNull() se usa para columnas que pueden ser NULL en la BD.
     */
    private Usuario mapRow(ResultSet rs) throws SQLException {
        Usuario u = new Usuario();
        u.setId(rs.getString("id"));
        u.setEmail(rs.getString("email"));
        u.setPasswordUsuario(rs.getString("passwordUsuario"));
        u.setEstado(rs.getString("estado"));

        // Rol (siempre existe, INNER JOIN)
        Rol rol = new Rol();
        rol.setId(rs.getString("rol_id"));
        rol.setNombreRol(rs.getString("nombre_rol"));
        rol.setDescripcion(rs.getString("rol_desc"));
        u.setRol(rol);

        // Empleado (puede ser NULL, LEFT JOIN)
        String empId = rs.getString("emp_id");
        if (!rs.wasNull() && empId != null) {
            Empleado emp = new Empleado();
            emp.setId(empId);
            emp.setNombre(rs.getString("emp_nombre"));
            emp.setApellido(rs.getString("emp_apellido"));
            emp.setNumeroDocumento(rs.getString("emp_doc"));
            emp.setEmail(rs.getString("emp_email"));
            emp.setTelefono(rs.getString("emp_tel"));

            // TipoDocumento del empleado (puede ser NULL)
            String tdId = rs.getString("td_id");
            if (!rs.wasNull() && tdId != null) {
                TipoDocumento td = new TipoDocumento();
                td.setId(tdId);
                td.setNombreDocumento(rs.getString("nombre_documento"));
                td.setAbreviado(rs.getString("abreviado"));
                td.setTamañoMax(rs.getInt("tamañoMax"));
                td.setTamañoMin(rs.getInt("tamañoMin"));
                td.setEsAlfanumerico(rs.getBoolean("esAlfanumerico"));
                emp.setTipoDocumento(td);
            }

            // Cargo del empleado (puede ser NULL)
            String cargoId = rs.getString("cargo_id");
            if (!rs.wasNull() && cargoId != null) {
                Cargo cargo = new Cargo();
                cargo.setId(cargoId);
                cargo.setNombre(rs.getString("cargo_nombre"));
                emp.setCargo(cargo);
            }

            u.setEmpleado(emp);
        }

        return u;
    }
}