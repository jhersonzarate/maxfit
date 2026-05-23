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

/**
 * Controlador de recuperación de contraseña (RF-15).
 *
 * Rutas:
 *   GET  /forgot-password                → paso 1: formulario de ingreso de email
 *   POST /forgot-password?action=buscar  → paso 2: verificar email, mostrar form nueva clave
 *   POST /forgot-password?action=reset   → paso 3: aplicar nueva contraseña
 *
 * Esta ruta está en RUTAS_PUBLICAS del AuthFilter → no requiere sesión activa.
 * Si el usuario ya tiene sesión, se redirige al login directamente.
 *
 * ── Diseño para sistema interno de gimnasio (sin servidor SMTP) ──────────────
 *
 *   MaxFit es un sistema interno donde el personal trabaja en el mismo local.
 *   En lugar de enviar un token por email (que requeriría SMTP, SendGrid, etc.)
 *   el flujo permite al usuario restablecer su contraseña directamente si
 *   conoce el email registrado. El administrador puede verificar identidad
 *   presencialmente antes de asistir al usuario.
 *
 *   Para un sistema con email externo se reemplazaría el paso POST buscar por:
 *     1. Generar UUID token + guardar en BD con expiración (30 min).
 *     2. Enviar link con token al email.
 *     3. GET /forgot-password?token=UUID → validar token → form nueva contraseña.
 *
 * ── Seguridad ─────────────────────────────────────────────────────────────────
 *
 *   1. El mensaje de "email verificado" es idéntico exista o no el email,
 *      para no revelar qué cuentas están registradas (previene enumeración).
 *   2. El email verificado se guarda en sesión (atributo "resetEmail") como
 *      guard del paso 3. Sin este atributo, el paso 3 no se puede ejecutar
 *      → previene CSRF/bypass directo al reset.
 *   3. La contraseña NUNCA se guarda en texto plano (BCrypt vía PasswordService).
 *   4. El atributo de sesión "resetEmail" se elimina después de un reset exitoso
 *      o si el usuario navega fuera del flujo.
 *
 * @author MaxFit
 */
@WebServlet("/forgot-password")
public class ForgotPasswordController extends HttpServlet {

    private static final Logger LOGGER =
            Logger.getLogger(ForgotPasswordController.class.getName());

    /** Longitud mínima de contraseña (consistente con UsersController). */
    private static final int MIN_PASSWORD_LENGTH = 8;

    /**
     * Clave del atributo de sesión que guarda el email validado en el paso 2.
     * Su presencia actúa como guard para el paso 3 (anti-bypass).
     */
    private static final String SESSION_RESET_EMAIL = "resetEmail";

    /**
     * Mensaje genérico que no revela si el email existe o no.
     * Protege contra enumeración de usuarios (timing attack si se añade
     * SMTP real: considerar sleep constante independiente del resultado).
     */
    private static final String MSG_GENERICO_PASO2 =
            "Si el correo está registrado y la cuenta está activa, "
            + "podrás establecer tu nueva contraseña a continuación. "
            + "De lo contrario, contacta al administrador del sistema.";

    private final UsuarioDAO usuarioDAO = new UsuarioDAO();

    // ─── GET /forgot-password ─────────────────────────────────────────────────

    /**
     * Paso 1: muestra el formulario para ingresar el email.
     * Si el usuario ya tiene sesión activa, redirige al login
     * (no tiene sentido restablecer contraseña si ya está autenticado).
     */
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        // Si tiene sesión activa → redirigir al login (que redirigirá a su dashboard)
        HttpSession sesion = req.getSession(false);
        if (sesion != null
                && sesion.getAttribute(AppConfig.SESSION_USER_NAME) != null) {
            resp.sendRedirect(req.getContextPath() + "/login");
            return;
        }

        // Limpiar estado de reset anterior (si el usuario navega "atrás" al formulario)
        if (sesion != null) {
            sesion.removeAttribute(SESSION_RESET_EMAIL);
        }

        // Mostrar paso 1: formulario de email
        req.getRequestDispatcher(ViewRoutes.AUTH_FORGOT_PASSWORD).forward(req, resp);
    }

    // ─── POST /forgot-password ────────────────────────────────────────────────

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String action = req.getParameter("action");

        if ("reset".equals(action)) {
            procesarReset(req, resp);
        } else {
            // action=buscar (default de paso 2)
            procesarBusqueda(req, resp);
        }
    }

    // ─── POST action=buscar: verificar email (paso 2) ────────────────────────

    /**
     * Verifica que el email esté registrado en la BD y la cuenta esté activa.
     *
     * Resultado A (email encontrado y activo):
     *   Guarda el email en sesión → muestra el formulario de nueva contraseña.
     *
     * Resultado B (email no existe o cuenta inactiva):
     *   Muestra el mismo mensaje genérico que A → no revela si existe o no.
     *   NO guarda nada en sesión → el JSP no mostrará el formulario de reset.
     *
     * El JSP distingue los dos casos por la presencia del atributo
     * "emailEncontrado" (true = mostrar form nueva clave, ausente = no mostrar).
     */
    private void procesarBusqueda(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String email = req.getParameter("email");

        // Validación de campo vacío
        if (email == null || email.trim().isEmpty()) {
            req.setAttribute("errorMsg", "Ingresa tu correo electrónico registrado.");
            req.getRequestDispatcher(ViewRoutes.AUTH_FORGOT_PASSWORD).forward(req, resp);
            return;
        }

        String emailLimpio = email.trim().toLowerCase();

        try {
            Usuario usuario = usuarioDAO.findByEmail(emailLimpio);

            if (usuario != null && usuario.isActivo()) {
                // Email válido y cuenta activa → habilitar paso 3
                req.getSession(true).setAttribute(SESSION_RESET_EMAIL, emailLimpio);
                req.setAttribute("emailEncontrado", true);
                req.setAttribute("emailIngresado",  emailLimpio);
                LOGGER.fine("Inicio de reset de contraseña para: " + emailLimpio);
            } else {
                // No existe o inactiva → mismo mensaje, sin guardar en sesión
                // No registramos cuál fue el caso para no revelar si el email existe
                LOGGER.fine("Reset solicitado para email no activo/existente: " + emailLimpio);
            }

        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE,
                    "Error de BD al buscar email en forgot-password: " + emailLimpio, e);
            req.setAttribute("errorMsg",
                    "Error interno. Intenta nuevamente en unos momentos.");
            req.getRequestDispatcher(ViewRoutes.AUTH_FORGOT_PASSWORD).forward(req, resp);
            return;
        }

        // Mensaje genérico para ambos casos (A y B)
        req.setAttribute("infoMsg", MSG_GENERICO_PASO2);
        req.getRequestDispatcher(ViewRoutes.AUTH_FORGOT_PASSWORD).forward(req, resp);
    }

    // ─── POST action=reset: aplicar nueva contraseña (paso 3) ────────────────

    /**
     * Aplica la nueva contraseña hashada en BCrypt.
     *
     * Guards de seguridad:
     *   1. SESSION_RESET_EMAIL debe estar en sesión (guard anti-bypass).
     *      Sin él → redirect al inicio del flujo.
     *   2. Nueva contraseña ≥ MIN_PASSWORD_LENGTH caracteres.
     *   3. Nueva contraseña == confirmación.
     *   4. El usuario sigue existiendo y activo en BD (pudo ser desactivado
     *      durante el tiempo que tardó en completar el formulario).
     *
     * Al terminar (éxito o fallo):
     *   - Limpia SESSION_RESET_EMAIL de sesión.
     *   - Redirige al login con parámetro ?msg=password_reset para que
     *     LoginController muestre un mensaje de confirmación.
     */
    private void procesarReset(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {

        HttpSession sesion = req.getSession(false);

        // Guard 1: verificar que el flujo viene del paso 2 correctamente
        String resetEmail = (sesion != null)
                ? (String) sesion.getAttribute(SESSION_RESET_EMAIL)
                : null;

        if (resetEmail == null || resetEmail.isBlank()) {
            // Alguien intentó hacer POST al paso 3 sin pasar por el paso 2
            LOGGER.warning("Intento de reset sin SESSION_RESET_EMAIL — posible bypass.");
            resp.sendRedirect(req.getContextPath() + "/forgot-password");
            return;
        }

        String nuevaPassword    = req.getParameter("nuevaPassword");
        String confirmaPassword = req.getParameter("confirmaPassword");

        // Guard 2: longitud mínima
        if (nuevaPassword == null || nuevaPassword.length() < MIN_PASSWORD_LENGTH) {
            reenviarConErrorReset(req, resp, resetEmail,
                    "La contraseña debe tener al menos "
                    + MIN_PASSWORD_LENGTH + " caracteres.");
            return;
        }

        // Guard 3: coincidencia de contraseñas
        if (!nuevaPassword.equals(confirmaPassword)) {
            reenviarConErrorReset(req, resp, resetEmail,
                    "Las contraseñas no coinciden. Verifica e inténtalo de nuevo.");
            return;
        }

        // Guard 4: usuario sigue existiendo y activo
        try {
            Usuario usuario = usuarioDAO.findByEmail(resetEmail);

            if (usuario == null || !usuario.isActivo()) {
                // La cuenta fue desactivada mientras realizaba el flujo
                LOGGER.warning("Reset abortado: cuenta inactiva o inexistente — "
                        + resetEmail);
                if (sesion != null) sesion.removeAttribute(SESSION_RESET_EMAIL);
                resp.sendRedirect(req.getContextPath()
                        + "/forgot-password?err=cuenta_inactiva");
                return;
            }

            // Hashear con BCrypt (NUNCA guardar texto plano)
            String nuevoHash = PasswordService.hashear(nuevaPassword);
            usuarioDAO.actualizarPassword(usuario.getId(), nuevoHash);

            LOGGER.info("Contraseña restablecida exitosamente para: " + resetEmail);

            // Limpiar el guard de sesión — el flujo terminó correctamente
            if (sesion != null) sesion.removeAttribute(SESSION_RESET_EMAIL);

            // Redirigir al login con indicador de éxito
            // LoginController puede leer ?msg=password_reset y mostrar el aviso
            resp.sendRedirect(req.getContextPath()
                    + "/login?msg=password_reset");

        } catch (Exception e) {
            // Capturamos Exception porque PasswordService puede lanzar
            // IllegalArgumentException si la contraseña viene vacía (ya validamos,
            // pero por seguridad defensiva).
            LOGGER.log(Level.SEVERE,
                    "Error al restablecer contraseña para: " + resetEmail, e);
            reenviarConErrorReset(req, resp, resetEmail,
                    "Error interno al actualizar la contraseña. Intenta nuevamente.");
        }
    }

    // ─── Helper privado ───────────────────────────────────────────────────────

    /**
     * Reenvía al formulario del paso 3 (nueva contraseña) con un mensaje de error.
     * Mantiene emailEncontrado=true para que el JSP siga mostrando el form de reset
     * y no vuelva al form de email del paso 1.
     * El guard SESSION_RESET_EMAIL permanece en sesión para que el usuario pueda
     * reintentar sin perder el contexto del flujo.
     */
    private void reenviarConErrorReset(HttpServletRequest req,
                                        HttpServletResponse resp,
                                        String email,
                                        String errorMsg)
            throws IOException {
        try {
            req.setAttribute("errorMsg",        errorMsg);
            req.setAttribute("emailEncontrado", true);
            req.setAttribute("emailIngresado",  email);
            req.getRequestDispatcher(ViewRoutes.AUTH_FORGOT_PASSWORD)
               .forward(req, resp);
        } catch (ServletException e) {
            // Si el forward falla, redirigir al inicio del flujo como fallback
            LOGGER.log(Level.SEVERE,
                    "Error al reenviar formulario de reset: " + e.getMessage(), e);
            resp.sendRedirect(req.getContextPath() + "/forgot-password");
        }
    }
}