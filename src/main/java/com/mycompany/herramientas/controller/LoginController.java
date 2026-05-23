package com.mycompany.herramientas.controller;

import com.mycompany.herramientas.config.AppConfig;
import com.mycompany.herramientas.model.Usuario;
import com.mycompany.herramientas.service.AuthService;
import com.mycompany.herramientas.view.RoleRoutes;
import com.mycompany.herramientas.view.ViewRoutes;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;

/**
 * Controlador de inicio de sesión (RF-15).
 *
 * GET  /login → muestra el formulario de login.
 * POST /login → valida credenciales y redirige según el rol.
 *
 * Flujo POST:
 *   1. Lee email y password del formulario.
 *   2. Llama a AuthService.login() que verifica BCrypt y estado de cuenta.
 *   3. Si OK → guarda datos en sesión → redirect a la URL de inicio del rol.
 *   4. Si falla → vuelve al formulario con mensaje de error genérico.
 *
 * Seguridad:
 *   - El mensaje de error NO indica si el email existe o no.
 *   - La sesión se invalida antes de crear una nueva (previene session fixation).
 *   - Se guarda redirectAfterLogin si fue puesto por AuthFilter (deep link).
 */
public class LoginController extends AbstractController {

    private final AuthService authService = new AuthService();

    // ── GET: mostrar formulario ──────────────────────────────────────────────

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        // Si ya tiene sesión activa, redirigir directamente a su página de inicio
        HttpSession session = getSession(req);
        if (session != null && session.getAttribute(AppConfig.SESSION_USER_NAME) != null) {
            String rol = (String) session.getAttribute(AppConfig.SESSION_USER_ROLE);
            redirect(req, resp, RoleRoutes.getUrlInicio(rol));
            return;
        }

        // Pasar mensaje de error si viene de un redirect (ej: sesión expirada)
        String errorParam = req.getParameter("error");
        if ("session".equals(errorParam)) {
            setError(req, "Tu sesión ha expirado. Por favor inicia sesión nuevamente.");
        }

        forward(req, resp, ViewRoutes.AUTH_LOGIN);
    }

    // ── POST: procesar credenciales ──────────────────────────────────────────

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String email    = param(req, "email");
        String password = param(req, "password");

        // Validación básica de campos vacíos
        if (email == null || password == null) {
            setError(req, "El correo y la contraseña son obligatorios.");
            forward(req, resp, ViewRoutes.AUTH_LOGIN);
            return;
        }

        // Intentar login
        Usuario usuario = authService.login(email, password);

        if (usuario == null) {
            // Mensaje genérico — no revelar si el email existe o no
            setError(req, "Correo o contraseña incorrectos. Verifica tus datos.");
            req.setAttribute("emailIngresado", email); // repoblar el campo email
            forward(req, resp, ViewRoutes.AUTH_LOGIN);
            return;
        }

        // ── Login exitoso ──────────────────────────────────────────────────

        // Invalidar sesión previa para prevenir session fixation
        HttpSession oldSession = getSession(req);
        String redirectAfterLogin = null;
        if (oldSession != null) {
            redirectAfterLogin = (String) oldSession.getAttribute("redirectAfterLogin");
            oldSession.invalidate();
        }

        // Crear nueva sesión limpia
        HttpSession newSession = req.getSession(true);
        newSession.setMaxInactiveInterval(AppConfig.SESSION_TIMEOUT_SECONDS);

        // Guardar datos del usuario en sesión (nunca guardar el hash de la contraseña)
        newSession.setAttribute(AppConfig.SESSION_USER_ID,    usuario.getId());
        newSession.setAttribute(AppConfig.SESSION_USER_NAME,  usuario.getNombreEmpleado());
        newSession.setAttribute(AppConfig.SESSION_USER_ROLE,  usuario.getIdRol());
        newSession.setAttribute(AppConfig.SESSION_USER_EMAIL, usuario.getEmail());

        // Redirigir: primero al deep link guardado por AuthFilter, luego a la página por rol
        String urlDestino;
        if (redirectAfterLogin != null && !redirectAfterLogin.contains("/login")) {
            urlDestino = redirectAfterLogin; // URL absoluta ya incluye contextPath
            resp.sendRedirect(urlDestino);
        } else {
            redirect(req, resp, RoleRoutes.getUrlInicio(usuario.getIdRol()));
        }
    }
}