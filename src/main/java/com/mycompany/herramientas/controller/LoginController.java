package com.mycompany.herramientas.controller;

import com.mycompany.herramientas.config.AppConfig;
import com.mycompany.herramientas.model.Usuario;
import com.mycompany.herramientas.service.AuthService;
import com.mycompany.herramientas.view.RoleRoutes;
import com.mycompany.herramientas.view.ViewRoutes;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;

/**
 * Controlador de inicio de sesión (RF-15).
 *
 * GET  /login → muestra el formulario de login (login.jsp)
 * POST /login → valida credenciales y redirige según rol
 *
 * Flujo POST:
 *   1. Leer email y password del formulario.
 *   2. Delegar validación a AuthService.login().
 *   3. Si OK → guardar datos mínimos en sesión y redirigir al dashboard del rol.
 *   4. Si falla → reenviar al formulario con mensaje de error.
 *
 * Datos de sesión que se guardan (claves en AppConfig.SESSION_*):
 *   userId    → ID del usuario (ej: USR-2026-0001)
 *   userName  → nombre completo del empleado (o email si no tiene empleado)
 *   userRole  → ID del rol (ej: ROL-ADMIN) — lo usa RoleFilter
 *   userEmail → email del usuario
 *
 * Seguridad:
 *   - El mensaje de error es siempre el mismo ("Credenciales incorrectas…")
 *     para no revelar si el email existe en el sistema (evita enumeración).
 *   - La contraseña NUNCA se guarda en sesión ni en ninguna variable de instancia.
 *   - La sesión anterior se invalida antes de crear la nueva (evita session fixation).
 *
 * @author MaxFit
 */
@WebServlet("/login")
public class LoginController extends HttpServlet {

    // Servicio de autenticación — sin estado, seguro para instancia de Servlet
    private final AuthService authService = new AuthService();

    // Mensaje genérico para no revelar si el email existe
    private static final String MSG_ERROR_CREDENCIALES =
            "Correo o contraseña incorrectos. Verifica tus datos e intenta nuevamente.";

    private static final String MSG_ERROR_CAMPO_VACIO =
            "Por favor ingresa tu correo y contraseña.";

    // ─── GET /login ───────────────────────────────────────────────────────────

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        // Si ya tiene sesión activa → redirigir al inicio según su rol
        HttpSession sesionExistente = req.getSession(false);
        if (sesionExistente != null
                && sesionExistente.getAttribute(AppConfig.SESSION_USER_NAME) != null) {

            String rol = (String) sesionExistente.getAttribute(AppConfig.SESSION_USER_ROLE);
            resp.sendRedirect(req.getContextPath() + RoleRoutes.getUrlInicio(rol));
            return;
        }

        // Sin sesión → mostrar formulario de login
        req.getRequestDispatcher(ViewRoutes.AUTH_LOGIN).forward(req, resp);
    }

    // ─── POST /login ──────────────────────────────────────────────────────────

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        // Leer parámetros del formulario
        String email    = req.getParameter("email");
        String password = req.getParameter("password");

        // ── 1. Validación básica de campos vacíos ────────────────────────────
        if (isBlank(email) || isBlank(password)) {
            reenviarConError(req, resp, MSG_ERROR_CAMPO_VACIO, email);
            return;
        }

        // ── 2. Delegar al servicio de autenticación ──────────────────────────
        Usuario usuario = authService.login(email.trim(), password);

        // ── 3. Autenticación fallida ─────────────────────────────────────────
        if (usuario == null) {
            reenviarConError(req, resp, MSG_ERROR_CREDENCIALES, email);
            return;
        }

        // ── 4. Autenticación exitosa ─────────────────────────────────────────

        // Invalidar sesión previa si existe (evita session fixation attack)
        HttpSession sesionVieja = req.getSession(false);
        if (sesionVieja != null) {
            sesionVieja.invalidate();
        }

        // Crear nueva sesión con los datos del usuario autenticado
        HttpSession sesion = req.getSession(true);
        sesion.setMaxInactiveInterval(AppConfig.SESSION_TIMEOUT_SECONDS);

        // Guardar solo datos mínimos — NUNCA la contraseña
        sesion.setAttribute(AppConfig.SESSION_USER_ID,    usuario.getId());
        sesion.setAttribute(AppConfig.SESSION_USER_NAME,  usuario.getNombreEmpleado());
        sesion.setAttribute(AppConfig.SESSION_USER_ROLE,  usuario.getIdRol());
        sesion.setAttribute(AppConfig.SESSION_USER_EMAIL, usuario.getEmail());

        // ── 5. Redirigir al inicio según rol ─────────────────────────────────
        // Verificar si había una URL guardada para redirigir después del login
        String redirectUrl = (String) sesion.getAttribute("redirectAfterLogin");
        if (redirectUrl != null && !redirectUrl.isBlank()
                && !redirectUrl.contains("/login")) {
            sesion.removeAttribute("redirectAfterLogin");
            resp.sendRedirect(redirectUrl);
        } else {
            String urlInicio = RoleRoutes.getUrlInicio(usuario.getIdRol());
            resp.sendRedirect(req.getContextPath() + urlInicio);
        }
    }

    // ─── Helpers privados ─────────────────────────────────────────────────────

    /**
     * Reenvía al formulario de login con un mensaje de error.
     * Devuelve el email ingresado para no obligar al usuario a reescribirlo.
     * La contraseña nunca se devuelve al formulario.
     */
    private void reenviarConError(HttpServletRequest req,
                                   HttpServletResponse resp,
                                   String mensaje,
                                   String emailIngresado)
            throws ServletException, IOException {

        req.setAttribute("errorMsg", mensaje);
        // Devolver el email para que el usuario no tenga que reescribirlo
        if (!isBlank(emailIngresado)) {
            req.setAttribute("emailIngresado", emailIngresado.trim().toLowerCase());
        }
        req.getRequestDispatcher(ViewRoutes.AUTH_LOGIN).forward(req, resp);
    }

    /** Verifica si un String es null o solo espacios. */
    private boolean isBlank(String s) {
        return s == null || s.trim().isEmpty();
    }
}