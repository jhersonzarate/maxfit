package com.mycompany.herramientas.dao;

import com.mycompany.herramientas.config.DatabaseConnection;
import com.mycompany.herramientas.model.*;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;
import java.util.logging.Logger;

// DAO unificado para los catálogos del sistema
// TipoDocumentos (RF-07) | Cargos (RF-13) | MetodosPago (RF-06)
// Roles (RF-15) | TipoClases (RF-10)
// CRUD completo para TipoDocumentos, TipoClases, Cargos
// Toggle estado para MetodosPago
public class CatalogoDAO {

    private static final Logger LOGGER =
            Logger.getLogger(CatalogoDAO.class.getName());

    // ═══════════════════════════════════════════════════════════
    // TIPO DOCUMENTOS (RF-07)
    // ═══════════════════════════════════════════════════════════

    // devuelve todos los tipos de documento — para selects
    public List<TipoDocumento> findAllTipoDocumentos()
            throws SQLException {

        List<TipoDocumento> lista = new ArrayList<>();
        String sql =
            "SELECT id, nombre_documento, abreviado, tamañoMax, " +
            "       tamañoMin, esAlfanumerico, estado " +
            "FROM TipoDocumentos " +
            "WHERE estado = 'activo' " +
            "ORDER BY nombre_documento";

        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                lista.add(mapTipoDocumento(rs));
            }
        }
        return lista;
    }

    // devuelve todos los tipos con estado — para vista de admin
    public List<TipoDocumento> findAllTipoDocumentosConEstado()
            throws SQLException {

        List<TipoDocumento> lista = new ArrayList<>();
        String sql =
            "SELECT id, nombre_documento, abreviado, tamañoMax, " +
            "       tamañoMin, esAlfanumerico, estado " +
            "FROM TipoDocumentos " +
            "ORDER BY nombre_documento";

        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                lista.add(mapTipoDocumento(rs));
            }
        }
        return lista;
    }

    // busca un tipo de documento por id — devuelve null si no existe
    public TipoDocumento findTipoDocumentoById(String id)
            throws SQLException {

        if (id == null || id.trim().isEmpty()) return null;

        String sql =
            "SELECT id, nombre_documento, abreviado, tamañoMax, " +
            "       tamañoMin, esAlfanumerico, estado " +
            "FROM TipoDocumentos WHERE id = ?";

        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setString(1, id.trim());
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapTipoDocumento(rs);
            }
        }
        return null;
    }

    // INSERT nuevo tipo de documento
    public void insertTipoDocumento(TipoDocumento td)
            throws SQLException {

        String sql =
            "INSERT INTO TipoDocumentos " +
            "(id, nombre_documento, abreviado, tamañoMax, tamañoMin, " +
            " esAlfanumerico, estado) " +
            "VALUES (?, ?, ?, ?, ?, ?, ?)";

        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setString(1, td.getId());
            ps.setString(2, td.getNombreDocumento().trim());
            ps.setString(3, td.getAbreviado().trim().toUpperCase());
            ps.setInt(4, td.getTamañoMax());
            ps.setInt(5, td.getTamañoMin());
            ps.setBoolean(6, td.isEsAlfanumerico());
            ps.setString(7, td.getEstado() != null
                    ? td.getEstado() : "activo");
            ps.executeUpdate();
            LOGGER.info("TipoDocumento insertado: " + td.getId());
        }
    }

    // UPDATE tipo de documento existente
    public boolean updateTipoDocumento(TipoDocumento td)
            throws SQLException {

        String sql =
            "UPDATE TipoDocumentos " +
            "SET nombre_documento = ?, abreviado = ?, " +
            "    tamañoMax = ?, tamañoMin = ?, " +
            "    esAlfanumerico = ?, estado = ? " +
            "WHERE id = ?";

        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setString(1, td.getNombreDocumento().trim());
            ps.setString(2, td.getAbreviado().trim().toUpperCase());
            ps.setInt(3, td.getTamañoMax());
            ps.setInt(4, td.getTamañoMin());
            ps.setBoolean(5, td.isEsAlfanumerico());
            ps.setString(6, td.getEstado());
            ps.setString(7, td.getId());
            boolean ok = ps.executeUpdate() > 0;
            if (ok) LOGGER.info("TipoDocumento actualizado: " + td.getId());
            return ok;
        }
    }

    // actualiza solo el estado de un tipo de documento
    public boolean updateEstadoTipoDocumento(String id, String estado)
            throws SQLException {

        String sql =
            "UPDATE TipoDocumentos SET estado = ? WHERE id = ?";

        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setString(1, estado);
            ps.setString(2, id);
            boolean ok = ps.executeUpdate() > 0;
            if (ok) LOGGER.info("TipoDocumento " + id
                    + " → " + estado);
            return ok;
        }
    }

    public boolean deleteTipoDocumento(String id) throws SQLException {
        String sql = "DELETE FROM TipoDocumentos WHERE id = ?";
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, id);
            boolean ok = ps.executeUpdate() > 0;
            if (ok) LOGGER.info("TipoDocumento eliminado: " + id);
            return ok;
        }
    }

    // ═══════════════════════════════════════════════════════════
    // CARGOS (RF-13)
    // ═══════════════════════════════════════════════════════════

    // devuelve todos los cargos activos — para selects
    public List<Cargo> findAllCargos() throws SQLException {
        List<Cargo> lista = new ArrayList<>();
        String sql =
            "SELECT id, nombre, estado FROM Cargos WHERE estado = 'activo' ORDER BY nombre";

        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                lista.add(new Cargo(
                    rs.getString("id"),
                    rs.getString("nombre"),
                    rs.getString("estado")
                ));
            }
        }
        return lista;
    }

    // devuelve todos los cargos con estado — para admin
    public List<Cargo> findAllCargosConEstado() throws SQLException {

        List<Cargo> lista = new ArrayList<>();
        String sql =
            "SELECT id, nombre, estado FROM Cargos ORDER BY nombre";

        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                lista.add(new Cargo(
                    rs.getString("id"),
                    rs.getString("nombre"),
                    rs.getString("estado")
                ));
            }
        }
        return lista;
    }

    // busca un cargo por id — devuelve null si no existe
    public Cargo findCargoById(String id) throws SQLException {

        if (id == null || id.trim().isEmpty()) return null;

        String sql =
            "SELECT id, nombre, estado FROM Cargos WHERE id = ?";

        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setString(1, id.trim());
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return new Cargo(
                        rs.getString("id"),
                        rs.getString("nombre"),
                        rs.getString("estado")
                    );
                }
            }
        }
        return null;
    }

    // INSERT nuevo cargo
    public void insertCargo(Cargo cargo) throws SQLException {

        String sql =
            "INSERT INTO Cargos (id, nombre, estado) VALUES (?, ?, ?)";

        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setString(1, cargo.getId());
            ps.setString(2, cargo.getNombre().trim());
            ps.setString(3, cargo.getEstado() != null
                    ? cargo.getEstado() : "activo");
            ps.executeUpdate();
            LOGGER.info("Cargo insertado: " + cargo.getId());
        }
    }

    // UPDATE cargo existente
    public boolean updateCargo(Cargo cargo) throws SQLException {

        String sql =
            "UPDATE Cargos SET nombre = ?, estado = ? WHERE id = ?";

        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setString(1, cargo.getNombre().trim());
            ps.setString(2, cargo.getEstado());
            ps.setString(3, cargo.getId());
            boolean ok = ps.executeUpdate() > 0;
            if (ok) LOGGER.info("Cargo actualizado: " + cargo.getId());
            return ok;
        }
    }

    // actualiza solo el estado de un cargo
    public boolean updateEstadoCargo(String id, String estado)
            throws SQLException {

        String sql = "UPDATE Cargos SET estado = ? WHERE id = ?";

        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setString(1, estado);
            ps.setString(2, id);
            boolean ok = ps.executeUpdate() > 0;
            if (ok) LOGGER.info("Cargo " + id + " → " + estado);
            return ok;
        }
    }

    // DELETE cargo
    public boolean deleteCargo(String id) throws SQLException {
        String sql = "DELETE FROM Cargos WHERE id = ?";
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, id);
            boolean ok = ps.executeUpdate() > 0;
            if (ok) LOGGER.info("Cargo eliminado: " + id);
            return ok;
        }
    }

    // ═══════════════════════════════════════════════════════════
    // METODOS DE PAGO (RF-06)
    // ═══════════════════════════════════════════════════════════

    // devuelve TODOS los métodos de pago
    public List<MetodoPago> findAllMetodosPago()
            throws SQLException {

        List<MetodoPago> lista = new ArrayList<>();
        String sql =
            "SELECT id, nombre_metodo, estado " +
            "FROM MetodosPago ORDER BY id";

        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                lista.add(new MetodoPago(
                    rs.getString("id"),
                    rs.getString("nombre_metodo"),
                    rs.getString("estado")
                ));
            }
        }
        return lista;
    }

    // devuelve solo los métodos activos — para selects de contrato
    public List<MetodoPago> findMetodosPagoActivos()
            throws SQLException {

        List<MetodoPago> lista = new ArrayList<>();
        String sql =
            "SELECT id, nombre_metodo, estado " +
            "FROM MetodosPago WHERE estado = 'activo' " +
            "ORDER BY id";

        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                lista.add(new MetodoPago(
                    rs.getString("id"),
                    rs.getString("nombre_metodo"),
                    rs.getString("estado")
                ));
            }
        }
        return lista;
    }

    // busca un método de pago por id
    public MetodoPago findMetodoPagoById(String id)
            throws SQLException {

        if (id == null || id.trim().isEmpty()) return null;

        String sql =
            "SELECT id, nombre_metodo, estado " +
            "FROM MetodosPago WHERE id = ?";

        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setString(1, id.trim());
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return new MetodoPago(
                        rs.getString("id"),
                        rs.getString("nombre_metodo"),
                        rs.getString("estado")
                    );
                }
            }
        }
        return null;
    }

    // INSERT nuevo método de pago
    public void insertMetodoPago(MetodoPago mp)
            throws SQLException {

        String sql =
            "INSERT INTO MetodosPago (id, nombre_metodo, estado) " +
            "VALUES (?, ?, ?)";

        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setString(1, mp.getId());
            ps.setString(2, mp.getNombre().trim());
            ps.setString(3, mp.getEstado() != null
                    ? mp.getEstado() : "activo");
            ps.executeUpdate();
            LOGGER.info("MetodoPago insertado: " + mp.getId());
        }
    }

    // UPDATE método de pago existente
    public boolean updateMetodoPago(MetodoPago mp)
            throws SQLException {

        String sql =
            "UPDATE MetodosPago " +
            "SET nombre_metodo = ?, estado = ? WHERE id = ?";

        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setString(1, mp.getNombre().trim());
            ps.setString(2, mp.getEstado());
            ps.setString(3, mp.getId());
            boolean ok = ps.executeUpdate() > 0;
            if (ok) LOGGER.info("MetodoPago actualizado: " + mp.getId());
            return ok;
        }
    }

    // alterna el estado de un método de pago
    public boolean updateEstadoMetodoPago(String id, String estado)
            throws SQLException {

        String sql =
            "UPDATE MetodosPago SET estado = ? WHERE id = ?";

        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setString(1, estado);
            ps.setString(2, id);
            boolean ok = ps.executeUpdate() > 0;
            if (ok) LOGGER.info("MetodoPago " + id + " → " + estado);
            return ok;
        }
    }

    // elimina físicamente un método de pago
    public boolean deleteMetodoPago(String id) throws SQLException {
        String sql = "DELETE FROM MetodosPago WHERE id = ?";
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, id);
            return ps.executeUpdate() > 0;
        }
    }

    // ═══════════════════════════════════════════════════════════
    // ROLES (RF-15)
    // ═══════════════════════════════════════════════════════════

    public List<Rol> findAllRoles() throws SQLException {

        List<Rol> lista = new ArrayList<>();
        String sql =
            "SELECT id, nombre_rol, descripcion " +
            "FROM Roles ORDER BY nombre_rol";

        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                String desc = rs.getString("descripcion");
                lista.add(new Rol(
                    rs.getString("id"),
                    rs.getString("nombre_rol"),
                    rs.wasNull() ? null : desc
                ));
            }
        }
        return lista;
    }

    public Rol findRolById(String id) throws SQLException {

        if (id == null || id.trim().isEmpty()) return null;

        String sql =
            "SELECT id, nombre_rol, descripcion FROM Roles WHERE id = ?";

        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setString(1, id.trim());
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    String desc = rs.getString("descripcion");
                    return new Rol(
                        rs.getString("id"),
                        rs.getString("nombre_rol"),
                        rs.wasNull() ? null : desc
                    );
                }
            }
        }
        return null;
    }

    // ═══════════════════════════════════════════════════════════
    // TIPO CLASES (RF-10)
    // ═══════════════════════════════════════════════════════════

    // devuelve todos los tipos de clase — para selects
    public List<TipoClase> findAllTipoClases() throws SQLException {
        return findAllTipoClasesConEstado();
    }

    // devuelve todos los tipos de clase con estado — para admin
    public List<TipoClase> findAllTipoClasesConEstado()
            throws SQLException {

        List<TipoClase> lista = new ArrayList<>();
        String sql =
            "SELECT id, nombre, estado " +
            "FROM TipoClases ORDER BY nombre";

        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                lista.add(new TipoClase(
                    rs.getString("id"),
                    rs.getString("nombre"),
                    rs.getString("estado")
                ));
            }
        }
        return lista;
    }

    // busca un tipo de clase por id — devuelve null si no existe
    public TipoClase findTipoClaseById(String id)
            throws SQLException {

        if (id == null || id.trim().isEmpty()) return null;

        String sql =
            "SELECT id, nombre, estado FROM TipoClases WHERE id = ?";

        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setString(1, id.trim());
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return new TipoClase(
                        rs.getString("id"),
                        rs.getString("nombre"),
                        rs.getString("estado")
                    );
                }
            }
        }
        return null;
    }

    // INSERT nuevo tipo de clase
    public void insertTipoClase(TipoClase tc) throws SQLException {

        String sql =
            "INSERT INTO TipoClases (id, nombre, estado) " +
            "VALUES (?, ?, ?)";

        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setString(1, tc.getId());
            ps.setString(2, tc.getNombre().trim());
            ps.setString(3, tc.getEstado() != null
                    ? tc.getEstado() : "activo");
            ps.executeUpdate();
            LOGGER.info("TipoClase insertado: " + tc.getId());
        }
    }

    // UPDATE tipo de clase existente
    public boolean updateTipoClase(TipoClase tc) throws SQLException {

        String sql =
            "UPDATE TipoClases SET nombre = ?, estado = ? WHERE id = ?";

        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setString(1, tc.getNombre().trim());
            ps.setString(2, tc.getEstado());
            ps.setString(3, tc.getId());
            boolean ok = ps.executeUpdate() > 0;
            if (ok) LOGGER.info("TipoClase actualizado: " + tc.getId());
            return ok;
        }
    }

    // actualiza solo el estado de un tipo de clase
    public boolean updateEstadoTipoClase(String id, String estado)
            throws SQLException {

        String sql =
            "UPDATE TipoClases SET estado = ? WHERE id = ?";

        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setString(1, estado);
            ps.setString(2, id);
            boolean ok = (ps.executeUpdate() > 0);
            if (ok) LOGGER.info("TipoClase " + id + " → " + estado);
            return ok;
        }
    }

    public boolean deleteTipoClase(String id) throws SQLException {
        String sql = "DELETE FROM TipoClases WHERE id = ?";
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, id);
            int rows = ps.executeUpdate();
            boolean ok = (rows > 0);
            if (ok) LOGGER.info("TipoClase eliminado: " + id);
            return ok;
        }
    }

    // ─── helpers privados ──────────────────────────────────────

    private TipoDocumento mapTipoDocumento(ResultSet rs)
            throws SQLException {

        TipoDocumento td = new TipoDocumento();
        td.setId(rs.getString("id"));
        td.setNombreDocumento(rs.getString("nombre_documento"));
        td.setAbreviado(rs.getString("abreviado"));
        td.setTamañoMax(rs.getInt("tamañoMax"));
        td.setTamañoMin(rs.getInt("tamañoMin"));
        td.setEsAlfanumerico(rs.getBoolean("esAlfanumerico"));
        td.setEstado(rs.getString("estado"));
        return td;
    }
}