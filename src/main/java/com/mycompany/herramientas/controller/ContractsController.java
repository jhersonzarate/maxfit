package com.mycompany.herramientas.controller;

import com.mycompany.herramientas.config.AppConfig;
import com.mycompany.herramientas.dao.CatalogoDAO;
import com.mycompany.herramientas.dao.ClienteDAO;
import com.mycompany.herramientas.dao.ContratoDAO;
import com.mycompany.herramientas.dao.EmpleadoDAO;
import com.mycompany.herramientas.dao.IdGenerator;
import com.mycompany.herramientas.dao.MembresiaDAO;
import com.mycompany.herramientas.dao.UsuarioDAO;
import com.mycompany.herramientas.model.Cliente;
import com.mycompany.herramientas.model.Contrato;
import com.mycompany.herramientas.model.Empleado;
import com.mycompany.herramientas.model.Membresia;
import com.mycompany.herramientas.model.MetodoPago;
import com.mycompany.herramientas.model.Usuario;
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

// controlador de gestión de contratos
@WebServlet("/contracts")
public class ContractsController extends AbstractController {

    private static final Logger LOGGER =
            Logger.getLogger(ContractsController.class.getName());

    // DAOs y services del módulo
    private final ContratoService contratoService = new ContratoService();
    private final ContratoDAO     contratoDAO     = new ContratoDAO();
    private final ClienteDAO      clienteDAO      = new ClienteDAO();
    private final MembresiaDAO    membresiaDAO    = new MembresiaDAO();
    private final EmpleadoDAO     empleadoDAO     = new EmpleadoDAO();
    private final CatalogoDAO     catalogoDAO     = new CatalogoDAO();
    private final UsuarioDAO      usuarioDAO      = new UsuarioDAO();

    // ─── GET ─────────────────────────────────────────────

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        // paso mensajes flash al request
        transferirFlashMessages(req);

        // actualizo contratos vencidos automáticamente
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

    // ─── POST ────────────────────────────────────────────

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

    // ─── mostrar lista de contratos ─────────────────────

    private void mostrarLista(HttpServletRequest req,
                              HttpServletResponse resp)
            throws ServletException, IOException {

        String clienteId = param(req, "clienteId");

        try {

            List<Contrato> contratos;

            // filtro por cliente si viene el parámetro
            if (clienteId != null) {

                contratos = contratoDAO.findByClienteId(clienteId);

                Cliente cliente = clienteDAO.findById(clienteId);

                req.setAttribute("clienteFiltro", cliente);

            } else {

                contratos = contratoDAO.findAll();
            }

            req.setAttribute("contratos", contratos);

            req.setAttribute(
                    "totalContratos",
                    contratos.size()
            );

            req.setAttribute(
                    "countActivos",
                    contratoDAO.countActivos()
            );

            irA(ViewRoutes.CONTRACTS_INDEX, req, resp);

        } catch (SQLException e) {

            LOGGER.log(
                    Level.SEVERE,
                    "Error al listar contratos",
                    e
            );

            req.setAttribute(
                    "errorMsg",
                    "Error al cargar los contratos."
            );

            irA(ViewRoutes.CONTRACTS_INDEX, req, resp);
        }
    }

    // ─── mostrar formulario de nuevo contrato ───────────

    private void mostrarFormularioNuevo(HttpServletRequest req,
                                        HttpServletResponse resp)
            throws ServletException, IOException {

        String clienteId = param(req, "clienteId");

        try {

            cargarDatosFormulario(req);

            // si viene clienteId -> preselecciono cliente
            if (clienteId != null) {

                Cliente cliente =
                        clienteDAO.findById(clienteId);

                req.setAttribute(
                        "clientePreseleccionado",
                        cliente
                );
            }

            irA(
                    ViewRoutes.CONTRACTS_INDEX + "?form=true",
                    req,
                    resp
            );

        } catch (SQLException e) {

            LOGGER.log(
                    Level.SEVERE,
                    "Error al cargar formulario de contrato",
                    e
            );

            mensajeError(req, "Error al cargar el formulario.");

            redirigirA("/contracts", req, resp);
        }
    }

    // ─── mostrar detalle del contrato ───────────────────

    private void mostrarDetalle(HttpServletRequest req,
                                HttpServletResponse resp)
            throws ServletException, IOException {

        String id = param(req, "id");

        if (id == null) {

            mensajeError(req,
                    "ID de contrato no especificado.");

            redirigirA("/contracts", req, resp);

            return;
        }

        try {

            Contrato contrato = contratoDAO.findById(id);

            // si el contrato no existe
            if (contrato == null) {

                mensajeError(
                        req,
                        "No se encontró el contrato con ID: " + id
                );

                redirigirA("/contracts", req, resp);

                return;
            }

            req.setAttribute("contrato", contrato);

            irA(
                    ViewRoutes.CONTRACTS_INDEX + "?detail=true",
                    req,
                    resp
            );

        } catch (SQLException e) {

            LOGGER.log(
                    Level.SEVERE,
                    "Error al cargar detalle del contrato: " + id,
                    e
            );

            mensajeError(req, "Error al cargar el contrato.");

            redirigirA("/contracts", req, resp);
        }
    }

    // ─── guardar contrato ───────────────────────────────

    private void guardarContrato(HttpServletRequest req,
                                 HttpServletResponse resp)
            throws ServletException, IOException {

        // leo datos del formulario
        String clienteId      = param(req, "clienteId");
        String membresiaId    = param(req, "membresiaId");
        String metodoPagoId   = param(req, "metodoPagoId");
        String fechaInicioStr = param(req, "fechaInicio");
        String montoStr       = param(req, "montoPagado");

        // validar campos obligatorios
        if (clienteId == null
                || membresiaId == null
                || metodoPagoId == null
                || fechaInicioStr == null
                || montoStr == null) {

            volverAlFormularioConError(
                    req,
                    resp,
                    "Todos los campos son obligatorios."
            );

            return;
        }

        LocalDate fechaInicio;

        try {

            fechaInicio = LocalDate.parse(fechaInicioStr);

        } catch (DateTimeParseException e) {

            volverAlFormularioConError(
                    req,
                    resp,
                    "El formato de fecha no es válido."
            );

            return;
        }

        BigDecimal montoPagado;

        try {

            montoPagado = new BigDecimal(
                    montoStr.trim().replace(",", ".")
            );

            // monto negativo no permitido
            if (montoPagado.compareTo(BigDecimal.ZERO) < 0) {

                volverAlFormularioConError(
                        req,
                        resp,
                        "El monto pagado no puede ser negativo."
                );

                return;
            }

        } catch (NumberFormatException e) {

            volverAlFormularioConError(
                    req,
                    resp,
                    "El monto ingresado no es válido."
            );

            return;
        }

        try {

            Cliente cliente =
                    clienteDAO.findById(clienteId);

            if (cliente == null) {

                volverAlFormularioConError(
                        req,
                        resp,
                        "El cliente seleccionado no existe."
                );

                return;
            }

            Membresia membresia =
                    membresiaDAO.findById(membresiaId);

            if (membresia == null) {

                volverAlFormularioConError(
                        req,
                        resp,
                        "La membresía seleccionada no existe."
                );

                return;
            }

            MetodoPago metodoPago = null;

            // buscar método de pago activo
            for (MetodoPago mp :
                    catalogoDAO.findMetodosPagoActivos()) {

                if (mp.getId().equals(metodoPagoId)) {

                    metodoPago = mp;

                    break;
                }
            }

            if (metodoPago == null) {

                volverAlFormularioConError(
                        req,
                        resp,
                        "El método de pago no está activo."
                );

                return;
            }

            // obtengo empleado desde la sesión
            Empleado empleado =
                    empleadoDAO.findById(
                            getEmpleadoIdDeSesion(req)
                    );

            if (empleado == null) {

                volverAlFormularioConError(
                        req,
                        resp,
                        "No se pudo identificar al empleado responsable."
                );

                return;
            }

            // construyo el contrato
            Contrato contrato = new Contrato();

            contrato.setId(IdGenerator.parContrato());

            contrato.setCliente(cliente);

            contrato.setMembresia(membresia);

            contrato.setEmpleado(empleado);

            contrato.setMetodoPago(metodoPago);

            contrato.setFechaInicio(fechaInicio);

            contrato.setMontoPagado(montoPagado);

            contrato.setEstado(AppConfig.CONTRATO_ACTIVO);

            // lógica de negocio en el service
            ContratoService.Resultado resultado =
                    contratoService.crearContrato(contrato);

            if (resultado.isExitoso()) {

                LOGGER.info(
                        "Contrato creado: "
                                + contrato.getId()
                                + " | cliente: "
                                + clienteId
                );

                mensajeExito(
                        req,
                        resultado.getMensaje()
                );

                redirigirA("/contracts", req, resp);

            } else {

                volverAlFormularioConError(
                        req,
                        resp,
                        resultado.getMensaje()
                );
            }

        } catch (SQLException e) {

            LOGGER.log(
                    Level.SEVERE,
                    "Error al guardar contrato",
                    e
            );

            volverAlFormularioConError(
                    req,
                    resp,
                    "Error al guardar el contrato."
            );
        }
    }

    // ─── cancelar contrato ──────────────────────────────

    private void cancelarContrato(HttpServletRequest req,
                                  HttpServletResponse resp)
            throws IOException {

        // solo admin puede cancelar
        if (!esAdmin(req)) {

            forbidden(resp);

            return;
        }

        String id = param(req, "id");

        if (id == null) {

            mensajeError(
                    req,
                    "ID de contrato no especificado."
            );

            redirigirA("/contracts", req, resp);

            return;
        }

        ContratoService.Resultado resultado =
                contratoService.cancelarContrato(id);

        if (resultado.isExitoso()) {

            mensajeExito(
                    req,
                    resultado.getMensaje()
            );

        } else {

            mensajeError(
                    req,
                    resultado.getMensaje()
            );
        }

        redirigirA("/contracts", req, resp);
    }

    // ─── helpers privados ───────────────────────────────

    // cargo datos necesarios para el formulario
    private void cargarDatosFormulario(HttpServletRequest req)
            throws SQLException {

        req.setAttribute(
                "clientes",
                clienteDAO.findAll()
        );

        req.setAttribute(
                "membresias",
                membresiaDAO.findAll()
        );

        req.setAttribute(
                "metodosPago",
                catalogoDAO.findMetodosPagoActivos()
        );

        req.setAttribute(
                "fechaHoy",
                LocalDate.now().toString()
        );
    }

    // recargo formulario manteniendo el mensaje de error
    private void volverAlFormularioConError(HttpServletRequest req,
                                            HttpServletResponse resp,
                                            String errorMsg)
            throws ServletException, IOException {

        try {

            cargarDatosFormulario(req);

        } catch (SQLException e) {

            LOGGER.log(
                    Level.WARNING,
                    "Error recargando formulario de contrato",
                    e
            );
        }

        // formError: atributo exclusivo para errores inline en el formulario
        // (no lo renderiza el navbar, evita la duplicación del mensaje)
        req.setAttribute("formError", errorMsg);

        irA(
                ViewRoutes.CONTRACTS_INDEX + "?form=true",
                req,
                resp
        );
    }

    // obtengo el empleado vinculado al usuario logueado
    private String getEmpleadoIdDeSesion(HttpServletRequest req) {

        try {

            String userId = getSessionUserId(req);

            if (userId == null) return null;

            Usuario usuario =
                    usuarioDAO.findById(userId);

            // si el usuario tiene empleado asociado
            if (usuario != null
                    && usuario.getEmpleado() != null) {

                return usuario.getEmpleado().getId();
            }

        } catch (SQLException e) {

            LOGGER.log(
                    Level.WARNING,
                    "No se pudo obtener empleado de sesión",
                    e
            );
        }

        return null;
    }
}