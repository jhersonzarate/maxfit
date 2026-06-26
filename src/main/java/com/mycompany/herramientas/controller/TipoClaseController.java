package com.mycompany.herramientas.controller;

import com.mycompany.herramientas.config.AppConfig;
import com.mycompany.herramientas.dao.CatalogoDAO;
import com.mycompany.herramientas.model.TipoClase;
import com.mycompany.herramientas.view.ViewRoutes;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.SQLException;
import java.util.logging.Level;
import java.util.logging.Logger;

@WebServlet("/tipoclase")
public class TipoClaseController extends AbstractController {

    private static final Logger LOGGER =
            Logger.getLogger(TipoClaseController.class.getName());

    private final CatalogoDAO catalogoDAO = new CatalogoDAO();

    @Override
    protected void doGet(HttpServletRequest req,
                         HttpServletResponse resp)
            throws ServletException, IOException {

        if (!esAdmin(req)) { forbidden(resp); return; }
        transferirFlashMessages(req);

        switch (getAction(req)) {
            case "save":
                guardar(req, resp);
                break;
            case "toggle":
                toggleEstado(req, resp);
                break;
            case "delete":
                delete(req, resp);
                break;
            default:
                redirigirA("/tipoclase", req, resp);
        }
    }

    @Override
    protected void doPost(HttpServletRequest req,
                          HttpServletResponse resp)
            throws ServletException, IOException {

        if (!esAdmin(req)) { forbidden(resp); return; }

        switch (getAction(req)) {
            case "save":   guardar(req, resp);      break;
            case "toggle": toggleEstado(req, resp); break;
            default:       redirigirA("/tipoclase", req, resp);
        }
    }

    // ── Lista ──────────────────────────────────────────────────
    private void mostrarLista(HttpServletRequest req,
                              HttpServletResponse resp)
            throws ServletException, IOException {
        try {
            req.setAttribute("tiposClase",
                    catalogoDAO.findAllTipoClasesConEstado());
            irA(ViewRoutes.TIPOCLASE_INDEX, req, resp);
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error al cargar TipoClase", e);
            mensajeError(req, "Error al cargar tipos de clase.");
            irA(ViewRoutes.TIPOCLASE_INDEX, req, resp);
        }
    }

    // ── Formulario ─────────────────────────────────────────────
    private void mostrarForm(HttpServletRequest req,
                             HttpServletResponse resp,
                             String id)
            throws ServletException, IOException {
        try {
            req.setAttribute("modoForm", true);

            if (id != null) {
                TipoClase tc = catalogoDAO.findTipoClaseById(id);
                if (tc == null) {
                    mensajeError(req, "No se encontró el tipo de clase.");
                    redirigirA("/tipoclase", req, resp);
                    return;
                }
                req.setAttribute("entidad", tc);
                req.setAttribute("modoEdicion", true);
            } else {
                req.setAttribute("entidad", new TipoClase());
                req.setAttribute("modoEdicion", false);
            }

            // NO se carga la lista aquí
            irA(ViewRoutes.TIPOCLASE_INDEX, req, resp);

        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error al cargar form TipoClase", e);
            mensajeError(req, "Error al cargar el formulario.");
            redirigirA("/tipoclase", req, resp);
        }
    }

    // ── Guardar ────────────────────────────────────────────────
    private void guardar(HttpServletRequest req,
                         HttpServletResponse resp)
            throws ServletException, IOException {

        String id     = param(req, "id");
        String nombre = param(req, "nombre");
        String estado = param(req, "estado", AppConfig.ESTADO_ACTIVO);
        boolean esNuevo = (id == null || id.isBlank());

        if (nombre == null || nombre.isBlank()) {
            mensajeError(req, "El nombre es obligatorio.");
            mostrarForm(req, resp, esNuevo ? null : id);
            return;
        }

        try {
            for (TipoClase t : catalogoDAO.findAllTipoClases()) {
                if (t.getNombre().equalsIgnoreCase(nombre.trim())) {
                    if (esNuevo || !t.getId().equals(id)) {
                        mensajeError(req, "Ya existe un tipo de clase registrado con ese nombre.");
                        redirigirA("/tipoclase", req, resp);
                        return;
                    }
                }
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error al validar nombre de TipoClase", e);
            mensajeError(req, "Error al validar el tipo de clase.");
            redirigirA("/tipoclase", req, resp);
            return;
        }

        TipoClase tc = new TipoClase();
        if (esNuevo) {
            String sufijo = nombre.trim()
                    .toUpperCase()
                    .replaceAll("[^A-Z0-9]", "");
            if (sufijo.length() > 8) sufijo = sufijo.substring(0, 8);
            tc.setId("TCL-" + sufijo);
        } else {
            tc.setId(id);
        }
        tc.setNombre(nombre.trim());
        tc.setEstado(estado);

        try {
            if (esNuevo) {
                catalogoDAO.insertTipoClase(tc);
                LOGGER.info("TipoClase creado: " + tc.getId());
                mensajeExito(req, "Tipo de clase \"" + tc.getNombre()
                        + "\" creado correctamente.");
            } else {
                catalogoDAO.updateTipoClase(tc);
                LOGGER.info("TipoClase actualizado: " + tc.getId());
                mensajeExito(req, "Tipo de clase \"" + tc.getNombre()
                        + "\" actualizado correctamente.");
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error al guardar TipoClase", e);
            mensajeError(req, e.getMessage() != null
                    && e.getMessage().contains("PRIMARY")
                    ? "Ya existe un tipo de clase con ese ID."
                    : "Error al guardar. Intenta nuevamente.");
        }

        redirigirA("/tipoclase", req, resp);
    }

    // ── Toggle estado ──────────────────────────────────────────
    private void toggleEstado(HttpServletRequest req,
                              HttpServletResponse resp)
            throws IOException {

        String id = param(req, "id");
        if (id == null) {
            mensajeError(req, "ID no especificado.");
            redirigirA("/tipoclase", req, resp);
            return;
        }

        try {
            TipoClase tc = catalogoDAO.findTipoClaseById(id);
            if (tc == null) {
                mensajeError(req, "No se encontró el tipo de clase.");
                redirigirA("/tipoclase", req, resp);
                return;
            }

            String nuevoEstado = AppConfig.ESTADO_ACTIVO.equals(tc.getEstado())
                    ? AppConfig.ESTADO_INACTIVO
                    : AppConfig.ESTADO_ACTIVO;

            catalogoDAO.updateEstadoTipoClase(id, nuevoEstado);

            String accion = AppConfig.ESTADO_ACTIVO.equals(nuevoEstado)
                    ? "activado" : "desactivado";

            LOGGER.info("TipoClase " + accion + ": " + id);
            mensajeExito(req, "\"" + tc.getNombre()
                    + "\" " + accion + " correctamente.");

        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE,
                    "Error al cambiar estado TipoClase: " + id, e);
            mensajeError(req, "Error al cambiar estado.");
        }

        redirigirA("/tipoclase", req, resp);
    }
    // ── Eliminar ───────────────────────────────────────────────
    private void delete(HttpServletRequest req,
                        HttpServletResponse resp)
            throws IOException {

        String id = param(req, "id");
        if (id == null) {
            mensajeError(req, "ID no especificado.");
            redirigirA("/tipoclase", req, resp);
            return;
        }

        try {
            com.mycompany.herramientas.dao.ClaseDAO claseDAO = new com.mycompany.herramientas.dao.ClaseDAO();
            if (claseDAO.isTipoClaseEnUso(id)) {
                mensajeError(req, "No se puede eliminar porque está asignado a una o más clases.");
            } else {
                boolean ok = catalogoDAO.deleteTipoClase(id);
                if (ok) {
                    mensajeExito(req, "Tipo de clase eliminado correctamente.");
                } else {
                    mensajeError(req, "No se encontró el tipo de clase a eliminar.");
                }
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error al eliminar TipoClase: " + id, e);
            mensajeError(req, "Error al eliminar el tipo de clase.");
        }

        redirigirA("/tipoclase", req, resp);
    }
}