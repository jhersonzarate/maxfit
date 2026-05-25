package com.mycompany.herramientas.dao;

import com.mycompany.herramientas.config.DatabaseConnection;
import com.mycompany.herramientas.model.*;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;
import java.util.logging.Logger;

// DAO del módulo de inscripción a clases
public class InscripcionDAO {

    private static final Logger LOGGER =
            Logger.getLogger(InscripcionDAO.class.getName());

    // ─── SQL ───────────────────────────────────────────────────

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

    // obtener inscritos de una clase
    private static final String SQL_FIND_BY_CLASE =
        SQL_SELECT_BASE +
        "WHERE ins.id_clase = ? ORDER BY ins.fecha_inscripcion ASC";

    // obtener clases inscritas de un cliente
    private static final String SQL_FIND_BY_CLIENTE =
        SQL_SELECT_BASE +
        "WHERE ins.id_cliente = ? ORDER BY ins.fecha_inscripcion DESC";

    // validar si ya existe inscripción
    private static final String SQL_EXISTE =
        "SELECT COUNT(*) FROM Inscripcion_Clases " +
        "WHERE id_cliente = ? AND id_clase = ?";

    // contar inscritos de una clase
    private static final String SQL_COUNT_INSCRITOS =
        "SELECT COUNT(*) FROM Inscripcion_Clases WHERE id_clase = ?";

    // obtener capacidad máxima de clase
    private static final String SQL_GET_CAPACIDAD =
        "SELECT capacidad_maxima FROM Clases WHERE id = ?";

    // registrar inscripción
    private static final String SQL_INSERT =
        "INSERT INTO Inscripcion_Clases (id, id_cliente, id_clase) " +
        "VALUES (?, ?, ?)";

    // eliminar inscripción por cliente y clase
    private static final String SQL_DELETE_BY_CLIENTE_CLASE =
        "DELETE FROM Inscripcion_Clases WHERE id_cliente = ? AND id_clase = ?";

    // eliminar inscripción por ID
    private static final String SQL_DELETE_BY_ID =
        "DELETE FROM Inscripcion_Clases WHERE id = ?";

    // eliminar todas las inscripciones de una clase
    private static final String SQL_DELETE_BY_CLASE =
        "DELETE FROM Inscripcion_Clases WHERE id_clase = ?";

    // ─── métodos públicos ──────────────────────────────────────

    // listar inscritos de una clase
    public List<InscripcionClase> findByClaseId(String claseId)
            throws SQLException {

        List<InscripcionClase> lista = new ArrayList<>();

        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_FIND_BY_CLASE)) {

            ps.setString(1, claseId);

            try (ResultSet rs = ps.executeQuery()) {

                while (rs.next()) {
                    lista.add(mapRow(rs));
                }
            }
        }

        return lista;
    }

    // listar clases inscritas de un cliente
    public List<InscripcionClase> findByClienteId(String clienteId)
            throws SQLException {

        List<InscripcionClase> lista = new ArrayList<>();

        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_FIND_BY_CLIENTE)) {

            ps.setString(1, clienteId);

            try (ResultSet rs = ps.executeQuery()) {

                while (rs.next()) {
                    lista.add(mapRow(rs));
                }
            }
        }

        return lista;
    }

    // validar si el cliente ya está inscrito
    public boolean existeInscripcion(String clienteId, String claseId)
            throws SQLException {

        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_EXISTE)) {

            ps.setString(1, clienteId);
            ps.setString(2, claseId);

            try (ResultSet rs = ps.executeQuery()) {

                return rs.next() && rs.getInt(1) > 0;
            }
        }
    }

    // contar inscritos usando conexión propia
    public int countInscritos(String claseId) throws SQLException {

        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_COUNT_INSCRITOS)) {

            ps.setString(1, claseId);

            try (ResultSet rs = ps.executeQuery()) {

                if (rs.next()) {
                    return rs.getInt(1);
                }
            }
        }

        return 0;
    }

    // contar inscritos usando transacción activa
    public int countInscritos(Connection con, String claseId)
            throws SQLException {

        try (PreparedStatement ps =
                     con.prepareStatement(SQL_COUNT_INSCRITOS)) {

            ps.setString(1, claseId);

            try (ResultSet rs = ps.executeQuery()) {

                if (rs.next()) {
                    return rs.getInt(1);
                }
            }
        }

        return 0;
    }

    // obtener capacidad máxima de clase
    public int getCapacidadMaxima(String claseId) throws SQLException {

        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_GET_CAPACIDAD)) {

            ps.setString(1, claseId);

            try (ResultSet rs = ps.executeQuery()) {

                if (rs.next()) {
                    return rs.getInt("capacidad_maxima");
                }
            }
        }

        return 0;
    }

    // guardar inscripción usando conexión propia
    public void save(InscripcionClase ins) throws SQLException {

        // generar ID si no existe
        if (ins.getId() == null || ins.getId().trim().isEmpty()) {
            ins.setId(IdGenerator.parInscripcion());
        }

        try (Connection con = DatabaseConnection.getConnection()) {
            doInsert(con, ins);
        }
    }

    // guardar inscripción dentro de una transacción
    public void save(Connection con, InscripcionClase ins)
            throws SQLException {

        // generar ID si no existe
        if (ins.getId() == null || ins.getId().trim().isEmpty()) {
            ins.setId(IdGenerator.parInscripcion());
        }

        doInsert(con, ins);
    }

    // eliminar inscripción por ID
    public boolean delete(String inscripcionId) throws SQLException {

        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_DELETE_BY_ID)) {

            ps.setString(1, inscripcionId);

            boolean ok = ps.executeUpdate() > 0;

            if (ok) {

                LOGGER.info(
                        "Inscripción eliminada por ID: "
                                + inscripcionId
                );
            }

            return ok;
        }
    }

    // eliminar inscripción por cliente y clase
    public boolean delete(String clienteId, String claseId)
            throws SQLException {

        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps =
                     con.prepareStatement(SQL_DELETE_BY_CLIENTE_CLASE)) {

            ps.setString(1, clienteId);
            ps.setString(2, claseId);

            boolean ok = ps.executeUpdate() > 0;

            if (ok) {

                LOGGER.info(
                        "Inscripción eliminada | cliente: "
                                + clienteId
                                + " | clase: "
                                + claseId
                );
            }

            return ok;
        }
    }

    // eliminar todas las inscripciones de una clase
    public int deleteByClaseId(String claseId) throws SQLException {

        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps =
                     con.prepareStatement(SQL_DELETE_BY_CLASE)) {

            ps.setString(1, claseId);

            int filas = ps.executeUpdate();

            if (filas > 0) {

                LOGGER.info(
                        "Inscripciones eliminadas para clase: "
                                + claseId
                                + " | total: "
                                + filas
                );
            }

            return filas;
        }
    }

    // ─── métodos privados ──────────────────────────────────────

    // ejecutar INSERT de inscripción
    private void doInsert(Connection con, InscripcionClase ins)
            throws SQLException {

        try (PreparedStatement ps = con.prepareStatement(SQL_INSERT)) {

            ps.setString(1, ins.getId());
            ps.setString(2, ins.getCliente().getId());
            ps.setString(3, ins.getClase().getId());

            ps.executeUpdate();

            LOGGER.info(
                    "Inscripción registrada: "
                            + ins.getId()
                            + " | cliente: "
                            + ins.getCliente().getId()
                            + " | clase: "
                            + ins.getClase().getId()
            );
        }
    }

    // mapear fila SQL a objeto InscripcionClase
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

        ins.setFechaInscripcion(
                fi != null
                        ? fi.toLocalDateTime()
                        : null
        );

        return ins;
    }
}