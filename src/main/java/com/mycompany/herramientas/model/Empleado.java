package com.mycompany.herramientas.model;

/**
 * Empleado del gimnasio. ID autogenerado con formato EMP-AÑO-CORRELATIVO.
 *
 * Alineado a la tabla Empleados del SQL:
 *   id               VARCHAR(20) PK,
 *   nombre           VARCHAR(100),
 *   id_TipoDocumento VARCHAR(20) FK → TipoDocumentos,
 *   numeroDocumento  VARCHAR(20) UNIQUE,
 *   email            VARCHAR(150),
 *   apellido         VARCHAR(100),
 *   telefono         VARCHAR(20) NULL,
 *   id_Cargo         VARCHAR(10) FK → Cargos
 *
 * NOTA: la tabla Empleados NO tiene columna estado.
 * Si se necesita activar/desactivar empleados en el futuro,
 * se debe agregar la columna a la BD primero.
 *
 * Un empleado puede ser responsable de contratos (FK en Contratos)
 * y entrenador de clases (FK en Clases).
 */
public class Empleado {

    private String        id;              // Ej: EMP-2026-0001
    private String        nombre;
    private String        apellido;
    private TipoDocumento tipoDocumento;   // FK → TipoDocumentos (objeto completo)
    private String        numeroDocumento; // UNIQUE en BD
    private String        email;
    private String        telefono;        // NULL permitido
    private Cargo         cargo;           // FK → Cargos (objeto completo)

    public Empleado() {}

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

    // -----------------------------------------------------------------------
    // Getters y Setters
    // -----------------------------------------------------------------------

    public String getId()                        { return id; }
    public void   setId(String id)               { this.id = id; }

    public String getNombre()                    { return nombre; }
    public void   setNombre(String nombre)       { this.nombre = nombre; }

    public String getApellido()                  { return apellido; }
    public void   setApellido(String apellido)   { this.apellido = apellido; }

    public TipoDocumento getTipoDocumento()                      { return tipoDocumento; }
    public void          setTipoDocumento(TipoDocumento td)      { this.tipoDocumento = td; }

    public String getNumeroDocumento()                     { return numeroDocumento; }
    public void   setNumeroDocumento(String numeroDocumento) { this.numeroDocumento = numeroDocumento; }

    public String getEmail()                     { return email; }
    public void   setEmail(String email)         { this.email = email; }

    public String getTelefono()                  { return telefono; }
    public void   setTelefono(String telefono)   { this.telefono = telefono; }

    public Cargo getCargo()                      { return cargo; }
    public void  setCargo(Cargo cargo)           { this.cargo = cargo; }

    // -----------------------------------------------------------------------
    // Helpers
    // -----------------------------------------------------------------------

    /** Nombre completo para mostrar en tablas y selects de los JSP. */
    public String getNombreCompleto() {
        return nombre + " " + apellido;
    }

    @Override
    public String toString() {
        return "Empleado{id='" + id + "', nombre='" + getNombreCompleto() + "'}";
    }
}