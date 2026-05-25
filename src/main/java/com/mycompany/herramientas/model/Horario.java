package com.mycompany.herramientas.model;

import java.time.LocalTime;

// horario asignado a una clase grupal
public class Horario {

    // ─── atributos ─────────────────────────────────────────────

    private String    id;          // Ej: HOR-2026-0001
    private Clase     clase;       // clase asociada
    private int       diaSemana;   // 1=lunes ... 7=domingo
    private LocalTime horaInicio;  // hora inicio
    private LocalTime horaFin;     // hora fin
    private String    estado;      // programado | cancelado

    // nombres de días para vista
    private static final String[] NOMBRES_DIA = {
        "", "Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado", "Domingo"
    };

    public Horario() {}

    // constructor completo
    public Horario(String id, Clase clase, int diaSemana,
                   LocalTime horaInicio, LocalTime horaFin, String estado) {
        this.id          = id;
        this.clase       = clase;
        this.diaSemana   = diaSemana;
        this.horaInicio  = horaInicio;
        this.horaFin     = horaFin;
        this.estado      = estado;
    }

    // ─── getters y setters ────────────────────────────────────

    public String getId()                { return id; }
    public void   setId(String id)       { this.id = id; }

    public Clase  getClase()             { return clase; }
    public void   setClase(Clase clase)  { this.clase = clase; }

    // valor 1-7 tal como en BD
    public int  getDiaSemana()           { return diaSemana; }
    public void setDiaSemana(int dia)    { this.diaSemana = dia; }

    public LocalTime getHoraInicio()              { return horaInicio; }
    public void      setHoraInicio(LocalTime hi)  { this.horaInicio = hi; }

    public LocalTime getHoraFin()                 { return horaFin; }
    public void      setHoraFin(LocalTime hf)     { this.horaFin = hf; }

    public String getEstado()            { return estado; }
    public void   setEstado(String e)    { this.estado = e; }

    // ─── helpers para vista ───────────────────────────────────

    // nombre del día para JSP
    public String getNombreDia() {
        if (diaSemana < 1 || diaSemana > 7) return "Desconocido";
        return NOMBRES_DIA[diaSemana];
    }

    // rango horario formateado
    public String getRangoHorario() {
        String inicio = horaInicio != null ? horaInicio.toString().substring(0, 5) : "--:--";
        String fin    = horaFin    != null ? horaFin.toString().substring(0, 5)    : "--:--";
        return inicio + " – " + fin;
    }

    // si está programado
    public boolean isProgramado() {
        return "programado".equalsIgnoreCase(estado);
    }

    @Override
    public String toString() {
        return "Horario{id='" + id + "', clase='" + (clase != null ? clase.getId() : "?")
                + "', dia=" + getNombreDia() + ", " + getRangoHorario() + "}";
    }
}