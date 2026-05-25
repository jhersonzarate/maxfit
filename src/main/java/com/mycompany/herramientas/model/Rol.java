package com.mycompany.herramientas.model;

// rol del sistema (catálogo fijo)
public class Rol {

    // ─── atributos ─────────────────────────────────────────────

    private String id;        // Ej: ROL-ADMIN
    private String nombreRol; // nombre del rol
    private String descripcion;

    public Rol() {}

    // constructor completo
    public Rol(String id, String nombreRol, String descripcion) {
        this.id = id;
        this.nombreRol = nombreRol;
        this.descripcion = descripcion;
    }

    // ─── getters y setters ────────────────────────────────────

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getNombreRol() { return nombreRol; }
    public void setNombreRol(String nombreRol) { this.nombreRol = nombreRol; }

    public String getDescripcion() { return descripcion; }
    public void setDescripcion(String descripcion) { this.descripcion = descripcion; }

    @Override
    public String toString() {
        return "Rol{id='" + id + "', nombreRol='" + nombreRol + "'}";
    }
}