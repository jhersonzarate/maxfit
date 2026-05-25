package com.mycompany.herramientas.util;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpSession;
import java.security.SecureRandom;
import java.util.Base64;

/**
 * Utilidad para protección CSRF (Cross-Site Request Forgery).
 *
 * Patrón: Synchronizer Token Pattern
 *   - El token se genera una vez por sesión.
 *   - Se guarda en HttpSession (server-side) → no manipulable por el cliente.
 *   - Se incluye en cada formulario como campo oculto.
 *   - En cada POST el CsrfFilter valida que el token del form coincida
 *     con el de la sesión.
 *
 * Buenas prácticas aplicadas:
 *   - SecureRandom (criptográficamente seguro), no Math.random().
 *   - 32 bytes de entropía → 256 bits → imposible de adivinar por fuerza bruta.
 *   - Comparación de tiempo constante para prevenir timing attacks.
 *   - El token no cambia entre peticiones de la misma sesión (rendimiento),
 *     pero sí cuando la sesión se regenera en login/logout.
 */
public final class CsrfUtils {

    // nombre del atributo de sesión donde se guarda el token
    public static final String SESSION_ATTR = "_csrfToken";

    // nombre del parámetro del formulario / cabecera HTTP
    public static final String PARAM_NAME   = "_csrf";
    public static final String HEADER_NAME  = "X-CSRF-Token";

    // generador criptográficamente seguro — una instancia compartida es seguro
    private static final SecureRandom SECURE_RANDOM = new SecureRandom();

    // clase utilitaria: no instanciar
    private CsrfUtils() {}

    // ─── GENERAR ───────────────────────────────────────────────

    /**
     * Devuelve el token CSRF de la sesión actual.
     * Si todavía no existe, genera uno nuevo y lo guarda en la sesión.
     *
     * Llamar desde los controladores en doGet() para pasarlo a la vista:
     *   req.setAttribute("csrfToken", CsrfUtils.getOrCreate(req));
     *
     * O directamente desde el JSP vía EL si el filtro ya lo puso:
     *   ${sessionScope._csrfToken}
     */
    public static String getOrCreate(HttpServletRequest req) {

        HttpSession session = req.getSession(true);

        String token = (String) session.getAttribute(SESSION_ATTR);

        if (token == null || token.isEmpty()) {

            token = generate();
            session.setAttribute(SESSION_ATTR, token);
        }

        return token;
    }

    // ─── VALIDAR ───────────────────────────────────────────────

    /**
     * Valida que el token del formulario (o cabecera X-CSRF-Token)
     * coincida con el token guardado en la sesión.
     *
     * Devuelve false si:
     *   - No hay sesión activa.
     *   - El token de sesión es null o vacío.
     *   - El token del request es null o vacío.
     *   - Los tokens no coinciden (comparación constante).
     */
    public static boolean isValid(HttpServletRequest req) {

        HttpSession session = req.getSession(false);

        if (session == null) {
            return false;
        }

        String tokenSesion = (String) session.getAttribute(SESSION_ATTR);

        if (tokenSesion == null || tokenSesion.isEmpty()) {
            return false;
        }

        // primero buscar en el parámetro del formulario,
        // si no viene, buscar en la cabecera (para peticiones AJAX)
        String tokenRequest = req.getParameter(PARAM_NAME);

        if (tokenRequest == null || tokenRequest.isEmpty()) {
            tokenRequest = req.getHeader(HEADER_NAME);
        }

        if (tokenRequest == null || tokenRequest.isEmpty()) {
            return false;
        }

        // comparación de tiempo constante → previene timing attacks
        return constantTimeEquals(tokenSesion, tokenRequest);
    }

    // ─── PRIVADOS ──────────────────────────────────────────────

    /**
     * Genera un token de 32 bytes (256 bits) codificado en Base64 URL-safe.
     * Ejemplo resultado: "k9zQF2mXpL8vR4wN7sBjCuEoAhDiTgYe0qKnWcZl1M="
     */
    private static String generate() {

        byte[] bytes = new byte[32];
        SECURE_RANDOM.nextBytes(bytes);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
    }

    /**
     * Comparación de strings en tiempo constante.
     * Evita que un atacante deduzca caracteres correctos midiendo el tiempo
     * de respuesta de comparaciones normales (early-exit).
     *
     * Los tokens generados por generate() siempre tienen 43 caracteres
     * (32 bytes en Base64 URL sin padding), así que la rama de longitudes
     * distintas solo se activa si alguien envía un token manipulado.
     */
    private static boolean constantTimeEquals(String a, String b) {

        if (a == null || b == null) {
            return false;
        }

        byte[] bytesA = a.getBytes(java.nio.charset.StandardCharsets.UTF_8);
        byte[] bytesB = b.getBytes(java.nio.charset.StandardCharsets.UTF_8);

        // longitudes distintas → siempre falso (token manipulado)
        if (bytesA.length != bytesB.length) {
            return false;
        }

        // XOR acumulado: si todos los bytes coinciden, result queda en 0
        int result = 0;
        for (int i = 0; i < bytesA.length; i++) {
            result |= bytesA[i] ^ bytesB[i];
        }

        return result == 0;
    }
}