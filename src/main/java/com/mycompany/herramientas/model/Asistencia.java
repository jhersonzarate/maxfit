package com.mycompany.herramientas.model;

import java.time.LocalDate;
import java.time.LocalTime;

/**
 * Registro de asistencia (check-in) de un cliente al gimnasio.
 * ID generado con prefijo ASI-AÑO-CORRELATIVO.
 *
 * Alineado a la tabla Asistencia del SQL:
 *   id           VARCHAR(20) PK,
 *   id_contrato  VARCHAR(20) FK → Contratos,
 *   fecha        DATE,
 *   estado       VARCHAR(20) CHECK('asistio','falto','pendiente') DEFAULT 'pendiente',
 *   hora_ingreso TIME NULL,
 *   CONSTRAINT UQ_Asistencia_Dia UNIQUE (id_contrato, fecha)
 *
 * NOTA IMPORTANTE vs el modelo anterior (MaxFit):
 * - El SQL solo tiene id_contrato como FK, NO id_cliente directamente.
 * - El cliente se obtiene a través del contrato: asistencia → contrato → cliente.
 * - hora_ingreso es NULL en la BD (se rellena al hacer check-in).
 * - El UNIQUE sobre (id_contrato, fecha) impide doble registro por día.
 *
 * Estados según RF-04 y RF-05:
 *   'pendiente' → aún no ha llegado (se crea al inicio del día o con cron)
 *   'asistio'   → registró entrada
 *   'falto'     → no se presentó
 */
public class Asistencia {

    private String    id;          // Ej: ASI-2026-0001
    private Contrato  contrato;    // FK → Contratos (contiene al cliente y membresía)
    private LocalDate fecha;       // DATE — un registro por contrato por día (UNIQUE)
    private String    estado;      // 'asistio' | 'falto' | 'pendiente'
    private LocalTime horaIngreso; // TIME NULL — se rellena al hacer check-in

    public Asistencia() {}

    public Asistencia(String id, Contrato contrato, LocalDate fecha,
                      String estado, LocalTime horaIngreso) {
        this.id          = id;
        this.contrato    = contrato;
        this.fecha       = fecha;
        this.estado      = estado;
        this.horaIngreso = horaIngreso;
    }

    // -----------------------------------------------------------------------
    // Getters y Setters
    // -----------------------------------------------------------------------

    public String    getId()                    { return id; }
    public void      setId(String id)           { this.id = id; }

    public Contrato  getContrato()              { return contrato; }
    public void      setContrato(Contrato c)    { this.contrato = c; }

    public LocalDate getFecha()                 { return fecha; }
    public void      setFecha(LocalDate fecha)  { this.fecha = fecha; }

    public String    getEstado()                { return estado; }
    public void      setEstado(String estado)   { this.estado = estado; }

    public LocalTime getHoraIngreso()               { return horaIngreso; }
    public void      setHoraIngreso(LocalTime hora) { this.horaIngreso = hora; }

    // -----------------------------------------------------------------------
    // Helpers
    // -----------------------------------------------------------------------

    /**
     * Shortcut para el JSP: obtiene el nombre completo del cliente
     * navegando por el contrato.
     * Nunca llama a cliente directamente porque no existe esa FK en el SQL.
     */
    public String getNombreCliente() {
        if (contrato != null && contrato.getCliente() != null) {
            return contrato.getCliente().getNombreCompleto();
        }
        return "—";
    }

    /** Hora formateada HH:mm para mostrar en tabla. */
    public String getHoraIngresoFormateada() {
        if (horaIngreso == null) return "—";
        return horaIngreso.toString().substring(0, 5);
    }

    public boolean isAsistio()   { return "asistio".equalsIgnoreCase(estado); }
    public boolean isFalto()     { return "falto".equalsIgnoreCase(estado); }
    public boolean isPendiente() { return "pendiente".equalsIgnoreCase(estado); }

    @Override
    public String toString() {
        return "Asistencia{id='" + id + "', contrato='"
                + (contrato != null ? contrato.getId() : "?")
                + "', fecha=" + fecha + ", estado='" + estado + "'}";
    }
}