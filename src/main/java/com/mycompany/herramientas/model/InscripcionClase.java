package com.mycompany.herramientas.model;

import java.time.LocalDateTime;

// inscripción de cliente a clase grupal
public class InscripcionClase {

    // ─── atributos ─────────────────────────────────────────────

    private String        id;                // Ej: INS-2026-0001
    private Cliente       cliente;           // cliente inscrito
    private Clase         clase;             // clase asociada
    private LocalDateTime fechaInscripcion;  // fecha registro

    public InscripcionClase() {}

    // constructor completo
    public InscripcionClase(String id, Cliente cliente, Clase clase,
                             LocalDateTime fechaInscripcion) {
        this.id               = id;
        this.cliente          = cliente;
        this.clase            = clase;
        this.fechaInscripcion = fechaInscripcion;
    }

    // ─── getters y setters ────────────────────────────────────

    public String        getId()                          { return id; }
    public void          setId(String id)                 { this.id = id; }

    public Cliente       getCliente()                     { return cliente; }
    public void          setCliente(Cliente c)            { this.cliente = c; }

    public Clase         getClase()                       { return clase; }
    public void          setClase(Clase clase)            { this.clase = clase; }

    public LocalDateTime getFechaInscripcion()                     { return fechaInscripcion; }
    public void          setFechaInscripcion(LocalDateTime fecha)  { this.fechaInscripcion = fecha; }

    // ─── helpers para JSP ─────────────────────────────────────

    // fecha formateada para tabla
    public String getFechaFormateada() {
        if (fechaInscripcion == null) return "—";

        return String.format("%02d/%02d/%d %02d:%02d",
                fechaInscripcion.getDayOfMonth(),
                fechaInscripcion.getMonthValue(),
                fechaInscripcion.getYear(),
                fechaInscripcion.getHour(),
                fechaInscripcion.getMinute());
    }

    @Override
    public String toString() {
        return "InscripcionClase{id='" + id
                + "', cliente='" + (cliente != null ? cliente.getId() : "?")
                + "', clase='"  + (clase   != null ? clase.getId()   : "?") + "'}";
    }
}