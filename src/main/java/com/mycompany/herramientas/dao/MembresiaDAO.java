package com.mycompany.herramientas.dao;

import com.mycompany.herramientas.config.DatabaseConnection;
import com.mycompany.herramientas.model.Membresia;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;
import java.util.logging.Logger;

/**
 * DAO para la tabla Membresias (RF-02).
 *
 * NOTA CRÍTICA sobre el SQL del proyecto:
 *   La tabla Membresias NO tiene columna "estado".
 *   El SQL original es:
 *     CREATE TABLE Membresias (
 *       id VARCHAR(20) NOT NULL PRIMARY KEY,
 *       nombre_membresia VARCHAR(100) NOT NULL,
 *       precio DECIMAL(10,2) NOT NULL,
 *       duracion_meses INT NOT NULL,
 *       descripcion VARCHAR(200)
 *     );
 *   Por eso este DAO NO filtra por estado — todos los planes
 *   registrados están disponibles para asignar a contratos.
 *
 * Se usa BigDecimal para precio — NUNCA double para dinero.
 * La columna descripcion es NULL-able.
 */
public class MembresiaDAO {

    private static final Logger LOGGER = Logger.getLogger(MembresiaDAO.class.getName());

    // ─── SQL ─────────────────────────────────────────────────────────────────

    private static final String SQL_FIND_ALL =
        "SELECT id, nombre_membresia, precio, duracion_meses, descripcion " +
        "FROM Membresias " +
        "ORDER BY duracion_meses ASC, precio ASC";

    private static final String SQL_FIND_BY_ID =
        "SELECT id, nombre_membresia, precio, duracion_meses, descripcion " +
        "FROM Membresias WHERE id = ?";

    private static final String SQL_INSERT =
        "INSERT INTO Membresias (id, nombre_membresia, precio, duracion_meses, descripcion) " +
        "VALUES (?, ?, ?, ?, ?)";

    private static final String SQL_UPDATE =
        "UPDATE Membresias " +
        "SET nombre_membresia = ?, precio = ?, duracion_meses = ?, descripcion = ? " +
        "WHERE id = ?";

    private static final String SQL_DELETE =
        "DELETE FROM Membresias WHERE id = ?";

    private static final String SQL_COUNT =
        "SELECT COUNT(*) FROM Membresias";

    // ─── Métodos públicos ─────────────────────────────────────────────────────

    /**
     * Devuelve todos los planes ordenados por duración y precio.
     * El recepcionista y el admin los ven en el formulario de nuevo contrato.
     */
    public List<Membresia> findAll() throws SQLException {
        List<Membresia> lista = new ArrayList<>();
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_FIND_ALL);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                lista.add(mapRow(rs));
            }
        }
        return lista;
    }

    /**
     * Busca una membresía por su ID.
     * Devuelve null si no existe.
     */
    public Membresia findById(String id) throws SQLException {
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
     * Guarda (INSERT o UPDATE) una membresía.
     * Si el id es null o no existe en BD → INSERT.
     * Si ya existe → UPDATE.
     * El ID debe venir generado por IdGenerator.parMembresia() antes de llamar.
     *
     * @throws SQLException si hay error de BD (ej: nombre duplicado)
     */
    public void save(Membresia m) throws SQLException {
        boolean existe = m.getId() != null && findById(m.getId()) != null;
        try (Connection con = DatabaseConnection.getConnection()) {
            if (!existe) {
                insert(con, m);
            } else {
                update(con, m);
            }
        }
    }

    /**
     * Elimina una membresía por ID.
     * Precaución: si hay contratos que referencian esta membresía,
     * la BD lanzará un error de integridad referencial.
     * El controlador debe capturarlo y mostrar mensaje amigable.
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

    /** Total de membresías registradas (para estadísticas del dashboard). */
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
            ps.setBigDecimal(3, m.getPrecio());          // DECIMAL(10,2) — nunca double
            ps.setInt(4, m.getDuracionMeses());
            setNullableString(ps, 5, m.getDescripcion()); // descripcion es NULL-able
            ps.executeUpdate();
            LOGGER.info("Membresía insertada: " + m.getId()
                    + " | " + m.getNombreMembresia());
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
            LOGGER.info("Membresía actualizada: " + m.getId());
        }
    }

    /**
     * Mapea una fila del ResultSet a un objeto Membresia.
     * rs.wasNull() para descripcion que puede ser NULL en BD.
     */
    private Membresia mapRow(ResultSet rs) throws SQLException {
        Membresia m = new Membresia();
        m.setId(rs.getString("id"));
        m.setNombreMembresia(rs.getString("nombre_membresia"));
        m.setPrecio(rs.getBigDecimal("precio"));
        m.setDuracionMeses(rs.getInt("duracion_meses"));
        String desc = rs.getString("descripcion");
        m.setDescripcion(rs.wasNull() ? null : desc);
        return m;
    }

    /** Establece un String o NULL en el PreparedStatement. */
    private void setNullableString(PreparedStatement ps, int idx, String val)
            throws SQLException {
        if (val != null && !val.trim().isEmpty()) {
            ps.setString(idx, val.trim());
        } else {
            ps.setNull(idx, Types.VARCHAR);
        }
    }
}