package com.mycompany.herramientas.model;

// modelo de clase grupal del gimnasio
public class Clase {

    // id único de la clase
    private String id;

    // nombre de la clase
    private String nombreClase;

    // entrenador asignado
    private Empleado empleado;

    // tipo de clase
    private TipoClase tipoClase;

    // capacidad máxima permitida
    private int capacidadMaxima;

    // descripción opcional
    private String descripcion;

    // estado: vigente | suspendida
    private String estado;

    // constructor vacío
    public Clase() {}

    // constructor completo
    public Clase(String id, String nombreClase,
                 Empleado empleado, TipoClase tipoClase,
                 int capacidadMaxima,
                 String descripcion,
                 String estado) {

        this.id              = id;
        this.nombreClase     = nombreClase;
        this.empleado        = empleado;
        this.tipoClase       = tipoClase;
        this.capacidadMaxima = capacidadMaxima;
        this.descripcion     = descripcion;
        this.estado          = estado;
    }

    // ─── getters y setters ───────────────────────────────────

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getNombreClase() {
        return nombreClase;
    }

    public void setNombreClase(String nombre) {
        this.nombreClase = nombre;
    }

    public Empleado getEmpleado() {
        return empleado;
    }

    public void setEmpleado(Empleado e) {
        this.empleado = e;
    }

    public TipoClase getTipoClase() {
        return tipoClase;
    }

    public void setTipoClase(TipoClase tc) {
        this.tipoClase = tc;
    }

    public int getCapacidadMaxima() {
        return capacidadMaxima;
    }

    public void setCapacidadMaxima(int cap) {
        this.capacidadMaxima = cap;
    }

    public String getDescripcion() {
        return descripcion;
    }

    public void setDescripcion(String desc) {
        this.descripcion = desc;
    }

    public String getEstado() {
        return estado;
    }

    public void setEstado(String estado) {
        this.estado = estado;
    }

    // ─── helpers ─────────────────────────────────────────────

    // validar si la clase está activa
    public boolean isVigente() {
        return "vigente".equalsIgnoreCase(estado);
    }

    // representación rápida del objeto
    @Override
    public String toString() {

        return "Clase{id='" + id
                + "', nombre='" + nombreClase + "'}";
    }
}