package com.mycompany.herramientas.model;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * Contrato entre un cliente y una membresía. ID generado con prefijo CON-AÑO-CORRELATIVO.
 *
 * Alineado a la tabla Contratos del SQL:
 *   id VARCHAR(20) PK,
 *   id_cliente     VARCHAR(20) FK → Clientes,
 *   id_membresia   VARCHAR(20) FK → Membresias,
 *   id_empleado    VARCHAR(20) FK → Empleados  (responsable del contrato),
 *   id_metodo_pago VARCHAR(20) FK → MetodosPago,
 *   fecha_inicio   DATE,
 *   fecha_fin      DATE,
 *   monto_pagado   DECIMAL(10,2)   → BigDecimal en Java (nunca double para dinero),
 *   fecha_pago     DATETIME DEFAULT GETDATE(),
 *   estado         VARCHAR(10) CHECK('activo','vencido','cancelado') DEFAULT 'activo'
 *
 * El DAO actualiza el estado a 'vencido' cuando fecha_fin < GETDATE().
 * La cancelación manual la hace el Administrador (RF-03).
 */
public class Contrato {

    private String        id;              // Ej: CON-2026-0001
    private Cliente       cliente;         // FK → Clientes
    private Membresia     membresia;       // FK → Membresias
    private Empleado      empleado;        // FK → Empleados (responsable)
    private MetodoPago    metodoPago;      // FK → MetodosPago
    private LocalDate     fechaInicio;     // DATE
    private LocalDate     fechaFin;        // DATE
    private BigDecimal    montoPagado;     // DECIMAL(10,2)
    private LocalDateTime fechaPago;       // DATETIME — por defecto GETDATE()
    private String        estado;          // 'activo' | 'vencido' | 'cancelado'

    public Contrato() {}

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

    // -----------------------------------------------------------------------
    // Getters y Setters
    // -----------------------------------------------------------------------

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

    // -----------------------------------------------------------------------
    // Helpers
    // -----------------------------------------------------------------------

    public boolean isActivo() {
        return "activo".equalsIgnoreCase(estado);
    }

    public boolean isVencido() {
        return "vencido".equalsIgnoreCase(estado);
    }

    public boolean isCancelado() {
        return "cancelado".equalsIgnoreCase(estado);
    }

    /**
     * Indica si la membresía está próxima a vencer (en los próximos N días).
     * Útil para mostrar alertas en el dashboard.
     */
    public boolean proximoAVencer(int dias) {
        if (fechaFin == null || !isActivo()) return false;
        return !fechaFin.isAfter(LocalDate.now().plusDays(dias));
    }

    @Override
    public String toString() {
        return "Contrato{id='" + id + "', cliente='"
                + (cliente != null ? cliente.getId() : "?")
                + "', estado='" + estado + "'}";
    }
}