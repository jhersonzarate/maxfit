package com.mycompany.herramientas.model;

import java.time.LocalDate;
import java.time.LocalTime;

// modelo de asistencia / check-in del cliente
public class Asistencia {

    // id único de asistencia
    private String id;

    // contrato asociado (desde aquí se obtiene el cliente)
    private Contrato contrato;

    // fecha del registro
    private LocalDate fecha;

    // estado: asistio | falto | pendiente
    private String estado;

    // hora exacta de ingreso
    private LocalTime horaIngreso;

    // constructor vacío
    public Asistencia() {}

    // constructor completo
    public Asistencia(String id, Contrato contrato,
                      LocalDate fecha, String estado,
                      LocalTime horaIngreso) {

        this.id          = id;
        this.contrato    = contrato;
        this.fecha       = fecha;
        this.estado      = estado;
        this.horaIngreso = horaIngreso;
    }

    // ─── getters y setters ───────────────────────────────────

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public Contrato getContrato() {
        return contrato;
    }

    public void setContrato(Contrato c) {
        this.contrato = c;
    }

    public LocalDate getFecha() {
        return fecha;
    }

    public void setFecha(LocalDate fecha) {
        this.fecha = fecha;
    }

    public String getEstado() {
        return estado;
    }

    public void setEstado(String estado) {
        this.estado = estado;
    }

    public LocalTime getHoraIngreso() {
        return horaIngreso;
    }

    public void setHoraIngreso(LocalTime hora) {
        this.horaIngreso = hora;
    }

    // ─── helpers ─────────────────────────────────────────────

    // obtener nombre completo del cliente desde el contrato
    public String getNombreCliente() {

        if (contrato != null
                && contrato.getCliente() != null) {

            return contrato.getCliente()
                    .getNombreCompleto();
        }

        return "—";
    }

    // hora formateada HH:mm
    public String getHoraIngresoFormateada() {

        if (horaIngreso == null) {
            return "—";
        }

        return horaIngreso.toString()
                .substring(0, 5);
    }

    // validar estados rápidos
    public boolean isAsistio() {
        return "asistio".equalsIgnoreCase(estado);
    }

    public boolean isFalto() {
        return "falto".equalsIgnoreCase(estado);
    }

    public boolean isPendiente() {
        return "pendiente".equalsIgnoreCase(estado);
    }

    // representación rápida del objeto
    @Override
    public String toString() {

        return "Asistencia{id='" + id
                + "', contrato='"

                + (contrato != null
                        ? contrato.getId()
                        : "?")

                + "', fecha=" + fecha
                + ", estado='" + estado + "'}";
    }
}