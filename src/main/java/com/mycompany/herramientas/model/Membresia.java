package com.mycompany.herramientas.model;

import java.math.BigDecimal;

// plan de membresía del gimnasio
public class Membresia {

    // ─── atributos ─────────────────────────────────────────────

    private String     id;               // Ej: MEM-STD
    private String     nombreMembresia;  // nombre del plan
    private BigDecimal precio;           // precio del plan
    private int        duracionMeses;    // duración en meses
    private String     descripcion;      // descripción opcional
    private String     estado = "activo"; // activo o inactivo

    public Membresia() {}

    // constructor completo
    public Membresia(String id, String nombreMembresia, BigDecimal precio,
                     int duracionMeses, String descripcion) {
        this.id              = id;
        this.nombreMembresia = nombreMembresia;
        this.precio          = precio;
        this.duracionMeses   = duracionMeses;
        this.descripcion     = descripcion;
        this.estado          = "activo";
    }

    // ─── getters y setters ────────────────────────────────────

    public String getId()                          { return id; }
    public void   setId(String id)                 { this.id = id; }

    public String getNombreMembresia()                          { return nombreMembresia; }
    public void   setNombreMembresia(String nombreMembresia)    { this.nombreMembresia = nombreMembresia; }

    public BigDecimal getPrecio()                  { return precio; }
    public void       setPrecio(BigDecimal precio) { this.precio = precio; }

    public int  getDuracionMeses()                   { return duracionMeses; }
    public void setDuracionMeses(int duracionMeses)  { this.duracionMeses = duracionMeses; }

    public String getDescripcion()                   { return descripcion; }
    public void   setDescripcion(String descripcion) { this.descripcion = descripcion; }

    public String getEstado()                        { return estado; }
    public void   setEstado(String estado)           { this.estado = estado; }

    // ─── helpers ─────────────────────────────────────────────

    // resumen para selects
    public String getResumen() {
        return nombreMembresia + " — S/ " + precio
                + " (" + duracionMeses + (duracionMeses == 1 ? " mes)" : " meses)");
    }

    @Override
    public String toString() {
        return "Membresia{id='" + id + "', nombre='" + nombreMembresia
                + "', precio=" + precio + "}";
    }
}