package com.mycompany.herramientas.service;

import com.mycompany.herramientas.dao.UsuarioDAO;
import com.mycompany.herramientas.model.Usuario;

import java.sql.SQLException;
import java.util.logging.Level;
import java.util.logging.Logger;

// servicio de autenticación (login)
public class AuthService {

    private static final Logger LOGGER = Logger.getLogger(AuthService.class.getName());

    private final UsuarioDAO usuarioDAO;

    public AuthService() {
        this.usuarioDAO = new UsuarioDAO();
    }

    public AuthService(UsuarioDAO usuarioDAO) {
        this.usuarioDAO = usuarioDAO;
    }

    // ─── LOGIN ────────────────────────────────────────────────

    public Usuario login(String email, String rawPassword) {

        // validación básica
        if (email == null || rawPassword == null) return null;

        String emailLimpio = email.trim().toLowerCase();

        if (emailLimpio.isEmpty() || rawPassword.isEmpty()) return null;

        // buscar usuario
        Usuario usuario;

        try {

            usuario = usuarioDAO.findByEmail(emailLimpio);

        } catch (SQLException e) {

            LOGGER.log(Level.SEVERE, "Error BD login: " + emailLimpio, e);
            return null;
        }

        // ── LOGS TEMPORALES ──────────────────────────────────
        LOGGER.severe("DEBUG LOGIN - email: " + emailLimpio);
        LOGGER.severe("DEBUG LOGIN - usuario encontrado: " + (usuario != null));
        if (usuario != null) {
            LOGGER.severe("DEBUG LOGIN - estado: " + usuario.getEstado());
            LOGGER.severe("DEBUG LOGIN - activo: " + usuario.isActivo());
            LOGGER.severe("DEBUG LOGIN - hash: " + usuario.getPasswordUsuario());
            boolean okDebug = PasswordService.verificar(rawPassword, usuario.getPasswordUsuario());
            LOGGER.severe("DEBUG LOGIN - password ok: " + okDebug);
        }
        // ─────────────────────────────────────────────────────

        // usuario no existe
        if (usuario == null) {
            LOGGER.fine("Login fallido: no existe " + emailLimpio);
            return null;
        }

        // cuenta inactiva
        if (!usuario.isActivo()) {
            LOGGER.info("Login fallido: inactivo " + emailLimpio);
            return null;
        }

        // validar contraseña
        boolean ok = PasswordService.verificar(
                rawPassword,
                usuario.getPasswordUsuario()
        );

        if (!ok) {
            LOGGER.fine("Login fallido: password incorrecta " + emailLimpio);
            return null;
        }

        // actualizar hash si cambió el costo
        if (PasswordService.necesitaActualizacion(usuario.getPasswordUsuario())) {

            try {

                String nuevoHash = PasswordService.hashear(rawPassword);

                usuario.setPasswordUsuario(nuevoHash);
                usuarioDAO.actualizarPassword(usuario.getId(), nuevoHash);

                LOGGER.info("Hash actualizado: " + emailLimpio);

            } catch (Exception e) {

                LOGGER.log(Level.WARNING,
                        "No se pudo actualizar hash: " + emailLimpio, e);
            }
        }

        LOGGER.info("Login exitoso: " + emailLimpio + " rol=" + usuario.getIdRol());

        return usuario;
    }
}