package com.mycompany.herramientas.controller;

import com.mycompany.herramientas.config.AppConfig;
import com.mycompany.herramientas.dao.CatalogoDAO;
import com.mycompany.herramientas.dao.ClienteDAO;
import com.mycompany.herramientas.dao.ContratoDAO;
import com.mycompany.herramientas.dao.EmpleadoDAO;
import com.mycompany.herramientas.dao.IdGenerator;
import com.mycompany.herramientas.dao.MembresiaDAO;
import com.mycompany.herramientas.model.Cliente;
import com.mycompany.herramientas.model.Contrato;
import com.mycompany.herramientas.model.Empleado;
import com.mycompany.herramientas.model.Membresia;
import com.mycompany.herramientas.model.MetodoPago;
import com.mycompany.herramientas.service.ContratoService;
import com.mycompany.herramientas.view.ViewRoutes;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.math.BigDecimal;
import java.sql.SQLException;
import java.time.LocalDate;
import java.time.format.DateTimeParseException;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * Controlador de Gestión de Contratos (RF-03).
 *
 * Rutas y acciones:
 *   GET  /contracts                     → lista de contratos
 *   GET  /contracts?action=new          → formulario de nuevo contrato
 *   GET  /contracts?action=new&clienteId=CLI-XXXX → formulario pre-cargado con cliente
 *   GET  /contracts?action=view&id=CON-XXXX → detalle del contrato
 *   POST /contracts?action=save         → registrar nuevo contrato
 *   POST /contracts?action=cancel&id=CON-XXXX → cancelar contrato (solo Admin)
 *
 * Acceso:
 *   ROL-ADMIN  → CRUD completo + cancelar contratos
 *   ROL-RECEP  → solo crear y ver contratos (no cancelar)
 *
 * Reglas de negocio (delegadas a ContratoService):
 *   - Un cliente no puede tener dos contratos activos simultáneos.
 *   - fecha_fin = fecha_inicio + duracion_meses de la membresía.
 *   - Solo el Admin puede cancelar contratos.
 *
 * @author MaxFit
 */
@WebServlet("/contracts")
public class ContractsController extends AbstractController {

    private static final Logger LOGGER =
            Logger.getLogger(ContractsController.class.getName());

    private final ContratoService contratoService = new ContratoService();
    private final ContratoDAO     contratoDAO     = new ContratoDAO();
    private final ClienteDAO      clienteDAO      = new ClienteDAO();
    private final MembresiaDAO    membresiaDAO    = new MembresiaDAO();
    private final EmpleadoDAO     empleadoDAO     = new EmpleadoDAO();
    private final CatalogoDAO     catalogoDAO     = new CatalogoDAO();

    // ─── GET ──────────────────────────────────────────────────────────────────

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        transferirFlashMessages(req);

        // Actualizar contratos vencidos en cada carga (sin job scheduler)
        contratoService.actualizarVencidos();

        String action = getAction(req);

        switch (action) {
            case "new":
                mostrarFormularioNuevo(req, resp);
                break;
            case "view":
                mostrarDetalle(req, resp);
                break;
            default:
                mostrarLista(req, resp);
        }
    }

    // ─── POST ─────────────────────────────────────────────────────────────────

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String action = getAction(req);

        switch (action) {
            case "save":
                guardarContrato(req, resp);
                break;
            case "cancel":
                cancelarContrato(req, resp);
                break;
            default:
                redirigirA("/contracts", req, resp);
        }
    }

    // ─── GET: lista de contratos ──────────────────────────────────────────────

    private void mostrarLista(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        // Filtro opcional por cliente
        String clienteId = param(req, "clienteId");

        try {
            List<Contrato> contratos;
            if (clienteId != null) {
                contratos = contratoDAO.findByClienteId(clienteId);
                // Pasar el cliente para mostrar su nombre en el título
                Cliente cliente = clienteDAO.findById(clienteId);
                req.setAttribute("clienteFiltro", cliente);
            } else {
                contratos = contratoDAO.findAll();
            }

            req.setAttribute("contratos",    contratos);
            req.setAttribute("totalContratos", contratos.size());
            req.setAttribute("countActivos", contratoDAO.countActivos());

            irA(ViewRoutes.CONTRACTS_INDEX, req, resp);

        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error al listar contratos", e);
            req.setAttribute("errorMsg", "Error al cargar los contratos.");
            irA(ViewRoutes.CONTRACTS_INDEX, req, resp);
        }
    }

    // ─── GET: formulario de nuevo contrato ───────────────────────────────────

    private void mostrarFormularioNuevo(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        // Si viene con clienteId → pre-cargar el cliente
        String clienteId = param(req, "clienteId");

        try {
            cargarDatosFormulario(req);

            if (clienteId != null) {
                Cliente cliente = clienteDAO.findById(clienteId);
                req.setAttribute("clientePreseleccionado", cliente);
            }

            irA(ViewRoutes.CONTRACTS_INDEX + "?form=true", req, resp);

        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error al cargar formulario de contrato", e);
            mensajeError(req, "Error al cargar el formulario.");
            redirigirA("/contracts", req, resp);
        }
    }

    // ─── GET: detalle del contrato ────────────────────────────────────────────

    private void mostrarDetalle(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String id = param(req, "id");
        if (id == null) {
            mensajeError(req, "ID de contrato no especificado.");
            redirigirA("/contracts", req, resp);
            return;
        }

        try {
            Contrato contrato = contratoDAO.findById(id);
            if (contrato == null) {
                mensajeError(req, "No se encontró el contrato con ID: " + id);
                redirigirA("/contracts", req, resp);
                return;
            }

            req.setAttribute("contrato", contrato);
            irA(ViewRoutes.CONTRACTS_INDEX + "?detail=true", req, resp);

        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error al cargar detalle del contrato: " + id, e);
            mensajeError(req, "Error al cargar el contrato.");
            redirigirA("/contracts", req, resp);
        }
    }

    // ─── POST: guardar nuevo contrato ─────────────────────────────────────────

    private void guardarContrato(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        // Leer parámetros
        String clienteId     = param(req, "clienteId");
        String membresiaId   = param(req, "membresiaId");
        String metodoPagoId  = param(req, "metodoPagoId");
        String fechaInicioStr = param(req, "fechaInicio");
        String montoStr      = param(req, "montoPagado");

        // ── Validaciones de campos obligatorios ──────────────────────────────
        if (clienteId == null || membresiaId == null
                || metodoPagoId == null || fechaInicioStr == null || montoStr == null) {
            volverAlFormularioConError(req, resp, "Todos los campos son obligatorios.");
            return;
        }

        // ── Parsear fecha inicio ─────────────────────────────────────────────
        LocalDate fechaInicio;
        try {
            fechaInicio = LocalDate.parse(fechaInicioStr);
        } catch (DateTimeParseException e) {
            volverAlFormularioConError(req, resp,
                    "El formato de fecha no es válido (usa YYYY-MM-DD).");
            return;
        }

        // ── Parsear monto ────────────────────────────────────────────────────
        BigDecimal montoPagado;
        try {
            montoPagado = new BigDecimal(montoStr.trim().replace(",", "."));
            if (montoPagado.compareTo(BigDecimal.ZERO) < 0) {
                volverAlFormularioConError(req, resp,
                        "El monto pagado no puede ser negativo.");
                return;
            }
        } catch (NumberFormatException e) {
            volverAlFormularioConError(req, resp,
                    "El monto ingresado no es válido.");
            return;
        }

        try {
            // ── Cargar entidades relacionadas ─────────────────────────────────
            Cliente cliente = clienteDAO.findById(clienteId);
            if (cliente == null) {
                volverAlFormularioConError(req, resp, "El cliente seleccionado no existe.");
                return;
            }

            Membresia membresia = membresiaDAO.findById(membresiaId);
            if (membresia == null) {
                volverAlFormularioConError(req, resp, "La membresía seleccionada no existe.");
                return;
            }

            MetodoPago metodoPago = null;
            for (MetodoPago mp : catalogoDAO.findMetodosPagoActivos()) {
                if (mp.getId().equals(metodoPagoId)) {
                    metodoPago = mp;
                    break;
                }
            }
            if (metodoPago == null) {
                volverAlFormularioConError(req, resp, "El método de pago no está activo.");
                return;
            }

            // El empleado responsable es el usuario en sesión
            Empleado empleado = empleadoDAO.findById(
                    getEmpleadoIdDeSesion(req));
            if (empleado == null) {
                volverAlFormularioConError(req, resp,
                        "No se pudo identificar al empleado responsable.");
                return;
            }

            // ── Construir contrato ────────────────────────────────────────────
            Contrato contrato = new Contrato();
            contrato.setId(IdGenerator.parContrato());
            contrato.setCliente(cliente);
            contrato.setMembresia(membresia);
            contrato.setEmpleado(empleado);
            contrato.setMetodoPago(metodoPago);
            contrato.setFechaInicio(fechaInicio);
            // fecha_fin la calcula ContratoService
            contrato.setMontoPagado(montoPagado);
            contrato.setEstado(AppConfig.CONTRATO_ACTIVO);

            // ── Delegar al servicio (verifica contrato activo existente) ───────
            ContratoService.Resultado resultado =
                    contratoService.crearContrato(contrato);

            if (resultado.isExitoso()) {
                LOGGER.info("Contrato creado: " + contrato.getId()
                        + " | cliente: " + clienteId);
                mensajeExito(req, resultado.getMensaje());
                redirigirA("/contracts", req, resp);
            } else {
                volverAlFormularioConError(req, resp, resultado.getMensaje());
            }

        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error al guardar contrato", e);
            volverAlFormularioConError(req, resp,
                    "Error al guardar el contrato. Intenta nuevamente.");
        }
    }

    // ─── POST: cancelar contrato (solo Admin) ────────────────────────────────

    private void cancelarContrato(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {

        // Solo Admin puede cancelar contratos (RF-03)
        if (!esAdmin(req)) {
            forbidden(resp);
            return;
        }

        String id = param(req, "id");
        if (id == null) {
            mensajeError(req, "ID de contrato no especificado.");
            redirigirA("/contracts", req, resp);
            return;
        }

        ContratoService.Resultado resultado = contratoService.cancelarContrato(id);

        if (resultado.isExitoso()) {
            mensajeExito(req, resultado.getMensaje());
        } else {
            mensajeError(req, resultado.getMensaje());
        }

        redirigirA("/contracts", req, resp);
    }

    // ─── Helpers privados ─────────────────────────────────────────────────────

    /**
     * Carga los datos necesarios para el formulario de nuevo contrato.
     * Centralizado para usarse tanto en mostrarFormularioNuevo como en
     * volverAlFormularioConError.
     */
    private void cargarDatosFormulario(HttpServletRequest req) throws SQLException {
        req.setAttribute("clientes",       clienteDAO.findAll());
        req.setAttribute("membresias",     membresiaDAO.findAll());
        req.setAttribute("metodosPago",    catalogoDAO.findMetodosPagoActivos());
        req.setAttribute("fechaHoy",       LocalDate.now().toString());
    }

    /**
     * Recarga el formulario con el mensaje de error.
     */
    private void volverAlFormularioConError(HttpServletRequest req,
                                             HttpServletResponse resp,
                                             String errorMsg)
            throws ServletException, IOException {
        try {
            cargarDatosFormulario(req);
        } catch (SQLException e) {
            LOGGER.log(Level.WARNING, "Error recargando formulario de contrato", e);
        }
        req.setAttribute("errorMsg", errorMsg);
        irA(ViewRoutes.CONTRACTS_INDEX + "?form=true", req, resp);
    }

    /**
     * Obtiene el ID del empleado vinculado al usuario en sesión.
     * Se usa para asignar el empleado responsable del contrato.
     */
    private String getEmpleadoIdDeSesion(HttpServletRequest req) {
        // El userId de sesión es el ID del Usuario (USR-XXXX).
        // Necesitamos el id del Empleado vinculado.
        // Como no lo guardamos directamente en sesión, lo obtenemos del userId.
        // Esta consulta es O(1) — solo si el usuario tiene empleado vinculado.
        // Si no tiene empleado (caso extremo), devuelve null y el controlador
        // mostrará un error amigable.
        try {
            String userId = getSessionUserId(req);
            if (userId == null) return null;
            // Obtener el empleado_id a través del UsuarioDAO
            com.mycompany.herramientas.dao.UsuarioDAO usuarioDAO =
                    new com.mycompany.herramientas.dao.UsuarioDAO();
            com.mycompany.herramientas.model.Usuario usuario =
                    usuarioDAO.findById(userId);
            if (usuario != null && usuario.getEmpleado() != null) {
                return usuario.getEmpleado().getId();
            }
        } catch (SQLException e) {
            LOGGER.log(Level.WARNING, "No se pudo obtener empleado de sesión", e);
        }
        return null;
    }
}