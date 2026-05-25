package com.mycompany.herramientas.dao;

import com.mycompany.herramientas.config.DatabaseConnection;
import com.mycompany.herramientas.model.*;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;
import java.util.logging.Logger;

// DAO unificado para las cinco tablas de catálogo del sistema
// TipoDocumentos (RF-07) | Cargos (RF-13) | MetodosPago (RF-06)
// Roles (RF-15) | TipoClases (RF-10)
// los IDs son fijos (ej: "TDOC-DNI", "CARGO-TRAINER") — no usan IdGenerator
public class CatalogoDAO {

    private static final Logger LOGGER = Logger.getLogger(CatalogoDAO.class.getName());

    // ─── TipoDocumentos (RF-07) ────────────────────────────────

    // devuelve todos los tipos de documento — para selects de cliente y empleado
    public List<TipoDocumento> findAllTipoDocumentos() throws SQLException {
        List<TipoDocumento> lista = new ArrayList<>();
        String sql =
            "SELECT id, nombre_documento, abreviado, tamañoMax, tamañoMin, esAlfanumerico " +
            "FROM TipoDocumentos ORDER BY nombre_documento";
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                lista.add(mapTipoDocumento(rs));
            }
        }
        return lista;
    }

    // busca un tipo de documento por id — usado en DocumentoValidator
    // devuelve null si no existe
    public TipoDocumento findTipoDocumentoById(String id) throws SQLException {
        if (id == null || id.trim().isEmpty()) return null;
        String sql =
            "SELECT id, nombre_documento, abreviado, tamañoMax, tamañoMin, esAlfanumerico " +
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

    // ─── Cargos (RF-13) ────────────────────────────────────────

    // devuelve todos los cargos — para el formulario de empleados
    public List<Cargo> findAllCargos() throws SQLException {
        List<Cargo> lista = new ArrayList<>();
        String sql = "SELECT id, nombre FROM Cargos ORDER BY nombre";
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                lista.add(new Cargo(
                    rs.getString("id"),
                    rs.getString("nombre")
                ));
            }
        }
        return lista;
    }

    // busca un cargo por id — devuelve null si no existe
    public Cargo findCargoById(String id) throws SQLException {
        if (id == null || id.trim().isEmpty()) return null;
        String sql = "SELECT id, nombre FROM Cargos WHERE id = ?";
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, id.trim());
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return new Cargo(rs.getString("id"), rs.getString("nombre"));
                }
            }
        }
        return null;
    }

    // ─── MetodosPago (RF-06) ───────────────────────────────────

    // devuelve TODOS los métodos de pago (activos e inactivos) — para vista de admin
    public List<MetodoPago> findAllMetodosPago() throws SQLException {
        List<MetodoPago> lista = new ArrayList<>();
        String sql =
            "SELECT id, nombre_metodo, estado " +
            "FROM MetodosPago ORDER BY nombre_metodo";
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

    // devuelve solo los métodos activos — para el select del formulario de contrato
    public List<MetodoPago> findMetodosPagoActivos() throws SQLException {
        List<MetodoPago> lista = new ArrayList<>();
        String sql =
            "SELECT id, nombre_metodo, estado " +
            "FROM MetodosPago WHERE estado = 'activo' ORDER BY nombre_metodo";
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

    // alterna el estado de un método de pago ('activo' ↔ 'inactivo') — solo Admin
    // devuelve true si se actualizó, false si no existía
    public boolean updateEstadoMetodoPago(String id, String estado) throws SQLException {
        String sql = "UPDATE MetodosPago SET estado = ? WHERE id = ?";
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, estado);
            ps.setString(2, id);
            boolean ok = ps.executeUpdate() > 0;
            if (ok) LOGGER.info("MetodoPago " + id + " → " + estado);
            return ok;
        }
    }

    // ─── Roles (RF-15) ─────────────────────────────────────────

    // devuelve todos los roles — para el formulario de gestión de usuarios
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
                    rs.wasNull() ? null : desc   // descripcion es NULL-able en la BD
                ));
            }
        }
        return lista;
    }

    // busca un rol por id — devuelve null si no existe
    public Rol findRolById(String id) throws SQLException {
        if (id == null || id.trim().isEmpty()) return null;
        String sql = "SELECT id, nombre_rol, descripcion FROM Roles WHERE id = ?";
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

    // ─── TipoClases (RF-10) ────────────────────────────────────

    // devuelve todos los tipos de clase — para el formulario de nueva clase (RF-08)
    public List<TipoClase> findAllTipoClases() throws SQLException {
        List<TipoClase> lista = new ArrayList<>();
        String sql = "SELECT id, nombre FROM TipoClases ORDER BY nombre";
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                lista.add(new TipoClase(
                    rs.getString("id"),
                    rs.getString("nombre")
                ));
            }
        }
        return lista;
    }

    // busca un tipo de clase por id — devuelve null si no existe
    public TipoClase findTipoClaseById(String id) throws SQLException {
        if (id == null || id.trim().isEmpty()) return null;
        String sql = "SELECT id, nombre FROM TipoClases WHERE id = ?";
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, id.trim());
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return new TipoClase(rs.getString("id"), rs.getString("nombre"));
                }
            }
        }
        return null;
    }

    // ─── helpers privados ──────────────────────────────────────

    // mapea una fila de TipoDocumentos a objeto — compartido por findAll y findById
    private TipoDocumento mapTipoDocumento(ResultSet rs) throws SQLException {
        TipoDocumento td = new TipoDocumento();
        td.setId(rs.getString("id"));
        td.setNombreDocumento(rs.getString("nombre_documento"));
        td.setAbreviado(rs.getString("abreviado"));
        td.setTamañoMax(rs.getInt("tamañoMax"));
        td.setTamañoMin(rs.getInt("tamañoMin"));
        td.setEsAlfanumerico(rs.getBoolean("esAlfanumerico"));
        return td;
    }
}