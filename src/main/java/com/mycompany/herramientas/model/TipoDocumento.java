package com.mycompany.herramientas.model;

/**
 * Tipo de documento de identidad aceptado (TDOC-DNI, TDOC-CE, TDOC-PASS).
 *
 * Los campos tamañoMax, tamañoMin y esAlfanumerico se usan en
 * DocumentoValidator para validar el número ingresado antes de guardar.
 */
public class TipoDocumento {

    private String id;              // Ej: TDOC-DNI
    private String nombreDocumento; // Ej: Documento Nacional de Identidad
    private String abreviado;       // Ej: DNI
    private int    tamañoMax;       // Longitud máxima permitida del número
    private int    tamañoMin;       // Longitud mínima permitida del número
    private boolean esAlfanumerico; // true si acepta letras y números

    public TipoDocumento() {}

    public TipoDocumento(String id, String nombreDocumento, String abreviado,
                         int tamañoMax, int tamañoMin, boolean esAlfanumerico) {
        this.id = id;
        this.nombreDocumento = nombreDocumento;
        this.abreviado = abreviado;
        this.tamañoMax = tamañoMax;
        this.tamañoMin = tamañoMin;
        this.esAlfanumerico = esAlfanumerico;
    }

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getNombreDocumento() { return nombreDocumento; }
    public void setNombreDocumento(String nombreDocumento) { this.nombreDocumento = nombreDocumento; }

    public String getAbreviado() { return abreviado; }
    public void setAbreviado(String abreviado) { this.abreviado = abreviado; }

    public int getTamañoMax() { return tamañoMax; }
    public void setTamañoMax(int tamañoMax) { this.tamañoMax = tamañoMax; }

    public int getTamañoMin() { return tamañoMin; }
    public void setTamañoMin(int tamañoMin) { this.tamañoMin = tamañoMin; }

    public boolean isEsAlfanumerico() { return esAlfanumerico; }
    public void setEsAlfanumerico(boolean esAlfanumerico) { this.esAlfanumerico = esAlfanumerico; }

    @Override
    public String toString() {
        return "TipoDocumento{id='" + id + "', abreviado='" + abreviado + "'}";
    }
}