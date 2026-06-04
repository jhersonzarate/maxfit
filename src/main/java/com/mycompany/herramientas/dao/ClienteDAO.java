package com.mycompany.herramientas.dao;

import com.mycompany.herramientas.config.DatabaseConnection;
import com.mycompany.herramientas.model.Cliente;
import com.mycompany.herramientas.model.TipoDocumento;

import java.sql.*;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.logging.Logger;
import java.util.logging.Level;

// DAO para la tabla Clientes (RF-01)
// columnas NULL-able: email, telefono, fecha_nacimiento, genero
// findByDocument se usa en el check-in del recepcionista (RF-04, RF-05)
public class ClienteDAO {

    private static final Logger LOGGER = Logger.getLogger(ClienteDAO.class.getName());

    // ─── SQL ───────────────────────────────────────────────────

    private static final String SQL_SELECT_BASE = "SELECT c.id, c.nombre, c.apellido, c.numero_documento, " +
            "       c.email, c.telefono, c.fecha_nacimiento, c.genero, " +
            "       td.id AS td_id, td.nombre_documento, td.abreviado, " +
            "       td.tamañoMax, td.tamañoMin, td.esAlfanumerico " +
            "FROM Clientes c " +
            "INNER JOIN TipoDocumentos td ON c.id_TipoDocumento = td.id ";

    private static final String SQL_FIND_ALL = SQL_SELECT_BASE + "ORDER BY c.id DESC";

    private static final String SQL_FIND_BY_ID = SQL_SELECT_BASE + "WHERE c.id = ?";

    private static final String SQL_FIND_BY_DOCUMENT = SQL_SELECT_BASE + "WHERE c.numero_documento = ?";

    // búsqueda libre por nombre, apellido o documento (para el buscador)
    private static final String SQL_SEARCH = SQL_SELECT_BASE +
            "WHERE c.nombre LIKE ? OR c.apellido LIKE ? OR c.numero_documento LIKE ? " +
            "ORDER BY c.id DESC";

    private static final String SQL_INSERT = "INSERT INTO Clientes " +
            "(id, nombre, apellido, id_TipoDocumento, numero_documento, " +
            " email, telefono, fecha_nacimiento, genero) " +
            "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)";

    private static final String SQL_UPDATE = "UPDATE Clientes SET nombre = ?, apellido = ?, id_TipoDocumento = ?, " +
            "numero_documento = ?, email = ?, telefono = ?, " +
            "fecha_nacimiento = ?, genero = ? " +
            "WHERE id = ?";

    private static final String SQL_DELETE = "DELETE FROM Clientes WHERE id = ?";

    private static final String SQL_COUNT = "SELECT COUNT(*) FROM Clientes";

    // ─── métodos públicos ──────────────────────────────────────

    // devuelve todos los clientes ordenados por apellido, nombre
    public List<Cliente> findAll() throws SQLException {
        List<Cliente> lista = new ArrayList<>();
        try (Connection con = DatabaseConnection.getConnection();
                PreparedStatement ps = con.prepareStatement(SQL_FIND_ALL);
                ResultSet rs = ps.executeQuery()) {
            while (rs.next())
                lista.add(mapRow(rs));
        }
        return lista;
    }

    // busca un cliente por id — devuelve null si no existe
    public Cliente findById(String id) throws SQLException {
        try (Connection con = DatabaseConnection.getConnection();
                PreparedStatement ps = con.prepareStatement(SQL_FIND_BY_ID)) {
            ps.setString(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next())
                    return mapRow(rs);
            }
        }
        return null;
    }

    // busca cliente por número de documento — usado en el check-in (RF-04)
    // devuelve null si no existe
    public Cliente findByDocument(String numeroDocumento) throws SQLException {
        try (Connection con = DatabaseConnection.getConnection();
                PreparedStatement ps = con.prepareStatement(SQL_FIND_BY_DOCUMENT)) {
            ps.setString(1, numeroDocumento.trim());
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next())
                    return mapRow(rs);
            }
        }
        return null;
    }

    // búsqueda libre por nombre, apellido o documento con LIKE parcial
    // si query es null o vacío devuelve todos los clientes
    public List<Cliente> search(String query) throws SQLException {
        if (query == null || query.trim().isEmpty())
            return findAll();

        String patron = "%" + query.trim() + "%";
        List<Cliente> lista = new ArrayList<>();
        try (Connection con = DatabaseConnection.getConnection();
                PreparedStatement ps = con.prepareStatement(SQL_SEARCH)) {
            ps.setString(1, patron);
            ps.setString(2, patron);
            ps.setString(3, patron);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next())
                    lista.add(mapRow(rs));
            }
        }
        return lista;
    }

    // INSERT si es nuevo, UPDATE si ya existe — el ID debe venir de IdGenerator
    public void save(Cliente cliente) throws SQLException {
        boolean existe = cliente.getId() != null
                && findById(cliente.getId()) != null;

        try (Connection con = DatabaseConnection.getConnection()) {
            if (!existe) {
                insert(con, cliente);
            } else {
                update(con, cliente);
            }
        }
    }

    // elimina un cliente por id — la BD lanza SQLException si tiene
    // contratos/inscripciones
    // devuelve true si se eliminó, false si no existía
    public boolean delete(String id) throws SQLException {
        try (Connection con = DatabaseConnection.getConnection();
                PreparedStatement ps = con.prepareStatement(SQL_DELETE)) {
            ps.setString(1, id);
            int filas = ps.executeUpdate();
            return filas > 0;
        }
    }

    // total de clientes registrados para el dashboard
    public int count() throws SQLException {
        try (Connection con = DatabaseConnection.getConnection();
                PreparedStatement ps = con.prepareStatement(SQL_COUNT);
                ResultSet rs = ps.executeQuery()) {
            if (rs.next())
                return rs.getInt(1);
        }
        return 0;
    }

    // ─── privados ──────────────────────────────────────────────

    private void insert(Connection con, Cliente c) throws SQLException {
        try (PreparedStatement ps = con.prepareStatement(SQL_INSERT)) {
            ps.setString(1, c.getId());
            ps.setString(2, c.getNombre().trim());
            ps.setString(3, c.getApellido().trim());
            ps.setString(4, c.getTipoDocumento().getId());
            ps.setString(5, c.getNumeroDocumento().trim());
            setNullableString(ps, 6, c.getEmail());
            setNullableString(ps, 7, c.getTelefono());
            setNullableDate(ps, 8, c.getFechaNacimiento());
            setNullableString(ps, 9, c.getGenero());
            ps.executeUpdate();
            LOGGER.info("Cliente insertado: " + c.getNombreCompleto());
        }
    }

    private void update(Connection con, Cliente c) throws SQLException {
        try (PreparedStatement ps = con.prepareStatement(SQL_UPDATE)) {
            ps.setString(1, c.getNombre().trim());
            ps.setString(2, c.getApellido().trim());
            ps.setString(3, c.getTipoDocumento().getId());
            ps.setString(4, c.getNumeroDocumento().trim());
            setNullableString(ps, 5, c.getEmail());
            setNullableString(ps, 6, c.getTelefono());
            setNullableDate(ps, 7, c.getFechaNacimiento());
            setNullableString(ps, 8, c.getGenero());
            ps.setString(9, c.getId());
            ps.executeUpdate();
            LOGGER.info("Cliente actualizado: " + c.getNombreCompleto());
        }
    }

    // mapea una fila a Cliente con su TipoDocumento — usa wasNull() para columnas
    // NULL-able
    private Cliente mapRow(ResultSet rs) throws SQLException {
        TipoDocumento td = new TipoDocumento();
        td.setId(rs.getString("td_id"));
        td.setNombreDocumento(rs.getString("nombre_documento"));
        td.setAbreviado(rs.getString("abreviado"));
        td.setTamañoMax(rs.getInt("tamañoMax"));
        td.setTamañoMin(rs.getInt("tamañoMin"));
        td.setEsAlfanumerico(rs.getBoolean("esAlfanumerico"));

        Cliente c = new Cliente();
        c.setId(rs.getString("id"));
        c.setNombre(rs.getString("nombre"));
        c.setApellido(rs.getString("apellido"));
        c.setTipoDocumento(td);
        c.setNumeroDocumento(rs.getString("numero_documento"));

        // columnas NULL-able
        String email = rs.getString("email");
        c.setEmail(rs.wasNull() ? null : email);

        String tel = rs.getString("telefono");
        c.setTelefono(rs.wasNull() ? null : tel);

        Date fechaNac = rs.getDate("fecha_nacimiento");
        c.setFechaNacimiento(rs.wasNull() ? null : fechaNac.toLocalDate());

        String genero = rs.getString("genero");
        c.setGenero(rs.wasNull() ? null : genero);

        return c;
    }

    // ─── helpers para NULL en PreparedStatement ────────────────

    // establece un String o NULL en el PreparedStatement
    private void setNullableString(PreparedStatement ps, int i, String val)
            throws SQLException {
        if (val != null && !val.trim().isEmpty()) {
            ps.setString(i, val.trim());
        } else {
            ps.setNull(i, Types.VARCHAR);
        }
    }

    // establece un LocalDate o NULL en el PreparedStatement
    private void setNullableDate(PreparedStatement ps, int i, LocalDate fecha)
            throws SQLException {
        if (fecha != null) {
            ps.setDate(i, Date.valueOf(fecha));
        } else {
            ps.setNull(i, Types.DATE);
        }
    }

    public boolean isTipoDocumentoEnUso(String idTipoDocumento) {
        String sql = "SELECT COUNT(*) FROM Clientes WHERE id_TipoDocumento = ?";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, idTipoDocumento);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt(1) > 0;
                }
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error al verificar uso de TipoDocumento en clientes", e);
        }
        return false;
    }
}