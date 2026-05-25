package com.mycompany.herramientas.model;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

// modelo de contrato entre cliente y membresía
public class Contrato {

    // ─── atributos ─────────────────────────────────────────────

    private String        id;              // Ej: CON-2026-0001
    private Cliente       cliente;         // cliente asociado al contrato
    private Membresia     membresia;       // membresía adquirida
    private Empleado      empleado;        // empleado responsable
    private MetodoPago    metodoPago;      // método de pago usado
    private LocalDate     fechaInicio;     // fecha de inicio
    private LocalDate     fechaFin;        // fecha de vencimiento
    private BigDecimal    montoPagado;     // monto pagado
    private LocalDateTime fechaPago;       // fecha y hora del pago
    private String        estado;          // activo | vencido | cancelado

    public Contrato() {}

    // constructor completo del contrato
    public Contrato(String id, Cliente cliente, Membresia membresia,
                    Empleado empleado, MetodoPago metodoPago,
                    LocalDate fechaInicio, LocalDate fechaFin,
                    BigDecimal montoPagado, LocalDateTime fechaPago,
                    String estado) {
        this.id          = id;
        this.cliente     = cliente;
        this.membresia   = membresia;
        this.empleado    = empleado;
        this.metodoPago  = metodoPago;
        this.fechaInicio = fechaInicio;
        this.fechaFin    = fechaFin;
        this.montoPagado = montoPagado;
        this.fechaPago   = fechaPago;
        this.estado      = estado;
    }

    // ─── getters y setters ────────────────────────────────────

    public String     getId()                          { return id; }
    public void       setId(String id)                 { this.id = id; }

    public Cliente    getCliente()                     { return cliente; }
    public void       setCliente(Cliente c)            { this.cliente = c; }

    public Membresia  getMembresia()                   { return membresia; }
    public void       setMembresia(Membresia m)        { this.membresia = m; }

    public Empleado   getEmpleado()                    { return empleado; }
    public void       setEmpleado(Empleado e)          { this.empleado = e; }

    public MetodoPago getMetodoPago()                  { return metodoPago; }
    public void       setMetodoPago(MetodoPago mp)     { this.metodoPago = mp; }

    public LocalDate  getFechaInicio()                 { return fechaInicio; }
    public void       setFechaInicio(LocalDate fi)     { this.fechaInicio = fi; }

    public LocalDate  getFechaFin()                    { return fechaFin; }
    public void       setFechaFin(LocalDate ff)        { this.fechaFin = ff; }

    public BigDecimal getMontoPagado()                 { return montoPagado; }
    public void       setMontoPagado(BigDecimal mp)    { this.montoPagado = mp; }

    public LocalDateTime getFechaPago()                    { return fechaPago; }
    public void          setFechaPago(LocalDateTime fp)    { this.fechaPago = fp; }

    public String     getEstado()                      { return estado; }
    public void       setEstado(String estado)         { this.estado = estado; }

    // ─── helpers ──────────────────────────────────────────────

    // verificar si el contrato está activo
    public boolean isActivo() {
        return "activo".equalsIgnoreCase(estado);
    }

    // verificar si el contrato está vencido
    public boolean isVencido() {
        return "vencido".equalsIgnoreCase(estado);
    }

    // verificar si el contrato fue cancelado
    public boolean isCancelado() {
        return "cancelado".equalsIgnoreCase(estado);
    }

    // validar si la membresía vencerá pronto
    public boolean proximoAVencer(int dias) {

        if (fechaFin == null || !isActivo()) {
            return false;
        }

        return !fechaFin.isAfter(LocalDate.now().plusDays(dias));
    }

    @Override
    public String toString() {
        return "Contrato{id='" + id + "', cliente='"
                + (cliente != null ? cliente.getId() : "?")
                + "', estado='" + estado + "'}";
    }
}