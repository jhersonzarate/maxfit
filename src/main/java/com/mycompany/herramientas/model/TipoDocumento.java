package com.mycompany.herramientas.model;

// tipo de documento de identidad del sistema
public class TipoDocumento {

    // ─── atributos ─────────────────────────────────────────────

    private String  id;               // Ej: TDOC-DNI
    private String  nombreDocumento;  // nombre completo
    private String  abreviado;        // abreviatura (DNI, CE)
    private int     tamañoMax;        // máximo de dígitos
    private int     tamañoMin;        // mínimo de dígitos
    private boolean esAlfanumerico;   // formato permitido

    public TipoDocumento() {}

    // constructor completo
    public TipoDocumento(String id, String nombreDocumento, String abreviado,
                         int tamañoMax, int tamañoMin, boolean esAlfanumerico) {
        this.id              = id;
        this.nombreDocumento = nombreDocumento;
        this.abreviado       = abreviado;
        this.tamañoMax       = tamañoMax;
        this.tamañoMin       = tamañoMin;
        this.esAlfanumerico  = esAlfanumerico;
    }

    // ─── getters y setters ────────────────────────────────────

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

    // ─── helpers ──────────────────────────────────────────────

    // validar longitud de documento
    public boolean longitudValida(String numero) {

        if (numero == null) return false;

        int len = numero.trim().length();
        return len >= tamañoMin && len <= tamañoMax;
    }

    // validar formato del documento
    public boolean formatoValido(String numero) {

        if (numero == null) return false;

        if (esAlfanumerico) {
            return numero.trim().matches("[a-zA-Z0-9]+");
        }

        return numero.trim().matches("\\d+");
    }

    @Override
    public String toString() {
        return "TipoDocumento{id='" + id + "', abreviado='" + abreviado + "'}";
    }
}