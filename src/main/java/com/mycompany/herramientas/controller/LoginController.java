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

// controlador de autenticación del sistema
@WebServlet("/login")
public class LoginController extends HttpServlet {

    // servicio encargado de validar credenciales
    private final AuthService authService =
            new AuthService();

    // mensaje genérico para evitar revelar datos del sistema
    private static final String MSG_ERROR_CREDENCIALES =
            "Correo o contraseña incorrectos. "
                    + "Verifica tus datos e intenta nuevamente.";

    // mensaje para campos vacíos
    private static final String MSG_ERROR_CAMPO_VACIO =
            "Por favor ingresa tu correo y contraseña.";

    // ───────────────── GET /login ─────────────────────

    @Override
    protected void doGet(HttpServletRequest req,
                         HttpServletResponse resp)
            throws ServletException, IOException {

        // verificar si el usuario ya inició sesión
        HttpSession sesionExistente =
                req.getSession(false);

        if (sesionExistente != null
                && sesionExistente.getAttribute(
                        AppConfig.SESSION_USER_NAME
                ) != null) {

            String rol = (String)
                    sesionExistente.getAttribute(
                            AppConfig.SESSION_USER_ROLE
                    );

            // redirigir al dashboard correspondiente
            resp.sendRedirect(
                    req.getContextPath()
                            + RoleRoutes.getUrlInicio(rol)
            );

            return;
        }

        // mostrar formulario de login
        req.getRequestDispatcher(
                ViewRoutes.AUTH_LOGIN
        ).forward(req, resp);
    }

    // ───────────────── POST /login ────────────────────

    @Override
    protected void doPost(HttpServletRequest req,
                          HttpServletResponse resp)
            throws ServletException, IOException {

        // obtener datos enviados desde el formulario
        String email =
                req.getParameter("email");

        String password =
                req.getParameter("password");

        // validar campos obligatorios
        if (isBlank(email)
                || isBlank(password)) {

            reenviarConError(
                    req,
                    resp,
                    MSG_ERROR_CAMPO_VACIO,
                    email
            );

            return;
        }

        // validar credenciales en el servicio
        Usuario usuario =
                authService.login(
                        email.trim(),
                        password
                );

        // credenciales inválidas
        if (usuario == null) {

            reenviarConError(
                    req,
                    resp,
                    MSG_ERROR_CREDENCIALES,
                    email
            );

            return;
        }

        // invalidar sesión anterior por seguridad
        HttpSession sesionVieja =
                req.getSession(false);

        if (sesionVieja != null) {
            sesionVieja.invalidate();
        }

        // crear nueva sesión autenticada
        HttpSession sesion =
                req.getSession(true);

        sesion.setMaxInactiveInterval(
                AppConfig.SESSION_TIMEOUT_SECONDS
        );

        // guardar datos mínimos del usuario
        sesion.setAttribute(
                AppConfig.SESSION_USER_ID,
                usuario.getId()
        );

        sesion.setAttribute(
                AppConfig.SESSION_USER_NAME,
                usuario.getNombreEmpleado()
        );

        sesion.setAttribute(
                AppConfig.SESSION_USER_ROLE,
                usuario.getIdRol()
        );

        sesion.setAttribute(
                AppConfig.SESSION_USER_EMAIL,
                usuario.getEmail()
        );

        // verificar redirección pendiente después del login
        String redirectUrl = (String)
                sesion.getAttribute("redirectAfterLogin");

        if (redirectUrl != null
                && !redirectUrl.isBlank()
                && !redirectUrl.contains("/login")) {

            sesion.removeAttribute("redirectAfterLogin");

            resp.sendRedirect(redirectUrl);

        } else {

            // redirigir al dashboard según rol
            String urlInicio =
                    RoleRoutes.getUrlInicio(
                            usuario.getIdRol()
                    );

            resp.sendRedirect(
                    req.getContextPath()
                            + urlInicio
            );
        }
    }

    // ───────────────── helpers privados ───────────────

    // reenviar al login mostrando mensaje de error
    private void reenviarConError(HttpServletRequest req,
                                  HttpServletResponse resp,
                                  String mensaje,
                                  String emailIngresado)
            throws ServletException, IOException {

        req.setAttribute(
                "errorMsg",
                mensaje
        );

        // devolver email ingresado al formulario
        if (!isBlank(emailIngresado)) {

            req.setAttribute(
                    "emailIngresado",
                    emailIngresado
                            .trim()
                            .toLowerCase()
            );
        }

        req.getRequestDispatcher(
                ViewRoutes.AUTH_LOGIN
        ).forward(req, resp);
    }

    // verificar si un texto está vacío o contiene espacios
    private boolean isBlank(String s) {

        return s == null
                || s.trim().isEmpty();
    }
}