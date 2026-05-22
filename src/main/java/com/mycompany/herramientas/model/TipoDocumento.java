package com.mycompany.herramientas.model;

/**
 * Tipo de documento de identidad aceptado (TDOC-DNI, TDOC-CE, TDOC-PASS).
 *
 * Alineado a la tabla TipoDocumentos del SQL:
 *   id              VARCHAR(20) PK,
 *   nombre_documento VARCHAR(20),
 *   abreviado       VARCHAR(10),
 *   tamañoMax       INT          ← longitud máxima del número de documento,
 *   tamañoMin       INT          ← longitud mínima del número de documento,
 *   esAlfanumerico  BIT          ← 1 si acepta letras y dígitos (CE, Pasaporte)
 *
 * NOTA: los nombres de los campos respetan exactamente las columnas del SQL.
 * En el MaxFit se llamaban "longitudValida" y "alfaNumerico" — aquí están corregidos.
 *
 * Uso en DocumentoValidator:
 *   - Verificar que numero.length() entre tamañoMin y tamañoMax.
 *   - Si !esAlfanumerico, verificar que solo contenga dígitos.
 */
public class TipoDocumento {

    private String  id;               // Ej: TDOC-DNI
    private String  nombreDocumento;  // Ej: Documento Nacional de Identidad
    private String  abreviado;        // Ej: DNI
    private int     tamañoMax;        // Longitud máxima del número (ej: 8 para DNI)
    private int     tamañoMin;        // Longitud mínima del número (ej: 8 para DNI)
    private boolean esAlfanumerico;   // true → CE/Pasaporte; false → DNI (solo dígitos)

    public TipoDocumento() {}

    public TipoDocumento(String id, String nombreDocumento, String abreviado,
                         int tamañoMax, int tamañoMin, boolean esAlfanumerico) {
        this.id              = id;
        this.nombreDocumento = nombreDocumento;
        this.abreviado       = abreviado;
        this.tamañoMax       = tamañoMax;
        this.tamañoMin       = tamañoMin;
        this.esAlfanumerico  = esAlfanumerico;
    }

    // -----------------------------------------------------------------------
    // Getters y Setters — nombres exactos igual que las columnas del SQL
    // -----------------------------------------------------------------------

    public String  getId()                      { return id; }
    public void    setId(String id)             { this.id = id; }

    public String  getNombreDocumento()                     { return nombreDocumento; }
    public void    setNombreDocumento(String nombre)        { this.nombreDocumento = nombre; }

    public String  getAbreviado()               { return abreviado; }
    public void    setAbreviado(String abr)     { this.abreviado = abr; }

    public int     getTamañoMax()               { return tamañoMax; }
    public void    setTamañoMax(int max)        { this.tamañoMax = max; }

    public int     getTamañoMin()               { return tamañoMin; }
    public void    setTamañoMin(int min)        { this.tamañoMin = min; }

    public boolean isEsAlfanumerico()              { return esAlfanumerico; }
    public void    setEsAlfanumerico(boolean alfa) { this.esAlfanumerico = alfa; }

    // -----------------------------------------------------------------------
    // Helpers para DocumentoValidator
    // -----------------------------------------------------------------------

    /**
     * Valida si el número de documento tiene la longitud correcta.
     * @param numero el valor ingresado por el usuario
     * @return true si está en el rango [tamañoMin, tamañoMax]
     */
    public boolean longitudValida(String numero) {
        if (numero == null) return false;
        int len = numero.trim().length();
        return len >= tamañoMin && len <= tamañoMax;
    }

    /**
     * Valida el formato (solo dígitos vs alfanumérico).
     * @param numero el valor ingresado por el usuario
     * @return true si cumple con el formato
     */
    public boolean formatoValido(String numero) {
        if (numero == null) return false;
        if (esAlfanumerico) {
            return numero.trim().matches("[a-zA-Z0-9]+");
        } else {
            return numero.trim().matches("\\d+");
        }
    }

    @Override
    public String toString() {
        return "TipoDocumento{id='" + id + "', abreviado='" + abreviado + "'}";
    }
}