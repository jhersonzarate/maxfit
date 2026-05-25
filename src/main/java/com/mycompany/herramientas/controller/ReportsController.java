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
import com.mycompany.herramientas.view.ViewRoutes;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.math.BigDecimal;
import java.sql.SQLException;
import java.time.LocalDate;
import java.util.Collections;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

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
                reporteContratos(req, resp);
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

        // ingresos del mes actual
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
                    "Error al calcular ingresos del mes",
                    e
            );

            req.setAttribute(
                    "ingresosMes",
                    BigDecimal.ZERO
            );
        }

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

        // historial reciente de asistencias
        try {

            List<Asistencia> historial =
                    asistenciaDAO.findRecientes(
                            MAX_ASISTENCIAS_REPORTE
                    );

            req.setAttribute(
                    "historialAsistencia",
                    historial
            );

            req.setAttribute(
                    "totalHistorial",
                    historial.size()
            );

        } catch (SQLException e) {

            LOGGER.log(
                    Level.WARNING,
                    "Error al cargar historial de asistencia",
                    e
            );

            req.setAttribute(
                    "historialAsistencia",
                    Collections.emptyList()
            );

            req.setAttribute(
                    "totalHistorial",
                    0
            );
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

            List<Contrato> contratosActivos =
                    contratoDAO.findAllActivos();

            req.setAttribute(
                    "contratosActivos",
                    contratosActivos
            );

            req.setAttribute(
                    "totalContratosActivos",
                    contratosActivos.size()
            );

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