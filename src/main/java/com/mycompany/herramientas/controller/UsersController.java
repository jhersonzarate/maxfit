package com.mycompany.herramientas.controller;

import com.mycompany.herramientas.config.AppConfig;
import com.mycompany.herramientas.dao.*;
import com.mycompany.herramientas.model.*;
import com.mycompany.herramientas.service.PasswordService;
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
 * Controlador de Gestión de Usuarios del Sistema (RF-14).
 *
 * Rutas y acciones:
 *   GET  /users                    → lista de usuarios
 *   GET  /users?action=new         → formulario de creación
 *   GET  /users?action=edit&id=USR-XXX → formulario de edición
 *   POST /users?action=save        → crear o actualizar usuario
 *   POST /users?action=toggleEstado&id=USR-XXX → activar/inactivar cuenta
 *   POST /users?action=resetPassword&id=USR-XXX → resetear contraseña
 *
 * Acceso: ROL-ADMIN únicamente (RoleFilter → /users).
 *
 * Seguridad:
 *   - La contraseña NUNCA se muestra en ningún formulario ni log.
 *   - Al crear: se hashea con PasswordService.hashear() antes de guardar.
 *   - Al resetear: el admin ingresa la nueva contraseña y se hashea de nuevo.
 *   - El admin NO puede desactivar su propia cuenta (previene auto-bloqueo).
 *   - id_empleado es UNIQUE en la BD: un empleado → máximo un usuario.
 *
 * Regla de negocio:
 *   Un usuario puede existir sin empleado vinculado (id_empleado nullable),
 *   pero en la práctica todos los usuarios del sistema son empleados.
 *
 * @author MaxFit
 */
@WebServlet("/users")
public class UsersController extends AbstractController {

    private static final Logger LOGGER =
            Logger.getLogger(UsersController.class.getName());

    // Longitud mínima de contraseña (política básica)
    private static final int MIN_PASSWORD_LENGTH = 8;

    private final UsuarioDAO  usuarioDAO  = new UsuarioDAO();
    private final EmpleadoDAO empleadoDAO = new EmpleadoDAO();
    private final CatalogoDAO catalogoDAO = new CatalogoDAO();

    // ─── GET ──────────────────────────────────────────────────────────────────

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        transferirFlashMessages(req);

        String action = getAction(req);

        switch (action) {
            case "new":
                mostrarFormularioNuevo(req, resp);
                break;
            case "edit":
                mostrarFormularioEdicion(req, resp);
                break;
            default:
                mostrarLista(req, resp);
        }
    }

    // ─── POST ─────────────────────────────────────────────────────────────────

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String action = getAction(req);

        switch (action) {
            case "save":
                guardarUsuario(req, resp);
                break;
            case "toggleEstado":
                toggleEstadoUsuario(req, resp);
                break;
            case "resetPassword":
                resetearContrasena(req, resp);
                break;
            default:
                redirigirA("/users", req, resp);
        }
    }

    // ─── GET: lista de usuarios ───────────────────────────────────────────────

    private void mostrarLista(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        try {
            List<Usuario> usuarios = usuarioDAO.findAll();
            req.setAttribute("usuarios",      usuarios);
            req.setAttribute("totalUsuarios", usuarios.size());
            irA(ViewRoutes.USERS_INDEX, req, resp);
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error al listar usuarios", e);
            req.setAttribute("errorMsg", "Error al cargar los usuarios.");
            irA(ViewRoutes.USERS_INDEX, req, resp);
        }
    }

    // ─── GET: formulario de nuevo usuario ─────────────────────────────────────

    private void mostrarFormularioNuevo(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        try {
            cargarCatalogosFormulario(req);
            req.setAttribute("modoEdicion", false);
            req.setAttribute("usuario",     new Usuario());
            irA(ViewRoutes.USERS_INDEX + "?form=true", req, resp);
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error al cargar formulario de usuario", e);
            mensajeError(req, "Error al cargar el formulario.");
            redirigirA("/users", req, resp);
        }
    }

    // ─── GET: formulario de edición ───────────────────────────────────────────

    private void mostrarFormularioEdicion(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String id = param(req, "id");
        if (id == null) {
            mensajeError(req, "ID de usuario no especificado.");
            redirigirA("/users", req, resp);
            return;
        }

        try {
            Usuario usuario = usuarioDAO.findById(id);
            if (usuario == null) {
                mensajeError(req, "No se encontró el usuario con ID: " + id);
                redirigirA("/users", req, resp);
                return;
            }
            cargarCatalogosFormulario(req);
            req.setAttribute("usuario",     usuario);
            req.setAttribute("modoEdicion", true);
            irA(ViewRoutes.USERS_INDEX + "?form=true", req, resp);
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error al cargar usuario para edición: " + id, e);
            mensajeError(req, "Error al cargar el usuario.");
            redirigirA("/users", req, resp);
        }
    }

    // ─── POST: crear o actualizar usuario ────────────────────────────────────

    private void guardarUsuario(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String id           = param(req, "id");
        String email        = param(req, "email");
        String rawPassword  = param(req, "password");          // solo en creación
        String idRol        = param(req, "idRol");
        String idEmpleado   = param(req, "idEmpleado");        // puede ser null

        boolean esNuevo = (id == null || id.isBlank());

        // ── Validaciones básicas ─────────────────────────────────────────────
        if (email == null) {
            volverAlFormulario(req, resp, esNuevo, id, "El correo es obligatorio.");
            return;
        }
        if (idRol == null) {
            volverAlFormulario(req, resp, esNuevo, id, "Debe seleccionar un rol.");
            return;
        }
        // Contraseña obligatoria solo en creación
        if (esNuevo && (rawPassword == null || rawPassword.length() < MIN_PASSWORD_LENGTH)) {
            volverAlFormulario(req, resp, esNuevo, id,
                    "La contraseña debe tener al menos " + MIN_PASSWORD_LENGTH
                    + " caracteres.");
            return;
        }

        try {
            // ── Verificar rol válido ─────────────────────────────────────────
            Rol rol = catalogoDAO.findRolById(idRol);
            if (rol == null) {
                volverAlFormulario(req, resp, esNuevo, id, "El rol seleccionado no es válido.");
                return;
            }

            // ── Verificar empleado vinculado (opcional) ──────────────────────
            Empleado empleado = null;
            if (idEmpleado != null && !idEmpleado.isBlank()) {
                empleado = empleadoDAO.findById(idEmpleado);
                if (empleado == null) {
                    volverAlFormulario(req, resp, esNuevo, id,
                            "El empleado seleccionado no existe.");
                    return;
                }
            }

            // ── Construir objeto Usuario ──────────────────────────────────
            Usuario usuario = new Usuario();
            usuario.setId(esNuevo ? IdGenerator.parUsuario() : id);
            usuario.setEmail(email.trim().toLowerCase());
            usuario.setRol(rol);
            usuario.setEmpleado(empleado);
            usuario.setEstado(AppConfig.ESTADO_ACTIVO); // activo por defecto

            // ── Contraseña: solo en creación; en edición no se toca ─────────
            if (esNuevo) {
                // Hashear la contraseña con BCrypt (NUNCA guardar en texto plano)
                usuario.setPasswordUsuario(PasswordService.hashear(rawPassword));
            } else {
                // En edición: mantener el hash existente
                Usuario existente = usuarioDAO.findById(id);
                if (existente == null) {
                    mensajeError(req, "Usuario no encontrado para actualizar.");
                    redirigirA("/users", req, resp);
                    return;
                }
                usuario.setPasswordUsuario(existente.getPasswordUsuario());
                usuario.setEstado(existente.getEstado()); // mantener estado actual
            }

            // ── Persistir ─────────────────────────────────────────────────
            usuarioDAO.save(usuario);
            String accion = esNuevo ? "creado" : "actualizado";
            LOGGER.info("Usuario " + accion + ": " + usuario.getEmail()
                    + " | rol: " + idRol);
            mensajeExito(req, "Usuario " + usuario.getEmail() + " " + accion
                    + " correctamente.");
            redirigirA("/users", req, resp);

        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error al guardar usuario", e);
            String msg;
            if (e.getMessage() != null && e.getMessage().contains("UNIQUE")) {
                msg = "El correo o el empleado vinculado ya tiene una cuenta asignada.";
            } else {
                msg = "Error al guardar el usuario. Intenta nuevamente.";
            }
            volverAlFormulario(req, resp, esNuevo, id, msg);
        }
    }

    // ─── POST: activar / inactivar cuenta ────────────────────────────────────

    /**
     * Alterna el estado de un usuario entre 'activo' e 'inactivo'.
     * El admin NO puede inactivar su propia cuenta (previene auto-bloqueo).
     */
    private void toggleEstadoUsuario(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {

        String id = param(req, "id");
        if (id == null) {
            mensajeError(req, "ID de usuario no especificado.");
            redirigirA("/users", req, resp);
            return;
        }

        // Prevenir auto-bloqueo del administrador
        String miId = getSessionUserId(req);
        if (id.equals(miId)) {
            mensajeError(req, "No puedes desactivar tu propia cuenta.");
            redirigirA("/users", req, resp);
            return;
        }

        try {
            Usuario usuario = usuarioDAO.findById(id);
            if (usuario == null) {
                mensajeError(req, "No se encontró el usuario.");
                redirigirA("/users", req, resp);
                return;
            }

            // Alternar estado
            String nuevoEstado = usuario.isActivo()
                    ? AppConfig.ESTADO_INACTIVO
                    : AppConfig.ESTADO_ACTIVO;
            usuario.setEstado(nuevoEstado);
            usuarioDAO.save(usuario);

            LOGGER.info("Estado de usuario cambiado: " + usuario.getEmail()
                    + " → " + nuevoEstado);
            mensajeExito(req, "Cuenta de " + usuario.getEmail()
                    + " " + (usuario.isActivo() ? "reactivada" : "desactivada")
                    + " correctamente.");

        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error al cambiar estado del usuario: " + id, e);
            mensajeError(req, "Error al cambiar el estado. Intenta nuevamente.");
        }

        redirigirA("/users", req, resp);
    }

    // ─── POST: resetear contraseña ────────────────────────────────────────────

    /**
     * El admin puede asignar una contraseña nueva a cualquier usuario.
     * La contraseña nueva se hashea con BCrypt antes de guardar.
     * NUNCA se log-ea la contraseña en texto plano.
     */
    private void resetearContrasena(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {

        String id          = param(req, "id");
        String rawPassword = param(req, "newPassword");

        if (id == null || rawPassword == null) {
            mensajeError(req, "Datos incompletos para el reseteo de contraseña.");
            redirigirA("/users", req, resp);
            return;
        }

        if (rawPassword.length() < MIN_PASSWORD_LENGTH) {
            mensajeError(req, "La nueva contraseña debe tener al menos "
                    + MIN_PASSWORD_LENGTH + " caracteres.");
            redirigirA("/users", req, resp);
            return;
        }

        try {
            // Hashear la nueva contraseña con BCrypt (NUNCA guardar en texto plano)
            String nuevoHash = PasswordService.hashear(rawPassword);
            usuarioDAO.actualizarPassword(id, nuevoHash);

            LOGGER.info("Contraseña reseteada por admin para usuario ID: " + id);
            mensajeExito(req, "Contraseña actualizada correctamente.");

        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error al resetear contraseña del usuario: " + id, e);
            mensajeError(req, "Error al actualizar la contraseña. Intenta nuevamente.");
        }

        redirigirA("/users", req, resp);
    }

    // ─── Helpers privados ─────────────────────────────────────────────────────

    /**
     * Carga los catálogos necesarios para el formulario: roles y empleados.
     * Los empleados sin usuario vinculado se filtran en la vista para el select.
     */
    private void cargarCatalogosFormulario(HttpServletRequest req) throws SQLException {
        req.setAttribute("roles",     catalogoDAO.findAllRoles());
        req.setAttribute("empleados", empleadoDAO.findAll());
    }

    private void volverAlFormulario(HttpServletRequest req,
                                     HttpServletResponse resp,
                                     boolean esNuevo,
                                     String id,
                                     String errorMsg)
            throws ServletException, IOException {

        req.setAttribute("errorMsg",    errorMsg);
        req.setAttribute("modoEdicion", !esNuevo);

        try {
            cargarCatalogosFormulario(req);
            if (!esNuevo && id != null) {
                Usuario original = usuarioDAO.findById(id);
                req.setAttribute("usuario", original != null ? original : new Usuario());
            } else {
                req.setAttribute("usuario", new Usuario());
            }
        } catch (SQLException e) {
            LOGGER.log(Level.WARNING, "Error al recargar formulario de usuario", e);
        }

        irA(ViewRoutes.USERS_INDEX + "?form=true", req, resp);
    }
}