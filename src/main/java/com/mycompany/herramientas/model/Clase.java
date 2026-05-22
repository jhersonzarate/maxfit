package com.mycompany.herramientas.model;

/**
 * Clase grupal del gimnasio. ID generado con prefijo CLA-AÑO-CORRELATIVO.
 *
 * Alineado a la tabla Clases del SQL:
 *   id VARCHAR(20) PK,
 *   nombre_clase VARCHAR(100),
 *   id_empleado VARCHAR(20) FK → Empleados,
 *   id_tipoClase VARCHAR(20) FK → TipoClases,
 *   capacidad_maxima INT,
 *   descripcion VARCHAR(200),
 *   estado VARCHAR(20) CHECK('vigente','suspendida') DEFAULT 'vigente'
 *
 * La columna en el SQL se llama nombre_clase (no nombre).
 * El entrenador es un Empleado (FK id_empleado).
 * El tipo es un objeto TipoClase (FK id_tipoClase).
 */
public class Clase {

    private String     id;              // Ej: CLA-2026-0001
    private String     nombreClase;     // Columna: nombre_clase
    private Empleado   empleado;        // FK → Empleados (el entrenador)
    private TipoClase  tipoClase;       // FK → TipoClases
    private int        capacidadMaxima; // Columna: capacidad_maxima
    private String     descripcion;     // null permitido
    private String     estado;          // 'vigente' | 'suspendida'

    public Clase() {}

    public Clase(String id, String nombreClase, Empleado empleado,
                 TipoClase tipoClase, int capacidadMaxima,
                 String descripcion, String estado) {
        this.id              = id;
        this.nombreClase     = nombreClase;
        this.empleado        = empleado;
        this.tipoClase       = tipoClase;
        this.capacidadMaxima = capacidadMaxima;
        this.descripcion     = descripcion;
        this.estado          = estado;
    }

    // -----------------------------------------------------------------------
    // Getters y Setters
    // -----------------------------------------------------------------------

    public String getId()                   { return id; }
    public void   setId(String id)          { this.id = id; }

    public String getNombreClase()               { return nombreClase; }
    public void   setNombreClase(String nombre)  { this.nombreClase = nombre; }

    public Empleado getEmpleado()                { return empleado; }
    public void     setEmpleado(Empleado e)      { this.empleado = e; }

    public TipoClase getTipoClase()              { return tipoClase; }
    public void      setTipoClase(TipoClase tc)  { this.tipoClase = tc; }

    public int  getCapacidadMaxima()             { return capacidadMaxima; }
    public void setCapacidadMaxima(int cap)      { this.capacidadMaxima = cap; }

    public String getDescripcion()               { return descripcion; }
    public void   setDescripcion(String desc)    { this.descripcion = desc; }

    public String getEstado()                    { return estado; }
    public void   setEstado(String estado)       { this.estado = estado; }

    // -----------------------------------------------------------------------
    // Helpers
    // -----------------------------------------------------------------------

    /** true si la clase está vigente y disponible para inscripciones. */
    public boolean isVigente() {
        return "vigente".equalsIgnoreCase(estado);
    }

    @Override
    public String toString() {
        return "Clase{id='" + id + "', nombre='" + nombreClase + "'}";
    }
}