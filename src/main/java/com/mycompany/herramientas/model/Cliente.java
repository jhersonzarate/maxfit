package com.mycompany.herramientas.model;

import java.time.LocalDate;

/**
 * Cliente del gimnasio. ID generado con prefijo CLI-AÑO-CORRELATIVO.
 *
 * Alineado a la tabla Clientes del SQL:
 *   id, nombre, apellido, id_TipoDocumento (FK), numero_documento (UNIQUE),
 *   email (UNIQUE), telefono, fecha_nacimiento, genero CHECK('Masculino','Femenino','Otro')
 */
public class Cliente {

    private String        id;               // Ej: CLI-2026-0001
    private String        nombre;
    private String        apellido;
    private TipoDocumento tipoDocumento;    // FK → TipoDocumentos
    private String        numeroDocumento;  // UNIQUE en BD
    private String        email;            // UNIQUE en BD, puede ser null
    private String        telefono;         // null permitido
    private LocalDate     fechaNacimiento;  // null permitido
    private String        genero;           // 'Masculino' | 'Femenino' | 'Otro' | null

    public Cliente() {}

    public Cliente(String id, String nombre, String apellido,
                   TipoDocumento tipoDocumento, String numeroDocumento,
                   String email, String telefono,
                   LocalDate fechaNacimiento, String genero) {
        this.id              = id;
        this.nombre          = nombre;
        this.apellido        = apellido;
        this.tipoDocumento   = tipoDocumento;
        this.numeroDocumento = numeroDocumento;
        this.email           = email;
        this.telefono        = telefono;
        this.fechaNacimiento = fechaNacimiento;
        this.genero          = genero;
    }

    // -----------------------------------------------------------------------
    // Getters y Setters
    // -----------------------------------------------------------------------

    public String getId()                    { return id; }
    public void   setId(String id)           { this.id = id; }

    public String getNombre()                { return nombre; }
    public void   setNombre(String nombre)   { this.nombre = nombre; }

    public String getApellido()              { return apellido; }
    public void   setApellido(String ap)     { this.apellido = ap; }

    public TipoDocumento getTipoDocumento()                     { return tipoDocumento; }
    public void          setTipoDocumento(TipoDocumento td)     { this.tipoDocumento = td; }

    public String getNumeroDocumento()               { return numeroDocumento; }
    public void   setNumeroDocumento(String num)     { this.numeroDocumento = num; }

    public String getEmail()                 { return email; }
    public void   setEmail(String email)     { this.email = email; }

    public String getTelefono()              { return telefono; }
    public void   setTelefono(String tel)    { this.telefono = tel; }

    public LocalDate getFechaNacimiento()             { return fechaNacimiento; }
    public void      setFechaNacimiento(LocalDate fn) { this.fechaNacimiento = fn; }

    public String getGenero()                { return genero; }
    public void   setGenero(String genero)   { this.genero = genero; }

    // -----------------------------------------------------------------------
    // Helpers útiles en JSP y DAOs
    // -----------------------------------------------------------------------

    /** Nombre completo para mostrar en tablas y selects. */
    public String getNombreCompleto() {
        return nombre + " " + apellido;
    }

    @Override
    public String toString() {
        return "Cliente{id='" + id + "', nombre='" + getNombreCompleto() + "'}";
    }
}