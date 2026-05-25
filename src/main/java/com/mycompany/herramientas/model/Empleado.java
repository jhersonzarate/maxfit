package com.mycompany.herramientas.model;

// modelo de empleado del gimnasio
public class Empleado {

    // ─── atributos ─────────────────────────────────────────────

    private String        id;              // Ej: EMP-2026-0001
    private String        nombre;
    private String        apellido;
    private TipoDocumento tipoDocumento;   // tipo de documento asociado
    private String        numeroDocumento; // documento único
    private String        email;
    private String        telefono;        // puede ser null
    private Cargo         cargo;           // cargo del empleado

    public Empleado() {}

    // constructor completo del empleado
    public Empleado(String id, String nombre, String apellido,
                    TipoDocumento tipoDocumento, String numeroDocumento,
                    String email, String telefono, Cargo cargo) {
        this.id              = id;
        this.nombre          = nombre;
        this.apellido        = apellido;
        this.tipoDocumento   = tipoDocumento;
        this.numeroDocumento = numeroDocumento;
        this.email           = email;
        this.telefono        = telefono;
        this.cargo           = cargo;
    }

    // ─── getters y setters ────────────────────────────────────

    public String getId()                        { return id; }
    public void   setId(String id)               { this.id = id; }

    public String getNombre()                    { return nombre; }
    public void   setNombre(String nombre)       { this.nombre = nombre; }

    public String getApellido()                  { return apellido; }
    public void   setApellido(String apellido)   { this.apellido = apellido; }

    public TipoDocumento getTipoDocumento()                      { return tipoDocumento; }
    public void          setTipoDocumento(TipoDocumento td)      { this.tipoDocumento = td; }

    public String getNumeroDocumento()                       { return numeroDocumento; }
    public void   setNumeroDocumento(String numeroDocumento) { this.numeroDocumento = numeroDocumento; }

    public String getEmail()                     { return email; }
    public void   setEmail(String email)         { this.email = email; }

    public String getTelefono()                  { return telefono; }
    public void   setTelefono(String telefono)   { this.telefono = telefono; }

    public Cargo getCargo()                      { return cargo; }
    public void  setCargo(Cargo cargo)           { this.cargo = cargo; }

    // ─── helpers ──────────────────────────────────────────────

    // obtener nombre completo para tablas y vistas
    public String getNombreCompleto() {
        return nombre + " " + apellido;
    }

    @Override
    public String toString() {
        return "Empleado{id='" + id + "', nombre='" + getNombreCompleto() + "'}";
    }
}