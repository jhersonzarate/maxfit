package com.mycompany.herramientas.model;

import java.math.BigDecimal;

/**
 * Plan de membresía del gimnasio (MEM-BASIC, MEM-STD, MEM-PREM, MEM-ANUAL).
 *
 * Solo los planes con estado "activo" se pueden asignar a contratos nuevos,
 * según RF-02 del documento. Usamos BigDecimal para el precio porque
 * double puede dar errores de redondeo con dinero.
 */
public class Membresia {

    private String     id;               // Ej: MEM-STD
    private String     nombreMembresia;  // Ej: Plan Estándar Mensual
    private BigDecimal precio;           // Ej: 120.00
    private int        duracionMeses;    // Ej: 1, 3, 12
    private String     descripcion;
    private String     estado;           // "activo" o "inactivo"

    public Membresia() {}

    public Membresia(String id, String nombreMembresia, BigDecimal precio,
                     int duracionMeses, String descripcion, String estado) {
        this.id = id;
        this.nombreMembresia = nombreMembresia;
        this.precio = precio;
        this.duracionMeses = duracionMeses;
        this.descripcion = descripcion;
        this.estado = estado;
    }

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getNombreMembresia() { return nombreMembresia; }
    public void setNombreMembresia(String nombreMembresia) { this.nombreMembresia = nombreMembresia; }

    public BigDecimal getPrecio() { return precio; }
    public void setPrecio(BigDecimal precio) { this.precio = precio; }

    public int getDuracionMeses() { return duracionMeses; }
    public void setDuracionMeses(int duracionMeses) { this.duracionMeses = duracionMeses; }

    public String getDescripcion() { return descripcion; }
    public void setDescripcion(String descripcion) { this.descripcion = descripcion; }

    public String getEstado() { return estado; }
    public void setEstado(String estado) { this.estado = estado; }

    public boolean isActiva() {
        return "activo".equalsIgnoreCase(estado);
    }

    @Override
    public String toString() {
        return "Membresia{id='" + id + "', nombre='" + nombreMembresia
                + "', precio=" + precio + "}";
    }
}