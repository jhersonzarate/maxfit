package com.mycompany.herramientas.dao;

import com.mycompany.herramientas.config.DatabaseConnection;
import com.mycompany.herramientas.model.Membresia;

import java.math.BigDecimal;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * DAO para la tabla Membresias (RF-02).
 *
 * NOTA: La tabla Membresias NO tiene columna "estado" en la BD.
 * Todos los planes registrados están disponibles para asignar a contratos.
 * AppConfig.java lo documenta explícitamente.
 * Si en el futuro se requiere activar/desactivar planes, se debe agregar
 * la columna estado a la BD primero.
 *
 * Se usa BigDecimal para el campo precio porque double genera
 * errores de redondeo en operaciones monetarias (RNF-07).
 */
public class MembresiaDAO {

    private static final Logger LOGGER = Logger.getLogger(MembresiaDAO.class.getName());

    // ─── SQL ─────────────────────────────────────────────────────────────────

    private static final String SQL_FIND_ALL =
        "SELECT id, nombre_membresia, precio, duracion_meses, descripcion " +
        "FROM Membresias " +
        "ORDER BY duracion_meses, nombre_membresia";

    private static final String SQL_FIND_BY_ID =
        "SELECT id, nombre_membresia, precio, duracion_meses, descripcion " +
        "FROM Membresias WHERE id = ?";

    private static final String SQL_INSERT =
        "INSERT INTO Membresias (id, nombre_membresia, precio, duracion_meses, descripcion) " +
        "VALUES (?, ?, ?, ?, ?)";

    private static final String SQL_UPDATE =
        "UPDATE Membresias SET nombre_membresia = ?, precio = ?, " +
        "duracion_meses = ?, descripcion = ? " +
        "WHERE id = ?";

    private static final String SQL_DELETE =
        "DELETE FROM Membresias WHERE id = ?";

    private static final String SQL_COUNT =
        "SELECT COUNT(*) FROM Membresias";

    // ─── Métodos públicos ─────────────────────────────────────────────────────

    /**
     * Todos los planes ordenados por duración y nombre.
     * Como la tabla no tiene estado, se devuelven todos.
     */
    public List<Membresia> findAll() throws SQLException {
        List<Membresia> lista = new ArrayList<>();
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_FIND_ALL);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) lista.add(mapRow(rs));
        }
        return lista;
    }

    /** Busca una membresía por su ID. Devuelve null si no existe. */
    public Membresia findById(String id) throws SQLException {
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
     * El ID debe venir generado antes de llamar save().
     * IDs de membresías siguen el patrón MEM-XXXX (ej: MEM-STD, MEM-TRIM).
     * Para membresías creadas dinámicamente usar IdGenerator con prefijo "MEM".
     */
    public void save(Membresia membresia) throws SQLException {
        boolean existe = membresia.getId() != null
                && findById(membresia.getId()) != null;

        try (Connection con = DatabaseConnection.getConnection()) {
            if (!existe) {
                insert(con, membresia);
            } else {
                update(con, membresia);
            }
        }
    }

    /**
     * Elimina una membresía por ID.
     * PRECAUCIÓN: la BD tiene FK desde Contratos hacia Membresias.
     * Si la membresía tiene contratos asociados, la BD lanzará error.
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

    /** Total de membresías registradas. */
    public int count() throws SQLException {
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_COUNT);
             ResultSet rs = ps.executeQuery()) {
            if (rs.next()) return rs.getInt(1);
        }
        return 0;
    }

    // ─── Privados ─────────────────────────────────────────────────────────────

    private void insert(Connection con, Membresia m) throws SQLException {
        try (PreparedStatement ps = con.prepareStatement(SQL_INSERT)) {
            ps.setString(1, m.getId());
            ps.setString(2, m.getNombreMembresia().trim());
            ps.setBigDecimal(3, m.getPrecio());
            ps.setInt(4, m.getDuracionMeses());
            setNullableString(ps, 5, m.getDescripcion());
            ps.executeUpdate();
            LOGGER.info("Membresía insertada: " + m.getNombreMembresia());
        }
    }

    private void update(Connection con, Membresia m) throws SQLException {
        try (PreparedStatement ps = con.prepareStatement(SQL_UPDATE)) {
            ps.setString(1, m.getNombreMembresia().trim());
            ps.setBigDecimal(2, m.getPrecio());
            ps.setInt(3, m.getDuracionMeses());
            setNullableString(ps, 4, m.getDescripcion());
            ps.setString(5, m.getId());
            ps.executeUpdate();
            LOGGER.info("Membresía actualizada: " + m.getNombreMembresia());
        }
    }

    private Membresia mapRow(ResultSet rs) throws SQLException {
        Membresia m = new Membresia();
        m.setId(rs.getString("id"));
        m.setNombreMembresia(rs.getString("nombre_membresia"));
        // getBigDecimal es la forma correcta para DECIMAL(10,2) — nunca getDouble
        m.setPrecio(rs.getBigDecimal("precio"));
        m.setDuracionMeses(rs.getInt("duracion_meses"));

        // descripcion es NULL-able
        String desc = rs.getString("descripcion");
        m.setDescripcion(rs.wasNull() ? null : desc);

        return m;
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