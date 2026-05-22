package com.mycompany.herramientas.model;

import java.time.LocalTime;

/**
 * Horario asignado a una clase grupal. ID generado con prefijo HOR-AÑO-CORRELATIVO.
 *
 * Alineado a la tabla Horarios del SQL:
 *   id VARCHAR(20) PK,
 *   id_clase VARCHAR(20) FK → Clases,
 *   dia_semana TINYINT CHECK(1..7)  ← 1=Lunes ... 7=Domingo,
 *   hora_inicio TIME,
 *   hora_fin TIME,
 *   estado VARCHAR(20) CHECK('programado','cancelado') DEFAULT 'programado'
 *
 * IMPORTANTE: el SQL usa TINYINT para dia_semana (1-7), no un String.
 * Se provee el helper getNombreDia() para mostrar "Lunes", "Martes", etc. en la vista.
 * El DAO debe guardar el int y este modelo lo convierte para los JSP.
 */
public class Horario {

    private String    id;          // Ej: HOR-2026-0001
    private Clase     clase;       // FK → Clases
    private int       diaSemana;   // 1=Lunes, 2=Martes, ..., 7=Domingo (TINYINT)
    private LocalTime horaInicio;  // TIME en SQL → LocalTime en Java
    private LocalTime horaFin;     // TIME en SQL → LocalTime en Java
    private String    estado;      // 'programado' | 'cancelado'

    private static final String[] NOMBRES_DIA = {
        "", "Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado", "Domingo"
    };

    public Horario() {}

    public Horario(String id, Clase clase, int diaSemana,
                   LocalTime horaInicio, LocalTime horaFin, String estado) {
        this.id          = id;
        this.clase       = clase;
        this.diaSemana   = diaSemana;
        this.horaInicio  = horaInicio;
        this.horaFin     = horaFin;
        this.estado      = estado;
    }

    // -----------------------------------------------------------------------
    // Getters y Setters
    // -----------------------------------------------------------------------

    public String getId()                { return id; }
    public void   setId(String id)       { this.id = id; }

    public Clase  getClase()             { return clase; }
    public void   setClase(Clase clase)  { this.clase = clase; }

    /** Valor numérico del día (1-7) tal como se guarda en la BD. */
    public int  getDiaSemana()           { return diaSemana; }
    public void setDiaSemana(int dia)    { this.diaSemana = dia; }

    public LocalTime getHoraInicio()              { return horaInicio; }
    public void      setHoraInicio(LocalTime hi)  { this.horaInicio = hi; }

    public LocalTime getHoraFin()                 { return horaFin; }
    public void      setHoraFin(LocalTime hf)     { this.horaFin = hf; }

    public String getEstado()            { return estado; }
    public void   setEstado(String e)    { this.estado = e; }

    // -----------------------------------------------------------------------
    // Helpers para la vista (JSP)
    // -----------------------------------------------------------------------

    /**
     * Devuelve el nombre del día en español para mostrarlo en los JSP.
     * Ej: diaSemana=1 → "Lunes", diaSemana=6 → "Sábado".
     */
    public String getNombreDia() {
        if (diaSemana < 1 || diaSemana > 7) return "Desconocido";
        return NOMBRES_DIA[diaSemana];
    }

    /** Devuelve el horario formateado: "07:00 – 08:30". */
    public String getRangoHorario() {
        String inicio = horaInicio != null ? horaInicio.toString().substring(0, 5) : "--:--";
        String fin    = horaFin    != null ? horaFin.toString().substring(0, 5)    : "--:--";
        return inicio + " – " + fin;
    }

    public boolean isProgramado() {
        return "programado".equalsIgnoreCase(estado);
    }

    @Override
    public String toString() {
        return "Horario{id='" + id + "', clase='" + (clase != null ? clase.getId() : "?")
                + "', dia=" + getNombreDia() + ", " + getRangoHorario() + "}";
    }
}