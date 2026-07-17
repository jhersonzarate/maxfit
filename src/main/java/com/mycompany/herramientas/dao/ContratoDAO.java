package com.mycompany.herramientas.dao;

import com.mycompany.herramientas.config.DatabaseConnection;
import com.mycompany.herramientas.model.*;

import java.math.BigDecimal;
import java.sql.*;
import java.time.LocalDate;
import java.time.YearMonth;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.logging.Logger;

// DAO para la tabla Contratos (RF-03)
// monto_pagado → DECIMAL(10,2) en BD → BigDecimal en Java (nunca double para dinero)
// fecha_pago no se envía desde Java — la BD la genera con DEFAULT GETDATE()
public class ContratoDAO {

    private static final Logger LOGGER = Logger.getLogger(ContratoDAO.class.getName());

    // ─── SQL ───────────────────────────────────────────────────

    private static final String SQL_SELECT_BASE =
        "SELECT con.id, con.fecha_inicio, con.fecha_fin, " +
        "       con.monto_pagado, con.fecha_pago, con.estado, " +
        // cliente
        "       cli.id AS cli_id, cli.nombre AS cli_nom, cli.apellido AS cli_ap, " +
        "       cli.numero_documento AS cli_doc, cli.email AS cli_email, " +
        "       cli.telefono AS cli_tel, cli.fecha_nacimiento, cli.genero, " +
        "       tdcli.id AS tdcli_id, tdcli.abreviado AS tdcli_abr, " +
        "       tdcli.nombre_documento AS tdcli_nom, " +
        "       tdcli.tamañoMax AS tdcli_max, tdcli.tamañoMin AS tdcli_min, " +
        "       tdcli.esAlfanumerico AS tdcli_alfa, " +
        // membresía
        "       mem.id AS mem_id, mem.nombre_membresia, mem.precio, " +
        "       mem.duracion_meses, mem.descripcion AS mem_desc, " +
        // empleado responsable
        "       emp.id AS emp_id, emp.nombre AS emp_nom, emp.apellido AS emp_ap, " +
        "       emp.email AS emp_email, " +
        "       cargo.id AS cargo_id, cargo.nombre AS cargo_nom, " +
        // método de pago
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

    // todos los contratos activos sin límite de fecha — reemplaza el hack de findProximosAVencer(36500)
    private static final String SQL_FIND_ALL_ACTIVOS =
        SQL_SELECT_BASE +
        "WHERE con.estado = 'activo' ORDER BY con.fecha_fin ASC";

    private static final String SQL_COUNT_ACTIVOS =
        "SELECT COUNT(*) FROM Contratos WHERE estado = 'activo'";

    private static final String SQL_COUNT_BY_ESTADO =
        "SELECT COUNT(*) FROM Contratos WHERE estado = ?";

    private static final String SQL_INGRESOS_MES =
        "SELECT ISNULL(SUM(monto_pagado), 0) FROM Contratos " +
        "WHERE MONTH(fecha_inicio) = MONTH(GETDATE()) " +
        "AND   YEAR(fecha_inicio)  = YEAR(GETDATE())";

    // fecha_pago no se incluye → la BD usa DEFAULT GETDATE()
    private static final String SQL_INSERT =
        "INSERT INTO Contratos " +
        "(id, id_cliente, id_membresia, id_empleado, id_metodo_pago, " +
        " fecha_inicio, fecha_fin, monto_pagado, estado) " +
        "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)";

    private static final String SQL_UPDATE_ESTADO =
        "UPDATE Contratos SET estado = ? WHERE id = ?";

    private static final String SQL_MARCAR_VENCIDOS =
        "UPDATE Contratos SET estado = ? " +
        "WHERE estado = ? AND fecha_fin < ?";

    // ingresos agrupados por año/mes desde una fecha de corte — para el gráfico de tendencia
    private static final String SQL_INGRESOS_POR_MES =
        "SELECT YEAR(fecha_inicio) AS anio, MONTH(fecha_inicio) AS mes, " +
        "       SUM(monto_pagado) AS total " +
        "FROM Contratos " +
        "WHERE fecha_inicio >= ? " +
        "GROUP BY YEAR(fecha_inicio), MONTH(fecha_inicio)";

    // agregados por rango de fechas — usados por el filtro de periodo (mensual/anual)
    private static final String SQL_INGRESOS_RANGO =
        "SELECT ISNULL(SUM(monto_pagado), 0) FROM Contratos " +
        "WHERE fecha_inicio BETWEEN ? AND ?";

    private static final String SQL_COUNT_NUEVOS_RANGO =
        "SELECT COUNT(*) FROM Contratos WHERE fecha_inicio BETWEEN ? AND ?";

    private static final String SQL_COUNT_VENCIDOS_RANGO =
        "SELECT COUNT(*) FROM Contratos WHERE estado = 'vencido' AND fecha_fin BETWEEN ? AND ?";

    // ─── métodos públicos ──────────────────────────────────────

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
                if (rs.next()) return mapRow(rs);
            }
        }
        return null;
    }

    // todos los contratos de un cliente ordenados por fecha desc
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

    // contrato activo y vigente de un cliente — usado en check-in (RF-04) y ContratoService
    // devuelve null si no tiene ninguno
    public Contrato findActiveByClienteId(String clienteId) throws SQLException {
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_FIND_ACTIVE_BY_CLIENTE)) {
            ps.setString(1, clienteId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapRow(rs);
            }
        }
        return null;
    }

    // contratos activos que vencen en los próximos N días — para el widget del dashboard
    // para obtener TODOS los activos sin límite usar findAllActivos()
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

    // todos los contratos activos sin límite de fecha, ordenados por fecha_fin asc
    // alternativa limpia al antiguo findProximosAVencer(36500)
    public List<Contrato> findAllActivos() throws SQLException {
        List<Contrato> lista = new ArrayList<>();
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_FIND_ALL_ACTIVOS);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) lista.add(mapRow(rs));
        }
        return lista;
    }

    // contratos filtrados por estado (activo/vencido/cancelado), más recientes
    // primero por fecha_fin — usado en el PDF de reportes (listado de vencidos)
    public List<Contrato> findByEstado(String estado) throws SQLException {
        List<Contrato> lista = new ArrayList<>();
        String sql = SQL_SELECT_BASE + "WHERE con.estado = ? ORDER BY con.fecha_fin DESC";
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, estado);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) lista.add(mapRow(rs));
            }
        }
        return lista;
    }

    // total de contratos activos para el dashboard
    public int countActivos() throws SQLException {
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_COUNT_ACTIVOS);
             ResultSet rs = ps.executeQuery()) {
            if (rs.next()) return rs.getInt(1);
        }
        return 0;
    }

    // cuenta contratos por estado — para el desglose del reporte sin cargar todo en memoria
    // estado: usar constantes AppConfig.CONTRATO_*
    public int countByEstado(String estado) throws SQLException {
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_COUNT_BY_ESTADO)) {
            ps.setString(1, estado);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getInt(1);
            }
        }
        return 0;
    }

    // suma de monto_pagado del mes en curso para el reporte de ingresos
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

    // guarda un contrato nuevo sin transacción — el ID debe venir de IdGenerator
    public void save(Contrato contrato) throws SQLException {
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
            LOGGER.info("Contrato insertado: " + contrato.getId());
        }
    }

    // guarda un contrato dentro de una transacción activa — no cierra la Connection
    public void save(Connection con, Contrato contrato) throws SQLException {
        try (PreparedStatement ps = con.prepareStatement(SQL_INSERT)) {
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
            LOGGER.info("Contrato insertado: " + contrato.getId());
        }
    }

    // cambia el estado de un contrato (cancelar, vencer manualmente)
    // devuelve true si se actualizó al menos una fila
    public boolean cancelar(String id, String nuevoEstado) throws SQLException {
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_UPDATE_ESTADO)) {
            ps.setString(1, nuevoEstado);
            ps.setString(2, id);
            return ps.executeUpdate() > 0;
        }
    }

    // UPDATE masivo: marca como 'vencido' los contratos con fecha_fin pasada y estado 'activo'
    // llamado desde ContratoService.actualizarVencidos()
    // devuelve el número de filas actualizadas
    public int marcarVencidos(LocalDate hoy, String estadoActual,
                               String estadoNuevo) throws SQLException {
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_MARCAR_VENCIDOS)) {
            ps.setString(1, estadoNuevo);
            ps.setString(2, estadoActual);
            ps.setDate(3, Date.valueOf(hoy));
            return ps.executeUpdate();
        }
    }

    // ingresos de los últimos N meses (incluye el mes actual), en orden cronológico.
    // rellena con BigDecimal.ZERO los meses sin contratos registrados — usado en
    // el gráfico de tendencia del reporte de Contratos cuando NO hay periodo elegido.
    public LinkedHashMap<String, BigDecimal> getIngresosUltimosMeses(int meses) throws SQLException {
        LocalDate hoy = LocalDate.now();
        LocalDate desde = hoy.withDayOfMonth(1).minusMonths(meses - 1L);
        return getIngresosPorMesesEnRango(desde, hoy);
    }

    // versión generalizada: ingresos mes a mes entre dos fechas cualquiera (inclusive),
    // rellenando con cero los meses sin contratos. Usada para el filtro de periodo:
    // "mensual" pide un rango de 6 meses terminando en el mes elegido; "anual" pide
    // los 12 meses del año elegido.
    public LinkedHashMap<String, BigDecimal> getIngresosPorMesesEnRango(LocalDate desde,
                                                                          LocalDate hasta) throws SQLException {

        YearMonth ymDesde = YearMonth.from(desde);
        YearMonth ymHasta = YearMonth.from(hasta);

        Map<YearMonth, BigDecimal> totalesPorMes = new HashMap<>();

        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_INGRESOS_POR_MES)) {

            ps.setDate(1, Date.valueOf(ymDesde.atDay(1)));

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    YearMonth ym = YearMonth.of(rs.getInt("anio"), rs.getInt("mes"));
                    totalesPorMes.put(ym, rs.getBigDecimal("total"));
                }
            }
        }

        LinkedHashMap<String, BigDecimal> resultado = new LinkedHashMap<>();
        DateTimeFormatter etiquetaMes = DateTimeFormatter.ofPattern("MMM", new Locale("es", "PE"));

        for (YearMonth ym = ymDesde; !ym.isAfter(ymHasta); ym = ym.plusMonths(1)) {
            String etiqueta = capitalizar(ym.atDay(1).format(etiquetaMes));
            BigDecimal total = totalesPorMes.getOrDefault(ym, BigDecimal.ZERO);
            resultado.put(etiqueta, total);
        }

        return resultado;
    }

    // suma de monto_pagado (por fecha_inicio) dentro de un rango — usado por el filtro de periodo
    public BigDecimal getIngresosPorRango(LocalDate desde, LocalDate hasta) throws SQLException {
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_INGRESOS_RANGO)) {
            ps.setDate(1, Date.valueOf(desde));
            ps.setDate(2, Date.valueOf(hasta));
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    BigDecimal val = rs.getBigDecimal(1);
                    return val != null ? val : BigDecimal.ZERO;
                }
            }
        }
        return BigDecimal.ZERO;
    }

    // contratos nuevos (fecha_inicio) dentro de un rango — usado por el filtro de periodo
    public int countNuevosPorRango(LocalDate desde, LocalDate hasta) throws SQLException {
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_COUNT_NUEVOS_RANGO)) {
            ps.setDate(1, Date.valueOf(desde));
            ps.setDate(2, Date.valueOf(hasta));
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getInt(1);
            }
        }
        return 0;
    }

    // contratos que vencieron (fecha_fin, estado actual = vencido) dentro de un rango.
    // aproximación: refleja el estado ACTUAL, no hay historial de estados en el esquema
    // (un contrato reactivado o cancelado después de vencer no se contaría aquí).
    public int countVencidosPorRango(LocalDate desde, LocalDate hasta) throws SQLException {
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_COUNT_VENCIDOS_RANGO)) {
            ps.setDate(1, Date.valueOf(desde));
            ps.setDate(2, Date.valueOf(hasta));
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getInt(1);
            }
        }
        return 0;
    }

    private String capitalizar(String texto) {
        if (texto == null || texto.isEmpty()) return texto;
        String limpio = texto.replace(".", "");
        return Character.toUpperCase(limpio.charAt(0)) + limpio.substring(1);
    }

    // ─── privados ──────────────────────────────────────────────

    private Contrato mapRow(ResultSet rs) throws SQLException {
        // tipo de documento del cliente
        TipoDocumento tdCli = new TipoDocumento();
        tdCli.setId(rs.getString("tdcli_id"));
        tdCli.setAbreviado(rs.getString("tdcli_abr"));
        tdCli.setNombreDocumento(rs.getString("tdcli_nom"));
        tdCli.setTamañoMax(rs.getInt("tdcli_max"));
        tdCli.setTamañoMin(rs.getInt("tdcli_min"));
        tdCli.setEsAlfanumerico(rs.getBoolean("tdcli_alfa"));

        // cliente
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

        // membresía
        Membresia mem = new Membresia();
        mem.setId(rs.getString("mem_id"));
        mem.setNombreMembresia(rs.getString("nombre_membresia"));
        mem.setPrecio(rs.getBigDecimal("precio"));
        mem.setDuracionMeses(rs.getInt("duracion_meses"));
        String memDesc = rs.getString("mem_desc");
        mem.setDescripcion(rs.wasNull() ? null : memDesc);

        // cargo del empleado
        Cargo cargo = new Cargo();
        cargo.setId(rs.getString("cargo_id"));
        cargo.setNombre(rs.getString("cargo_nom"));

        // empleado responsable
        Empleado emp = new Empleado();
        emp.setId(rs.getString("emp_id"));
        emp.setNombre(rs.getString("emp_nom"));
        emp.setApellido(rs.getString("emp_ap"));
        emp.setEmail(rs.getString("emp_email"));
        emp.setCargo(cargo);

        // método de pago
        MetodoPago mp = new MetodoPago();
        mp.setId(rs.getString("mp_id"));
        mp.setNombre(rs.getString("nombre_metodo"));
        mp.setEstado(rs.getString("mp_estado"));

        // contrato
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