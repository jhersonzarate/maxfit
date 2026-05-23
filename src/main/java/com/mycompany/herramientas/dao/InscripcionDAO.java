package com.mycompany.herramientas.dao;

import com.mycompany.herramientas.config.DatabaseConnection;
import com.mycompany.herramientas.model.*;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;
import java.util.logging.Logger;

/**
 * DAO para la tabla Inscripcion_Clases (RF-11).
 *
 * Separado de ClaseDAO porque manejan ciclos de vida distintos:
 *   ClaseDAO  → crea/edita la clase.
 *   HorarioDAO → gestiona sus horarios.
 *   InscripcionDAO → gestiona quién está inscrito en cada clase.
 *
 * Validaciones que hace este DAO antes de insertar:
 *   1. existeInscripcion(clienteId, claseId) → evita duplicados.
 *   2. countByClaseId(claseId) vs clase.capacidadMaxima → verifica cupo.
 *   Ambas las llama el controlador o un InscripcionService antes de save().
 *
 * Columna fecha_inscripcion:
 *   Es DATETIME DEFAULT GETDATE() en la BD.
 *   No se envía desde Java — la BD la genera sola con DEFAULT.
 *
 * Tabla en la BD: Inscripcion_Clases (con guión bajo entre palabras).
 */
public class InscripcionDAO {

    private static final Logger LOGGER = Logger.getLogger(InscripcionDAO.class.getName());

    // ─── SQL ─────────────────────────────────────────────────────────────────

    private static final String SQL_SELECT_BASE =
        "SELECT ins.id, ins.fecha_inscripcion, " +
        // Cliente
        "       cli.id AS cli_id, cli.nombre AS cli_nom, " +
        "       cli.apellido AS cli_ap, " +
        "       cli.numero_documento AS cli_doc, " +
        "       cli.email AS cli_email, " +
        // Clase (solo datos básicos)
        "       cl.id AS cl_id, cl.nombre_clase, " +
        "       cl.capacidad_maxima, cl.estado AS cl_estado " +
        "FROM Inscripcion_Clases ins " +
        "INNER JOIN Clientes cli ON ins.id_cliente = cli.id " +
        "INNER JOIN Clases cl    ON ins.id_clase   = cl.id ";

    /** Todos los inscritos en una clase, ordenados por fecha. */
    private static final String SQL_FIND_BY_CLASE =
        SQL_SELECT_BASE +
        "WHERE ins.id_clase = ? ORDER BY ins.fecha_inscripcion ASC";

    /** Todas las clases en las que está inscrito un cliente. */
    private static final String SQL_FIND_BY_CLIENTE =
        SQL_SELECT_BASE +
        "WHERE ins.id_cliente = ? ORDER BY ins.fecha_inscripcion DESC";

    /** Verifica si un cliente ya está inscrito en una clase específica. */
    private static final String SQL_EXISTE =
        "SELECT COUNT(*) FROM Inscripcion_Clases " +
        "WHERE id_cliente = ? AND id_clase = ?";

    /** Cuenta los inscritos en una clase (para verificar capacidad). */
    private static final String SQL_COUNT_BY_CLASE =
        "SELECT COUNT(*) FROM Inscripcion_Clases WHERE id_clase = ?";

    /**
     * INSERT — fecha_inscripcion se omite porque la BD usa DEFAULT GETDATE().
     */
    private static final String SQL_INSERT =
        "INSERT INTO Inscripcion_Clases (id, id_cliente, id_clase) " +
        "VALUES (?, ?, ?)";

    /** Elimina la inscripción de un cliente en una clase específica. */
    private static final String SQL_DELETE =
        "DELETE FROM Inscripcion_Clases WHERE id_cliente = ? AND id_clase = ?";

    /** Elimina todas las inscripciones de una clase (ej: al cancelarla). */
    private static final String SQL_DELETE_BY_CLASE =
        "DELETE FROM Inscripcion_Clases WHERE id_clase = ?";

    // ─── Métodos públicos ─────────────────────────────────────────────────────

    /**
     * Devuelve todos los clientes inscritos en una clase.
     * Usado en el modal "Ver Inscritos" de schedules.jsp
     * y en el dashboard del Instructor.
     */
    public List<InscripcionClase> findByClaseId(String claseId) throws SQLException {
        List<InscripcionClase> lista = new ArrayList<>();
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_FIND_BY_CLASE)) {
            ps.setString(1, claseId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) lista.add(mapRow(rs));
            }
        }
        return lista;
    }

    /**
     * Devuelve todas las clases en las que un cliente está inscrito.
     * Usado en el perfil del cliente (client-detail.jsp).
     */
    public List<InscripcionClase> findByClienteId(String clienteId) throws SQLException {
        List<InscripcionClase> lista = new ArrayList<>();
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_FIND_BY_CLIENTE)) {
            ps.setString(1, clienteId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) lista.add(mapRow(rs));
            }
        }
        return lista;
    }

    /**
     * Verifica si un cliente ya está inscrito en una clase.
     * Llamar ANTES de save() para evitar duplicados.
     *
     * @param clienteId ID del cliente
     * @param claseId   ID de la clase
     * @return true si ya existe la inscripción
     */
    public boolean existeInscripcion(String clienteId, String claseId) throws SQLException {
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_EXISTE)) {
            ps.setString(1, clienteId);
            ps.setString(2, claseId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() && rs.getInt(1) > 0;
            }
        }
    }

    /**
     * Cuenta el número de clientes inscritos en una clase.
     * Comparar con clase.getCapacidadMaxima() para verificar cupo disponible
     * ANTES de inscribir (RF-11).
     *
     * @param claseId ID de la clase
     * @return número de inscritos actuales
     */
    public int countByClaseId(String claseId) throws SQLException {
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_COUNT_BY_CLASE)) {
            ps.setString(1, claseId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getInt(1);
            }
        }
        return 0;
    }

    /**
     * Registra una nueva inscripción.
     * El ID debe venir generado por IdGenerator.parInscripcion().
     * fecha_inscripcion la genera la BD con DEFAULT GETDATE().
     *
     * PRECONDICIÓN: verificar existeInscripcion() y countByClaseId() antes.
     */
    public void save(InscripcionClase ins) throws SQLException {
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_INSERT)) {
            ps.setString(1, ins.getId());
            ps.setString(2, ins.getCliente().getId());
            ps.setString(3, ins.getClase().getId());
            // fecha_inscripcion omitida → BD usa DEFAULT GETDATE()
            ps.executeUpdate();
            LOGGER.info("Inscripción registrada: " + ins.getId()
                    + " | cliente: " + ins.getCliente().getId()
                    + " | clase: " + ins.getClase().getId());
        }
    }

    /**
     * Elimina la inscripción de un cliente en una clase específica.
     *
     * @param clienteId ID del cliente
     * @param claseId   ID de la clase
     * @return true si se eliminó, false si no existía
     */
    public boolean delete(String clienteId, String claseId) throws SQLException {
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_DELETE)) {
            ps.setString(1, clienteId);
            ps.setString(2, claseId);
            boolean ok = ps.executeUpdate() > 0;
            if (ok) LOGGER.info("Inscripción eliminada | cliente: "
                    + clienteId + " | clase: " + claseId);
            return ok;
        }
    }

    /**
     * Elimina TODAS las inscripciones de una clase.
     * Llamar cuando se cancela o elimina una clase (para respetar la FK).
     *
     * @param claseId ID de la clase
     * @return número de inscripciones eliminadas
     */
    public int deleteByClaseId(String claseId) throws SQLException {
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_DELETE_BY_CLASE)) {
            ps.setString(1, claseId);
            int filas = ps.executeUpdate();
            if (filas > 0) LOGGER.info("Inscripciones eliminadas para clase: "
                    + claseId + " | total: " + filas);
            return filas;
        }
    }

    // ─── Privados ─────────────────────────────────────────────────────────────

    private InscripcionClase mapRow(ResultSet rs) throws SQLException {
        // Cliente (datos mínimos para mostrar en la tabla de inscritos)
        Cliente cli = new Cliente();
        cli.setId(rs.getString("cli_id"));
        cli.setNombre(rs.getString("cli_nom"));
        cli.setApellido(rs.getString("cli_ap"));
        cli.setNumeroDocumento(rs.getString("cli_doc"));
        String cliEmail = rs.getString("cli_email");
        cli.setEmail(rs.wasNull() ? null : cliEmail);

        // Clase (datos mínimos — id, nombre, capacidad, estado)
        Clase cl = new Clase();
        cl.setId(rs.getString("cl_id"));
        cl.setNombreClase(rs.getString("nombre_clase"));
        cl.setCapacidadMaxima(rs.getInt("capacidad_maxima"));
        cl.setEstado(rs.getString("cl_estado"));

        // Inscripción
        InscripcionClase ins = new InscripcionClase();
        ins.setId(rs.getString("id"));
        ins.setCliente(cli);
        ins.setClase(cl);
        // fecha_inscripcion es DATETIME en BD → Timestamp → LocalDateTime
        Timestamp fi = rs.getTimestamp("fecha_inscripcion");
        ins.setFechaInscripcion(fi != null ? fi.toLocalDateTime() : null);
        return ins;
    }
}