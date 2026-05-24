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
 *
 * ← CORRECCIÓN transacciones:
 *   Se añadieron overloads que reciben Connection como primer parámetro:
 *     - countInscritos(Connection, claseId)
 *     - save(Connection, InscripcionClase)
 *   Estos métodos NO cierran la Connection, solo el PreparedStatement.
 *   Son los que InscripcionService usa cuando hay una transacción activa
 *   para garantizar que el count y el insert ocurran atómicamente,
 *   previniendo race conditions en la validación de cupo (RF-11).
 *
 * @author MaxFit
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

    private static final String SQL_COUNT_INSCRITOS =
        "SELECT COUNT(*) FROM Inscripcion_Clases WHERE id_clase = ?";

    private static final String SQL_GET_CAPACIDAD =
        "SELECT capacidad_maxima FROM Clases WHERE id = ?";

    private static final String SQL_INSERT =
        "INSERT INTO Inscripcion_Clases (id, id_cliente, id_clase) " +
        "VALUES (?, ?, ?)";

    private static final String SQL_DELETE_BY_CLIENTE_CLASE =
        "DELETE FROM Inscripcion_Clases WHERE id_cliente = ? AND id_clase = ?";

    private static final String SQL_DELETE_BY_ID =
        "DELETE FROM Inscripcion_Clases WHERE id = ?";

    private static final String SQL_DELETE_BY_CLASE =
        "DELETE FROM Inscripcion_Clases WHERE id_clase = ?";

    // ─── Métodos públicos ─────────────────────────────────────────────────────

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
     * Cuenta inscritos usando su propia Connection (uso simple, sin transacción).
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
     * ← CORRECCIÓN transacciones: overload que usa la Connection proporcionada.
     * No cierra la Connection — solo cierra PreparedStatement y ResultSet.
     * InscripcionService lo llama dentro de beginTransaction() para que el count
     * y el INSERT posterior sean atómicos, evitando race conditions de cupo.
     *
     * @param con     Connection con transacción ya activa
     * @param claseId ID de la clase a contar
     */
    public int countInscritos(Connection con, String claseId) throws SQLException {
        try (PreparedStatement ps = con.prepareStatement(SQL_COUNT_INSCRITOS)) {
            ps.setString(1, claseId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getInt(1);
            }
        }
        return 0;
    }

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
     * Registra una nueva inscripción (versión sin transacción del Service).
     * Abre su propia Connection con try-with-resources.
     * NO usar cuando hay una transacción activa; usar save(Connection, inscripcion).
     */
    public void save(InscripcionClase ins) throws SQLException {
        if (ins.getId() == null || ins.getId().trim().isEmpty()) {
            ins.setId(IdGenerator.parInscripcion());
        }
        try (Connection con = DatabaseConnection.getConnection()) {
            doInsert(con, ins);
        }
    }

    /**
     * ← CORRECCIÓN transacciones: registra la inscripción DENTRO de una transacción activa.
     * Recibe la Connection del Service y NO la cierra.
     * Solo el PreparedStatement se cierra con try-with-resources.
     *
     * @param con Connection con transacción ya iniciada
     * @param ins objeto InscripcionClase a persistir
     */
    public void save(Connection con, InscripcionClase ins) throws SQLException {
        if (ins.getId() == null || ins.getId().trim().isEmpty()) {
            ins.setId(IdGenerator.parInscripcion());
        }
        doInsert(con, ins);
    }

    public boolean delete(String inscripcionId) throws SQLException {
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_DELETE_BY_ID)) {
            ps.setString(1, inscripcionId);
            boolean ok = ps.executeUpdate() > 0;
            if (ok) LOGGER.info("Inscripción eliminada por ID: " + inscripcionId);
            return ok;
        }
    }

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

    /**
     * Ejecuta el INSERT sobre la Connection proporcionada.
     * Solo cierra el PreparedStatement; la Connection la gestiona el llamador.
     */
    private void doInsert(Connection con, InscripcionClase ins) throws SQLException {
        try (PreparedStatement ps = con.prepareStatement(SQL_INSERT)) {
            ps.setString(1, ins.getId());
            ps.setString(2, ins.getCliente().getId());
            ps.setString(3, ins.getClase().getId());
            ps.executeUpdate();
            LOGGER.info("Inscripción registrada: " + ins.getId()
                    + " | cliente: " + ins.getCliente().getId()
                    + " | clase: " + ins.getClase().getId());
        }
    }

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