package com.mycompany.herramientas.dao;

import com.mycompany.herramientas.config.AppConfig;
import com.mycompany.herramientas.config.DatabaseConnection;
import com.mycompany.herramientas.model.*;

import java.sql.*;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.logging.Logger;

/**
 * DAO para la tabla Inscripcion_Clases (RF-11).
 *
 * Tablas involucradas (JOINs):
 *   Inscripcion_Clases → Clientes → TipoDocumentos
 *                      → Clases   → Empleados + TipoClases
 *
 * Regla de negocio clave (RF-11):
 *   Antes de insertar, el Service verifica:
 *     1. Que la clase no haya superado capacidad_maxima.
 *        Se usa countInscritos(claseId) para eso.
 *     2. Que el cliente no esté ya inscrito.
 *        Se usa existeInscripcion(clienteId, claseId) para eso.
 *
 * La verificación de cupo usa COUNT(*) contra Inscripcion_Clases
 * comparado con capacidad_maxima de la tabla Clases.
 * Para evitar race conditions la lógica transaccional debe hacerse
 * en el Service con beginTransaction() + commit().
 *
 * Formato de ID: INS-AÑO-CORRELATIVO (ej: INS-2026-0001)
 */
public class InscripcionDAO {

    private static final Logger LOGGER = Logger.getLogger(InscripcionDAO.class.getName());

    // ─── SQL ─────────────────────────────────────────────────────────────────

    private static final String SQL_SELECT_BASE =
        "SELECT ic.id, ic.fecha_inscripcion, " +
        // Cliente
        "       cli.id AS cli_id, cli.nombre AS cli_nom, cli.apellido AS cli_ap, " +
        "       cli.numero_documento AS cli_doc, cli.email AS cli_email, " +
        "       cli.telefono AS cli_tel, cli.fecha_nacimiento, cli.genero, " +
        "       tdcli.id AS tdcli_id, tdcli.nombre_documento AS tdcli_nom, " +
        "       tdcli.abreviado AS tdcli_abr, " +
        "       tdcli.tamañoMax AS tdcli_max, tdcli.tamañoMin AS tdcli_min, " +
        "       tdcli.esAlfanumerico AS tdcli_alfa, " +
        // Clase
        "       cl.id AS cl_id, cl.nombre_clase, cl.capacidad_maxima, " +
        "       cl.descripcion AS cl_desc, cl.estado AS cl_estado, " +
        // Empleado (entrenador)
        "       emp.id AS emp_id, emp.nombre AS emp_nom, emp.apellido AS emp_ap, " +
        "       emp.email AS emp_email, " +
        "       car.id AS car_id, car.nombre AS car_nom, " +
        // TipoClase
        "       tc.id AS tc_id, tc.nombre AS tc_nombre " +
        "FROM Inscripcion_Clases ic " +
        "INNER JOIN Clientes cli         ON ic.id_cliente   = cli.id " +
        "INNER JOIN TipoDocumentos tdcli ON cli.id_TipoDocumento = tdcli.id " +
        "INNER JOIN Clases cl            ON ic.id_clase     = cl.id " +
        "INNER JOIN Empleados emp        ON cl.id_empleado  = emp.id " +
        "INNER JOIN Cargos car           ON emp.id_Cargo    = car.id " +
        "INNER JOIN TipoClases tc        ON cl.id_tipoClase = tc.id ";

    private static final String SQL_FIND_ALL =
        SQL_SELECT_BASE + "ORDER BY ic.fecha_inscripcion DESC";

    private static final String SQL_FIND_BY_CLIENTE =
        SQL_SELECT_BASE +
        "WHERE ic.id_cliente = ? ORDER BY ic.fecha_inscripcion DESC";

    private static final String SQL_FIND_BY_CLASE =
        SQL_SELECT_BASE +
        "WHERE ic.id_clase = ? ORDER BY ic.fecha_inscripcion DESC";

    private static final String SQL_FIND_BY_ID =
        SQL_SELECT_BASE + "WHERE ic.id = ?";

    /**
     * Verifica si un cliente ya está inscrito en una clase concreta.
     * Evita inscripciones duplicadas (cliente + clase) antes del INSERT.
     */
    private static final String SQL_EXISTE_INSCRIPCION =
        "SELECT COUNT(*) FROM Inscripcion_Clases " +
        "WHERE id_cliente = ? AND id_clase = ?";

    /**
     * Cuenta cuántos clientes están actualmente inscritos en una clase.
     * Se compara con capacidad_maxima de la tabla Clases en el Service.
     */
    private static final String SQL_COUNT_INSCRITOS =
        "SELECT COUNT(*) FROM Inscripcion_Clases WHERE id_clase = ?";

    /**
     * Obtiene la capacidad máxima de una clase directamente.
     * Se usa junto con countInscritos para verificar cupo disponible.
     */
    private static final String SQL_CAPACIDAD_MAXIMA =
        "SELECT capacidad_maxima FROM Clases WHERE id = ?";

    /**
     * INSERT de nueva inscripción.
     * fecha_inscripcion usa DEFAULT GETDATE() de la BD — no se envía desde Java.
     * Posiciones: 1=id, 2=id_cliente, 3=id_clase
     */
    private static final String SQL_INSERT =
        "INSERT INTO Inscripcion_Clases (id, id_cliente, id_clase) " +
        "VALUES (?, ?, ?)";

    /**
     * DELETE para cancelar una inscripción.
     * Posición: 1=id (PK de la inscripción)
     */
    private static final String SQL_DELETE =
        "DELETE FROM Inscripcion_Clases WHERE id = ?";

    /**
     * DELETE por cliente + clase — útil para desinscribir desde el perfil del cliente.
     * Posiciones: 1=id_cliente, 2=id_clase
     */
    private static final String SQL_DELETE_BY_CLIENTE_CLASE =
        "DELETE FROM Inscripcion_Clases WHERE id_cliente = ? AND id_clase = ?";

    /** Correlativo para IDs con formato INS-AÑO-CORRELATIVO */
    private static final String SQL_NEXT_ID =
        "SELECT ISNULL(MAX(CAST(SUBSTRING(id, CHARINDEX('-', id, 5)+1, 10) AS INT)), 0) + 1 " +
        "FROM Inscripcion_Clases WHERE id LIKE 'INS-%'";

    // ─── Métodos públicos ─────────────────────────────────────────────────────

    /** Todas las inscripciones, ordenadas por fecha descendente. */
    public List<InscripcionClase> findAll() throws SQLException {
        List<InscripcionClase> lista = new ArrayList<>();
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_FIND_ALL);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) lista.add(mapRow(rs));
        }
        return lista;
    }

    /**
     * Todas las inscripciones de un cliente.
     * Usado en el perfil del cliente para ver qué clases tiene asignadas.
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
     * Todos los clientes inscritos en una clase.
     * Usado en la vista de detalle de clase para mostrar la lista de inscritos.
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
     * Busca una inscripción por su ID.
     * Devuelve null si no existe.
     */
    public InscripcionClase findById(String id) throws SQLException {
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_FIND_BY_ID)) {
            ps.setString(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? mapRow(rs) : null;
            }
        }
    }

    /**
     * Verifica si un cliente ya está inscrito en una clase.
     * Llamar ANTES de hacer el INSERT para evitar duplicados.
     *
     * @param clienteId ID del cliente
     * @param claseId   ID de la clase
     * @return true si ya existe la inscripción
     */
    public boolean existeInscripcion(String clienteId, String claseId) throws SQLException {
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_EXISTE_INSCRIPCION)) {
            ps.setString(1, clienteId);
            ps.setString(2, claseId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() && rs.getInt(1) > 0;
            }
        }
    }

    /**
     * Cuenta cuántos clientes están inscritos en una clase.
     * El Service compara este valor con capacidad_maxima antes de inscribir.
     *
     * @param claseId ID de la clase
     * @return número de inscritos actuales
     */
    public int countInscritos(String claseId) throws SQLException {
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_COUNT_INSCRITOS)) {
            ps.setString(1, claseId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getInt(1) : 0;
            }
        }
    }

    /**
     * Obtiene la capacidad máxima de una clase.
     * Usado junto con countInscritos() para verificar cupo disponible
     * sin tener que cargar el objeto Clase completo.
     *
     * @param claseId ID de la clase
     * @return capacidad máxima, o -1 si la clase no existe
     */
    public int getCapacidadMaxima(String claseId) throws SQLException {
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_CAPACIDAD_MAXIMA)) {
            ps.setString(1, claseId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getInt(1) : -1;
            }
        }
    }

    /**
     * Guarda una nueva inscripción en la BD.
     * El ID se genera automáticamente si viene vacío/null.
     * La fecha_inscripcion la pone la BD con DEFAULT GETDATE().
     *
     * IMPORTANTE: el Service debe verificar cupo y duplicados ANTES de llamar save().
     * Este DAO solo realiza el INSERT, no valida reglas de negocio.
     *
     * @param inscripcion objeto con cliente y clase cargados (solo se usan sus IDs)
     */
    public void save(InscripcionClase inscripcion) throws SQLException {
        if (inscripcion.getId() == null || inscripcion.getId().trim().isEmpty()) {
            inscripcion.setId(generarId());
        }
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_INSERT)) {
            ps.setString(1, inscripcion.getId());
            ps.setString(2, inscripcion.getCliente().getId());
            ps.setString(3, inscripcion.getClase().getId());
            ps.executeUpdate();
            LOGGER.info("Inscripción registrada: " + inscripcion.getId()
                    + " | cliente: " + inscripcion.getCliente().getId()
                    + " | clase: " + inscripcion.getClase().getId());
        }
    }

    /**
     * Elimina una inscripción por su ID (PK).
     * Usado cuando el Admin cancela la inscripción de un cliente.
     *
     * @param id ID de la inscripción
     * @return true si se eliminó, false si no existía
     */
    public boolean delete(String id) throws SQLException {
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_DELETE)) {
            ps.setString(1, id);
            boolean ok = ps.executeUpdate() > 0;
            if (ok) LOGGER.info("Inscripción eliminada: " + id);
            return ok;
        }
    }

    /**
     * Elimina la inscripción de un cliente en una clase concreta.
     * Sobrecarga útil cuando no se tiene el ID de la inscripción pero sí
     * el par (clienteId, claseId) — por ejemplo, desde el formulario de la clase.
     *
     * @param clienteId ID del cliente
     * @param claseId   ID de la clase
     * @return true si se eliminó, false si no existía
     */
    public boolean deleteByClienteClase(String clienteId, String claseId) throws SQLException {
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_DELETE_BY_CLIENTE_CLASE)) {
            ps.setString(1, clienteId);
            ps.setString(2, claseId);
            boolean ok = ps.executeUpdate() > 0;
            if (ok) LOGGER.info("Inscripción eliminada: cliente=" + clienteId
                    + " | clase=" + claseId);
            return ok;
        }
    }

    // ─── Privados ─────────────────────────────────────────────────────────────

    /**
     * Genera el ID con formato INS-AÑO-CORRELATIVO.
     * El correlativo se obtiene de la BD para ser thread-safe en Tomcat.
     * Ejemplo: INS-2026-0001
     */
    private String generarId() throws SQLException {
        int anio = LocalDate.now().getYear();
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_NEXT_ID);
             ResultSet rs = ps.executeQuery()) {
            int siguiente = rs.next() ? rs.getInt(1) : 1;
            return String.format("%s-%d-%04d", AppConfig.PREFIX_INSCRIPCION, anio, siguiente);
        }
    }

    /**
     * Mapea una fila del ResultSet a un objeto InscripcionClase completo,
     * con Cliente (+ TipoDocumento) y Clase (+ Empleado + TipoClase) hidratados.
     */
    private InscripcionClase mapRow(ResultSet rs) throws SQLException {
        // TipoDocumento del cliente
        TipoDocumento tdCli = new TipoDocumento();
        tdCli.setId(rs.getString("tdcli_id"));
        tdCli.setNombreDocumento(rs.getString("tdcli_nom"));
        tdCli.setAbreviado(rs.getString("tdcli_abr"));
        tdCli.setTamañoMax(rs.getInt("tdcli_max"));
        tdCli.setTamañoMin(rs.getInt("tdcli_min"));
        tdCli.setEsAlfanumerico(rs.getBoolean("tdcli_alfa"));

        // Cliente
        Cliente cli = new Cliente();
        cli.setId(rs.getString("cli_id"));
        cli.setNombre(rs.getString("cli_nom"));
        cli.setApellido(rs.getString("cli_ap"));
        cli.setNumeroDocumento(rs.getString("cli_doc"));
        cli.setTipoDocumento(tdCli);
        String cliEmail = rs.getString("cli_email");
        cli.setEmail(rs.wasNull() ? null : cliEmail);
        String cliTel = rs.getString("cli_tel");
        cli.setTelefono(rs.wasNull() ? null : cliTel);
        Date fn = rs.getDate("fecha_nacimiento");
        cli.setFechaNacimiento(rs.wasNull() ? null : fn.toLocalDate());
        String genero = rs.getString("genero");
        cli.setGenero(rs.wasNull() ? null : genero);

        // Cargo del entrenador
        Cargo cargo = new Cargo();
        cargo.setId(rs.getString("car_id"));
        cargo.setNombre(rs.getString("car_nom"));

        // Empleado (entrenador de la clase)
        Empleado emp = new Empleado();
        emp.setId(rs.getString("emp_id"));
        emp.setNombre(rs.getString("emp_nom"));
        emp.setApellido(rs.getString("emp_ap"));
        emp.setEmail(rs.getString("emp_email"));
        emp.setCargo(cargo);

        // TipoClase
        TipoClase tipoClase = new TipoClase();
        tipoClase.setId(rs.getString("tc_id"));
        tipoClase.setNombre(rs.getString("tc_nombre"));

        // Clase
        Clase clase = new Clase();
        clase.setId(rs.getString("cl_id"));
        clase.setNombreClase(rs.getString("nombre_clase"));
        clase.setCapacidadMaxima(rs.getInt("capacidad_maxima"));
        String clDesc = rs.getString("cl_desc");
        clase.setDescripcion(rs.wasNull() ? null : clDesc);
        clase.setEstado(rs.getString("cl_estado"));
        clase.setEmpleado(emp);
        clase.setTipoClase(tipoClase);

        // Inscripción
        InscripcionClase ic = new InscripcionClase();
        ic.setId(rs.getString("id"));
        ic.setCliente(cli);
        ic.setClase(clase);
        Timestamp fi = rs.getTimestamp("fecha_inscripcion");
        ic.setFechaInscripcion(fi != null ? fi.toLocalDateTime() : null);

        return ic;
    }
}