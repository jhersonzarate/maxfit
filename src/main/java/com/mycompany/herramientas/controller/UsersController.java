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

// controlador de gestión de usuarios del sistema (RF-14)
@WebServlet("/users")
public class UsersController extends AbstractController {

    private static final Logger LOGGER =
            Logger.getLogger(UsersController.class.getName());

    // longitud mínima de contraseña (política básica)
    private static final int MIN_PASSWORD_LENGTH = 8;

    private final UsuarioDAO  usuarioDAO  = new UsuarioDAO();
    private final EmpleadoDAO empleadoDAO = new EmpleadoDAO();
    private final CatalogoDAO catalogoDAO = new CatalogoDAO();

    // ─── GET ───────────────────────────────────────────────────

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        transferirFlashMessages(req);

        String action = getAction(req);

        switch (action) {

            // formulario de creación
            case "new":
                mostrarFormularioNuevo(req, resp);
                break;

            // formulario de edición
            case "edit":
                mostrarFormularioEdicion(req, resp);
                break;

            // lista de usuarios
            default:
                mostrarLista(req, resp);
        }
    }

    // ─── POST ──────────────────────────────────────────────────

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String action = getAction(req);

        switch (action) {

            // crear o actualizar usuario
            case "save":
                guardarUsuario(req, resp);
                break;

            // activar o inactivar cuenta
            case "toggleEstado":
                toggleEstadoUsuario(req, resp);
                break;

            // resetear contraseña
            case "resetPassword":
                resetearContrasena(req, resp);
                break;

            default:
                redirigirA("/users", req, resp);
        }
    }

    // ─── lista de usuarios ─────────────────────────────────────

    // carga todos los usuarios para mostrar en la tabla
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

    // ─── formulario nuevo usuario ──────────────────────────────

    // prepara el formulario vacío para crear un usuario
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

    // ─── formulario edición usuario ────────────────────────────

    // carga el usuario existente en el formulario para editar
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

    // ─── guardar usuario ───────────────────────────────────────

    // crea o actualiza un usuario según si llega id o no
    private void guardarUsuario(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String id           = param(req, "id");
        String email        = param(req, "email");
        String rawPassword  = param(req, "password");       // solo en creación
        String idRol        = param(req, "idRol");
        String idEmpleado   = param(req, "idEmpleado");

        boolean esNuevo = (id == null || id.isBlank());

        // validar campos obligatorios
        if (email == null || email.isBlank()) {
            volverAlFormulario(req, resp, esNuevo, id, "El correo es obligatorio.");
            return;
        }
        if (idRol == null || idRol.isBlank()) {
            volverAlFormulario(req, resp, esNuevo, id, "Debe seleccionar un rol.");
            return;
        }
        if (idEmpleado == null || idEmpleado.isBlank()) {
            volverAlFormulario(req, resp, esNuevo, id, "Debe seleccionar un empleado.");
            return;
        }
        // contraseña obligatoria solo al crear
        if (esNuevo && (rawPassword == null || rawPassword.length() < MIN_PASSWORD_LENGTH)) {
            volverAlFormulario(req, resp, esNuevo, id,
                    "La contraseña debe tener al menos " + MIN_PASSWORD_LENGTH
                    + " caracteres.");
            return;
        }

        try {
            // verificar que el rol exista en catálogo
            Rol rol = catalogoDAO.findRolById(idRol);
            if (rol == null) {
                volverAlFormulario(req, resp, esNuevo, id, "El rol seleccionado no es válido.");
                return;
            }

            // verificar empleado vinculado
            Empleado empleado = null;
            if (idEmpleado != null && !idEmpleado.isBlank()) {
                empleado = empleadoDAO.findById(idEmpleado);
                if (empleado == null) {
                    volverAlFormulario(req, resp, esNuevo, id,
                            "El empleado seleccionado no existe.");
                    return;
                }
            }

            // construir objeto usuario
            Usuario usuario = new Usuario();
            usuario.setId(esNuevo ? IdGenerator.parUsuario() : id);
            usuario.setEmail(email.trim().toLowerCase());
            usuario.setRol(rol);
            usuario.setEmpleado(empleado);
            usuario.setEstado(AppConfig.ESTADO_ACTIVO); // activo por defecto

            // contraseña: hashear solo en creación; en edición conservar el hash existente
            if (esNuevo) {
                // hashear con BCrypt — nunca guardar en texto plano
                usuario.setPasswordUsuario(PasswordService.hashear(rawPassword));
            } else {
                // mantener hash y estado actuales del usuario
                Usuario existente = usuarioDAO.findById(id);
                if (existente == null) {
                    mensajeError(req, "Usuario no encontrado para actualizar.");
                    redirigirA("/users", req, resp);
                    return;
                }
                usuario.setPasswordUsuario(existente.getPasswordUsuario());
                usuario.setEstado(existente.getEstado());
            }

            // verificar email duplicado antes de guardar
            Usuario emailExistente = usuarioDAO.findByEmail(email);
            if (emailExistente != null && !emailExistente.getId().equals(id == null ? "" : id)) {
                volverAlFormulario(req, resp, esNuevo, id,
                        "El correo " + email + " ya está registrado en otro usuario.");
                return;
            }

            // verificar que el empleado no tenga ya una cuenta asignada
            if (idEmpleado != null && !idEmpleado.isBlank()) {
                Usuario empExistente = usuarioDAO.findByEmpleadoId(idEmpleado);
                if (empExistente != null && !empExistente.getId().equals(id == null ? "" : id)) {
                    volverAlFormulario(req, resp, esNuevo, id,
                            "El empleado seleccionado ya tiene una cuenta asignada.");
                    return;
                }
            }

            // persistir en BD
            usuarioDAO.save(usuario);

            String accion = esNuevo ? "creado" : "actualizado";
            LOGGER.info("Usuario " + accion + ": " + usuario.getEmail()
                    + " | rol: " + idRol);
            mensajeExito(req, "Usuario " + usuario.getEmail() + " " + accion
                    + " correctamente.");
            redirigirA("/users", req, resp);

        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error al guardar usuario", e);
            // distinguir violación de UNIQUE para mensaje más claro
            String msg;
            if (e.getMessage() != null && e.getMessage().contains("UNIQUE")) {
                msg = "El correo o el empleado vinculado ya tiene una cuenta asignada.";
            } else {
                msg = "Error al guardar el usuario. Intenta nuevamente.";
            }
            volverAlFormulario(req, resp, esNuevo, id, msg);
        }
    }

    // ─── toggle estado usuario ─────────────────────────────────

    // alterna la cuenta entre activo e inactivo
    // el admin no puede desactivar su propia cuenta (previene auto-bloqueo)
    private void toggleEstadoUsuario(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {

        String id = param(req, "id");
        if (id == null) {
            mensajeError(req, "ID de usuario no especificado.");
            redirigirA("/users", req, resp);
            return;
        }

        // prevenir que el admin se bloquee a sí mismo
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

            // alternar estado
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

    // ─── resetear contraseña ───────────────────────────────────

    // el admin asigna una contraseña nueva — se hashea con BCrypt antes de guardar
    // nunca se loguea la contraseña en texto plano
    private void resetearContrasena(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {

        String id          = param(req, "id");
        String rawPassword = param(req, "newPassword");

        if (id == null || rawPassword == null) {
            mensajeError(req, "Datos incompletos para el reseteo de contraseña.");
            redirigirA("/users", req, resp);
            return;
        }

        // validar longitud mínima
        if (rawPassword.length() < MIN_PASSWORD_LENGTH) {
            mensajeError(req, "La nueva contraseña debe tener al menos "
                    + MIN_PASSWORD_LENGTH + " caracteres.");
            redirigirA("/users", req, resp);
            return;
        }

        try {
            // hashear y persistir — nunca guardar en texto plano
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

    // ─── helpers privados ──────────────────────────────────────

    // carga roles y empleados en el request para los selects del formulario
    private void cargarCatalogosFormulario(HttpServletRequest req) throws SQLException {
        req.setAttribute("roles",     catalogoDAO.findAllRoles());
        req.setAttribute("empleados", empleadoDAO.findAll());
    }

    // recarga el formulario mostrando el error recibido
    private void volverAlFormulario(HttpServletRequest req,
                                     HttpServletResponse resp,
                                     boolean esNuevo,
                                     String id,
                                     String errorMsg)
            throws ServletException, IOException {

        // formError: exclusivo para errores inline — el navbar no lo renderiza
        req.setAttribute("formError",    errorMsg);
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