package com.mycompany.herramientas.model;

/**
 * Empleado del gimnasio. ID autogenerado con formato EMP-2026-0001.
 *
 * Un empleado puede ser responsable de contratos y entrenador de clases.
 * El estado "activo"/"inactivo" controla si aparece disponible para
 * asignar, según RF-12 del documento.
 */
public class Empleado {

    private String       id;              // Ej: EMP-2026-0001
    private String       nombre;
    private String       apellido;
    private TipoDocumento tipoDocumento;  // Objeto completo, no solo el ID
    private String       numeroDocumento;
    private String       email;
    private String       telefono;
    private Cargo        cargo;           // Objeto completo
    private String       estado;         // "activo" o "inactivo"

    public Empleado() {}

    public Empleado(String id, String nombre, String apellido,
                    TipoDocumento tipoDocumento, String numeroDocumento,
                    String email, String telefono, Cargo cargo, String estado) {
        this.id = id;
        this.nombre = nombre;
        this.apellido = apellido;
        this.tipoDocumento = tipoDocumento;
        this.numeroDocumento = numeroDocumento;
        this.email = email;
        this.telefono = telefono;
        this.cargo = cargo;
        this.estado = estado;
    }

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getNombre() { return nombre; }
    public void setNombre(String nombre) { this.nombre = nombre; }

    public String getApellido() { return apellido; }
    public void setApellido(String apellido) { this.apellido = apellido; }

    public TipoDocumento getTipoDocumento() { return tipoDocumento; }
    public void setTipoDocumento(TipoDocumento tipoDocumento) { this.tipoDocumento = tipoDocumento; }

    public String getNumeroDocumento() { return numeroDocumento; }
    public void setNumeroDocumento(String numeroDocumento) { this.numeroDocumento = numeroDocumento; }

    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }

    public String getTelefono() { return telefono; }
    public void setTelefono(String telefono) { this.telefono = telefono; }

    public Cargo getCargo() { return cargo; }
    public void setCargo(Cargo cargo) { this.cargo = cargo; }

    public String getEstado() { return estado; }
    public void setEstado(String estado) { this.estado = estado; }

    // Útil para mostrar en tablas y selects de los JSP
    public String getNombreCompleto() {
        return nombre + " " + apellido;
    }

    public boolean isActivo() {
        return "activo".equalsIgnoreCase(estado);
    }

    @Override
    public String toString() {
        return "Empleado{id='" + id + "', nombre='" + getNombreCompleto() + "'}";
    }
}