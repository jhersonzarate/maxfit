package com.mycompany.herramientas.dao;

import com.mycompany.herramientas.config.DatabaseConnection;
import com.mycompany.herramientas.model.*;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;
import java.util.logging.Logger;

/**
 * DAO para los catálogos fijos de la BD (tablas sin operaciones CRUD frecuentes).
 *
 * Tablas que gestiona:
 *   TipoDocumentos  → TipoDocumento
 *   Cargos          → Cargo
 *   MetodosPago     → MetodoPago
 *   Roles           → Rol
 *   TipoClases      → TipoClase
 *
 * Estos catálogos se cargan al inicio del formulario o al renderizar un <select>.
 * Se proveen métodos de solo lectura (no se crean ni eliminan por la app web).
 *
 * NOTA: MetodosPago SÍ tiene columna estado ('activo'/'inactivo') en la BD,
 *       por eso hay un método listMetodosActivos() además de listAll.
 *       TipoDocumentos, Cargos, Roles y TipoClases son catálogos inmutables.
 */
public class CatalogoDAO {

    private static final Logger LOGGER = Logger.getLogger(CatalogoDAO.class.getName());

    // ─── TipoDocumentos ───────────────────────────────────────────────────────

    private static final String SQL_TIPO_DOCS =
        "SELECT id, nombre_documento, abreviado, tamañoMax, tamañoMin, esAlfanumerico " +
        "FROM TipoDocumentos " +
        "ORDER BY nombre_documento";

    private static final String SQL_TIPO_DOC_BY_ID =
        "SELECT id, nombre_documento, abreviado, tamañoMax, tamañoMin, esAlfanumerico " +
        "FROM TipoDocumentos WHERE id = ?";

    // ─── Cargos ───────────────────────────────────────────────────────────────

    private static final String SQL_CARGOS =
        "SELECT id, nombre FROM Cargos ORDER BY nombre";

    private static final String SQL_CARGO_BY_ID =
        "SELECT id, nombre FROM Cargos WHERE id = ?";

    // ─── MetodosPago ──────────────────────────────────────────────────────────

    private static final String SQL_METODOS_PAGO_ALL =
        "SELECT id, nombre_metodo, estado FROM MetodosPago ORDER BY nombre_metodo";

    private static final String SQL_METODOS_PAGO_ACTIVOS =
        "SELECT id, nombre_metodo, estado FROM MetodosPago " +
        "WHERE estado = 'activo' ORDER BY nombre_metodo";

    private static final String SQL_METODO_PAGO_BY_ID =
        "SELECT id, nombre_metodo, estado FROM MetodosPago WHERE id = ?";

    // ─── Roles ────────────────────────────────────────────────────────────────

    private static final String SQL_ROLES =
        "SELECT id, nombre_rol, descripcion FROM Roles ORDER BY nombre_rol";

    private static final String SQL_ROL_BY_ID =
        "SELECT id, nombre_rol, descripcion FROM Roles WHERE id = ?";

    // ─── TipoClases ───────────────────────────────────────────────────────────

    private static final String SQL_TIPO_CLASES =
        "SELECT id, nombre FROM TipoClases ORDER BY nombre";

    private static final String SQL_TIPO_CLASE_BY_ID =
        "SELECT id, nombre FROM TipoClases WHERE id = ?";

    // ─── TipoDocumentos — métodos públicos ────────────────────────────────────

    /**
     * Lista todos los tipos de documento disponibles.
     * Usados en formularios de registro de Clientes y Empleados.
     */
    public List<TipoDocumento> listTipoDocumentos() throws SQLException {
        List<TipoDocumento> lista = new ArrayList<>();
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_TIPO_DOCS);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) lista.add(mapTipoDocumento(rs));
        }
        return lista;
    }

    /**
     * Busca un TipoDocumento por su ID (ej: 'TDOC-DNI').
     * Devuelve null si no existe.
     */
    public TipoDocumento findTipoDocumentoById(String id) throws SQLException {
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_TIPO_DOC_BY_ID)) {
            ps.setString(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? mapTipoDocumento(rs) : null;
            }
        }
    }

    // ─── Cargos — métodos públicos ────────────────────────────────────────────

    /**
     * Lista todos los cargos disponibles.
     * Usados en formularios de Empleados.
     */
    public List<Cargo> listCargos() throws SQLException {
        List<Cargo> lista = new ArrayList<>();
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_CARGOS);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) lista.add(mapCargo(rs));
        }
        return lista;
    }

    /**
     * Busca un Cargo por su ID (ej: 'CARGO-TRAINER').
     * Devuelve null si no existe.
     */
    public Cargo findCargoById(String id) throws SQLException {
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_CARGO_BY_ID)) {
            ps.setString(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? mapCargo(rs) : null;
            }
        }
    }

    // ─── MetodosPago — métodos públicos ───────────────────────────────────────

    /**
     * Lista todos los métodos de pago (activos e inactivos).
     * Para la pantalla de administración de métodos de pago (RF-06).
     */
    public List<MetodoPago> listMetodosPago() throws SQLException {
        List<MetodoPago> lista = new ArrayList<>();
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_METODOS_PAGO_ALL);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) lista.add(mapMetodoPago(rs));
        }
        return lista;
    }

    /**
     * Lista solo los métodos de pago con estado 'activo'.
     * Usados en el formulario de registro de contratos (RF-03).
     * Solo los activos están disponibles para nuevos contratos.
     */
    public List<MetodoPago> listMetodosActivos() throws SQLException {
        List<MetodoPago> lista = new ArrayList<>();
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_METODOS_PAGO_ACTIVOS);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) lista.add(mapMetodoPago(rs));
        }
        return lista;
    }

    /**
     * Busca un MetodoPago por su ID (ej: 'PAY-YAPE').
     * Devuelve null si no existe.
     */
    public MetodoPago findMetodoPagoById(String id) throws SQLException {
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_METODO_PAGO_BY_ID)) {
            ps.setString(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? mapMetodoPago(rs) : null;
            }
        }
    }

    // ─── Roles — métodos públicos ─────────────────────────────────────────────

    /**
     * Lista todos los roles del sistema.
     * Usados en el formulario de administración de usuarios (RF-14).
     */
    public List<Rol> listRoles() throws SQLException {
        List<Rol> lista = new ArrayList<>();
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_ROLES);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) lista.add(mapRol(rs));
        }
        return lista;
    }

    /**
     * Busca un Rol por su ID (ej: 'ROL-ADMIN').
     * Devuelve null si no existe.
     */
    public Rol findRolById(String id) throws SQLException {
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_ROL_BY_ID)) {
            ps.setString(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? mapRol(rs) : null;
            }
        }
    }

    // ─── TipoClases — métodos públicos ────────────────────────────────────────

    /**
     * Lista todos los tipos de clase disponibles (RF-10).
     * Usados en el formulario de creación de clases grupales.
     */
    public List<TipoClase> listTipoClases() throws SQLException {
        List<TipoClase> lista = new ArrayList<>();
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_TIPO_CLASES);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) lista.add(mapTipoClase(rs));
        }
        return lista;
    }

    /**
     * Busca un TipoClase por su ID (ej: 'TCL-YOGA').
     * Devuelve null si no existe.
     */
    public TipoClase findTipoClaseById(String id) throws SQLException {
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_TIPO_CLASE_BY_ID)) {
            ps.setString(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? mapTipoClase(rs) : null;
            }
        }
    }

    // ─── Mappers privados ─────────────────────────────────────────────────────

    /**
     * Mapea una fila de TipoDocumentos.
     * Columnas: id, nombre_documento, abreviado, tamañoMax, tamañoMin, esAlfanumerico
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

    /**
     * Mapea una fila de Cargos.
     * Columnas: id, nombre
     */
    private Cargo mapCargo(ResultSet rs) throws SQLException {
        Cargo c = new Cargo();
        c.setId(rs.getString("id"));
        c.setNombre(rs.getString("nombre"));
        return c;
    }

    /**
     * Mapea una fila de MetodosPago.
     * Columnas: id, nombre_metodo, estado
     */
    private MetodoPago mapMetodoPago(ResultSet rs) throws SQLException {
        MetodoPago mp = new MetodoPago();
        mp.setId(rs.getString("id"));
        mp.setNombre(rs.getString("nombre_metodo"));
        mp.setEstado(rs.getString("estado"));
        return mp;
    }

    /**
     * Mapea una fila de Roles.
     * Columnas: id, nombre_rol, descripcion
     */
    private Rol mapRol(ResultSet rs) throws SQLException {
        Rol r = new Rol();
        r.setId(rs.getString("id"));
        r.setNombreRol(rs.getString("nombre_rol"));
        String desc = rs.getString("descripcion");
        r.setDescripcion(rs.wasNull() ? null : desc);
        return r;
    }

    /**
     * Mapea una fila de TipoClases.
     * Columnas: id, nombre
     */
    private TipoClase mapTipoClase(ResultSet rs) throws SQLException {
        TipoClase tc = new TipoClase();
        tc.setId(rs.getString("id"));
        tc.setNombre(rs.getString("nombre"));
        return tc;
    }
}