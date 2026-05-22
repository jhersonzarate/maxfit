package com.mycompany.herramientas.service;

import com.mycompany.herramientas.dao.UsuarioDAO;
import com.mycompany.herramientas.model.Usuario;

import java.sql.SQLException;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * Servicio de autenticación.
 *
 * Centraliza la lógica de login en un solo lugar, separándola del controlador.
 * El LoginController solo llama a AuthService.login() y trabaja con el resultado.
 *
 * Flujo de login:
 *   1. Buscar usuario por email en la BD (UsuarioDAO.findByEmail).
 *   2. Verificar que el usuario exista y esté activo.
 *   3. Verificar la contraseña con BCrypt (PasswordService.verificar).
 *   4. Si todo es correcto, devolver el objeto Usuario para guardar en sesión.
 *
 * Por qué separar esto del controlador:
 *   - El controlador no debe contener lógica de negocio (principio MVC).
 *   - Si se cambia el mecanismo de autenticación (ej: LDAP, OAuth), solo se
 *     modifica este servicio, no el controlador.
 *   - Facilita probar la lógica de login sin necesidad de HTTP.
 */
public class AuthService {

    private static final Logger LOGGER = Logger.getLogger(AuthService.class.getName());

    private final UsuarioDAO usuarioDAO;

    public AuthService() {
        this.usuarioDAO = new UsuarioDAO();
    }

    /** Constructor con inyección de DAO (útil para tests). */
    public AuthService(UsuarioDAO usuarioDAO) {
        this.usuarioDAO = usuarioDAO;
    }

    /**
     * Intenta autenticar a un usuario con email y contraseña.
     *
     * @param email       correo ingresado en el formulario (puede venir con espacios)
     * @param rawPassword contraseña en texto plano ingresada en el formulario
     * @return el objeto Usuario si las credenciales son correctas y la cuenta está activa,
     *         null en cualquier otro caso (usuario no encontrado, contraseña incorrecta,
     *         cuenta inactiva, error de BD)
     */
    public Usuario login(String email, String rawPassword) {

        // ── Validación básica de entrada ─────────────────────────────────────
        if (email == null || rawPassword == null) return null;

        String emailLimpio = email.trim().toLowerCase();
        if (emailLimpio.isEmpty() || rawPassword.isEmpty()) return null;

        // ── Buscar usuario en la BD ──────────────────────────────────────────
        Usuario usuario;
        try {
            usuario = usuarioDAO.findByEmail(emailLimpio);
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE,
                    "Error de BD al intentar login para: " + emailLimpio, e);
            return null; // No exponer el error al controlador ni al usuario
        }

        // ── Verificar que exista y esté activo ───────────────────────────────
        if (usuario == null) {
            // No revelar si el email existe o no (seguridad)
            LOGGER.fine("Login fallido — email no encontrado: " + emailLimpio);
            return null;
        }

        if (!usuario.isActivo()) {
            LOGGER.info("Login fallido — cuenta inactiva: " + emailLimpio);
            return null;
        }

        // ── Verificar contraseña con BCrypt ──────────────────────────────────
        boolean passwordCorrecta = PasswordService.verificar(
                rawPassword,
                usuario.getPasswordUsuario()
        );

        if (!passwordCorrecta) {
            LOGGER.fine("Login fallido — contraseña incorrecta para: " + emailLimpio);
            return null;
        }

        // ── Re-hashear si el factor de coste subió (opcional pero recomendado) ──
        if (PasswordService.necesitaActualizacion(usuario.getPasswordUsuario())) {
            try {
                String nuevoHash = PasswordService.hashear(rawPassword);
                usuario.setPasswordUsuario(nuevoHash);
                usuarioDAO.actualizarPassword(usuario.getId(), nuevoHash);
                LOGGER.info("Hash actualizado para: " + emailLimpio);
            } catch (Exception e) {
                // Si falla la actualización del hash, el login igual procede.
                // Se intentará de nuevo en el próximo login exitoso.
                LOGGER.log(Level.WARNING,
                        "No se pudo actualizar el hash para: " + emailLimpio, e);
            }
        }

        LOGGER.info("Login exitoso: " + emailLimpio
                + " | rol: " + usuario.getIdRol());
        return usuario;
    }
}