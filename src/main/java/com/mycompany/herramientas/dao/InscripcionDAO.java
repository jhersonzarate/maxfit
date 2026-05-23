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
 * Separado de ClaseDAO porque manejan ciclos de vida distintos.
 *
 * Columna fecha_inscripcion:
 *   DATETIME DEFAULT GETDATE() en BD — no se envía desde Java.
 *
 * Tabla en la BD: Inscripcion_Clases (con guión bajo entre palabras).
 */
public class InscripcionDAO {

    private static final Logger LOGGER = Logger.getLogger(InscripcionDAO.class.getName());

    // ─── SQL ─────────────────────────────────────────────────────────────────

    private static final String SQL_SELECT_BASE =
        "SELECT ins.id, ins.fecha_inscripcion, " +
        "       cli.id AS cli_id, cli.nombre AS cli_nom, " +
        "       cli.apellido AS cli_ap, " +
        "       cli.numero_documento AS cli_doc, " +
        "       cli.email AS cli_email, " +
        "       cl.id AS cl_id, cl.nombre_clase, " +
        "       cl.capacidad_maxima, cl.estado AS cl_estado " +
        "FROM Inscripcion_Clases ins " +
        "INNER JOIN Clientes cli ON ins.id_cliente = cli.id " +
        "INNER JOIN Clases cl    ON ins.id_clase   = cl.id ";

    private static final String SQL_FIND_BY_CLASE =
        SQL_SELECT_BASE +
        "WHERE ins.id_clase = ? ORDER BY ins.fecha_inscripcion ASC";

    private static final String SQL_FIND_BY_CLIENTE =
        SQL_SELECT_BASE +
        "WHERE ins.id_cliente = ? ORDER BY ins.fecha_inscripcion DESC";

    private static final String SQL_EXISTE =
        "SELECT COUNT(*) FROM Inscripcion_Clases " +
        "WHERE id_cliente = ? AND id_clase = ?";

    /**
     * Cuenta inscritos en una clase — usado por InscripcionService
     * para verificar cupo antes de inscribir (RF-11).
     * Nombre usado en InscripcionService: countInscritos(claseId)
     */
    private static final String SQL_COUNT_INSCRITOS =
        "SELECT COUNT(*) FROM Inscripcion_Clases WHERE id_clase = ?";

    /**
     * Obtiene la capacidad máxima de una clase.
     * Usado por InscripcionService.cuposInfo() para mostrar "X / Y cupos".
     */
    private static final String SQL_GET_CAPACIDAD =
        "SELECT capacidad_maxima FROM Clases WHERE id = ?";

    /**
     * INSERT por ID de cliente + clase.
     * fecha_inscripcion → BD usa DEFAULT GETDATE()
     */
    private static final String SQL_INSERT =
        "INSERT INTO Inscripcion_Clases (id, id_cliente, id_clase) " +
        "VALUES (?, ?, ?)";

    /** Elimina por (clienteId, claseId) — para cancelar inscripción desde vista */
    private static final String SQL_DELETE_BY_CLIENTE_CLASE =
        "DELETE FROM Inscripcion_Clases WHERE id_cliente = ? AND id_clase = ?";

    /** Elimina por PK (id) — usado desde InscripcionService.cancelar(inscripcionId) */
    private static final String SQL_DELETE_BY_ID =
        "DELETE FROM Inscripcion_Clases WHERE id = ?";

    /** Elimina todas las inscripciones de una clase (al cancelarla). */
    private static final String SQL_DELETE_BY_CLASE =
        "DELETE FROM Inscripcion_Clases WHERE id_clase = ?";

    // ─── Métodos públicos ─────────────────────────────────────────────────────

    /**
     * Todos los inscritos en una clase.
     * Usado en el modal "Ver Inscritos" y en el dashboard del Instructor.
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
     * Todas las clases en las que un cliente está inscrito.
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
     * Cuenta los inscritos actuales en una clase.
     * Nombre requerido por InscripcionService: countInscritos(claseId).
     * Comparar con getCapacidadMaxima() para verificar cupo (RF-11).
     */
    public int countInscritos(String claseId) throws SQLException {
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_COUNT_INSCRITOS)) {
            ps.setString(1, claseId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getInt(1);
            }
        }
        return 0;
    }

    /**
     * Obtiene la capacidad máxima de una clase directamente de la BD.
     * Nombre requerido por InscripcionService: getCapacidadMaxima(claseId).
     * Devuelve 0 si la clase no existe.
     */
    public int getCapacidadMaxima(String claseId) throws SQLException {
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_GET_CAPACIDAD)) {
            ps.setString(1, claseId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getInt("capacidad_maxima");
            }
        }
        return 0;
    }

    /**
     * Registra una nueva inscripción.
     * El ID debe venir generado por IdGenerator.parInscripcion().
     * fecha_inscripcion la genera la BD con DEFAULT GETDATE().
     */
    public void save(InscripcionClase ins) throws SQLException {
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_INSERT)) {
            ps.setString(1, ins.getId());
            ps.setString(2, ins.getCliente().getId());
            ps.setString(3, ins.getClase().getId());
            ps.executeUpdate();
            LOGGER.info("Inscripción registrada: " + ins.getId()
                    + " | cliente: " + ins.getCliente().getId()
                    + " | clase: " + ins.getClase().getId());
        }
    }

    /**
     * Elimina por PK (id de la inscripción).
     * Nombre requerido por InscripcionService.cancelar(inscripcionId).
     * @return true si se eliminó, false si no existía
     */
    public boolean delete(String inscripcionId) throws SQLException {
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_DELETE_BY_ID)) {
            ps.setString(1, inscripcionId);
            boolean ok = ps.executeUpdate() > 0;
            if (ok) LOGGER.info("Inscripción eliminada por ID: " + inscripcionId);
            return ok;
        }
    }

    /**
     * Elimina por par (clienteId, claseId).
     * Para cancelar inscripción desde la vista de clases.
     */
    public boolean delete(String clienteId, String claseId) throws SQLException {
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_DELETE_BY_CLIENTE_CLASE)) {
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
        Cliente cli = new Cliente();
        cli.setId(rs.getString("cli_id"));
        cli.setNombre(rs.getString("cli_nom"));
        cli.setApellido(rs.getString("cli_ap"));
        cli.setNumeroDocumento(rs.getString("cli_doc"));
        String cliEmail = rs.getString("cli_email");
        cli.setEmail(rs.wasNull() ? null : cliEmail);

        Clase cl = new Clase();
        cl.setId(rs.getString("cl_id"));
        cl.setNombreClase(rs.getString("nombre_clase"));
        cl.setCapacidadMaxima(rs.getInt("capacidad_maxima"));
        cl.setEstado(rs.getString("cl_estado"));

        InscripcionClase ins = new InscripcionClase();
        ins.setId(rs.getString("id"));
        ins.setCliente(cli);
        ins.setClase(cl);
        Timestamp fi = rs.getTimestamp("fecha_inscripcion");
        ins.setFechaInscripcion(fi != null ? fi.toLocalDateTime() : null);
        return ins;
    }
}