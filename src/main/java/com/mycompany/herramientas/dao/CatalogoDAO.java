package com.mycompany.herramientas.dao;

import com.mycompany.herramientas.config.DatabaseConnection;
import com.mycompany.herramientas.model.*;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;
import java.util.logging.Logger;

/**
 * DAO para las cinco tablas de catálogo del sistema (RF-06, RF-07, RF-10, RF-13).
 *
 * Agrupa en un solo DAO las tablas que son catálogos fijos:
 *   TipoDocumentos  → RF-07 (tipos de documento: DNI, CE, Pasaporte)
 *   Cargos          → RF-13 (cargos del personal: Admin, Recep, Trainer)
 *   MetodosPago     → RF-06 (métodos de pago: Efectivo, Yape, Tarjeta…)
 *   Roles           → RF-15 (roles del sistema: ROL-ADMIN, ROL-RECEP, ROL-TRAINER)
 *   TipoClases      → RF-10 (tipos de clase: Yoga, CrossFit, Spinning…)
 *
 * Por qué un DAO unificado y no cinco separados:
 *   Estas tablas son catálogos de solo lectura en la operación diaria.
 *   Solo MetodosPago tiene un UPDATE de estado (RF-06 permite
 *   activar/desactivar). Las demás solo se leen.
 *   Unificarlas evita crear cinco archivos de 30 líneas cada uno.
 *
 * Los IDs de los catálogos son fijos (ej: "TDOC-DNI", "CARGO-TRAINER")
 * y se insertan con el script SQL inicial, no con IdGenerator.
 */
public class CatalogoDAO {

    private static final Logger LOGGER = Logger.getLogger(CatalogoDAO.class.getName());

    // ═══════════════════════════════════════════════════════════════════════════
    // TipoDocumentos  (RF-07)
    // ═══════════════════════════════════════════════════════════════════════════

    /**
     * Devuelve todos los tipos de documento ordenados por nombre.
     * Se usa en los formularios de registro de cliente y empleado.
     */
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

    /**
     * Busca un tipo de documento por su ID.
     * Devuelve null si no existe.
     * Usado en DocumentoValidator para obtener tamañoMin/Max/esAlfanumerico.
     */
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

    // ═══════════════════════════════════════════════════════════════════════════
    // Cargos  (RF-13)
    // ═══════════════════════════════════════════════════════════════════════════

    /**
     * Devuelve todos los cargos disponibles ordenados por nombre.
     * Se usa en el formulario de registro/edición de empleados.
     */
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

    /**
     * Busca un cargo por su ID.
     * Devuelve null si no existe.
     */
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

    // ═══════════════════════════════════════════════════════════════════════════
    // MetodosPago  (RF-06)
    // ═══════════════════════════════════════════════════════════════════════════

    /**
     * Devuelve TODOS los métodos de pago (activos e inactivos).
     * Para la vista de administración de métodos de pago (solo Admin).
     */
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

    /**
     * Devuelve solo los métodos de pago con estado 'activo'.
     * Para el select del formulario de nuevo contrato (RF-06).
     * El recepcionista y el admin solo ven los activos al registrar.
     */
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

    /**
     * Cambia el estado de un método de pago ('activo' ↔ 'inactivo').
     * Solo el Admin puede hacer esto (RF-06).
     *
     * @param id     ID del método de pago (ej: "PAY-YAPE")
     * @param estado nuevo estado: "activo" o "inactivo"
     * @return true si se actualizó, false si no existía
     */
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

    // ═══════════════════════════════════════════════════════════════════════════
    // Roles  (RF-15 — control de acceso)
    // ═══════════════════════════════════════════════════════════════════════════

    /**
     * Devuelve todos los roles del sistema.
     * Se usa en el formulario de gestión de usuarios (RF-14, solo Admin).
     */
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
                    rs.wasNull() ? null : desc   // descripcion NULL-able en la BD
                ));
            }
        }
        return lista;
    }

    /**
     * Busca un rol por su ID.
     * Devuelve null si no existe.
     */
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

    // ═══════════════════════════════════════════════════════════════════════════
    // TipoClases  (RF-10)
    // ═══════════════════════════════════════════════════════════════════════════

    /**
     * Devuelve todos los tipos de clase disponibles ordenados por nombre.
     * Se usa en el formulario de nueva clase grupal (RF-08).
     */
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

    /**
     * Busca un tipo de clase por su ID.
     * Devuelve null si no existe.
     */
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

    // ─── Helpers privados ─────────────────────────────────────────────────────

    /**
     * Mapea una fila de TipoDocumentos a objeto.
     * Centralizado para no repetir el mismo mapeo en findAll y findById.
     */
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