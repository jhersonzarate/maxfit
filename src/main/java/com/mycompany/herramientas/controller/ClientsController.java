package com.mycompany.herramientas.controller;

import com.mycompany.herramientas.dao.CatalogoDAO;
import com.mycompany.herramientas.dao.ClienteDAO;
import com.mycompany.herramientas.dao.ContratoDAO;
import com.mycompany.herramientas.model.Cliente;
import com.mycompany.herramientas.model.TipoDocumento;
import com.mycompany.herramientas.service.DocumentoValidator;
import com.mycompany.herramientas.view.ViewRoutes;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.SQLIntegrityConstraintViolationException;
import java.time.LocalDate;
import java.time.format.DateTimeParseException;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * Controlador de gestión de clientes (RF-01).
 *
 * GET  /clients             → lista todos los clientes (con búsqueda opcional ?q=)
 * GET  /clients?action=new  → formulario de nuevo cliente
 * GET  /clients?action=edit&id=X → formulario de edición
 * GET  /clients?action=detail&id=X → perfil del cliente (contratos + asistencias)
 * POST /clients             → crear o actualizar cliente
 * POST /clients?action=delete&id=X → eliminar cliente (solo Admin)
 *
 * Patrón PRG: después de POST exitoso → redirect con ?success=mensaje
 *
 * Permisos según el documento:
 *   Admin      → CRUD completo (incluyendo eliminar)
 *   Recepción  → crear + editar, NO eliminar
 */
public class ClientsController extends AbstractController {

    private static final Logger LOGGER = Logger.getLogger(ClientsController.class.getName());

    private final ClienteDAO  clienteDAO  = new ClienteDAO();
    private final CatalogoDAO catalogoDAO = new CatalogoDAO();
    private final ContratoDAO contratoDAO = new ContratoDAO();

    // ── GET ──────────────────────────────────────────────────────────────────

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String action = param(req, "action");

        if ("new".equals(action)) {
            mostrarFormularioNuevo(req, resp);
        } else if ("edit".equals(action)) {
            mostrarFormularioEdicion(req, resp);
        } else if ("detail".equals(action)) {
            mostrarDetalle(req, resp);
        } else {
            mostrarLista(req, resp);
        }
    }

    // ── POST ─────────────────────────────────────────────────────────────────

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String action = param(req, "action");

        if ("delete".equals(action)) {
            eliminarCliente(req, resp);
        } else {
            guardarCliente(req, resp);
        }
    }

    // ── Handlers ─────────────────────────────────────────────────────────────

    private void mostrarLista(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String query = param(req, "q");
        try {
            if (query != null) {
                req.setAttribute("clientes", clienteDAO.search(query));
                req.setAttribute("queryBusqueda", query);
            } else {
                req.setAttribute("clientes", clienteDAO.findAll());
            }
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Error al listar clientes", e);
            setError(req, "Error al cargar la lista de clientes.");
        }

        readSuccessParam(req);
        req.setAttribute("paginaTitulo", "Gestión de Clientes");
        forward(req, resp, ViewRoutes.CLIENTS_INDEX);
    }

    private void mostrarFormularioNuevo(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        try {
            req.setAttribute("tiposDocumento", catalogoDAO.listTipoDocumentos());
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Error al cargar tipos de documento", e);
            setError(req, "Error al cargar el formulario.");
        }
        req.setAttribute("modoEdicion", false);
        req.setAttribute("paginaTitulo", "Nuevo Cliente");
        forward(req, resp, ViewRoutes.CLIENTS_INDEX);
    }

    private void mostrarFormularioEdicion(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        String id = param(req, "id");
        if (id == null) { redirect(req, resp, "/clients"); return; }

        try {
            Cliente cliente = clienteDAO.findById(id);
            if (cliente == null) { redirect(req, resp, "/clients"); return; }

            req.setAttribute("clienteEditar", cliente);
            req.setAttribute("tiposDocumento", catalogoDAO.listTipoDocumentos());
            req.setAttribute("modoEdicion", true);
            req.setAttribute("paginaTitulo", "Editar Cliente — " + cliente.getNombreCompleto());
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Error al cargar cliente para edición: " + id, e);
            setError(req, "Error al cargar los datos del cliente.");
        }
        forward(req, resp, ViewRoutes.CLIENTS_INDEX);
    }

    private void mostrarDetalle(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        String id = param(req, "id");
        if (id == null) { redirect(req, resp, "/clients"); return; }

        try {
            Cliente cliente = clienteDAO.findById(id);
            if (cliente == null) { redirect(req, resp, "/clients"); return; }

            req.setAttribute("cliente", cliente);
            req.setAttribute("contratos", contratoDAO.findByClienteId(id));
            req.setAttribute("paginaTitulo", "Perfil — " + cliente.getNombreCompleto());
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Error al cargar detalle del cliente: " + id, e);
            setError(req, "Error al cargar el perfil del cliente.");
        }
        forward(req, resp, ViewRoutes.CLIENT_DETAIL);
    }

    private void guardarCliente(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String id              = param(req, "id");          // null = nuevo
        String tipoDocId       = param(req, "tipoDocumentoId");
        String numeroDoc       = param(req, "numeroDocumento");
        String nombre          = param(req, "nombre");
        String apellido        = param(req, "apellido");
        String email           = param(req, "email");
        String telefono        = param(req, "telefono");
        String fechaNacStr     = param(req, "fechaNacimiento");
        String genero          = param(req, "genero");

        // Validaciones básicas
        if (nombre == null || apellido == null || tipoDocId == null || numeroDoc == null) {
            setError(req, "Nombre, apellido, tipo y número de documento son obligatorios.");
            try {
                req.setAttribute("tiposDocumento", catalogoDAO.listTipoDocumentos());
            } catch (Exception ignored) {}
            req.setAttribute("modoEdicion", id != null);
            forward(req, resp, ViewRoutes.CLIENTS_INDEX);
            return;
        }

        // Validar documento según las reglas del TipoDocumento (RF-07)
        try {
            TipoDocumento td = catalogoDAO.findTipoDocumentoById(tipoDocId);
            if (td == null) {
                setError(req, "Tipo de documento no válido.");
                req.setAttribute("tiposDocumento", catalogoDAO.listTipoDocumentos());
                req.setAttribute("modoEdicion", id != null);
                forward(req, resp, ViewRoutes.CLIENTS_INDEX);
                return;
            }

            DocumentoValidator.ResultadoValidacion rv =
                    DocumentoValidator.validar(td, numeroDoc);
            if (!rv.isValido()) {
                setError(req, rv.getMensaje());
                req.setAttribute("tiposDocumento", catalogoDAO.listTipoDocumentos());
                req.setAttribute("modoEdicion", id != null);
                forward(req, resp, ViewRoutes.CLIENTS_INDEX);
                return;
            }

            // Construir objeto Cliente
            Cliente cliente = new Cliente();
            if (id != null) cliente.setId(id);
            cliente.setNombre(nombre);
            cliente.setApellido(apellido);
            cliente.setTipoDocumento(td);
            cliente.setNumeroDocumento(numeroDoc);
            cliente.setEmail(email);
            cliente.setTelefono(telefono);
            cliente.setGenero(genero);

            if (fechaNacStr != null) {
                try {
                    cliente.setFechaNacimiento(LocalDate.parse(fechaNacStr));
                } catch (DateTimeParseException e) {
                    // fecha inválida → dejar en null
                }
            }

            clienteDAO.save(cliente);

            String msg = (id == null)
                    ? "Cliente registrado correctamente."
                    : "Cliente actualizado correctamente.";
            redirectWithParam(req, resp, "/clients", "success", msg);

        } catch (SQLIntegrityConstraintViolationException e) {
            LOGGER.log(Level.WARNING, "Documento o email duplicado al guardar cliente", e);
            setError(req, "El número de documento o correo ya está registrado en el sistema.");
            try { req.setAttribute("tiposDocumento", catalogoDAO.listTipoDocumentos()); }
            catch (Exception ignored) {}
            req.setAttribute("modoEdicion", id != null);
            forward(req, resp, ViewRoutes.CLIENTS_INDEX);

        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Error al guardar cliente", e);
            setError(req, "Error al guardar el cliente. Intenta nuevamente.");
            try { req.setAttribute("tiposDocumento", catalogoDAO.listTipoDocumentos()); }
            catch (Exception ignored) {}
            req.setAttribute("modoEdicion", id != null);
            forward(req, resp, ViewRoutes.CLIENTS_INDEX);
        }
    }

    private void eliminarCliente(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {

        // Solo el administrador puede eliminar clientes
        if (!esAdmin(req)) {
            try { forbidden(resp); } catch (Exception e) { redirect(req, resp, "/clients"); }
            return;
        }

        String id = param(req, "id");
        if (id == null) { redirect(req, resp, "/clients"); return; }

        try {
            clienteDAO.delete(id);
            redirectWithParam(req, resp, "/clients", "success", "Cliente eliminado correctamente.");
        } catch (SQLIntegrityConstraintViolationException e) {
            redirectWithParam(req, resp, "/clients", "error",
                    "No se puede eliminar el cliente porque tiene contratos o inscripciones asociadas.");
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Error al eliminar cliente: " + id, e);
            redirectWithParam(req, resp, "/clients", "error",
                    "Error al eliminar el cliente.");
        }
    }
}