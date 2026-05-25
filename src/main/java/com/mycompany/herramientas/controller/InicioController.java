package com.mycompany.herramientas.controller;

import com.mycompany.herramientas.dao.*;
import com.mycompany.herramientas.model.*;
import com.mycompany.herramientas.view.ViewRoutes;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.math.BigDecimal;
import java.sql.SQLException;
import java.time.LocalDate;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

// dashboard principal del administrador
@WebServlet("/inicio")
public class InicioController extends AbstractController {

    private static final Logger LOGGER =
            Logger.getLogger(InicioController.class.getName());

    // días previos usados para alertar contratos próximos a vencer
    private static final int DIAS_ALERTA_VENCIMIENTO = 7;

    // máximo de asistencias mostradas en actividad reciente
    private static final int MAX_ASISTENCIAS_RECIENTES = 5;

    private final ClienteDAO clienteDAO = new ClienteDAO();
    private final ContratoDAO contratoDAO = new ContratoDAO();
    private final EmpleadoDAO empleadoDAO = new EmpleadoDAO();
    private final ClaseDAO claseDAO = new ClaseDAO();
    private final AsistenciaDAO asistenciaDAO = new AsistenciaDAO();
    private final HorarioDAO horarioDAO = new HorarioDAO();

    // ───────────────── GET /inicio ────────────────────

    @Override
    protected void doGet(HttpServletRequest req,
                         HttpServletResponse resp)
            throws ServletException, IOException {

        transferirFlashMessages(req);

        cargarKpis(req);

        cargarWidgets(req);

        irA(ViewRoutes.INICIO_ADMIN, req, resp);
    }

    // ───────────────── KPIs principales ───────────────

    private void cargarKpis(HttpServletRequest req) {

        // total de clientes registrados
        try {

            req.setAttribute(
                    "totalClientes",
                    clienteDAO.count()
            );

        } catch (SQLException e) {

            LOGGER.log(
                    Level.WARNING,
                    "Error al contar clientes",
                    e
            );

            req.setAttribute("totalClientes", "-");
        }

        // contratos activos actualmente
        try {

            req.setAttribute(
                    "contratosActivos",
                    contratoDAO.countActivos()
            );

        } catch (SQLException e) {

            LOGGER.log(
                    Level.WARNING,
                    "Error al contar contratos activos",
                    e
            );

            req.setAttribute("contratosActivos", "-");
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
                    "Error al contar check-ins hoy",
                    e
            );

            req.setAttribute("atendidosHoy", "-");
        }

        // total de empleados registrados
        try {

            req.setAttribute(
                    "totalEmpleados",
                    empleadoDAO.count()
            );

        } catch (SQLException e) {

            LOGGER.log(
                    Level.WARNING,
                    "Error al contar empleados",
                    e
            );

            req.setAttribute("totalEmpleados", "-");
        }

        // clases con estado vigente
        try {

            req.setAttribute(
                    "clasesVigentes",
                    claseDAO.countVigentes()
            );

        } catch (SQLException e) {

            LOGGER.log(
                    Level.WARNING,
                    "Error al contar clases vigentes",
                    e
            );

            req.setAttribute("clasesVigentes", "-");
        }

        // ingresos generados en el mes actual
        try {

            // usar BigDecimal para cálculos monetarios
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
    }

    // ───────────────── widgets del dashboard ──────────

    private void cargarWidgets(HttpServletRequest req) {

        // contratos próximos a vencer
        try {

            List<Contrato> proximos =
                    contratoDAO.findProximosAVencer(
                            DIAS_ALERTA_VENCIMIENTO
                    );

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
                    java.util.Collections.emptyList()
            );

            req.setAttribute(
                    "countProximosVencer",
                    0
            );
        }

        // últimas asistencias registradas
        try {

            List<Asistencia> recientes =
                    asistenciaDAO.findRecientes(
                            MAX_ASISTENCIAS_RECIENTES
                    );

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
                    java.util.Collections.emptyList()
            );
        }

        // clases programadas para hoy
        try {

            int diaSemanaHoy =
                    LocalDate.now()
                            .getDayOfWeek()
                            .getValue();

            List<Horario> clasesHoy =
                    horarioDAO.findByDia(diaSemanaHoy);

            req.setAttribute(
                    "clasesHoy",
                    clasesHoy
            );

            req.setAttribute(
                    "countClasesHoy",
                    clasesHoy.size()
            );

        } catch (SQLException e) {

            LOGGER.log(
                    Level.WARNING,
                    "Error al cargar clases de hoy",
                    e
            );

            req.setAttribute(
                    "clasesHoy",
                    java.util.Collections.emptyList()
            );

            req.setAttribute(
                    "countClasesHoy",
                    0
            );
        }

        // datos auxiliares del panel
        req.setAttribute(
                "fechaHoy",
                LocalDate.now().toString()
        );

        req.setAttribute(
                "diasAlertaVencimiento",
                DIAS_ALERTA_VENCIMIENTO
        );
    }
}