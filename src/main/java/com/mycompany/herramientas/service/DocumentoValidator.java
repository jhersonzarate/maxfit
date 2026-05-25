package com.mycompany.herramientas.service;

import com.mycompany.herramientas.model.TipoDocumento;

// validador de números de documento de identidad
public final class DocumentoValidator {

    private DocumentoValidator() {}

    // ─── RESULTADO ─────────────────────────────────────────────

    // resultado inmutable de validación
    public static final class ResultadoValidacion {

        private final boolean valido;
        private final String mensaje;

        private ResultadoValidacion(boolean valido, String mensaje) {
            this.valido = valido;
            this.mensaje = mensaje;
        }

        public boolean isValido() { return valido; }
        public String getMensaje() { return mensaje; }

        public static ResultadoValidacion ok() {
            return new ResultadoValidacion(true, null);
        }

        public static ResultadoValidacion error(String mensaje) {
            return new ResultadoValidacion(false, mensaje);
        }
    }

    // ─── VALIDACIÓN ───────────────────────────────────────────

    // valida número de documento según reglas del tipo
    public static ResultadoValidacion validar(TipoDocumento tipo, String numero) {

        if (tipo == null) {
            return ResultadoValidacion.error("Seleccione tipo de documento.");
        }

        if (numero == null || numero.trim().isEmpty()) {
            return ResultadoValidacion.error("Número de documento vacío.");
        }

        String num = numero.trim();

        // validar longitud
        int len = num.length();
        int min = tipo.getTamañoMin();
        int max = tipo.getTamañoMax();

        if (len < min || len > max) {

            if (min == max) {
                return ResultadoValidacion.error(
                        tipo.getAbreviado() + " debe tener " + min + " caracteres");
            }

            return ResultadoValidacion.error(
                    tipo.getAbreviado() + " debe tener entre " + min + " y " + max + " caracteres");
        }

        // validar formato
        if (!tipo.isEsAlfanumerico()) {

            if (!num.matches("\\d+")) {
                return ResultadoValidacion.error(
                        tipo.getAbreviado() + " solo admite números");
            }

        } else {

            if (!num.matches("[a-zA-Z0-9]+")) {
                return ResultadoValidacion.error(
                        tipo.getAbreviado() + " solo admite letras y números");
            }
        }

        return ResultadoValidacion.ok();
    }

    // ─── VALIDACIÓN BÁSICA ───────────────────────────────────

    // validación rápida sin TipoDocumento (check-in)
    public static boolean esFormatoBasicoValido(String numero) {

        if (numero == null || numero.trim().isEmpty()) return false;

        String num = numero.trim();

        return num.length() >= 6
                && num.length() <= 20
                && num.matches("[a-zA-Z0-9]+");
    }
}