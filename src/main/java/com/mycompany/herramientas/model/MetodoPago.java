package com.mycompany.herramientas.model;

// método de pago del sistema
// catálogo fijo usado al registrar contratos
public class MetodoPago {

    // ─── atributos ─────────────────────────────────────────────

    private String id;     // Ej: PAY-YAPE
    private String nombre; // nombre del método
    private String estado; // activo | inactivo

    public MetodoPago() {}

    // constructor completo
    public MetodoPago(String id, String nombre, String estado) {
        this.id = id;
        this.nombre = nombre;
        this.estado = estado;
    }

    // ─── getters y setters ────────────────────────────────────

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getNombre() { return nombre; }
    public void setNombre(String nombre) { this.nombre = nombre; }

    public String getEstado() { return estado; }
    public void setEstado(String estado) { this.estado = estado; }

    // ─── helper ───────────────────────────────────────────────

    // validar si el método está activo
    public boolean isActivo() {
        return "activo".equalsIgnoreCase(estado);
    }

    @Override
    public String toString() {
        return "MetodoPago{id='" + id + "', nombre='" + nombre + "'}";
    }
}