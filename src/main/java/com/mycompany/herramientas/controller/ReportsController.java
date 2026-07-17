package com.mycompany.herramientas.controller;

import com.mycompany.herramientas.config.AppConfig;
import com.mycompany.herramientas.dao.AsistenciaDAO;
import com.mycompany.herramientas.dao.ClaseDAO;
import com.mycompany.herramientas.dao.ClienteDAO;
import com.mycompany.herramientas.dao.ContratoDAO;
import com.mycompany.herramientas.dao.EmpleadoDAO;
import com.mycompany.herramientas.dao.MembresiaDAO;
import com.mycompany.herramientas.model.Asistencia;
import com.mycompany.herramientas.model.Contrato;
import com.mycompany.herramientas.model.Membresia;
import com.mycompany.herramientas.service.ReportPdfService;
import com.mycompany.herramientas.view.ViewRoutes;
import com.lowagie.text.DocumentException;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.math.BigDecimal;
import java.sql.SQLException;
import java.time.LocalDate;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.time.YearMonth;
import java.time.format.DateTimeFormatter;
import java.time.format.TextStyle;

// reportes globales del sistema para administrador
@WebServlet("/reports")
public class ReportsController extends AbstractController {

    private static final Logger LOGGER =
            Logger.getLogger(ReportsController.class.getName());

    // máximo de asistencias mostradas en historial
    private static final int MAX_ASISTENCIAS_REPORTE = 50;

    private final ContratoDAO   contratoDAO   = new ContratoDAO();
    private final ClienteDAO    clienteDAO    = new ClienteDAO();
    private final AsistenciaDAO asistenciaDAO = new AsistenciaDAO();
    private final EmpleadoDAO   empleadoDAO   = new EmpleadoDAO();
    private final ClaseDAO      claseDAO      = new ClaseDAO();
    private final MembresiaDAO  membresiaDAO  = new MembresiaDAO();
    private final ReportPdfService reportPdfService = new ReportPdfService();

    // ─── GET ──────────────────────────────────────────────────

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        transferirFlashMessages(req);

        // actualizar contratos vencidos antes de generar reportes
        actualizarVencidosSilencioso();

        String action = getAction(req);

        switch (action) {
            case "contratos":
                if ("pdf".equals(param(req, "formato"))) {
                    exportarContratosPdf(req, resp);
                } else {
                    reporteContratos(req, resp);
                }
                break;
            case "asistencia":
                reporteAsistencia(req, resp);
                break;
            case "membresias":
                reporteMembresias(req, resp);
                break;
            default:
                reporteResumen(req, resp);
        }
    }

    // ─── reporte general ─────────────────────────────────────

    private void reporteResumen(HttpServletRequest req,
                                 HttpServletResponse resp)
            throws ServletException, IOException {

        cargarKpisGlobales(req);

        // contratos próximos a vencer
        try {

            List<Contrato> proximos =
                    contratoDAO.findProximosAVencer(7);

            req.setAttribute(
                    "proximosVencer",
                    proximos
            );

            req.setAttribute(
                    "countProximosVencer",
                    proximos.size()
            );

        } catch (SQLException e) {

            LOGGER.log(
                    Level.WARNING,
                    "Error al cargar próximos vencimientos",
                    e
            );

            req.setAttribute(
                    "proximosVencer",
                    Collections.emptyList()
            );

            req.setAttribute(
                    "countProximosVencer",
                    0
            );
        }

        // últimas asistencias registradas
        try {

            List<Asistencia> recientes =
                    asistenciaDAO.findRecientes(10);

            req.setAttribute(
                    "asistenciasRecientes",
                    recientes
            );

        } catch (SQLException e) {

            LOGGER.log(
                    Level.WARNING,
                    "Error al cargar asistencias recientes",
                    e
            );

            req.setAttribute(
                    "asistenciasRecientes",
                    Collections.emptyList()
            );
        }

        req.setAttribute("vistaActiva", "resumen");

        req.setAttribute(
                "fechaReporte",
                LocalDate.now().toString()
        );

        irA(ViewRoutes.REPORTS_INDEX, req, resp);
    }

    // ─── reporte de contratos ────────────────────────────────

    private void reporteContratos(HttpServletRequest req,
                                   HttpServletResponse resp)
            throws ServletException, IOException {

        int activos    = 0;
        int vencidos   = 0;
        int cancelados = 0;

        // contar contratos por estado
        try {

            activos = contratoDAO.countByEstado(
                    AppConfig.CONTRATO_ACTIVO
            );

            vencidos = contratoDAO.countByEstado(
                    AppConfig.CONTRATO_VENCIDO
            );

            cancelados = contratoDAO.countByEstado(
                    AppConfig.CONTRATO_CANCELADO
            );

        } catch (SQLException e) {

            LOGGER.log(
                    Level.WARNING,
                    "Error al contar contratos por estado",
                    e
            );
        }

        int total = activos + vencidos + cancelados;

        req.setAttribute("contratosActivos", activos);

        req.setAttribute(
                "contratosVencidos",
                vencidos
        );

        req.setAttribute(
                "contratosCancelados",
                cancelados
        );

        req.setAttribute(
                "contratosTotal",
                total
        );

        // porcentajes para gráficos o métricas visuales
        req.setAttribute(
                "pctActivos",
                total > 0 ? (activos * 100 / total) : 0
        );

        req.setAttribute(
                "pctVencidos",
                total > 0 ? (vencidos * 100 / total) : 0
        );

        req.setAttribute(
                "pctCancelados",
                total > 0 ? (cancelados * 100 / total) : 0
        );

        // ingresos del mes actual, tendencia y KPIs del periodo filtrado (mensual/anual)
        cargarDatosPeriodo(req);

        // contratos próximos a vencer
        try {

            List<Contrato> proximos =
                    contratoDAO.findProximosAVencer(7);

            req.setAttribute(
                    "proximosVencer",
                    proximos
            );

            req.setAttribute(
                    "countProximosVencer",
                    proximos.size()
            );

        } catch (SQLException e) {

            LOGGER.log(
                    Level.WARNING,
                    "Error al cargar próximos vencimientos",
                    e
            );

            req.setAttribute(
                    "proximosVencer",
                    Collections.emptyList()
            );

            req.setAttribute(
                    "countProximosVencer",
                    0
            );
        }

        req.setAttribute("vistaActiva", "contratos");

        req.setAttribute(
                "fechaReporte",
                LocalDate.now().toString()
        );

        irA(ViewRoutes.REPORTS_INDEX, req, resp);
    }

    // ─── reporte de asistencia ───────────────────────────────

    private void reporteAsistencia(HttpServletRequest req,
                                    HttpServletResponse resp)
            throws ServletException, IOException {

        // total de asistencias del día
        try {

            req.setAttribute(
                    "atendidosHoy",
                    asistenciaDAO.countHoy()
            );

        } catch (SQLException e) {

            LOGGER.log(
                    Level.WARNING,
                    "Error al contar asistencias hoy",
                    e
            );

            req.setAttribute(
                    "atendidosHoy",
                    0
            );
        }

        // Filtros para el gráfico
        int year = LocalDate.now().getYear();
        int currentMonth = LocalDate.now().getMonthValue();
        
        String mesParam = req.getParameter("mes");
        String semanaParam = req.getParameter("semana");
        
        int month = (mesParam != null && !mesParam.isEmpty()) ? Integer.parseInt(mesParam) : currentMonth;
        int week = (semanaParam != null && !semanaParam.isEmpty()) ? Integer.parseInt(semanaParam) : 1;

        YearMonth ym = YearMonth.of(year, month);
        LocalDate startOfMonth = ym.atDay(1);
        LocalDate startOfWeek = startOfMonth.plusDays((week - 1) * 7);
        LocalDate endOfWeek = startOfWeek.plusDays(6);

        if (startOfWeek.getMonthValue() != month) {
            startOfWeek = startOfMonth;
            endOfWeek = ym.atEndOfMonth();
        } else if (endOfWeek.getMonthValue() != month) {
            endOfWeek = ym.atEndOfMonth();
        }

        try {
            Map<LocalDate, Integer> conteo = asistenciaDAO.getConteoAsistenciaPorRango(startOfWeek, endOfWeek);

            // Determinar el Lunes de la semana para que el gráfico sea siempre de Lunes a Domingo
            LocalDate mondayOfWeek = startOfWeek;
            while (mondayOfWeek.getDayOfWeek() != java.time.DayOfWeek.MONDAY) {
                mondayOfWeek = mondayOfWeek.minusDays(1);
            }

            StringBuilder labelsJson = new StringBuilder("[");
            StringBuilder dataJson = new StringBuilder("[");

            LocalDate current = mondayOfWeek;
            for (int i = 0; i < 7; i++) {
                if (i > 0) {
                    labelsJson.append(",");
                    dataJson.append(",");
                }
                String dayName = current.getDayOfWeek().getDisplayName(TextStyle.FULL, new Locale("es", "ES"));
                dayName = dayName.substring(0, 1).toUpperCase() + dayName.substring(1);
                labelsJson.append("\"").append(dayName).append("\"");
                
                if (!current.isBefore(startOfWeek) && !current.isAfter(endOfWeek)) {
                    dataJson.append(conteo.getOrDefault(current, 0));
                } else {
                    dataJson.append(0);
                }
                
                current = current.plusDays(1);
            }
            labelsJson.append("]");
            dataJson.append("]");

            req.setAttribute("chartLabels", labelsJson.toString());
            req.setAttribute("chartData", dataJson.toString());
            req.setAttribute("filtroMes", month);
            req.setAttribute("filtroSemana", week);
            
            String[] diaPico = asistenciaDAO.getDiaPicoAsistencia();
            req.setAttribute("diaPicoNombre", diaPico[0]);
            req.setAttribute("diaPicoPromedio", diaPico[1]);
            
            List<Asistencia> recientes = asistenciaDAO.findRecientes(1);
            req.setAttribute("asistenciasRecientes", recientes);

        } catch (SQLException e) {
            LOGGER.log(Level.WARNING, "Error al cargar datos para gráfico de asistencia", e);
            req.setAttribute("chartLabels", "[]");
            req.setAttribute("chartData", "[]");
            req.setAttribute("diaPicoNombre", "Ninguno");
            req.setAttribute("diaPicoPromedio", "0");
        }

        req.setAttribute("vistaActiva", "asistencia");

        req.setAttribute(
                "maxAsistencias",
                MAX_ASISTENCIAS_REPORTE
        );

        req.setAttribute(
                "fechaReporte",
                LocalDate.now().toString()
        );

        irA(ViewRoutes.REPORTS_INDEX, req, resp);
    }

    // ─── reporte de membresías ───────────────────────────────

    private void reporteMembresias(HttpServletRequest req,
                                    HttpServletResponse resp)
            throws ServletException, IOException {

        // catálogo completo de planes
        try {

            List<Membresia> membresias =
                    membresiaDAO.findAll();

            req.setAttribute(
                    "membresias",
                    membresias
            );

            req.setAttribute(
                    "totalPlanes",
                    membresias.size()
            );

        } catch (SQLException e) {

            LOGGER.log(
                    Level.WARNING,
                    "Error al cargar membresías",
                    e
            );

            req.setAttribute(
                    "membresias",
                    Collections.emptyList()
            );

            req.setAttribute(
                    "totalPlanes",
                    0
            );
        }

        // contratos activos actuales
        try {

            String filtroRapido = req.getParameter("filtroRapido");
            String desdeStr = req.getParameter("desde");
            String hastaStr = req.getParameter("hasta");
            
            LocalDate desde = null;
            LocalDate hasta = null;
            LocalDate hoy = LocalDate.now();

            if ("hoy".equals(filtroRapido)) {
                desde = hoy;
                hasta = hoy;
            } else if ("semana".equals(filtroRapido)) {
                desde = hoy.with(java.time.temporal.TemporalAdjusters.previousOrSame(java.time.DayOfWeek.MONDAY));
                hasta = hoy.with(java.time.temporal.TemporalAdjusters.nextOrSame(java.time.DayOfWeek.SUNDAY));
            } else if ("mes".equals(filtroRapido)) {
                desde = hoy.withDayOfMonth(1);
                hasta = hoy.withDayOfMonth(hoy.lengthOfMonth());
            } else if (desdeStr != null && !desdeStr.isEmpty() && hastaStr != null && !hastaStr.isEmpty()) {
                try {
                    desde = LocalDate.parse(desdeStr);
                    hasta = LocalDate.parse(hastaStr);
                } catch (Exception e) {
                    LOGGER.warning("Error parsing dates for membresias filter");
                }
            }

            List<Contrato> contratosActivos;
            if (desde != null && hasta != null) {
                contratosActivos = contratoDAO.findByRango(desde, hasta);
                req.setAttribute("filtroRapido", filtroRapido);
                req.setAttribute("desde", desde.toString());
                req.setAttribute("hasta", hasta.toString());
            } else {
                contratosActivos = contratoDAO.findAll();
            }

            req.setAttribute(
                    "contratosActivos",
                    contratosActivos
            );

            req.setAttribute(
                    "totalContratosActivos",
                    contratosActivos.size()
            );

            java.util.Map<String, Integer> conteoPorPlan = new java.util.HashMap<>();
            for (Contrato c : contratosActivos) {
                if (c.getMembresia() != null) {
                    String nombre = c.getMembresia().getNombreMembresia();
                    conteoPorPlan.put(nombre, conteoPorPlan.getOrDefault(nombre, 0) + 1);
                }
            }

            StringBuilder labelsJson = new StringBuilder("[");
            StringBuilder dataJson = new StringBuilder("[");
            boolean first = true;
            
            String planMasVendido = "Ninguno";
            int maxVentas = 0;

            for (java.util.Map.Entry<String, Integer> entry : conteoPorPlan.entrySet()) {
                if (entry.getValue() > maxVentas) {
                    maxVentas = entry.getValue();
                    planMasVendido = entry.getKey();
                }
                if (!first) {
                    labelsJson.append(",");
                    dataJson.append(",");
                }
                labelsJson.append("\"").append(entry.getKey()).append("\"");
                dataJson.append(entry.getValue());
                first = false;
            }
            labelsJson.append("]");
            dataJson.append("]");

            req.setAttribute("membresiasChartLabels", labelsJson.toString());
            req.setAttribute("membresiasChartData", dataJson.toString());
            req.setAttribute("planMasVendido", planMasVendido);
            req.setAttribute("planMasVendidoCantidad", maxVentas);

        } catch (SQLException e) {

            LOGGER.log(
                    Level.WARNING,
                    "Error al cargar contratos activos",
                    e
            );

            req.setAttribute(
                    "contratosActivos",
                    Collections.emptyList()
            );

            req.setAttribute(
                    "totalContratosActivos",
                    0
            );
        }

        req.setAttribute("vistaActiva", "membresias");

        req.setAttribute(
                "fechaReporte",
                LocalDate.now().toString()
        );

        irA(ViewRoutes.REPORTS_INDEX, req, resp);
    }

    // ─── helpers privados ────────────────────────────────────

    // lee tipo=mensual|anual, mes, anio de la request (con defaults al mes/año
    // actuales) y calcula ingresos/nuevos/vencidos del periodo + la tendencia
    // mensual para el gráfico. Usado tanto por la vista web como por el PDF,
    // para que ambos muestren siempre el mismo periodo seleccionado.
    private void cargarDatosPeriodo(HttpServletRequest req) {

        LocalDate hoy = LocalDate.now();

        String tipo = param(req, "tipo", "mensual");
        if (!"anual".equals(tipo)) {
            tipo = "mensual";
        }

        int anio = paramInt(req, "anio", hoy.getYear());
        int mes = paramInt(req, "mes", hoy.getMonthValue());
        if (mes < 1 || mes > 12) {
            mes = hoy.getMonthValue();
        }

        LocalDate desde;
        LocalDate hasta;
        LocalDate desdeChart;
        LocalDate hastaChart;
        String label;

        if ("anual".equals(tipo)) {

            desde = LocalDate.of(anio, 1, 1);
            hasta = LocalDate.of(anio, 12, 31);
            desdeChart = desde;
            hastaChart = hasta;
            label = "Año " + anio;

        } else {

            YearMonth ym = YearMonth.of(anio, mes);
            desde = ym.atDay(1);
            hasta = ym.atEndOfMonth();
            desdeChart = ym.minusMonths(5).atDay(1);
            hastaChart = hasta;

            DateTimeFormatter fmtMes = DateTimeFormatter.ofPattern("MMMM yyyy", new Locale("es", "PE"));
            String nombreMes = ym.atDay(1).format(fmtMes);
            label = nombreMes.substring(0, 1).toUpperCase(Locale.ROOT) + nombreMes.substring(1);
        }

        try {

            BigDecimal ingresosPeriodo = contratoDAO.getIngresosPorRango(desde, hasta);
            int nuevosPeriodo = contratoDAO.countNuevosPorRango(desde, hasta);
            int vencidosPeriodo = contratoDAO.countVencidosPorRango(desde, hasta);

            req.setAttribute("ingresosMes", ingresosPeriodo); // compat con la tarjeta KPI existente
            req.setAttribute("ingresosPeriodo", ingresosPeriodo);
            req.setAttribute("contratosNuevosPeriodo", nuevosPeriodo);
            req.setAttribute("contratosVencidosPeriodo", vencidosPeriodo);

            boolean sinDatos = nuevosPeriodo == 0
                    && vencidosPeriodo == 0
                    && ingresosPeriodo.compareTo(BigDecimal.ZERO) == 0;

            req.setAttribute("periodoSinDatos", sinDatos);

            LinkedHashMap<String, BigDecimal> ingresosPorMes =
                    contratoDAO.getIngresosPorMesesEnRango(desdeChart, hastaChart);

            StringBuilder labelsJson = new StringBuilder("[");
            StringBuilder dataJson = new StringBuilder("[");
            boolean primero = true;

            for (Map.Entry<String, BigDecimal> entry : ingresosPorMes.entrySet()) {
                if (!primero) {
                    labelsJson.append(",");
                    dataJson.append(",");
                }
                labelsJson.append("\"").append(entry.getKey()).append("\"");
                dataJson.append(entry.getValue());
                primero = false;
            }

            labelsJson.append("]");
            dataJson.append("]");

            req.setAttribute("contratosIngresosLabels", labelsJson.toString());
            req.setAttribute("contratosIngresosData", dataJson.toString());

        } catch (SQLException e) {

            LOGGER.log(Level.WARNING, "Error al cargar datos del periodo", e);

            req.setAttribute("ingresosMes", BigDecimal.ZERO);
            req.setAttribute("ingresosPeriodo", BigDecimal.ZERO);
            req.setAttribute("contratosNuevosPeriodo", 0);
            req.setAttribute("contratosVencidosPeriodo", 0);
            req.setAttribute("contratosIngresosLabels", "[]");
            req.setAttribute("contratosIngresosData", "[]");
            req.setAttribute("periodoSinDatos", true);
        }

        req.setAttribute("periodoTipo", tipo);
        req.setAttribute("periodoMes", mes);
        req.setAttribute("periodoAnio", anio);
        req.setAttribute("periodoLabel", label);
        req.setAttribute("periodoDesde", desde);
        req.setAttribute("periodoHasta", hasta);
        req.setAttribute("anioHoy", hoy.getYear());
    }

    private void exportarContratosPdf(HttpServletRequest req,
                                       HttpServletResponse resp)
            throws ServletException, IOException {

        try {

            int activos = contratoDAO.countByEstado(AppConfig.CONTRATO_ACTIVO);
            int vencidos = contratoDAO.countByEstado(AppConfig.CONTRATO_VENCIDO);
            int cancelados = contratoDAO.countByEstado(AppConfig.CONTRATO_CANCELADO);
            int total = activos + vencidos + cancelados;

            // usa el mismo helper que la vista web para que el PDF refleje
            // exactamente el periodo (mensual/anual) que el usuario tenía seleccionado
            cargarDatosPeriodo(req);

            boolean periodoSinDatos = Boolean.TRUE.equals(req.getAttribute("periodoSinDatos"));

            if (periodoSinDatos) {
                mensajeError(req, "No hay datos para el periodo seleccionado ("
                        + req.getAttribute("periodoLabel") + "). No se generó el PDF.");
                redirigirA("/reports?action=contratos&tipo=" + req.getAttribute("periodoTipo")
                        + "&mes=" + req.getAttribute("periodoMes")
                        + "&anio=" + req.getAttribute("periodoAnio"), req, resp);
                return;
            }

            BigDecimal ingresosPeriodo = (BigDecimal) req.getAttribute("ingresosPeriodo");
            int nuevosPeriodo = (int) req.getAttribute("contratosNuevosPeriodo");
            int vencidosPeriodo = (int) req.getAttribute("contratosVencidosPeriodo");
            String periodoLabel = (String) req.getAttribute("periodoLabel");

            // el gráfico de tendencia del PDF usa la misma ventana que el gráfico
            // web (6 meses terminando en el mes elegido, o los 12 del año elegido)
            String tipoPeriodo = (String) req.getAttribute("periodoTipo");
            int anioSel = (int) req.getAttribute("periodoAnio");
            int mesSel = (int) req.getAttribute("periodoMes");
            LocalDate desdeChart;
            LocalDate hastaChart;
            if ("anual".equals(tipoPeriodo)) {
                desdeChart = LocalDate.of(anioSel, 1, 1);
                hastaChart = LocalDate.of(anioSel, 12, 31);
            } else {
                YearMonth ym = YearMonth.of(anioSel, mesSel);
                desdeChart = ym.minusMonths(5).atDay(1);
                hastaChart = ym.atEndOfMonth();
            }
            LinkedHashMap<String, BigDecimal> ingresosParaGrafico =
                    contratoDAO.getIngresosPorMesesEnRango(desdeChart, hastaChart);

            List<Contrato> proximos = contratoDAO.findProximosAVencer(7);
            List<Contrato> listaActivos = contratoDAO.findAllActivos();
            List<Contrato> listaVencidos = contratoDAO.findByEstado(AppConfig.CONTRATO_VENCIDO);

            ReportPdfService.ContratosReportData data = new ReportPdfService.ContratosReportData(
                    activos,
                    vencidos,
                    cancelados,
                    total,
                    ingresosPeriodo,
                    ingresosParaGrafico,
                    proximos,
                    listaActivos,
                    listaVencidos,
                    LocalDate.now(),
                    getSessionUserName(req),
                    periodoLabel,
                    nuevosPeriodo,
                    vencidosPeriodo
            );

            // ruta absoluta en disco del logo — si no existe todavía, el
            // servicio dibuja un wordmark de texto "MAXFIT" en su lugar
            String logoRealPath = req.getServletContext().getRealPath("/static/img/logo.png");

            byte[] pdf = reportPdfService.generarPdfContratos(data, logoRealPath);

            resp.reset();
            resp.setContentType("application/pdf");
            resp.setHeader(
                    "Content-Disposition",
                    "attachment; filename=\"reporte-contratos-" + LocalDate.now() + ".pdf\""
            );
            resp.setContentLength(pdf.length);
            resp.getOutputStream().write(pdf);
            resp.getOutputStream().flush();

        } catch (SQLException | DocumentException e) {

            LOGGER.log(
                    Level.SEVERE,
                    "Error al generar PDF de contratos",
                    e
            );

            mensajeError(req, "No se pudo generar el PDF del reporte. Intenta nuevamente.");
            redirigirA("/reports?action=contratos", req, resp);
        }
    }

    private void cargarKpisGlobales(HttpServletRequest req) {

        // total de clientes registrados
        try {

            req.setAttribute(
                    "totalClientes",
                    clienteDAO.count()
            );

        } catch (SQLException e) {

            LOGGER.log(
                    Level.WARNING,
                    "KPI fallido: totalClientes",
                    e
            );

            req.setAttribute(
                    "totalClientes",
                    "-"
            );
        }

        // contratos activos
        try {

            req.setAttribute(
                    "contratosActivos",
                    contratoDAO.countActivos()
            );

        } catch (SQLException e) {

            LOGGER.log(
                    Level.WARNING,
                    "KPI fallido: contratosActivos",
                    e
            );

            req.setAttribute(
                    "contratosActivos",
                    "-"
            );
        }

        // check-ins registrados hoy
        try {

            req.setAttribute(
                    "atendidosHoy",
                    asistenciaDAO.countHoy()
            );

        } catch (SQLException e) {

            LOGGER.log(
                    Level.WARNING,
                    "KPI fallido: atendidosHoy",
                    e
            );

            req.setAttribute(
                    "atendidosHoy",
                    "-"
            );
        }

        // total de empleados
        try {

            req.setAttribute(
                    "totalEmpleados",
                    empleadoDAO.count()
            );

        } catch (SQLException e) {

            LOGGER.log(
                    Level.WARNING,
                    "KPI fallido: totalEmpleados",
                    e
            );

            req.setAttribute(
                    "totalEmpleados",
                    "-"
            );
        }

        // clases vigentes
        try {

            req.setAttribute(
                    "clasesVigentes",
                    claseDAO.countVigentes()
            );

        } catch (SQLException e) {

            LOGGER.log(
                    Level.WARNING,
                    "KPI fallido: clasesVigentes",
                    e
            );

            req.setAttribute(
                    "clasesVigentes",
                    "-"
            );
        }

        // ingresos del mes
        try {

            BigDecimal ingresos =
                    contratoDAO.getIngresosMesActual();

            req.setAttribute(
                    "ingresosMes",
                    ingresos
            );

        } catch (SQLException e) {

            LOGGER.log(
                    Level.WARNING,
                    "KPI fallido: ingresosMes",
                    e
            );

            req.setAttribute(
                    "ingresosMes",
                    BigDecimal.ZERO
            );
        }
    }

    // actualizar contratos vencidos sin interrumpir reportes
    private void actualizarVencidosSilencioso() {

        try {

            int actualizados =
                    contratoDAO.marcarVencidos(
                            LocalDate.now(),
                            AppConfig.CONTRATO_ACTIVO,
                            AppConfig.CONTRATO_VENCIDO
                    );

            if (actualizados > 0) {

                LOGGER.info(
                        "Reports: contratos vencidos actualizados = "
                                + actualizados
                );
            }

        } catch (SQLException e) {

            LOGGER.log(
                    Level.WARNING,
                    "Reports: error al actualizar contratos vencidos",
                    e
            );
        }
    }
}