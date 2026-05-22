package com.mycompany.herramientas.service;

import com.mycompany.herramientas.model.TipoDocumento;

/**
 * Validador de números de documento de identidad.
 *
 * Usa los campos tamañoMin, tamañoMax y esAlfanumerico de TipoDocumento
 * para validar el número ingresado antes de guardarlo en la BD.
 *
 * Esto respeta el diseño de la tabla TipoDocumentos que define:
 *   tamañoMax INT, tamañoMin INT, esAlfanumerico BIT
 *
 * En el proyecto anterior (MaxFit) estos campos existían en la BD pero
 * nunca se usaban — esta clase los aprovecha correctamente (RF-07).
 *
 * Uso en los controladores:
 *   ResultadoValidacion resultado = DocumentoValidator.validar(tipoDoc, numeroIngresado);
 *   if (!resultado.isValido()) {
 *       req.setAttribute("errorDoc", resultado.getMensaje());
 *       renderView(...);
 *       return;
 *   }
 */
public final class DocumentoValidator {

    private DocumentoValidator() {}

    // ── Clase de resultado ───────────────────────────────────────────────────

    /**
     * Resultado inmutable de una validación.
     * Evita usar booleans sueltos o excepciones para el flujo de validación.
     */
    public static final class ResultadoValidacion {

        private final boolean valido;
        private final String  mensaje;

        private ResultadoValidacion(boolean valido, String mensaje) {
            this.valido   = valido;
            this.mensaje  = mensaje;
        }

        public boolean isValido()    { return valido; }
        public String  getMensaje()  { return mensaje; }

        public static ResultadoValidacion ok() {
            return new ResultadoValidacion(true, null);
        }

        public static ResultadoValidacion error(String mensaje) {
            return new ResultadoValidacion(false, mensaje);
        }
    }

    // ── Método principal ─────────────────────────────────────────────────────

    /**
     * Valida un número de documento contra las reglas del tipo de documento.
     *
     * @param tipo   el TipoDocumento seleccionado por el usuario (DNI, CE, Pasaporte…)
     * @param numero el número de documento ingresado en el formulario
     * @return ResultadoValidacion con isValido() y getMensaje() en caso de error
     */
    public static ResultadoValidacion validar(TipoDocumento tipo, String numero) {

        // ── Null / vacío ─────────────────────────────────────────────────────
        if (tipo == null) {
            return ResultadoValidacion.error("Debe seleccionar un tipo de documento.");
        }
        if (numero == null || numero.trim().isEmpty()) {
            return ResultadoValidacion.error("El número de documento no puede estar vacío.");
        }

        String num = numero.trim();

        // ── Longitud ─────────────────────────────────────────────────────────
        int len = num.length();
        int min = tipo.getTamañoMin();
        int max = tipo.getTamañoMax();

        if (len < min || len > max) {
            if (min == max) {
                return ResultadoValidacion.error(
                        "El " + tipo.getAbreviado() + " debe tener exactamente "
                        + min + " caracteres. Ingresaste " + len + ".");
            } else {
                return ResultadoValidacion.error(
                        "El " + tipo.getAbreviado() + " debe tener entre "
                        + min + " y " + max + " caracteres. Ingresaste " + len + ".");
            }
        }

        // ── Formato (solo dígitos vs alfanumérico) ───────────────────────────
        if (!tipo.isEsAlfanumerico()) {
            // Solo dígitos (ej: DNI peruano)
            if (!num.matches("\\d+")) {
                return ResultadoValidacion.error(
                        "El " + tipo.getAbreviado()
                        + " solo puede contener números (sin letras ni símbolos).");
            }
        } else {
            // Alfanumérico (ej: Carnet de Extranjería, Pasaporte)
            if (!num.matches("[a-zA-Z0-9]+")) {
                return ResultadoValidacion.error(
                        "El " + tipo.getAbreviado()
                        + " solo puede contener letras y números (sin espacios ni símbolos).");
            }
        }

        return ResultadoValidacion.ok();
    }

    /**
     * Sobrecarga conveniente cuando solo se tiene el número y se quiere
     * verificar formato básico (sin TipoDocumento).
     * Útil en el check-in por documento donde no siempre se conoce el tipo.
     *
     * @param numero el número de documento
     * @return true si tiene entre 6 y 20 caracteres alfanuméricos
     */
    public static boolean esFormatoBasicoValido(String numero) {
        if (numero == null || numero.trim().isEmpty()) return false;
        String num = numero.trim();
        return num.length() >= 6
                && num.length() <= 20
                && num.matches("[a-zA-Z0-9]+");
    }
}