package com.mycompany.herramientas.view;

import com.mycompany.herramientas.config.AppConfig;

// rutas de redirección según rol
public final class RoleRoutes {

    private RoleRoutes() {}

    // obtiene URL de inicio según rol
    public static String getUrlInicio(String idRol) {

        if (idRol == null) return "/login";

        switch (idRol) {

            case AppConfig.ROL_ADMIN:
                return "/inicio";

            case AppConfig.ROL_RECEP:
                return "/dashboard";

            case AppConfig.ROL_INSTRUCTOR:
                return "/instructor";

            default:
                return "/login";
        }
    }

    // nombre legible del rol para UI
    public static String getNombreRol(String idRol) {

        if (idRol == null) return "Desconocido";

        switch (idRol) {

            case AppConfig.ROL_ADMIN:
                return "Administrador";

            case AppConfig.ROL_RECEP:
                return "Recepcionista";

            case AppConfig.ROL_INSTRUCTOR:
                return "Instructor";

            default:
                return "Usuario";
        }
    }
}