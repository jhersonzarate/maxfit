package com.mycompany.herramientas.service;

import com.mycompany.herramientas.config.AppConfig;
import org.mindrot.jbcrypt.BCrypt;

// servicio de seguridad para contraseñas (BCrypt)
public final class PasswordService {

    // clase utilitaria: no se instancia
    private PasswordService() {}

    // ─── HASH ───────────────────────────────────────────────

    // genera hash BCrypt a partir de contraseña en texto plano
    public static String hashear(String rawPassword) {

        if (rawPassword == null || rawPassword.trim().isEmpty()) {
            throw new IllegalArgumentException("La contraseña no puede ser nula o vacía.");
        }

        return BCrypt.hashpw(
                rawPassword,
                BCrypt.gensalt(AppConfig.BCRYPT_COST)
        );
    }

    // ─── VERIFICACIÓN ───────────────────────────────────────

    // valida contraseña contra hash almacenado en BD
    public static boolean verificar(String rawPassword, String hashGuardado) {

        if (rawPassword == null || hashGuardado == null) return false;
        if (rawPassword.trim().isEmpty() || hashGuardado.trim().isEmpty()) return false;

        try {

            return BCrypt.checkpw(rawPassword, hashGuardado);

        } catch (IllegalArgumentException e) {

            // hash inválido o corrupto
            return false;
        }
    }

    // ─── ACTUALIZACIÓN DE HASH ─────────────────────────────

    // verifica si el hash necesita actualizar su costo
    public static boolean necesitaActualizacion(String hashGuardado) {

        if (hashGuardado == null || !hashGuardado.startsWith("$2")) return true;

        try {

            String[] partes = hashGuardado.split("\\$");
            if (partes.length < 4) return true;

            int costoActual = Integer.parseInt(partes[2]);

            return costoActual < AppConfig.BCRYPT_COST;

        } catch (Exception e) {

            return true;
        }
    }
}