package com.mycompany.herramientas.controller;

import com.mycompany.herramientas.config.AppConfig;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;
import java.util.logging.Logger;

/**
 * Controlador de cierre de sesión.
 *
 * GET  /logout → invalida la sesión y redirige al login con mensaje de confirmación
 * POST /logout → mismo comportamiento (para formularios con botón "Salir")
 *
 * Seguridad:
 *   - Invalida la sesión completa (no solo borra atributos).
 *   - Limpia la cookie JSESSIONID explícitamente para evitar que el navegador
 *     la reutilice en la misma pestaña.
 *   - Cabeceras de no-caché para evitar que el botón "Atrás" muestre
 *     páginas protegidas después del logout.
 *
 * @author MaxFit
 */
@WebServlet("/logout")
public class LogoutController extends HttpServlet {

    private static final Logger LOGGER =
            Logger.getLogger(LogoutController.class.getName());

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        procesarLogout(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        procesarLogout(req, resp);
    }

    // ─── Lógica de logout ─────────────────────────────────────────────────────

    private void procesarLogout(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {

        // ── 1. Registrar el cierre de sesión en el log ───────────────────────
        HttpSession sesion = req.getSession(false);
        if (sesion != null) {
            String userName = (String) sesion.getAttribute(AppConfig.SESSION_USER_NAME);
            String userRole = (String) sesion.getAttribute(AppConfig.SESSION_USER_ROLE);
            LOGGER.info("Logout: usuario='" + userName
                    + "' | rol='" + userRole + "'");

            // ── 2. Invalidar la sesión completa ──────────────────────────────
            sesion.invalidate();
        }

        // ── 3. Cabeceras de no-caché ─────────────────────────────────────────
        // Impide que el botón "Atrás" del navegador muestre páginas protegidas
        resp.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
        resp.setHeader("Pragma", "no-cache");
        resp.setDateHeader("Expires", 0);

        // ── 4. Redirigir al login con mensaje de confirmación ────────────────
        resp.sendRedirect(req.getContextPath()
                + "/login?msg=logout");
    }
}