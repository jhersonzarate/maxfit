package com.mycompany.herramientas.dao;

import com.mycompany.herramientas.config.DatabaseConnection;
import com.mycompany.herramientas.model.Membresia;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;
import java.util.logging.Logger;

// DAO del módulo de membresías
public class MembresiaDAO {

    private static final Logger LOGGER =
            Logger.getLogger(MembresiaDAO.class.getName());

    // ─── SQL ───────────────────────────────────────────────────

    // listar todas las membresías
    private static final String SQL_FIND_ALL =
        "SELECT id, nombre_membresia, precio, duracion_meses, descripcion, estado " +
        "FROM Membresias " +
        "ORDER BY duracion_meses ASC, precio ASC";

    // buscar membresía por ID
    private static final String SQL_FIND_BY_ID =
        "SELECT id, nombre_membresia, precio, duracion_meses, descripcion, estado " +
        "FROM Membresias WHERE id = ?";

    // registrar membresía
    private static final String SQL_INSERT =
        "INSERT INTO Membresias (id, nombre_membresia, precio, duracion_meses, descripcion, estado) " +
        "VALUES (?, ?, ?, ?, ?, ?)";

    // actualizar membresía
    private static final String SQL_UPDATE =
        "UPDATE Membresias " +
        "SET nombre_membresia = ?, precio = ?, duracion_meses = ?, descripcion = ?, estado = ? " +
        "WHERE id = ?";

    // eliminar membresía
    private static final String SQL_DELETE =
        "DELETE FROM Membresias WHERE id = ?";

    // contar membresías registradas
    private static final String SQL_COUNT =
        "SELECT COUNT(*) FROM Membresias";

    // buscar membresías activas
    private static final String SQL_FIND_ACTIVES =
        "SELECT id, nombre_membresia, precio, duracion_meses, descripcion, estado " +
        "FROM Membresias WHERE estado = 'activo' " +
        "ORDER BY duracion_meses ASC, precio ASC";

    // ─── métodos públicos ──────────────────────────────────────

    // obtener todas las membresías
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

    // obtener todas las membresías activas
    public List<Membresia> findActivas() throws SQLException {

        List<Membresia> lista = new ArrayList<>();

        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_FIND_ACTIVES);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                lista.add(mapRow(rs));
            }
        }

        return lista;
    }

    // buscar membresía por ID
    public Membresia findById(String id) throws SQLException {

        if (id == null || id.trim().isEmpty()) {
            return null;
        }

        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_FIND_BY_ID)) {

            ps.setString(1, id.trim());

            try (ResultSet rs = ps.executeQuery()) {

                if (rs.next()) {
                    return mapRow(rs);
                }
            }
        }

        return null;
    }

    // guardar o actualizar membresía
    public void save(Membresia m) throws SQLException {

        boolean existe =
                m.getId() != null
                && findById(m.getId()) != null;

        try (Connection con = DatabaseConnection.getConnection()) {

            // insertar nueva membresía
            if (!existe) {

                insert(con, m);

            } else {

                // actualizar membresía existente
                update(con, m);
            }
        }
    }

    // eliminar membresía por ID
    public boolean delete(String id) throws SQLException {

        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_DELETE)) {

            ps.setString(1, id);

            return ps.executeUpdate() > 0;
        }
    }

    // contar membresías registradas
    public int count() throws SQLException {

        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_COUNT);
             ResultSet rs = ps.executeQuery()) {

            if (rs.next()) {
                return rs.getInt(1);
            }
        }

        return 0;
    }

    // ─── métodos privados ──────────────────────────────────────

    // insertar nueva membresía
    private void insert(Connection con, Membresia m)
            throws SQLException {

        try (PreparedStatement ps = con.prepareStatement(SQL_INSERT)) {

            ps.setString(1, m.getId());
            ps.setString(2, m.getNombreMembresia().trim());

            // usar BigDecimal para dinero
            ps.setBigDecimal(3, m.getPrecio());

            ps.setInt(4, m.getDuracionMeses());

            // descripción puede ser null
            setNullableString(ps, 5, m.getDescripcion());
            ps.setString(6, m.getEstado());

            ps.executeUpdate();

            LOGGER.info(
                    "Membresía insertada: "
                            + m.getId()
                            + " | "
                            + m.getNombreMembresia()
            );
        }
    }

    // actualizar membresía existente
    private void update(Connection con, Membresia m)
            throws SQLException {

        try (PreparedStatement ps = con.prepareStatement(SQL_UPDATE)) {

            ps.setString(1, m.getNombreMembresia().trim());
            ps.setBigDecimal(2, m.getPrecio());
            ps.setInt(3, m.getDuracionMeses());

            setNullableString(ps, 4, m.getDescripcion());
            ps.setString(5, m.getEstado());

            ps.setString(6, m.getId());

            ps.executeUpdate();

            LOGGER.info(
                    "Membresía actualizada: "
                            + m.getId()
            );
        }
    }

    // mapear fila SQL a objeto Membresia
    private Membresia mapRow(ResultSet rs) throws SQLException {

        Membresia m = new Membresia();

        m.setId(rs.getString("id"));
        m.setNombreMembresia(rs.getString("nombre_membresia"));
        m.setPrecio(rs.getBigDecimal("precio"));
        m.setDuracionMeses(rs.getInt("duracion_meses"));

        String desc = rs.getString("descripcion");

        // descripción nullable
        m.setDescripcion(rs.wasNull() ? null : desc);
        
        String est = rs.getString("estado");
        m.setEstado(est != null ? est : "activo");

        return m;
    }

    // asignar String o NULL al PreparedStatement
    private void setNullableString(
            PreparedStatement ps,
            int idx,
            String val
    ) throws SQLException {

        if (val != null && !val.trim().isEmpty()) {

            ps.setString(idx, val.trim());

        } else {

            ps.setNull(idx, Types.VARCHAR);
        }
    }
}