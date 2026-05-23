package com.mycompany.herramientas.controller;

import com.mycompany.herramientas.dao.CatalogoDAO;
import com.mycompany.herramientas.dao.ClienteDAO;
import com.mycompany.herramientas.dao.ContratoDAO;
import com.mycompany.herramientas.dao.IdGenerator;
import com.mycompany.herramientas.dao.InscripcionDAO;
import com.mycompany.herramientas.dao.AsistenciaDAO;
import com.mycompany.herramientas.model.Cliente;
import com.mycompany.herramientas.model.TipoDocumento;
import com.mycompany.herramientas.service.DocumentoValidator;
import com.mycompany.herramientas.view.ViewRoutes;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.SQLException;
import java.time.LocalDate;
import java.time.format.DateTimeParseException;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * Controlador de Gestión de Clientes (RF-01).
 *
 * Rutas y acciones:
 *   GET  /clients              → lista de clientes (con búsqueda opcional ?q=)
 *   GET  /clients?action=new   → formulario de registro
 *   GET  /clients?action=edit&id=CLI-XXXX → formulario de edición
 *   GET  /clients?action=view&id=CLI-XXXX → detalle del cliente
 *   POST /clients?action=save  → crear o actualizar cliente
 *   POST /clients?action=delete&id=CLI-XXXX → eliminar cliente
 *
 * Acceso:
 *   ROL-ADMIN  → CRUD completo (crear, editar, eliminar, ver)
 *   ROL-RECEP  → solo lectura + crear (no puede eliminar ni editar)
 *
 * El RoleFilter ya garantizó que solo Admin y Recep llegan aquí.
 * Este controlador aplica la restricción fina por operación.
 *
 * Validaciones (RF-07 DocumentoValidator):
 *   - tipoDocumento requerido
 *   - numero_documento: longitud y formato según TipoDocumento
 *   - nombre y apellido: no vacíos
 *   - email: único en BD (la BD lanza error de integridad si hay duplicado)
 *
 * @author MaxFit
 */
@WebServlet("/clients")
public class ClientsController extends AbstractController {

    private static final Logger LOGGER =
            Logger.getLogger(ClientsController.class.getName());

    private final ClienteDAO     clienteDAO     = new ClienteDAO();
    private final CatalogoDAO    catalogoDAO    = new CatalogoDAO();
    private final ContratoDAO    contratoDAO    = new ContratoDAO();
    private final InscripcionDAO inscripcionDAO = new InscripcionDAO();
    private final AsistenciaDAO  asistenciaDAO  = new AsistenciaDAO();

    // ─── GET ──────────────────────────────────────────────────────────────────

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        // Transferir flash messages de sesión a atributos de request
        transferirFlashMessages(req);

        String action = getAction(req);

        switch (action) {
            case "new":
                mostrarFormularioNuevo(req, resp);
                break;
            case "edit":
                mostrarFormularioEdicion(req, resp);
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
                guardarCliente(req, resp);
                break;
            case "delete":
                eliminarCliente(req, resp);
                break;
            default:
                redirigirA("/clients", req, resp);
        }
    }

    // ─── GET: lista de clientes ───────────────────────────────────────────────

    private void mostrarLista(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String query = param(req, "q"); // parámetro de búsqueda libre

        try {
            List<Cliente> clientes = (query != null)
                    ? clienteDAO.search(query)
                    : clienteDAO.findAll();

            req.setAttribute("clientes", clientes);
            req.setAttribute("query", query);
            req.setAttribute("totalClientes", clientes.size());

            irA(ViewRoutes.CLIENTS_INDEX, req, resp);

        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error al listar clientes", e);
            req.setAttribute("errorMsg", "Error al cargar los clientes. Intenta nuevamente.");
            irA(ViewRoutes.CLIENTS_INDEX, req, resp);
        }
    }

    // ─── GET: formulario de nuevo cliente ────────────────────────────────────

    private void mostrarFormularioNuevo(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        try {
            req.setAttribute("tiposDocumento", catalogoDAO.findAllTipoDocumentos());
            req.setAttribute("modoEdicion", false);
            // cliente vacío para que el JSP no tenga que comprobar null
            req.setAttribute("cliente", new Cliente());
            irA(ViewRoutes.CLIENTS_INDEX + "?form=true", req, resp);

        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error al cargar formulario de cliente", e);
            mensajeError(req, "Error al cargar el formulario.");
            redirigirA("/clients", req, resp);
        }
    }

    // ─── GET: formulario de edición ───────────────────────────────────────────

    private void mostrarFormularioEdicion(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        // Solo Admin puede editar
        if (!esAdmin(req)) {
            forbidden(resp);
            return;
        }

        String id = param(req, "id");
        if (id == null) {
            mensajeError(req, "ID de cliente no especificado.");
            redirigirA("/clients", req, resp);
            return;
        }

        try {
            Cliente cliente = clienteDAO.findById(id);
            if (cliente == null) {
                mensajeError(req, "No se encontró el cliente con ID: " + id);
                redirigirA("/clients", req, resp);
                return;
            }

            req.setAttribute("cliente", cliente);
            req.setAttribute("tiposDocumento", catalogoDAO.findAllTipoDocumentos());
            req.setAttribute("modoEdicion", true);
            irA(ViewRoutes.CLIENTS_INDEX + "?form=true", req, resp);

        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error al cargar cliente para edición: " + id, e);
            mensajeError(req, "Error al cargar el cliente.");
            redirigirA("/clients", req, resp);
        }
    }

    // ─── GET: detalle de cliente ──────────────────────────────────────────────

    private void mostrarDetalle(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String id = param(req, "id");
        if (id == null) {
            mensajeError(req, "ID de cliente no especificado.");
            redirigirA("/clients", req, resp);
            return;
        }

        try {
            Cliente cliente = clienteDAO.findById(id);
            if (cliente == null) {
                mensajeError(req, "No se encontró el cliente con ID: " + id);
                redirigirA("/clients", req, resp);
                return;
            }

            // Cargar datos relacionados para la vista de detalle
            req.setAttribute("cliente",       cliente);
            req.setAttribute("contratos",     contratoDAO.findByClienteId(id));
            req.setAttribute("inscripciones", inscripcionDAO.findByClienteId(id));
            req.setAttribute("asistencias",   asistenciaDAO.findByClienteId(id));

            irA(ViewRoutes.CLIENT_DETAIL, req, resp);

        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error al cargar detalle del cliente: " + id, e);
            mensajeError(req, "Error al cargar el cliente.");
            redirigirA("/clients", req, resp);
        }
    }

    // ─── POST: guardar cliente (crear o actualizar) ───────────────────────────

    private void guardarCliente(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        // Leer parámetros del formulario
        String id              = param(req, "id");           // vacío si es nuevo
        String nombre          = param(req, "nombre");
        String apellido        = param(req, "apellido");
        String idTipoDoc       = param(req, "idTipoDocumento");
        String numeroDoc       = param(req, "numeroDocumento");
        String email           = param(req, "email");
        String telefono        = param(req, "telefono");
        String fechaNacStr     = param(req, "fechaNacimiento");
        String genero          = param(req, "genero");

        boolean esNuevo = (id == null || id.isBlank());

        // ── Verificar permisos: solo Admin puede editar, ambos pueden crear ──
        if (!esNuevo && !esAdmin(req)) {
            forbidden(resp);
            return;
        }

        // ── Validaciones básicas ─────────────────────────────────────────────
        if (nombre == null || apellido == null) {
            volverAlFormulario(req, resp, esNuevo, id,
                    "El nombre y apellido son obligatorios.");
            return;
        }

        if (idTipoDoc == null || numeroDoc == null) {
            volverAlFormulario(req, resp, esNuevo, id,
                    "Debe seleccionar un tipo de documento e ingresar el número.");
            return;
        }

        // ── Validar número de documento con DocumentoValidator (RF-07) ───────
        try {
            TipoDocumento tipoDoc = catalogoDAO.findTipoDocumentoById(idTipoDoc);
            if (tipoDoc == null) {
                volverAlFormulario(req, resp, esNuevo, id,
                        "El tipo de documento seleccionado no es válido.");
                return;
            }

            DocumentoValidator.ResultadoValidacion validacion =
                    DocumentoValidator.validar(tipoDoc, numeroDoc);
            if (!validacion.isValido()) {
                volverAlFormulario(req, resp, esNuevo, id, validacion.getMensaje());
                return;
            }

            // ── Construir el objeto Cliente ───────────────────────────────────
            Cliente cliente = new Cliente();

            if (esNuevo) {
                cliente.setId(IdGenerator.parCliente());
            } else {
                cliente.setId(id);
            }

            cliente.setNombre(nombre);
            cliente.setApellido(apellido);
            cliente.setTipoDocumento(tipoDoc);
            cliente.setNumeroDocumento(numeroDoc);
            cliente.setEmail(email);          // null si no se ingresó
            cliente.setTelefono(telefono);    // null si no se ingresó
            cliente.setGenero(esGeneroValido(genero) ? genero : null);

            // Parsear fecha de nacimiento (opcional)
            if (fechaNacStr != null && !fechaNacStr.isBlank()) {
                try {
                    cliente.setFechaNacimiento(LocalDate.parse(fechaNacStr));
                } catch (DateTimeParseException e) {
                    volverAlFormulario(req, resp, esNuevo, id,
                            "El formato de fecha de nacimiento no es válido (usa YYYY-MM-DD).");
                    return;
                }
            }

            // ── Persistir ────────────────────────────────────────────────────
            clienteDAO.save(cliente);

            String accion = esNuevo ? "registrado" : "actualizado";
            LOGGER.info("Cliente " + accion + ": " + cliente.getId()
                    + " | " + cliente.getNombreCompleto());

            mensajeExito(req, "Cliente " + cliente.getNombreCompleto()
                    + " " + accion + " correctamente.");
            redirigirA("/clients", req, resp);

        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error al guardar cliente", e);

            // Detectar violación de UNIQUE (email o número de documento duplicado)
            String msgError;
            if (e.getMessage() != null && e.getMessage().contains("UNIQUE")) {
                msgError = "El número de documento o email ya está registrado en el sistema.";
            } else {
                msgError = "Error al guardar el cliente. Intenta nuevamente.";
            }
            volverAlFormulario(req, resp, esNuevo, id, msgError);
        }
    }

    // ─── POST: eliminar cliente ───────────────────────────────────────────────

    private void eliminarCliente(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        // Solo Admin puede eliminar
        if (!esAdmin(req)) {
            forbidden(resp);
            return;
        }

        String id = param(req, "id");
        if (id == null) {
            mensajeError(req, "ID de cliente no especificado.");
            redirigirA("/clients", req, resp);
            return;
        }

        try {
            boolean eliminado = clienteDAO.delete(id);
            if (eliminado) {
                LOGGER.info("Cliente eliminado: " + id);
                mensajeExito(req, "Cliente eliminado correctamente.");
            } else {
                mensajeError(req, "No se encontró el cliente con ID: " + id);
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error al eliminar cliente: " + id, e);

            // La BD lanza error de FK si el cliente tiene contratos/inscripciones
            String msgError;
            if (e.getMessage() != null && e.getMessage().contains("REFERENCE")) {
                msgError = "No se puede eliminar el cliente porque tiene contratos "
                         + "o inscripciones registradas. Cancélalos primero.";
            } else {
                msgError = "Error al eliminar el cliente. Intenta nuevamente.";
            }
            mensajeError(req, msgError);
        }

        redirigirA("/clients", req, resp);
    }

    // ─── Helpers privados ─────────────────────────────────────────────────────

    /**
     * Recarga el formulario con el mensaje de error y los datos ingresados.
     * Evita que el usuario pierda lo que escribió.
     */
    private void volverAlFormulario(HttpServletRequest req,
                                     HttpServletResponse resp,
                                     boolean esNuevo,
                                     String id,
                                     String errorMsg)
            throws ServletException, IOException {

        req.setAttribute("errorMsg", errorMsg);
        req.setAttribute("modoEdicion", !esNuevo);

        try {
            req.setAttribute("tiposDocumento", catalogoDAO.findAllTipoDocumentos());

            // Si es edición, cargar el cliente original para no perder los datos
            if (!esNuevo && id != null) {
                Cliente clienteOriginal = clienteDAO.findById(id);
                req.setAttribute("cliente", clienteOriginal != null
                        ? clienteOriginal : new Cliente());
            } else {
                // Preservar los datos del formulario para no perderlos
                req.setAttribute("cliente", construirClienteDesdeRequest(req));
            }
        } catch (SQLException e) {
            LOGGER.log(Level.WARNING, "Error al recargar formulario de cliente", e);
        }

        irA(ViewRoutes.CLIENTS_INDEX + "?form=true", req, resp);
    }

    /**
     * Construye un objeto Cliente parcial con los datos del request.
     * Solo para pre-poblar el formulario en caso de error de validación.
     */
    private Cliente construirClienteDesdeRequest(HttpServletRequest req) {
        Cliente c = new Cliente();
        c.setNombre(param(req, "nombre", ""));
        c.setApellido(param(req, "apellido", ""));
        c.setNumeroDocumento(param(req, "numeroDocumento", ""));
        c.setEmail(param(req, "email"));
        c.setTelefono(param(req, "telefono"));
        String genero = param(req, "genero");
        c.setGenero(esGeneroValido(genero) ? genero : null);
        return c;
    }

    /**
     * Verifica que el género sea uno de los valores válidos del CHECK de la BD.
     * CHECK (genero IN ('Masculino','Femenino','Otro'))
     */
    private boolean esGeneroValido(String genero) {
        return "Masculino".equals(genero)
                || "Femenino".equals(genero)
                || "Otro".equals(genero);
    }
}