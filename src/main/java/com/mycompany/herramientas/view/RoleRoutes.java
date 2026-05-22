package com.mycompany.herramientas.view;

import com.mycompany.herramientas.config.AppConfig;

/**
 * Mapea cada rol a la URL de inicio a la que debe redirigirse tras el login.
 *
 * Centralizar esto evita tener la lógica de redirección dispersa en
 * LoginController, AuthFilter u otros lugares.
 *
 * Uso en LoginController:
 *   String urlInicio = RoleRoutes.getUrlInicio(usuario.getIdRol());
 *   resp.sendRedirect(req.getContextPath() + urlInicio);
 */
public final class RoleRoutes {

    private RoleRoutes() {}

    /**
     * Devuelve la URL relativa al contexto a la que debe ir el usuario
     * según su rol después de iniciar sesión.
     *
     * @param idRol el ID del rol (usar constantes de AppConfig.ROL_*)
     * @return URL relativa, ej: "/inicio", "/dashboard", "/instructor"
     */
    public static String getUrlInicio(String idRol) {
        if (idRol == null) return "/login";

        switch (idRol) {
            case AppConfig.ROL_ADMIN:      return "/inicio";
            case AppConfig.ROL_RECEP:      return "/dashboard";
            case AppConfig.ROL_INSTRUCTOR: return "/instructor";
            default:                       return "/login";
        }
    }

    /**
     * Nombre legible del rol para mostrar en la UI (navbar, logs, etc.).
     *
     * @param idRol el ID del rol
     * @return nombre en español, ej: "Administrador"
     */
    public static String getNombreRol(String idRol) {
        if (idRol == null) return "Desconocido";

        switch (idRol) {
            case AppConfig.ROL_ADMIN:      return "Administrador";
            case AppConfig.ROL_RECEP:      return "Recepcionista";
            case AppConfig.ROL_INSTRUCTOR: return "Instructor";
            default:                       return "Usuario";
        }
    }
}