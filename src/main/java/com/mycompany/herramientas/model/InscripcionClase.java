package com.mycompany.herramientas.model;

import java.time.LocalDateTime;

/**
 * Inscripción de un cliente a una clase grupal.
 * ID generado con prefijo INS-AÑO-CORRELATIVO.
 *
 * Alineado a la tabla Inscripcion_Clases del SQL:
 *   id                VARCHAR(20) PK,
 *   id_cliente        VARCHAR(20) FK → Clientes,
 *   id_clase          VARCHAR(20) FK → Clases,
 *   fecha_inscripcion DATETIME DEFAULT GETDATE()
 *
 * Antes de confirmar la inscripción, el servicio verifica:
 *   1. Que el cliente exista y tenga contrato activo (RF-11).
 *   2. Que la clase no haya superado capacidad_maxima (RF-11).
 *   3. Que el cliente no esté ya inscrito en esa clase.
 */
public class InscripcionClase {

    private String        id;                // Ej: INS-2026-0001
    private Cliente       cliente;           // FK → Clientes
    private Clase         clase;             // FK → Clases
    private LocalDateTime fechaInscripcion;  // DATETIME — GETDATE() por defecto en BD

    public InscripcionClase() {}

    public InscripcionClase(String id, Cliente cliente, Clase clase,
                             LocalDateTime fechaInscripcion) {
        this.id               = id;
        this.cliente          = cliente;
        this.clase            = clase;
        this.fechaInscripcion = fechaInscripcion;
    }

    // -----------------------------------------------------------------------
    // Getters y Setters
    // -----------------------------------------------------------------------

    public String        getId()                          { return id; }
    public void          setId(String id)                 { this.id = id; }

    public Cliente       getCliente()                     { return cliente; }
    public void          setCliente(Cliente c)            { this.cliente = c; }

    public Clase         getClase()                       { return clase; }
    public void          setClase(Clase clase)            { this.clase = clase; }

    public LocalDateTime getFechaInscripcion()                     { return fechaInscripcion; }
    public void          setFechaInscripcion(LocalDateTime fecha)  { this.fechaInscripcion = fecha; }

    // -----------------------------------------------------------------------
    // Helpers para JSP
    // -----------------------------------------------------------------------

    /** Fecha formateada "dd/MM/yyyy HH:mm" para tablas. */
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