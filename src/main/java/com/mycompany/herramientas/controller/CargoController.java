package com.mycompany.herramientas.controller;

import com.mycompany.herramientas.config.AppConfig;
import com.mycompany.herramientas.dao.CatalogoDAO;
import com.mycompany.herramientas.model.Cargo;
import com.mycompany.herramientas.view.ViewRoutes;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.SQLException;
import java.util.logging.Level;
import java.util.logging.Logger;

@WebServlet("/cargo")
public class CargoController extends AbstractController {

    private static final Logger LOGGER =
            Logger.getLogger(CargoController.class.getName());

    private final CatalogoDAO catalogoDAO = new CatalogoDAO();

    @Override
    protected void doGet(HttpServletRequest req,
                         HttpServletResponse resp)
            throws ServletException, IOException {

        if (!esAdmin(req)) { forbidden(resp); return; }
        transferirFlashMessages(req);

        switch (getAction(req)) {
            case "new":  mostrarForm(req, resp, null);             break;
            case "edit": mostrarForm(req, resp, param(req, "id")); break;
            default:     mostrarLista(req, resp);
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
            default:       redirigirA("/cargo", req, resp);
        }
    }

    // ── Lista ──────────────────────────────────────────────────
    private void mostrarLista(HttpServletRequest req,
                              HttpServletResponse resp)
            throws ServletException, IOException {
        try {
            req.setAttribute("cargos", catalogoDAO.findAllCargosConEstado());
            irA(ViewRoutes.CARGO_INDEX, req, resp);
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error al cargar Cargos", e);
            mensajeError(req, "Error al cargar los cargos.");
            irA(ViewRoutes.CARGO_INDEX, req, resp);
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
                Cargo cargo = catalogoDAO.findCargoById(id);
                if (cargo == null) {
                    mensajeError(req, "No se encontró el cargo.");
                    redirigirA("/cargo", req, resp);
                    return;
                }
                req.setAttribute("entidad", cargo);
                req.setAttribute("modoEdicion", true);
            } else {
                req.setAttribute("entidad", new Cargo());
                req.setAttribute("modoEdicion", false);
            }

            irA(ViewRoutes.CARGO_INDEX, req, resp);

        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error al cargar form Cargo", e);
            mensajeError(req, "Error al cargar el formulario.");
            redirigirA("/cargo", req, resp);
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
            mensajeError(req, "El nombre del cargo es obligatorio.");
            mostrarForm(req, resp, esNuevo ? null : id);
            return;
        }

        Cargo cargo = new Cargo();
        if (esNuevo) {
            String sufijo = nombre.trim()
                    .toUpperCase()
                    .replaceAll("[^A-Z0-9]", "");
            if (sufijo.length() > 8) sufijo = sufijo.substring(0, 8);
            cargo.setId("CARGO-" + sufijo);
        } else {
            cargo.setId(id);
        }
        cargo.setNombre(nombre.trim());
        cargo.setEstado(estado);

        try {
            if (esNuevo) {
                catalogoDAO.insertCargo(cargo);
                LOGGER.info("Cargo creado: " + cargo.getId());
                mensajeExito(req, "Cargo \"" + cargo.getNombre()
                        + "\" creado correctamente.");
            } else {
                catalogoDAO.updateCargo(cargo);
                LOGGER.info("Cargo actualizado: " + cargo.getId());
                mensajeExito(req, "Cargo \"" + cargo.getNombre()
                        + "\" actualizado correctamente.");
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error al guardar Cargo", e);
            mensajeError(req, e.getMessage() != null
                    && e.getMessage().contains("PRIMARY")
                    ? "Ya existe un cargo con ese ID."
                    : "Error al guardar. Intenta nuevamente.");
        }

        redirigirA("/cargo", req, resp);
    }

    // ── Toggle estado ──────────────────────────────────────────
    private void toggleEstado(HttpServletRequest req,
                              HttpServletResponse resp)
            throws IOException {

        String id = param(req, "id");
        if (id == null) {
            mensajeError(req, "ID no especificado.");
            redirigirA("/cargo", req, resp);
            return;
        }

        try {
            Cargo cargo = catalogoDAO.findCargoById(id);
            if (cargo == null) {
                mensajeError(req, "No se encontró el cargo.");
                redirigirA("/cargo", req, resp);
                return;
            }

            String nuevoEstado = AppConfig.ESTADO_ACTIVO.equals(cargo.getEstado())
                    ? AppConfig.ESTADO_INACTIVO
                    : AppConfig.ESTADO_ACTIVO;

            catalogoDAO.updateEstadoCargo(id, nuevoEstado);

            String accion = AppConfig.ESTADO_ACTIVO.equals(nuevoEstado)
                    ? "activado" : "desactivado";

            LOGGER.info("Cargo " + accion + ": " + id);
            mensajeExito(req, "\"" + cargo.getNombre()
                    + "\" " + accion + " correctamente.");

        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error al cambiar estado Cargo: " + id, e);
            mensajeError(req, "Error al cambiar estado.");
        }

        redirigirA("/cargo", req, resp);
    }
}