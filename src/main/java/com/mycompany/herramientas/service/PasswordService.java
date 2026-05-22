package com.mycompany.herramientas.service;

import com.mycompany.herramientas.config.AppConfig;
import org.mindrot.jbcrypt.BCrypt;

/**
 * Servicio de seguridad para contraseñas.
 *
 * Usa BCrypt (jBCrypt 0.4) para hashear y verificar contraseñas.
 * BCrypt es la opción estándar para Java sin Spring Security porque:
 *   - Incluye salt aleatorio en cada hash (nunca el mismo hash para la misma clave).
 *   - El factor de coste (BCRYPT_COST en AppConfig) controla la velocidad del hash,
 *     haciendo los ataques de fuerza bruta computacionalmente costosos.
 *   - El hash resultante incluye el salt, no se necesita columna separada en la BD.
 *
 * Formato del hash almacenado en la BD:
 *   $2a$12$SALT_22_CHARS_HERE_HASH_31_CHARS
 *   ↑    ↑  ↑
 *   alg  cost  salt+hash (60 chars total)
 *
 * Por eso VARCHAR(255) en la columna passwordUsuario de la BD es suficiente.
 *
 * NUNCA hacer:
 *   - Guardar la contraseña original en ningún log ni variable de sesión.
 *   - Comparar contraseñas con .equals() — siempre usar verificar().
 *   - Usar MD5 o SHA-1 (son rápidos → vulnerables a fuerza bruta).
 *
 * Uso:
 *   String hash = PasswordService.hashear("miContrasena123");
 *   boolean ok  = PasswordService.verificar("miContrasena123", hash);
 */
public final class PasswordService {

    // Clase utilitaria — nadie debe instanciarla
    private PasswordService() {}

    /**
     * Genera el hash BCrypt de una contraseña en texto plano.
     * Llama a esto UNA sola vez al crear o cambiar contraseña de un usuario.
     * El resultado es el valor a guardar en la columna passwordUsuario de la BD.
     *
     * @param rawPassword la contraseña en texto plano ingresada por el usuario
     * @return hash BCrypt de 60 caracteres listo para guardar en la BD
     * @throws IllegalArgumentException si la contraseña es nula o vacía
     */
    public static String hashear(String rawPassword) {
        if (rawPassword == null || rawPassword.trim().isEmpty()) {
            throw new IllegalArgumentException(
                    "La contraseña no puede ser nula o vacía.");
        }
        // BCrypt.gensalt(cost) genera un salt aleatorio con el factor de coste configurado.
        // BCrypt.hashpw() aplica el algoritmo y devuelve el hash final (salt incluido).
        return BCrypt.hashpw(rawPassword, BCrypt.gensalt(AppConfig.BCRYPT_COST));
    }

    /**
     * Verifica si una contraseña en texto plano coincide con su hash BCrypt.
     * Usar en el login: si devuelve true, las credenciales son correctas.
     *
     * @param rawPassword la contraseña ingresada por el usuario en el formulario
     * @param hashGuardado el hash almacenado en la columna passwordUsuario de la BD
     * @return true si coinciden, false si no coinciden o si algún parámetro es inválido
     */
    public static boolean verificar(String rawPassword, String hashGuardado) {
        if (rawPassword == null || hashGuardado == null) return false;
        if (rawPassword.trim().isEmpty() || hashGuardado.trim().isEmpty()) return false;

        try {
            // BCrypt.checkpw extrae el salt del hash guardado, aplica el mismo algoritmo
            // a rawPassword y compara los resultados de forma segura (tiempo constante).
            return BCrypt.checkpw(rawPassword, hashGuardado);
        } catch (IllegalArgumentException e) {
            // El hash guardado tiene formato inválido (no es un hash BCrypt válido).
            // Esto puede pasar si hay datos corruptos o contraseñas antiguas en texto plano.
            return false;
        }
    }

    /**
     * Verifica si un hash necesita ser actualizado por tener un factor de coste
     * inferior al configurado en AppConfig.BCRYPT_COST.
     *
     * Útil cuando se sube el factor de coste en el futuro:
     * se puede llamar en cada login exitoso y re-hashear si es necesario.
     *
     * @param hashGuardado el hash almacenado en la BD
     * @return true si el hash usa un factor de coste menor al actual
     */
    public static boolean necesitaActualizacion(String hashGuardado) {
        if (hashGuardado == null || !hashGuardado.startsWith("$2")) return true;
        try {
            // BCrypt guarda el coste en el propio hash: $2a$12$...
            // Extraemos el número entre los segundos y terceros '$'
            String[] partes = hashGuardado.split("\\$");
            if (partes.length < 4) return true;
            int costoActual = Integer.parseInt(partes[2]);
            return costoActual < AppConfig.BCRYPT_COST;
        } catch (NumberFormatException e) {
            return true;
        }
    }
}