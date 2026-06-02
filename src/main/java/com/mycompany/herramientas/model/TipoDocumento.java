package com.mycompany.herramientas.model;

// tipo de documento de identidad del sistema
public class TipoDocumento {

    private String  id;
    private String  nombreDocumento;
    private String  abreviado;
    private int     tamañoMax;
    private int     tamañoMin;
    private boolean esAlfanumerico;
    private String  estado; // activo | inactivo

    public TipoDocumento() {}

    public TipoDocumento(String id, String nombreDocumento,
                         String abreviado,
                         int tamañoMax, int tamañoMin,
                         boolean esAlfanumerico) {
        this.id              = id;
        this.nombreDocumento = nombreDocumento;
        this.abreviado       = abreviado;
        this.tamañoMax       = tamañoMax;
        this.tamañoMin       = tamañoMin;
        this.esAlfanumerico  = esAlfanumerico;
        this.estado          = "activo";
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

    public String  getEstado()                  { return estado; }
    public void    setEstado(String estado)     { this.estado = estado; }

    // ─── helpers ──────────────────────────────────────────────

    public boolean isActivo() {
        return "activo".equalsIgnoreCase(estado);
    }

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
        return "TipoDocumento{id='" + id
                + "', abreviado='" + abreviado + "'}";
    }
}