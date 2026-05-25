package com.mycompany.herramientas.controller;

import com.mycompany.herramientas.config.AppConfig;
import com.mycompany.herramientas.dao.UsuarioDAO;
import com.mycompany.herramientas.model.Usuario;
import com.mycompany.herramientas.service.PasswordService;
import com.mycompany.herramientas.view.ViewRoutes;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;
import java.sql.SQLException;
import java.util.logging.Level;
import java.util.logging.Logger;

// recuperación de contraseña del sistema
@WebServlet("/forgot-password")
public class ForgotPasswordController extends HttpServlet {

    private static final Logger LOGGER =
            Logger.getLogger(ForgotPasswordController.class.getName());

    // longitud mínima permitida para la contraseña
    private static final int MIN_PASSWORD_LENGTH = 8;

    // atributo de sesión usado como guard del flujo de reset
    private static final String SESSION_RESET_EMAIL = "resetEmail";

    // mensaje genérico para evitar enumeración de usuarios
    private static final String MSG_GENERICO_PASO2 =
            "Si el correo está registrado y la cuenta está activa, "
            + "podrás establecer tu nueva contraseña a continuación. "
            + "De lo contrario, contacta al administrador del sistema.";

    private final UsuarioDAO usuarioDAO = new UsuarioDAO();

    // ───────────────── GET /forgot-password ───────────

    @Override
    protected void doGet(HttpServletRequest req,
                         HttpServletResponse resp)
            throws ServletException, IOException {

        HttpSession sesion = req.getSession(false);

        // si el usuario ya inició sesión → volver al login
        if (sesion != null
                && sesion.getAttribute(AppConfig.SESSION_USER_NAME) != null) {

            resp.sendRedirect(req.getContextPath() + "/login");

            return;
        }

        // limpiar flujo anterior de recuperación
        if (sesion != null) {
            sesion.removeAttribute(SESSION_RESET_EMAIL);
        }

        // mostrar formulario de ingreso de correo
        req.getRequestDispatcher(
                ViewRoutes.AUTH_FORGOT_PASSWORD
        ).forward(req, resp);
    }

    // ───────────────── POST /forgot-password ──────────

    @Override
    protected void doPost(HttpServletRequest req,
                          HttpServletResponse resp)
            throws ServletException, IOException {

        String action = req.getParameter("action");

        if ("reset".equals(action)) {

            procesarReset(req, resp);

        } else {

            // action=buscar
            procesarBusqueda(req, resp);
        }
    }

    // ───────────────── verificar email ────────────────

    private void procesarBusqueda(HttpServletRequest req,
                                  HttpServletResponse resp)
            throws ServletException, IOException {

        String email = req.getParameter("email");

        // validar campo vacío
        if (email == null || email.trim().isEmpty()) {
                
                req.setAttribute("errorMsg", "Ingresa tu correo electrónico registrado.");
                req.setAttribute("csrfToken", com.mycompany.herramientas.util.CsrfUtils.getOrCreate(req));
                req.getRequestDispatcher(ViewRoutes.AUTH_FORGOT_PASSWORD).forward(req, resp);
                
                return;
        }
        
        String emailLimpio = email.trim().toLowerCase();

        try {

            Usuario usuario = usuarioDAO.findByEmail(emailLimpio);

            // validar usuario activo
            if (usuario != null && usuario.isActivo()) {

                // habilitar paso de cambio de contraseña
                req.getSession(true).setAttribute(
                        SESSION_RESET_EMAIL,
                        emailLimpio
                );

                req.setAttribute("emailEncontrado", true);

                req.setAttribute(
                        "emailIngresado",
                        emailLimpio
                );

                LOGGER.fine(
                        "Inicio de reset de contraseña para: "
                                + emailLimpio
                );

            } else {

                // no revelar si el correo existe o no
                LOGGER.fine(
                        "Reset solicitado para email no activo/existente: "
                                + emailLimpio
                );
            }

        } catch (SQLException e) {

            LOGGER.log(
                    Level.SEVERE,
                    "Error de BD al buscar email en forgot-password: "
                            + emailLimpio,
                    e
            );
            
            req.setAttribute("errorMsg", "Error interno. Intenta nuevamente en unos momentos.");
            req.setAttribute("csrfToken", com.mycompany.herramientas.util.CsrfUtils.getOrCreate(req));
            req.getRequestDispatcher(ViewRoutes.AUTH_FORGOT_PASSWORD).forward(req, resp);
            
            return;
        }

        // mismo mensaje para ambos escenarios 
            req.setAttribute("infoMsg", MSG_GENERICO_PASO2);
            req.setAttribute("csrfToken", com.mycompany.herramientas.util.CsrfUtils.getOrCreate(req));
            req.getRequestDispatcher(ViewRoutes.AUTH_FORGOT_PASSWORD).forward(req, resp);

        }

    // ───────────────── aplicar nueva contraseña ───────

    private void procesarReset(HttpServletRequest req,
                               HttpServletResponse resp)
            throws IOException {

        HttpSession sesion = req.getSession(false);

        // verificar guard de sesión
        String resetEmail = (sesion != null)
                ? (String) sesion.getAttribute(SESSION_RESET_EMAIL)
                : null;

        // prevenir bypass directo al paso 3
        if (resetEmail == null || resetEmail.isBlank()) {

            LOGGER.warning(
                    "Intento de reset sin SESSION_RESET_EMAIL"
            );

            resp.sendRedirect(
                    req.getContextPath() + "/forgot-password"
            );

            return;
        }

        String nuevaPassword =
                req.getParameter("nuevaPassword");

        String confirmaPassword =
                req.getParameter("confirmaPassword");

        // validar longitud mínima
        if (nuevaPassword == null
                || nuevaPassword.length() < MIN_PASSWORD_LENGTH) {

            reenviarConErrorReset(
                    req,
                    resp,
                    resetEmail,
                    "La contraseña debe tener al menos "
                            + MIN_PASSWORD_LENGTH
                            + " caracteres."
            );

            return;
        }

        // validar coincidencia de contraseñas
        if (!nuevaPassword.equals(confirmaPassword)) {

            reenviarConErrorReset(
                    req,
                    resp,
                    resetEmail,
                    "Las contraseñas no coinciden."
            );

            return;
        }

        try {

            Usuario usuario =
                    usuarioDAO.findByEmail(resetEmail);

            // verificar que la cuenta siga activa
            if (usuario == null || !usuario.isActivo()) {

                LOGGER.warning(
                        "Reset abortado: cuenta inactiva o inexistente — "
                                + resetEmail
                );

                if (sesion != null) {
                    sesion.removeAttribute(SESSION_RESET_EMAIL);
                }

                resp.sendRedirect(
                        req.getContextPath()
                                + "/forgot-password?err=cuenta_inactiva"
                );

                return;
            }

            // hashear contraseña con BCrypt
            String nuevoHash =
                    PasswordService.hashear(nuevaPassword);

            usuarioDAO.actualizarPassword(
                    usuario.getId(),
                    nuevoHash
            );

            LOGGER.info(
                    "Contraseña restablecida exitosamente para: "
                            + resetEmail
            );

            // limpiar guard de sesión
            if (sesion != null) {
                sesion.removeAttribute(SESSION_RESET_EMAIL);
            }

            // redirigir al login con mensaje de éxito
            resp.sendRedirect(
                    req.getContextPath()
                            + "/login?msg=password_reset"
            );

        } catch (Exception e) {

            LOGGER.log(
                    Level.SEVERE,
                    "Error al restablecer contraseña para: "
                            + resetEmail,
                    e
            );

            reenviarConErrorReset(
                    req,
                    resp,
                    resetEmail,
                    "Error interno al actualizar la contraseña."
            );
        }
    }

    // ───────────────── helper privado ─────────────────

    // reenviar formulario de reset manteniendo el flujo activo
    private void reenviarConErrorReset(HttpServletRequest req,
                                       HttpServletResponse resp,
                                       String email,
                                       String errorMsg)
            throws IOException {

        try {

            req.setAttribute("errorMsg", errorMsg);

            req.setAttribute(
                    "emailEncontrado",
                    true
            );
            
            req.setAttribute("emailIngresado", email);
            req.setAttribute("csrfToken", com.mycompany.herramientas.util.CsrfUtils.getOrCreate(req));
            req.getRequestDispatcher(ViewRoutes.AUTH_FORGOT_PASSWORD).forward(req, resp);

        } catch (ServletException e) {

            LOGGER.log(
                    Level.SEVERE,
                    "Error al reenviar formulario de reset",
                    e
            );

            // fallback al inicio del flujo
            resp.sendRedirect(
                    req.getContextPath() + "/forgot-password"
            );
        }
    }
}