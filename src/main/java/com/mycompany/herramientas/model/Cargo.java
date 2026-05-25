package com.mycompany.herramientas.model;

// modelo de cargo para empleados
public class Cargo {

    // id fijo del cargo
    private String id;

    // nombre visible del cargo
    private String nombre;

    // constructor vacío
    public Cargo() {}

    // constructor completo
    public Cargo(String id, String nombre) {

        this.id = id;
        this.nombre = nombre;
    }

    // ─── getters y setters ───────────────────────────────────

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getNombre() {
        return nombre;
    }

    public void setNombre(String nombre) {
        this.nombre = nombre;
    }

    // ─── representación rápida ───────────────────────────────

    @Override
    public String toString() {

        return "Cargo{id='" + id
                + "', nombre='" + nombre + "'}";
    }
}