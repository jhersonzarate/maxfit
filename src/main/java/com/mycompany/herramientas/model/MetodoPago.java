package com.mycompany.herramientas.model;

/**
 * Método de pago disponible para registrar contratos.
 * Catálogo fijo (PAY-YAPE, PAY-EFECTIVO, etc.).
 *
 * Solo los métodos con estado "activo" se muestran al registrar un contrato,
 * según RF-06 del documento.
 */
public class MetodoPago {

    private String id;     // Ej: PAY-YAPE
    private String nombre; // Ej: Yape / Plin
    private String estado; // "activo" o "inactivo"

    public MetodoPago() {}

    public MetodoPago(String id, String nombre, String estado) {
        this.id = id;
        this.nombre = nombre;
        this.estado = estado;
    }

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getNombre() { return nombre; }
    public void setNombre(String nombre) { this.nombre = nombre; }

    public String getEstado() { return estado; }
    public void setEstado(String estado) { this.estado = estado; }

    // Util para no comparar strings sueltos en los JSP
    public boolean isActivo() {
        return "activo".equalsIgnoreCase(estado);
    }

    @Override
    public String toString() {
        return "MetodoPago{id='" + id + "', nombre='" + nombre + "'}";
    }
}