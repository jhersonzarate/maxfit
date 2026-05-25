package com.mycompany.herramientas.model;

// tipo de clase grupal del gimnasio
public class TipoClase {

    // ─── atributos ─────────────────────────────────────────────

    private String id;     // Ej: TCL-YOGA
    private String nombre; // nombre del tipo de clase

    public TipoClase() {}

    // constructor completo
    public TipoClase(String id, String nombre) {
        this.id     = id;
        this.nombre = nombre;
    }

    // ─── getters y setters ────────────────────────────────────

    public String getId()                { return id; }
    public void   setId(String id)       { this.id = id; }

    public String getNombre()            { return nombre; }
    public void   setNombre(String n)    { this.nombre = n; }

    @Override
    public String toString() {
        return "TipoClase{id='" + id + "', nombre='" + nombre + "'}";
    }
}