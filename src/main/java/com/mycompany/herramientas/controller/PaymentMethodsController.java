package com.mycompany.herramientas.controller;

import com.mycompany.herramientas.config.AppConfig;
import com.mycompany.herramientas.dao.CatalogoDAO;
import com.mycompany.herramientas.model.MetodoPago;
import com.mycompany.herramientas.view.ViewRoutes;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.SQLException;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * Controlador de Gestión de Métodos de Pago (RF-06).
 *
 * Rutas y acciones:
 *   GET  /payment-methods                        → lista todos los métodos de pago
 *   POST /payment-methods?action=toggle&id=PAY-X → activa o inactiva un método
 *
 * Acceso: ROL-ADMIN únicamente (RoleFilter → /payment-methods).
 *
 * Reglas de negocio (RF-06):
 *   - Solo los métodos con estado 'activo' aparecen en el formulario de
 *     nuevo contrato (ContractsController usa findMetodosPagoActivos()).
 *   - El admin puede activar o desactivar métodos de pago desde aquí.
 *   - NO se permite eliminar un método de pago porque puede tener contratos
 *     asociados (la BD lo rechazaría con FK violation desde Contratos).
 *     La estrategia correcta es desactivarlo → estado 'inactivo'.
 *   - Si se intenta desactivar el ÚNICO método activo, se bloquea la acción
 *     con un mensaje de error, ya que sin métodos activos no podrían
 *     registrarse nuevos contratos.
 *
 * Diseño:
 *   CatalogoDAO ya tiene todos los métodos SQL necesarios:
 *     findAllMetodosPago()        → lista todos (activos e inactivos)
 *     updateEstadoMetodoPago()    → UPDATE estado WHERE id
 *   No se necesita un DAO adicional.
 *
 * @author MaxFit
 */
@WebServlet("/payment-methods")
public class PaymentMethodsController extends AbstractController {

    private static final Logger LOGGER =
            Logger.getLogger(PaymentMethodsController.class.getName());

    private final CatalogoDAO catalogoDAO = new CatalogoDAO();

    // ─── GET ──────────────────────────────────────────────────────────────────

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        transferirFlashMessages(req);
        mostrarLista(req, resp);
    }

    // ─── POST ─────────────────────────────────────────────────────────────────

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String action = getAction(req);

        if ("toggle".equals(action)) {
            toggleEstadoMetodoPago(req, resp);
        } else {
            redirigirA("/payment-methods", req, resp);
        }
    }

    // ─── GET: lista de todos los métodos de pago ──────────────────────────────

    /**
     * Carga todos los métodos de pago (activos e inactivos) para que
     * el admin vea el estado completo y pueda gestionar cada uno.
     * Los contadores se calculan en Java para no añadir queries adicionales.
     */
    private void mostrarLista(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        try {
            List<MetodoPago> metodos = catalogoDAO.findAllMetodosPago();

            long totalActivos   = metodos.stream().filter(MetodoPago::isActivo).count();
            long totalInactivos = metodos.size() - totalActivos;

            req.setAttribute("metodos",         metodos);
            req.setAttribute("totalMetodos",    metodos.size());
            req.setAttribute("totalActivos",    totalActivos);
            req.setAttribute("totalInactivos",  totalInactivos);

            irA(ViewRoutes.PAYMENT_METHODS_INDEX, req, resp);

        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error al listar métodos de pago", e);
            req.setAttribute("errorMsg",
                    "Error al cargar los métodos de pago. Intenta nuevamente.");
            irA(ViewRoutes.PAYMENT_METHODS_INDEX, req, resp);
        }
    }

    // ─── POST: activar / desactivar método de pago ────────────────────────────

    /**
     * Alterna el estado de un método de pago entre 'activo' e 'inactivo' (RF-06).
     *
     * Regla de seguridad:
     *   Si el método a desactivar es el ÚNICO que está activo actualmente,
     *   se bloquea la acción para no dejar el sistema sin métodos de pago
     *   disponibles, lo que impediría registrar nuevos contratos.
     *
     * Flujo:
     *   1. Cargar todos los métodos para encontrar el seleccionado.
     *   2. Si es el único activo y se quiere desactivar → error y redirect.
     *   3. Si no → invertir estado y guardar en BD.
     *   4. Flash message de resultado → redirect (PRG pattern).
     */
    private void toggleEstadoMetodoPago(HttpServletRequest req,
                                         HttpServletResponse resp)
            throws IOException {

        String id = param(req, "id");
        if (id == null) {
            mensajeError(req, "ID de método de pago no especificado.");
            redirigirA("/payment-methods", req, resp);
            return;
        }

        try {
            // Cargar todos para encontrar el método y calcular cuántos activos hay
            List<MetodoPago> todos = catalogoDAO.findAllMetodosPago();

            MetodoPago metodo = todos.stream()
                    .filter(m -> id.equals(m.getId()))
                    .findFirst()
                    .orElse(null);

            if (metodo == null) {
                mensajeError(req, "No se encontró el método de pago con ID: " + id);
                redirigirA("/payment-methods", req, resp);
                return;
            }

            // Regla de negocio: no permitir desactivar el último método activo
            if (metodo.isActivo()) {
                long totalActivos = todos.stream()
                        .filter(MetodoPago::isActivo)
                        .count();

                if (totalActivos <= 1) {
                    mensajeError(req,
                            "No puedes desactivar \"" + metodo.getNombre() + "\" porque "
                            + "es el único método de pago activo. "
                            + "Activa otro primero y luego desactiva este.");
                    redirigirA("/payment-methods", req, resp);
                    return;
                }
            }

            // Invertir estado
            String nuevoEstado = metodo.isActivo()
                    ? AppConfig.ESTADO_INACTIVO
                    : AppConfig.ESTADO_ACTIVO;

            boolean ok = catalogoDAO.updateEstadoMetodoPago(id, nuevoEstado);

            if (ok) {
                LOGGER.info("Método de pago " + id
                        + " (" + metodo.getNombre() + ") → " + nuevoEstado);

                String accion = AppConfig.ESTADO_ACTIVO.equals(nuevoEstado)
                        ? "activado" : "desactivado";
                mensajeExito(req, "\"" + metodo.getNombre() + "\" "
                        + accion + " correctamente.");
            } else {
                mensajeError(req,
                        "No se pudo actualizar el estado de \""
                        + metodo.getNombre() + "\". Intenta nuevamente.");
            }

        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE,
                    "Error al cambiar estado del método de pago: " + id, e);
            mensajeError(req,
                    "Error interno al actualizar el método de pago. Intenta nuevamente.");
        }

        redirigirA("/payment-methods", req, resp);
    }
}