package com.mycompany.herramientas.model;

/**
 * Cargo que puede tener un empleado (CARGO-ADM, CARGO-REC, CARGO-TRAINER).
 * Catálogo fijo, no se autogenera el ID.
 */
public class Cargo {

    private String id;     // Ej: CARGO-TRAINER
    private String nombre; // Ej: Entrenador

    public Cargo() {}

    public Cargo(String id, String nombre) {
        this.id = id;
        this.nombre = nombre;
    }

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getNombre() { return nombre; }
    public void setNombre(String nombre) { this.nombre = nombre; }

    @Override
    public String toString() {
        return "Cargo{id='" + id + "', nombre='" + nombre + "'}";
    }
}