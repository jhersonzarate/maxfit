package com.mycompany.herramientas.controller;

import com.mycompany.herramientas.dao.*;
import com.mycompany.herramientas.model.*;
import com.mycompany.herramientas.service.ContratoService;
import com.mycompany.herramientas.view.ViewRoutes;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.SQLException;
import java.time.LocalDate;
import java.util.Collections;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

// dashboard principal del recepcionista
@WebServlet("/dashboard")
public class DashboardController extends AbstractController {

    private static final Logger LOGGER =
            Logger.getLogger(DashboardController.class.getName());

    // cantidad de días para alertar contratos próximos a vencer
    private static final int DIAS_ALERTA_VENCIMIENTO = 7;

    // máximo de asistencias mostradas en el feed
    private static final int MAX_ASISTENCIAS_HOY = 10;

    private final AsistenciaDAO   asistenciaDAO   = new AsistenciaDAO();
    private final ContratoDAO     contratoDAO     = new ContratoDAO();
    private final HorarioDAO      horarioDAO      = new HorarioDAO();
    private final ContratoService contratoService = new ContratoService();

    // ─── GET /dashboard ───────────────────────────────────────

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        transferirFlashMessages(req);

        // actualizar contratos vencidos antes de cargar KPIs
        contratoService.actualizarVencidos();

        cargarKpisRecep(req);
        cargarWidgetsRecep(req);

        irA(ViewRoutes.DASHBOARD_RECEP, req, resp);
    }

    // ─── KPIs principales ─────────────────────────────────────

    private void cargarKpisRecep(HttpServletRequest req) {

        // total de check-ins registrados hoy
        try {
            req.setAttribute("atendidosHoy", asistenciaDAO.countHoy());

        } catch (SQLException e) {

            LOGGER.log(Level.WARNING, "Error al contar check-ins hoy", e);

            req.setAttribute("atendidosHoy", 0);
        }

        // clientes con contrato activo
        try {
            req.setAttribute("contratosActivos", contratoDAO.countActivos());

        } catch (SQLException e) {

            LOGGER.log(Level.WARNING, "Error al contar contratos activos", e);

            req.setAttribute("contratosActivos", 0);
        }

        // clases programadas para hoy
        try {

            int dia = LocalDate.now().getDayOfWeek().getValue();

            req.setAttribute("countClasesHoy", horarioDAO.countByDia(dia));

        } catch (SQLException e) {

            LOGGER.log(Level.WARNING, "Error al contar clases de hoy", e);

            req.setAttribute("countClasesHoy", 0);
        }
    }

    // ─── widgets del dashboard ────────────────────────────────

    private void cargarWidgetsRecep(HttpServletRequest req) {

        // últimas asistencias del día
        try {

            List<Asistencia> recientes =
                    asistenciaDAO.findRecientes(MAX_ASISTENCIAS_HOY);

            req.setAttribute("asistenciasRecientes", recientes);

        } catch (SQLException e) {

            LOGGER.log(Level.WARNING, "Error al cargar asistencias recientes", e);

            req.setAttribute(
                    "asistenciasRecientes",
                    Collections.emptyList()
            );
        }

        // contratos que vencen pronto
        try {

            List<Contrato> proximos =
                    contratoDAO.findProximosAVencer(
                            DIAS_ALERTA_VENCIMIENTO
                    );

            req.setAttribute("proximosVencer", proximos);

            req.setAttribute(
                    "countProximosVencer",
                    proximos.size()
            );

        } catch (SQLException e) {

            LOGGER.log(Level.WARNING, "Error al cargar próximos vencimientos", e);

            req.setAttribute(
                    "proximosVencer",
                    Collections.emptyList()
            );

            req.setAttribute("countProximosVencer", 0);
        }

        // clases disponibles hoy
        try {

            int dia = LocalDate.now().getDayOfWeek().getValue();

            List<Horario> clasesHoy = horarioDAO.findByDia(dia);

            req.setAttribute("clasesHoy", clasesHoy);

        } catch (SQLException e) {

            LOGGER.log(Level.WARNING, "Error al cargar clases de hoy", e);

            req.setAttribute(
                    "clasesHoy",
                    Collections.emptyList()
            );
        }

        req.setAttribute("fechaHoy", LocalDate.now().toString());
    }
}