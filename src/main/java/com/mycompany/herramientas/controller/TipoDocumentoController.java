package com.mycompany.herramientas.controller;

import com.mycompany.herramientas.config.AppConfig;
import com.mycompany.herramientas.dao.CatalogoDAO;
import com.mycompany.herramientas.dao.ClienteDAO;
import com.mycompany.herramientas.dao.EmpleadoDAO;
import com.mycompany.herramientas.model.TipoDocumento;
import com.mycompany.herramientas.view.ViewRoutes;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.SQLException;
import java.util.logging.Level;
import java.util.logging.Logger;

@WebServlet("/tipodocumento")
public class TipoDocumentoController extends AbstractController {

    private static final Logger LOGGER = Logger.getLogger(TipoDocumentoController.class.getName());

    private final CatalogoDAO catalogoDAO = new CatalogoDAO();
    private final ClienteDAO clienteDAO = new ClienteDAO();
    private final EmpleadoDAO empleadoDAO = new EmpleadoDAO();

    @Override
    protected void doGet(HttpServletRequest req,
                         HttpServletResponse resp)
            throws ServletException, IOException {

        if (!esAdmin(req)) { forbidden(resp); return; }
        transferirFlashMessages(req);

        switch (getAction(req)) {
            default:     mostrarLista(req, resp);
        }
    }

    @Override
    protected void doPost(HttpServletRequest req,
            HttpServletResponse resp)
            throws ServletException, IOException {

        if (!esAdmin(req)) {
            forbidden(resp);
            return;
        }

        switch (getAction(req)) {
            case "save":
                guardar(req, resp);
                break;
            case "toggle":
                toggleEstado(req, resp);
                break;
            case "delete":
                eliminar(req, resp);
                break;
            default:
                redirigirA("/tipodocumento", req, resp);
        }
    }

    // ── Lista ──────────────────────────────────────────────────
    private void mostrarLista(HttpServletRequest req,
            HttpServletResponse resp)
            throws ServletException, IOException {
        try {
            req.setAttribute("tiposDocumento",
                    catalogoDAO.findAllTipoDocumentosConEstado());
            irA(ViewRoutes.TIPODOCUMENTO_INDEX, req, resp);
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error al cargar TipoDocumento", e);
            mensajeError(req, "Error al cargar tipos de documento.");
            irA(ViewRoutes.TIPODOCUMENTO_INDEX, req, resp);
        }
    }

    // ── Guardar ────────────────────────────────────────────────
    private void guardar(HttpServletRequest req,
            HttpServletResponse resp)
            throws ServletException, IOException {

        String id = param(req, "id");
        String nombre = param(req, "nombreDocumento");
        String abreviado = param(req, "abreviado");
        String tamMaxStr = param(req, "tamañoMax");
        String tamMinStr = param(req, "tamañoMin");
        String esAlfaStr = param(req, "esAlfanumerico");
        String estado = param(req, "estado", AppConfig.ESTADO_ACTIVO);
        boolean esNuevo = (id == null || id.isBlank());

        // Error de validación → vuelve a la lista con error
        if (nombre == null || nombre.isBlank()
                || abreviado == null || abreviado.isBlank()) {
            mensajeError(req, "Nombre y abreviado son obligatorios.");
            redirigirA("/tipodocumento", req, resp);
            return;
        }

        if (nombre.matches(".*\\d.*") || abreviado.matches(".*\\d.*")) {
            mensajeError(req, "El nombre y abreviado no pueden contener números.");
            redirigirA("/tipodocumento", req, resp);
            return;
        }

        if (abreviado.trim().length() > 3) {
            mensajeError(req, "El abreviado no puede tener más de 3 caracteres.");
            redirigirA("/tipodocumento", req, resp);
            return;
        }

        int tamMax, tamMin;
        try {
            tamMax = Integer.parseInt(tamMaxStr != null ? tamMaxStr.trim() : "");
            tamMin = Integer.parseInt(tamMinStr != null ? tamMinStr.trim() : "");
            if (tamMin <= 0 || tamMax <= 0 || tamMin > tamMax) {
                mensajeError(req, "Los tamaños deben ser positivos y min ≤ max.");
                redirigirA("/tipodocumento", req, resp);
                return;
            }
        } catch (NumberFormatException e) {
            mensajeError(req, "Tamaños inválidos.");
            redirigirA("/tipodocumento", req, resp);
            return;
        }

        TipoDocumento td = new TipoDocumento();
        if (esNuevo) {
            td.setId("TDOC-" + abreviado.trim()
                    .toUpperCase()
                    .replaceAll("[^A-Z0-9]", ""));
        } else {
            td.setId(id);
        }
        td.setNombreDocumento(nombre.trim());
        td.setAbreviado(abreviado.trim().toUpperCase());
        td.setTamañoMax(tamMax);
        td.setTamañoMin(tamMin);
        td.setEsAlfanumerico("on".equals(esAlfaStr) || "true".equals(esAlfaStr));
        td.setEstado(estado);

        try {
            if (esNuevo) {
                for (TipoDocumento tdExistente : catalogoDAO.findAllTipoDocumentos()) {
                    if (tdExistente.getNombreDocumento().equalsIgnoreCase(nombre.trim()) ||
                            tdExistente.getAbreviado().equalsIgnoreCase(abreviado.trim())) {
                        mensajeError(req, "Ya existe un tipo de documento con ese nombre o abreviado.");
                        redirigirA("/tipodocumento", req, resp);
                        return;
                    }
                }
                catalogoDAO.insertTipoDocumento(td);
                LOGGER.info("TipoDocumento creado: " + td.getId());
                mensajeExito(req, "Tipo de documento \""
                        + td.getNombreDocumento() + "\" creado correctamente.");
            } else {
                for (TipoDocumento tdExistente : catalogoDAO.findAllTipoDocumentos()) {
                    if (!tdExistente.getId().equals(id) &&
                            (tdExistente.getNombreDocumento().equalsIgnoreCase(nombre.trim()) ||
                                    tdExistente.getAbreviado().equalsIgnoreCase(abreviado.trim()))) {
                        mensajeError(req, "Ya existe otro tipo de documento con ese nombre o abreviado.");
                        redirigirA("/tipodocumento", req, resp);
                        return;
                    }
                }
                catalogoDAO.updateTipoDocumento(td);
                LOGGER.info("TipoDocumento actualizado: " + td.getId());
                mensajeExito(req, "Tipo de documento \""
                        + td.getNombreDocumento() + "\" actualizado correctamente.");
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error al guardar TipoDocumento", e);
            mensajeError(req, e.getMessage() != null
                    && e.getMessage().contains("PRIMARY")
                            ? "Ya existe un tipo con ese ID o abreviado."
                            : "Error al guardar. Intenta nuevamente.");
        }

        redirigirA("/tipodocumento", req, resp);
    }

    // ── Toggle estado ──────────────────────────────────────────
    private void toggleEstado(HttpServletRequest req,
            HttpServletResponse resp)
            throws IOException {

        String id = param(req, "id");
        if (id == null) {
            mensajeError(req, "ID no especificado.");
            redirigirA("/tipodocumento", req, resp);
            return;
        }

        try {
            TipoDocumento td = catalogoDAO.findTipoDocumentoById(id);
            if (td == null) {
                mensajeError(req, "No se encontró el tipo de documento.");
                redirigirA("/tipodocumento", req, resp);
                return;
            }

            String nuevoEstado = AppConfig.ESTADO_ACTIVO.equals(td.getEstado())
                    ? AppConfig.ESTADO_INACTIVO
                    : AppConfig.ESTADO_ACTIVO;

            catalogoDAO.updateEstadoTipoDocumento(id, nuevoEstado);

            String accion = AppConfig.ESTADO_ACTIVO.equals(nuevoEstado)
                    ? "activado"
                    : "desactivado";

            LOGGER.info("TipoDocumento " + accion + ": " + id);
            mensajeExito(req, "\"" + td.getNombreDocumento()
                    + "\" " + accion + " correctamente.");

        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE,
                    "Error al cambiar estado TipoDocumento: " + id, e);
            mensajeError(req, "Error al cambiar estado.");
        }

        redirigirA("/tipodocumento", req, resp);
    }

    // ── Eliminar ───────────────────────────────────────────────
    private void eliminar(HttpServletRequest req,
            HttpServletResponse resp)
            throws IOException {

        String id = param(req, "id");
        if (id == null) {
            mensajeError(req, "ID no especificado.");
            redirigirA("/tipodocumento", req, resp);
            return;
        }

        try {
            TipoDocumento td = catalogoDAO.findTipoDocumentoById(id);
            if (td == null) {
                mensajeError(req, "No se encontró el tipo de documento.");
                redirigirA("/tipodocumento", req, resp);
                return;
            }

            if (empleadoDAO.isTipoDocumentoEnUso(id) || clienteDAO.isTipoDocumentoEnUso(id)) {
                mensajeError(req, "No se puede eliminar porque está en uso por empleados o clientes.");
                redirigirA("/tipodocumento", req, resp);
                return;
            }

            catalogoDAO.deleteTipoDocumento(id);
            LOGGER.info("TipoDocumento eliminado: " + id);
            mensajeExito(req, "\"" + td.getNombreDocumento() + "\" eliminado correctamente.");

        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error al eliminar TipoDocumento: " + id, e);
            mensajeError(req, "Error al eliminar el tipo de documento.");
        }

        redirigirA("/tipodocumento", req, resp);
    }
}