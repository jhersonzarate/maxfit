package com.mycompany.herramientas.model;

/**
 * Representa un rol del sistema (ROL-ADMIN, ROL-RECEP, ROL-TRAINER).
 * Es un catálogo fijo: los IDs no se autogeneran, se insertan manualmente en la BD.
 */
public class Rol {

    private String id;        // Ej: ROL-ADMIN
    private String nombreRol; // Ej: Administrador
    private String descripcion;

    public Rol() {}

    public Rol(String id, String nombreRol, String descripcion) {
        this.id = id;
        this.nombreRol = nombreRol;
        this.descripcion = descripcion;
    }

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