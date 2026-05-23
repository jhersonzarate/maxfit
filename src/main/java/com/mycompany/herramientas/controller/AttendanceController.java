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

/**
 * Controlador de Control de Asistencia (RF-04, RF-05).
 *
 * Rutas y acciones:
 *   GET  /attendance              → panel principal: formulario check-in + lista de hoy
 *   GET  /attendance?action=hist  → historial filtrado por cliente y/o rango de fechas
 *   POST /attendance?action=checkin → registrar ingreso de un cliente
 *
 * Acceso: ROL-ADMIN y ROL-RECEP (garantizado por RoleFilter)
 *
 * Flujo de check-in (RF-04):
 *   1. El recepcionista ingresa el número de documento del cliente.
 *   2. Se delega a AsistenciaService.registrarCheckIn().
 *   3. El servicio verifica contrato activo y UNIQUE (id_contrato, fecha).
 *   4. Se muestra el resultado con el nombre del cliente y estado.
 *
 * Historial (RF-05):
 *   - Filtrable por clienteId, fechaDesde, fechaHasta.
 *   - Todos los parámetros son opcionales (null = sin filtro).
 *
 * @author MaxFit
 */
@WebServlet("/attendance")
public class AttendanceController extends AbstractController {

    private static final Logger LOGGER =
            Logger.getLogger(AttendanceController.class.getName());

    private final AsistenciaService asistenciaService = new AsistenciaService();
    private final AsistenciaDAO     asistenciaDAO     = new AsistenciaDAO();
    private final ClienteDAO        clienteDAO        = new ClienteDAO();

    // ─── GET ──────────────────────────────────────────────────────────────────

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        transferirFlashMessages(req);

        String action = getAction(req);

        switch (action) {
            case "hist":
                mostrarHistorial(req, resp);
                break;
            default:
                mostrarPanelCheckIn(req, resp);
        }
    }

    // ─── POST ─────────────────────────────────────────────────────────────────

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String action = getAction(req);

        if ("checkin".equals(action)) {
            procesarCheckIn(req, resp);
        } else {
            redirigirA("/attendance", req, resp);
        }
    }

    // ─── GET: panel principal de check-in ────────────────────────────────────

    /**
     * Carga el panel de asistencia con:
     *   - Formulario de check-in por documento
     *   - Lista de los últimos check-ins del día (máx. 20)
     *   - Contador de atendidos hoy
     */
    private void mostrarPanelCheckIn(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        try {
            // Últimas 20 asistencias del día para el widget de actividad
            List<Asistencia> recientes = asistenciaDAO.findRecientes(20);
            int countHoy = asistenciaDAO.countHoy();

            req.setAttribute("asistenciasRecientes", recientes);
            req.setAttribute("countHoy", countHoy);

            irA(ViewRoutes.ATTENDANCE_INDEX, req, resp);

        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error al cargar panel de asistencia", e);
            req.setAttribute("errorMsg", "Error al cargar el panel. Intenta nuevamente.");
            irA(ViewRoutes.ATTENDANCE_INDEX, req, resp);
        }
    }

    // ─── GET: historial de asistencia (RF-05) ────────────────────────────────

    /**
     * Historial filtrado. Todos los filtros son opcionales.
     * Parámetros: clienteId, desde (YYYY-MM-DD), hasta (YYYY-MM-DD)
     */
    private void mostrarHistorial(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String clienteId  = param(req, "clienteId");
        String desdeStr   = param(req, "desde");
        String hastaStr   = param(req, "hasta");

        LocalDate desde = parseFecha(desdeStr);
        LocalDate hasta = parseFecha(hastaStr);

        try {
            List<Asistencia> historial =
                    asistenciaDAO.filter(clienteId, desde, hasta);

            // Cargar lista de clientes para el select del filtro
            req.setAttribute("clientes",   clienteDAO.findAll());
            req.setAttribute("historial",  historial);
            req.setAttribute("clienteId",  clienteId);
            req.setAttribute("desde",      desdeStr);
            req.setAttribute("hasta",      hastaStr);
            req.setAttribute("totalFiltro", historial.size());

            irA(ViewRoutes.ATTENDANCE_INDEX, req, resp);

        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error al cargar historial de asistencia", e);
            req.setAttribute("errorMsg", "Error al cargar el historial.");
            irA(ViewRoutes.ATTENDANCE_INDEX, req, resp);
        }
    }

    // ─── POST: check-in por documento (RF-04) ────────────────────────────────

    /**
     * Registra el ingreso de un cliente.
     * Usa el patrón Post-Redirect-Get para evitar reenvío del formulario.
     *
     * Flujo:
     *   1. Leer numeroDocumento del formulario.
     *   2. Delegar a AsistenciaService.registrarCheckIn().
     *   3. Guardar resultado en flash message.
     *   4. Redirigir a GET /attendance para mostrar el resultado.
     */
    private void procesarCheckIn(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {

        String numeroDocumento = param(req, "numeroDocumento");

        if (numeroDocumento == null) {
            mensajeError(req, "Ingresa el número de documento del cliente.");
            redirigirA("/attendance", req, resp);
            return;
        }

        AsistenciaService.ResultadoCheckIn resultado =
                asistenciaService.registrarCheckIn(numeroDocumento);

        // Guardar el resultado en sesión para mostrarlo después del redirect
        if (resultado.isExitoso()) {
            mensajeExito(req, resultado.getMensaje());
            // También guardar datos del cliente para el widget de confirmación
            req.getSession(true).setAttribute("checkInCliente",
                    resultado.getCliente() != null
                            ? resultado.getCliente().getNombreCompleto() : "");
            req.getSession(true).setAttribute("checkInMembresia",
                    resultado.getContrato() != null
                    && resultado.getContrato().getMembresia() != null
                            ? resultado.getContrato().getMembresia().getNombreMembresia()
                            : "");
        } else {
            // Mapear el tipo de resultado a un mensaje de color/icono en la vista
            req.getSession(true).setAttribute("checkInTipo",
                    resultado.getTipo().name());
            mensajeError(req, resultado.getMensaje());
        }

        redirigirA("/attendance", req, resp);
    }

    // ─── Helper privado ───────────────────────────────────────────────────────

    /**
     * Parsea una fecha en formato ISO (YYYY-MM-DD).
     * Devuelve null si el string es nulo, vacío o tiene formato inválido.
     */
    private LocalDate parseFecha(String fechaStr) {
        if (fechaStr == null || fechaStr.isBlank()) return null;
        try {
            return LocalDate.parse(fechaStr);
        } catch (Exception e) {
            return null;
        }
    }
}