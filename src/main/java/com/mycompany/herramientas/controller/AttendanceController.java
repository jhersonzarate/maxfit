package com.mycompany.herramientas.controller;

import com.mycompany.herramientas.dao.AsistenciaDAO;
import com.mycompany.herramientas.dao.ClienteDAO;
import com.mycompany.herramientas.model.Asistencia;
import com.mycompany.herramientas.service.AsistenciaService;
import com.mycompany.herramientas.view.ViewRoutes;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.SQLException;
import java.time.LocalDate;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

// controlador del módulo de asistencia
@WebServlet("/attendance")
public class AttendanceController extends AbstractController {

    private static final Logger LOGGER =
            Logger.getLogger(AttendanceController.class.getName());

    private final AsistenciaService asistenciaService = new AsistenciaService();
    private final AsistenciaDAO     asistenciaDAO     = new AsistenciaDAO();
    private final ClienteDAO        clienteDAO        = new ClienteDAO();

    // ─── GET ───────────────────────────────────────────────────

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        transferirFlashMessages(req);

        String action = getAction(req);

        switch (action) {

            // mostrar historial de asistencias
            case "hist":
                mostrarHistorial(req, resp);
                break;

            // panel principal de check-in
            default:
                mostrarPanelCheckIn(req, resp);
        }
    }

    // ─── POST ──────────────────────────────────────────────────

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String action = getAction(req);

        // registrar ingreso del cliente
        if ("checkin".equals(action)) {

            procesarCheckIn(req, resp);

        } else {

            redirigirA("/attendance", req, resp);
        }
    }

    // ─── panel principal ───────────────────────────────────────

    // carga el formulario y las últimas asistencias del día
    private void mostrarPanelCheckIn(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        try {

            // últimas asistencias para el widget de actividad
            List<Asistencia> recientes = asistenciaDAO.findRecientes(20);

            int countHoy = asistenciaDAO.countHoy();

            req.setAttribute("asistenciasRecientes", recientes);
            req.setAttribute("countHoy", countHoy);

            irA(ViewRoutes.ATTENDANCE_INDEX, req, resp);

        } catch (SQLException e) {

            LOGGER.log(Level.SEVERE,
                    "Error al cargar panel de asistencia", e);

            req.setAttribute("errorMsg",
                    "Error al cargar el panel. Intenta nuevamente.");

            irA(ViewRoutes.ATTENDANCE_INDEX, req, resp);
        }
    }

    // ─── historial de asistencias ──────────────────────────────

    // muestra historial filtrado por cliente y fechas
    private void mostrarHistorial(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String clienteId = param(req, "clienteId");
        String desdeStr  = param(req, "desde");
        String hastaStr  = param(req, "hasta");

        LocalDate desde = parseFecha(desdeStr);
        LocalDate hasta = parseFecha(hastaStr);

        try {

            List<Asistencia> historial =
                    asistenciaDAO.filter(clienteId, desde, hasta);

            // datos para la tabla y filtros
            req.setAttribute("clientes", clienteDAO.findAll());
            req.setAttribute("historial", historial);
            req.setAttribute("clienteId", clienteId);
            req.setAttribute("desde", desdeStr);
            req.setAttribute("hasta", hastaStr);
            req.setAttribute("totalFiltro", historial.size());

            irA(ViewRoutes.ATTENDANCE_INDEX, req, resp);

        } catch (SQLException e) {

            LOGGER.log(Level.SEVERE,
                    "Error al cargar historial de asistencia", e);

            req.setAttribute("errorMsg",
                    "Error al cargar el historial.");

            irA(ViewRoutes.ATTENDANCE_INDEX, req, resp);
        }
    }

    // ─── registrar check-in ────────────────────────────────────

    // registra el ingreso del cliente por número de documento
    private void procesarCheckIn(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {

        String numeroDocumento = param(req, "numeroDocumento");

        // validar que ingresen documento
        if (numeroDocumento == null) {

            mensajeError(req,
                    "Ingresa el número de documento del cliente.");

            redirigirA("/attendance", req, resp);

            return;
        }

        AsistenciaService.ResultadoCheckIn resultado =
                asistenciaService.registrarCheckIn(numeroDocumento);

        // guardar resultado después del redirect
        if (resultado.isExitoso()) {

            mensajeExito(req, resultado.getMensaje());

            // guardar nombre del cliente para el widget
            req.getSession(true).setAttribute(
                    "checkInCliente",

                    resultado.getCliente() != null
                            ? resultado.getCliente().getNombreCompleto()
                            : ""
            );

            // guardar membresía del cliente
            req.getSession(true).setAttribute(
                    "checkInMembresia",

                    resultado.getContrato() != null
                    && resultado.getContrato().getMembresia() != null

                            ? resultado.getContrato()
                                    .getMembresia()
                                    .getNombreMembresia()

                            : ""
            );

        } else {

            // guardar tipo de error para mostrar icono/color
            req.getSession(true).setAttribute(
                    "checkInTipo",
                    resultado.getTipo().name()
            );

            mensajeError(req, resultado.getMensaje());
        }

        redirigirA("/attendance", req, resp);
    }

    // ─── helpers privados ──────────────────────────────────────

    // convierto string a LocalDate de forma segura
    private LocalDate parseFecha(String fechaStr) {

        if (fechaStr == null || fechaStr.isBlank()) {
            return null;
        }

        try {

            return LocalDate.parse(fechaStr);

        } catch (Exception e) {

            // si el formato es inválido -> retorno null
            return null;
        }
    }
}