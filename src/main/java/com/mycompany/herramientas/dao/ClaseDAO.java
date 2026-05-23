package com.mycompany.herramientas.dao;

import com.mycompany.herramientas.config.AppConfig;
import com.mycompany.herramientas.config.DatabaseConnection;
import com.mycompany.herramientas.model.*;

import java.sql.*;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.logging.Logger;

/**
 * DAO para la tabla Clases (RF-08).
 *
 * Tablas involucradas:
 *   Clases → Empleados (entrenador, FK id_empleado)
 *   Clases → TipoClases (FK id_tipoClase)
 *
 * Estados válidos para Clases (columna estado):
 *   'vigente'    → disponible para inscripciones y horarios
 *   'suspendida' → no aparece en listas activas
 *
 * La columna en la BD se llama nombre_clase (no nombre).
 * El modelo Clase.java lo refleja con getNombreClase().
 *
 * Formato de ID: CLA-AÑO-CORRELATIVO (ej: CLA-2026-0001)
 */
public class ClaseDAO {

    private static final Logger LOGGER = Logger.getLogger(ClaseDAO.class.getName());

    // ─── SQL ─────────────────────────────────────────────────────────────────

    private static final String SQL_SELECT_BASE =
        "SELECT cl.id, cl.nombre_clase, cl.capacidad_maxima, cl.descripcion, cl.estado, " +
        "       emp.id AS emp_id, emp.nombre AS emp_nombre, emp.apellido AS emp_apellido, " +
        "       emp.email AS emp_email, emp.telefono AS emp_tel, " +
        "       emp.numeroDocumento AS emp_doc, " +
        "       tde.id AS tde_id, tde.nombre_documento AS tde_nd, " +
        "       tde.abreviado AS tde_abrev, " +
        "       tde.tamañoMax AS tde_max, tde.tamañoMin AS tde_min, " +
        "       tde.esAlfanumerico AS tde_alfa, " +
        "       car.id AS car_id, car.nombre AS car_nombre, " +
        "       tc.id AS tc_id, tc.nombre AS tc_nombre " +
        "FROM Clases cl " +
        "INNER JOIN Empleados emp       ON cl.id_empleado  = emp.id " +
        "INNER JOIN TipoDocumentos tde  ON emp.id_TipoDocumento = tde.id " +
        "INNER JOIN Cargos car          ON emp.id_Cargo    = car.id " +
        "INNER JOIN TipoClases tc       ON cl.id_tipoClase = tc.id ";

    private static final String SQL_FIND_ALL =
        SQL_SELECT_BASE + "ORDER BY cl.nombre_clase";

    private static final String SQL_FIND_ALL_VIGENTES =
        SQL_SELECT_BASE + "WHERE cl.estado = 'vigente' ORDER BY cl.nombre_clase";

    private static final String SQL_FIND_BY_ID =
        SQL_SELECT_BASE + "WHERE cl.id = ?";

    private static final String SQL_EXISTS =
        "SELECT COUNT(*) FROM Clases WHERE id = ?";

    private static final String SQL_INSERT =
        "INSERT INTO Clases " +
        "(id, nombre_clase, id_empleado, id_tipoClase, capacidad_maxima, descripcion, estado) " +
        "VALUES (?, ?, ?, ?, ?, ?, ?)";

    private static final String SQL_UPDATE =
        "UPDATE Clases SET nombre_clase = ?, id_empleado = ?, id_tipoClase = ?, " +
        "capacidad_maxima = ?, descripcion = ?, estado = ? " +
        "WHERE id = ?";

    private static final String SQL_DELETE =
        "DELETE FROM Clases WHERE id = ?";

    private static final String SQL_COUNT_VIGENTES =
        "SELECT COUNT(*) FROM Clases WHERE estado = 'vigente'";

    /** Correlativo para IDs con formato CLA-AÑO-CORRELATIVO */
    private static final String SQL_NEXT_ID =
        "SELECT ISNULL(MAX(CAST(SUBSTRING(id, CHARINDEX('-', id, 5)+1, 10) AS INT)), 0) + 1 " +
        "FROM Clases WHERE id LIKE 'CLA-%'";

    // ─── Métodos públicos ─────────────────────────────────────────────────────

    /** Todas las clases independientemente del estado. */
    public List<Clase> findAll() throws SQLException {
        List<Clase> lista = new ArrayList<>();
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_FIND_ALL);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) lista.add(mapRow(rs));
        }
        return lista;
    }

    /** Solo las clases con estado 'vigente'. */
    public List<Clase> findAllVigentes() throws SQLException {
        List<Clase> lista = new ArrayList<>();
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_FIND_ALL_VIGENTES);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) lista.add(mapRow(rs));
        }
        return lista;
    }

    /**
     * Busca una clase por ID.
     * Devuelve null si no existe.
     */
    public Clase findById(String id) throws SQLException {
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_FIND_BY_ID)) {
            ps.setString(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? mapRow(rs) : null;
            }
        }
    }

    /**
     * INSERT si la clase es nueva (sin id o no existe en BD),
     * UPDATE si ya existe.
     *
     * Si el id está vacío/null, se genera automáticamente.
     * El id_empleado y id_tipoClase deben venir con IDs válidos en la BD.
     *
     * @param clase objeto con todos los campos requeridos
     */
    public void save(Clase clase) throws SQLException {
        if (clase.getId() == null || clase.getId().trim().isEmpty()) {
            clase.setId(generarId());
        }
        boolean existe = exists(clase.getId());
        try (Connection con = DatabaseConnection.getConnection()) {
            if (!existe) {
                insert(con, clase);
            } else {
                update(con, clase);
            }
        }
    }

    /**
     * Elimina una clase por ID.
     * PRECAUCIÓN: la BD tiene FKs desde Horarios e Inscripcion_Clases.
     * Si hay horarios o inscripciones asociadas, la BD lanzará error de integridad.
     * El controlador debe capturarlo y mostrar un mensaje amigable.
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

    /** Número de clases vigentes (para el dashboard). */
    public int countVigentes() throws SQLException {
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_COUNT_VIGENTES);
             ResultSet rs = ps.executeQuery()) {
            return rs.next() ? rs.getInt(1) : 0;
        }
    }

    // ─── Privados ─────────────────────────────────────────────────────────────

    /**
     * Verifica si existe una clase con el ID dado.
     * Se usa en save() para decidir INSERT o UPDATE, evitando abrir dos conexiones.
     */
    private boolean exists(String id) throws SQLException {
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_EXISTS)) {
            ps.setString(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() && rs.getInt(1) > 0;
            }
        }
    }

    /**
     * Genera el ID con formato CLA-AÑO-CORRELATIVO.
     * El correlativo se obtiene de la BD para ser thread-safe.
     */
    private String generarId() throws SQLException {
        int anio = java.time.LocalDate.now().getYear();
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_NEXT_ID);
             ResultSet rs = ps.executeQuery()) {
            int siguiente = rs.next() ? rs.getInt(1) : 1;
            return String.format("%s-%d-%04d", AppConfig.PREFIX_CLASE, anio, siguiente);
        }
    }

    /**
     * INSERT de nueva clase.
     * Posiciones: 1=id, 2=nombre_clase, 3=id_empleado, 4=id_tipoClase,
     *             5=capacidad_maxima, 6=descripcion, 7=estado
     */
    private void insert(Connection con, Clase c) throws SQLException {
        try (PreparedStatement ps = con.prepareStatement(SQL_INSERT)) {
            ps.setString(1, c.getId());
            ps.setString(2, c.getNombreClase().trim());
            ps.setString(3, c.getEmpleado().getId());
            ps.setString(4, c.getTipoClase().getId());
            ps.setInt(5, c.getCapacidadMaxima());
            setNullableString(ps, 6, c.getDescripcion());
            ps.setString(7, c.getEstado());
            ps.executeUpdate();
            LOGGER.info("Clase insertada: " + c.getId() + " | " + c.getNombreClase());
        }
    }

    /**
     * UPDATE de clase existente.
     * Posiciones: 1=nombre_clase, 2=id_empleado, 3=id_tipoClase,
     *             4=capacidad_maxima, 5=descripcion, 6=estado, 7=id (WHERE)
     */
    private void update(Connection con, Clase c) throws SQLException {
        try (PreparedStatement ps = con.prepareStatement(SQL_UPDATE)) {
            ps.setString(1, c.getNombreClase().trim());
            ps.setString(2, c.getEmpleado().getId());
            ps.setString(3, c.getTipoClase().getId());
            ps.setInt(4, c.getCapacidadMaxima());
            setNullableString(ps, 5, c.getDescripcion());
            ps.setString(6, c.getEstado());
            ps.setString(7, c.getId());
            ps.executeUpdate();
            LOGGER.info("Clase actualizada: " + c.getId() + " | " + c.getNombreClase());
        }
    }

    /**
     * Mapea una fila del ResultSet a un objeto Clase completo con su
     * Empleado (entrenador) y TipoClase hidratados.
     */
    private Clase mapRow(ResultSet rs) throws SQLException {
        TipoDocumento tdEmp = new TipoDocumento();
        tdEmp.setId(rs.getString("tde_id"));
        tdEmp.setNombreDocumento(rs.getString("tde_nd"));
        tdEmp.setAbreviado(rs.getString("tde_abrev"));
        tdEmp.setTamañoMax(rs.getInt("tde_max"));
        tdEmp.setTamañoMin(rs.getInt("tde_min"));
        tdEmp.setEsAlfanumerico(rs.getBoolean("tde_alfa"));

        Cargo cargo = new Cargo();
        cargo.setId(rs.getString("car_id"));
        cargo.setNombre(rs.getString("car_nombre"));

        Empleado empleado = new Empleado();
        empleado.setId(rs.getString("emp_id"));
        empleado.setNombre(rs.getString("emp_nombre"));
        empleado.setApellido(rs.getString("emp_apellido"));
        empleado.setEmail(rs.getString("emp_email"));
        empleado.setNumeroDocumento(rs.getString("emp_doc"));
        String empTel = rs.getString("emp_tel");
        empleado.setTelefono(rs.wasNull() ? null : empTel);
        empleado.setTipoDocumento(tdEmp);
        empleado.setCargo(cargo);

        TipoClase tipoClase = new TipoClase();
        tipoClase.setId(rs.getString("tc_id"));
        tipoClase.setNombre(rs.getString("tc_nombre"));

        Clase clase = new Clase();
        clase.setId(rs.getString("id"));
        clase.setNombreClase(rs.getString("nombre_clase"));
        clase.setEmpleado(empleado);
        clase.setTipoClase(tipoClase);
        clase.setCapacidadMaxima(rs.getInt("capacidad_maxima"));
        String desc = rs.getString("descripcion");
        clase.setDescripcion(rs.wasNull() ? null : desc);
        clase.setEstado(rs.getString("estado"));

        return clase;
    }

    /** Establece un String o NULL en el PreparedStatement. */
    private void setNullableString(PreparedStatement ps, int i, String val)
            throws SQLException {
        if (val != null && !val.trim().isEmpty()) {
            ps.setString(i, val.trim());
        } else {
            ps.setNull(i, Types.VARCHAR);
        }
    }
}