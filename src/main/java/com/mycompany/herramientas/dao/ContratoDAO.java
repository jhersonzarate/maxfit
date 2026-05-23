package com.mycompany.herramientas.dao;

import com.mycompany.herramientas.config.AppConfig;
import com.mycompany.herramientas.config.DatabaseConnection;
import com.mycompany.herramientas.model.*;

import java.math.BigDecimal;
import java.sql.*;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.logging.Logger;

/**
 * DAO para la tabla Contratos (RF-03).
 *
 * Nota sobre tipos de datos:
 *   monto_pagado → DECIMAL(10,2) en BD → BigDecimal en Java.
 *   NUNCA usar double para dinero (errores de punto flotante).
 *
 *   fecha_pago → DATETIME DEFAULT GETDATE() → se deja que la BD
 *   la genere automáticamente; no se envía desde Java en el INSERT.
 *
 * Tablas involucradas (JOINs):
 *   Contratos → Clientes → TipoDocumentos
 *             → Membresias
 *             → Empleados → TipoDocumentos + Cargos
 *             → MetodosPago
 *
 * Formato de ID: CON-AÑO-CORRELATIVO (ej: CON-2026-0001)
 */
public class ContratoDAO {

    private static final Logger LOGGER = Logger.getLogger(ContratoDAO.class.getName());

    // ─── SQL ─────────────────────────────────────────────────────────────────

    private static final String SQL_SELECT_BASE =
        "SELECT con.id, con.fecha_inicio, con.fecha_fin, " +
        "       con.monto_pagado, con.fecha_pago, con.estado, " +
        // Cliente
        "       cli.id AS cli_id, cli.nombre AS cli_nom, cli.apellido AS cli_ap, " +
        "       cli.numero_documento AS cli_doc, cli.email AS cli_email, " +
        "       cli.telefono AS cli_tel, cli.fecha_nacimiento, cli.genero, " +
        "       tdcli.id AS tdcli_id, tdcli.abreviado AS tdcli_abr, " +
        "       tdcli.nombre_documento AS tdcli_nom, " +
        "       tdcli.tamañoMax AS tdcli_max, tdcli.tamañoMin AS tdcli_min, " +
        "       tdcli.esAlfanumerico AS tdcli_alfa, " +
        // Membresía
        "       mem.id AS mem_id, mem.nombre_membresia, mem.precio, " +
        "       mem.duracion_meses, mem.descripcion AS mem_desc, " +
        // Empleado responsable
        "       emp.id AS emp_id, emp.nombre AS emp_nom, emp.apellido AS emp_ap, " +
        "       emp.email AS emp_email, " +
        "       cargo.id AS cargo_id, cargo.nombre AS cargo_nom, " +
        // Método de pago
        "       mp.id AS mp_id, mp.nombre_metodo, mp.estado AS mp_estado " +
        "FROM Contratos con " +
        "INNER JOIN Clientes cli         ON con.id_cliente     = cli.id " +
        "INNER JOIN TipoDocumentos tdcli ON cli.id_TipoDocumento = tdcli.id " +
        "INNER JOIN Membresias mem       ON con.id_membresia   = mem.id " +
        "INNER JOIN Empleados emp        ON con.id_empleado    = emp.id " +
        "INNER JOIN Cargos cargo         ON emp.id_Cargo       = cargo.id " +
        "INNER JOIN MetodosPago mp       ON con.id_metodo_pago = mp.id ";

    private static final String SQL_FIND_ALL =
        SQL_SELECT_BASE + "ORDER BY con.fecha_inicio DESC";

    private static final String SQL_FIND_BY_ID =
        SQL_SELECT_BASE + "WHERE con.id = ?";

    private static final String SQL_FIND_BY_CLIENTE =
        SQL_SELECT_BASE + "WHERE con.id_cliente = ? ORDER BY con.fecha_inicio DESC";

    private static final String SQL_FIND_ACTIVE_BY_CLIENTE =
        SQL_SELECT_BASE +
        "WHERE con.id_cliente = ? AND con.estado = 'activo' " +
        "AND con.fecha_inicio <= CAST(GETDATE() AS DATE) " +
        "AND con.fecha_fin    >= CAST(GETDATE() AS DATE)";

    private static final String SQL_FIND_PROXIMOS_VENCER =
        SQL_SELECT_BASE +
        "WHERE con.estado = 'activo' " +
        "AND con.fecha_fin BETWEEN CAST(GETDATE() AS DATE) " +
        "AND DATEADD(day, ?, CAST(GETDATE() AS DATE)) " +
        "ORDER BY con.fecha_fin ASC";

    private static final String SQL_EXISTS =
        "SELECT COUNT(*) FROM Contratos WHERE id = ?";

    private static final String SQL_COUNT_ACTIVOS =
        "SELECT COUNT(*) FROM Contratos WHERE estado = 'activo'";

    private static final String SQL_INGRESOS_MES =
        "SELECT ISNULL(SUM(monto_pagado), 0) FROM Contratos " +
        "WHERE MONTH(fecha_inicio) = MONTH(GETDATE()) " +
        "AND   YEAR(fecha_inicio)  = YEAR(GETDATE())";

    /**
     * INSERT de nuevo contrato.
     * fecha_pago NO se incluye → la BD usa DEFAULT GETDATE().
     * Posiciones: 1=id, 2=id_cliente, 3=id_membresia, 4=id_empleado,
     *             5=id_metodo_pago, 6=fecha_inicio, 7=fecha_fin,
     *             8=monto_pagado, 9=estado
     */
    private static final String SQL_INSERT =
        "INSERT INTO Contratos " +
        "(id, id_cliente, id_membresia, id_empleado, id_metodo_pago, " +
        " fecha_inicio, fecha_fin, monto_pagado, estado) " +
        "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)";

    /** UPDATE de estado únicamente (cancelar/vencer manualmente). */
    private static final String SQL_UPDATE_ESTADO =
        "UPDATE Contratos SET estado = ? WHERE id = ?";

    /** UPDATE masivo: marca como 'vencido' contratos con fecha_fin ya pasada. */
    private static final String SQL_MARCAR_VENCIDOS =
        "UPDATE Contratos SET estado = ? " +
        "WHERE estado = ? AND fecha_fin < ?";

    /** Correlativo para IDs con formato CON-AÑO-CORRELATIVO */
    private static final String SQL_NEXT_ID =
        "SELECT ISNULL(MAX(CAST(SUBSTRING(id, CHARINDEX('-', id, 5)+1, 10) AS INT)), 0) + 1 " +
        "FROM Contratos WHERE id LIKE 'CON-%'";

    // ─── Métodos públicos ─────────────────────────────────────────────────────

    public List<Contrato> findAll() throws SQLException {
        List<Contrato> lista = new ArrayList<>();
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_FIND_ALL);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) lista.add(mapRow(rs));
        }
        return lista;
    }

    public Contrato findById(String id) throws SQLException {
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_FIND_BY_ID)) {
            ps.setString(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? mapRow(rs) : null;
            }
        }
    }

    /** Todos los contratos de un cliente, ordenados por fecha descendente. */
    public List<Contrato> findByClienteId(String clienteId) throws SQLException {
        List<Contrato> lista = new ArrayList<>();
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
     * Busca el contrato activo y vigente de un cliente.
     * Devuelve null si no tiene ninguno.
     * Usado en el check-in (RF-04) y en ContratoService.
     */
    public Contrato findActiveByClienteId(String clienteId) throws SQLException {
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_FIND_ACTIVE_BY_CLIENTE)) {
            ps.setString(1, clienteId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? mapRow(rs) : null;
            }
        }
    }

    /**
     * Contratos activos que vencen en los próximos N días.
     * Usado en el widget "Próximos Vencimientos" del dashboard.
     */
    public List<Contrato> findProximosAVencer(int diasHastaVencer) throws SQLException {
        List<Contrato> lista = new ArrayList<>();
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_FIND_PROXIMOS_VENCER)) {
            ps.setInt(1, diasHastaVencer);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) lista.add(mapRow(rs));
            }
        }
        return lista;
    }

    /** Total de contratos con estado 'activo' (para el dashboard). */
    public int countActivos() throws SQLException {
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_COUNT_ACTIVOS);
             ResultSet rs = ps.executeQuery()) {
            return rs.next() ? rs.getInt(1) : 0;
        }
    }

    /** Suma de monto_pagado de contratos del mes en curso (para Reportes). */
    public BigDecimal getIngresosMesActual() throws SQLException {
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_INGRESOS_MES);
             ResultSet rs = ps.executeQuery()) {
            if (rs.next()) {
                BigDecimal val = rs.getBigDecimal(1);
                return val != null ? val : BigDecimal.ZERO;
            }
        }
        return BigDecimal.ZERO;
    }

    /**
     * Guarda un contrato nuevo.
     * Si el id está vacío/null, se genera automáticamente con formato CON-AÑO-CORRELATIVO.
     * fecha_pago la pone la BD con DEFAULT GETDATE().
     *
     * @param contrato objeto con todos los campos requeridos
     */
    public void save(Contrato contrato) throws SQLException {
        if (contrato.getId() == null || contrato.getId().trim().isEmpty()) {
            contrato.setId(generarId());
        }
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_INSERT)) {
            ps.setString(1, contrato.getId());
            ps.setString(2, contrato.getCliente().getId());
            ps.setString(3, contrato.getMembresia().getId());
            ps.setString(4, contrato.getEmpleado().getId());
            ps.setString(5, contrato.getMetodoPago().getId());
            ps.setDate(6, Date.valueOf(contrato.getFechaInicio()));
            ps.setDate(7, Date.valueOf(contrato.getFechaFin()));
            ps.setBigDecimal(8, contrato.getMontoPagado());
            ps.setString(9, contrato.getEstado());
            ps.executeUpdate();
            LOGGER.info("Contrato insertado: " + contrato.getId()
                    + " | cliente: " + contrato.getCliente().getId());
        }
    }

    /**
     * Cambia el estado de un contrato (cancelar, vencer manualmente).
     *
     * @param id          ID del contrato
     * @param nuevoEstado nuevo estado ('cancelado', 'vencido')
     * @return true si se actualizó al menos una fila
     */
    public boolean updateEstado(String id, String nuevoEstado) throws SQLException {
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_UPDATE_ESTADO)) {
            ps.setString(1, nuevoEstado);
            ps.setString(2, id);
            int filas = ps.executeUpdate();
            if (filas > 0) {
                LOGGER.info("Contrato " + id + " → estado=" + nuevoEstado);
            }
            return filas > 0;
        }
    }

    /**
     * UPDATE masivo: marca como 'vencido' todos los contratos cuya fecha_fin
     * ya pasó y aún tienen estado 'activo'.
     * Llamado desde ContratoService.actualizarVencidos().
     *
     * @param hoy          fecha actual
     * @param estadoActual estado que tienen ahora ('activo')
     * @param estadoNuevo  estado nuevo ('vencido')
     * @return número de filas actualizadas
     */
    public int marcarVencidos(LocalDate hoy, String estadoActual,
                               String estadoNuevo) throws SQLException {
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_MARCAR_VENCIDOS)) {
            ps.setString(1, estadoNuevo);
            ps.setString(2, estadoActual);
            ps.setDate(3, Date.valueOf(hoy));
            int filas = ps.executeUpdate();
            if (filas > 0) {
                LOGGER.info("Contratos marcados como vencidos: " + filas);
            }
            return filas;
        }
    }

    // ─── Privados ─────────────────────────────────────────────────────────────

    /**
     * Genera el ID con formato CON-AÑO-CORRELATIVO.
     * El correlativo se obtiene de la BD para ser thread-safe en Tomcat.
     * Ejemplo: CON-2026-0001
     */
    private String generarId() throws SQLException {
        int anio = LocalDate.now().getYear();
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_NEXT_ID);
             ResultSet rs = ps.executeQuery()) {
            int siguiente = rs.next() ? rs.getInt(1) : 1;
            return String.format("%s-%d-%04d", AppConfig.PREFIX_CONTRATO, anio, siguiente);
        }
    }

    private Contrato mapRow(ResultSet rs) throws SQLException {
        // TipoDocumento del cliente
        TipoDocumento tdCli = new TipoDocumento();
        tdCli.setId(rs.getString("tdcli_id"));
        tdCli.setAbreviado(rs.getString("tdcli_abr"));
        tdCli.setNombreDocumento(rs.getString("tdcli_nom"));
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

        // Membresía
        Membresia mem = new Membresia();
        mem.setId(rs.getString("mem_id"));
        mem.setNombreMembresia(rs.getString("nombre_membresia"));
        mem.setPrecio(rs.getBigDecimal("precio"));
        mem.setDuracionMeses(rs.getInt("duracion_meses"));
        String memDesc = rs.getString("mem_desc");
        mem.setDescripcion(rs.wasNull() ? null : memDesc);

        // Cargo del empleado
        Cargo cargo = new Cargo();
        cargo.setId(rs.getString("cargo_id"));
        cargo.setNombre(rs.getString("cargo_nom"));

        // Empleado responsable
        Empleado emp = new Empleado();
        emp.setId(rs.getString("emp_id"));
        emp.setNombre(rs.getString("emp_nom"));
        emp.setApellido(rs.getString("emp_ap"));
        emp.setEmail(rs.getString("emp_email"));
        emp.setCargo(cargo);

        // Método de pago
        MetodoPago mp = new MetodoPago();
        mp.setId(rs.getString("mp_id"));
        mp.setNombre(rs.getString("nombre_metodo"));
        mp.setEstado(rs.getString("mp_estado"));

        // Contrato
        Contrato c = new Contrato();
        c.setId(rs.getString("id"));
        c.setCliente(cli);
        c.setMembresia(mem);
        c.setEmpleado(emp);
        c.setMetodoPago(mp);
        c.setFechaInicio(rs.getDate("fecha_inicio").toLocalDate());
        c.setFechaFin(rs.getDate("fecha_fin").toLocalDate());
        c.setMontoPagado(rs.getBigDecimal("monto_pagado"));
        Timestamp fp = rs.getTimestamp("fecha_pago");
        c.setFechaPago(fp != null ? fp.toLocalDateTime() : null);
        c.setEstado(rs.getString("estado"));
        return c;
    }
}