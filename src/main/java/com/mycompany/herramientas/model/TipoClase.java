package com.mycompany.herramientas.model;

// tipo de clase grupal del gimnasio (con estado activo/inactivo)
public class TipoClase {

    private String id;
    private String nombre;
    private String estado; // activo | inactivo

    public TipoClase() {}

    public TipoClase(String id, String nombre) {
        this.id = id;
        this.nombre = nombre;
        this.estado = "activo";
    }

    public TipoClase(String id, String nombre, String estado) {
        this.id = id;
        this.nombre = nombre;
        this.estado = estado;
    }

    // ─── getters y setters ────────────────────────────────────

    public String getId()             { return id; }
    public void   setId(String id)    { this.id = id; }

    public String getNombre()         { return nombre; }
    public void   setNombre(String n) { this.nombre = n; }

    public String getEstado()         { return estado; }
    public void   setEstado(String e) { this.estado = e; }

    // ─── helpers ─────────────────────────────────────────────

    public boolean isActivo() {
        return "activo".equalsIgnoreCase(estado);
    }

    @Override
    public String toString() {
        return "TipoClase{id='" + id + "', nombre='" + nombre
                + "', estado='" + estado + "'}";
    }
}