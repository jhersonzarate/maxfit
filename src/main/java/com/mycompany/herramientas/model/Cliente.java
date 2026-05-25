package com.mycompany.herramientas.model;

import java.time.LocalDate;

// modelo de cliente del gimnasio
public class Cliente {

    // id único del cliente
    private String id;

    // nombres del cliente
    private String nombre;

    // apellidos del cliente
    private String apellido;

    // tipo de documento asociado
    private TipoDocumento tipoDocumento;

    // número de documento único
    private String numeroDocumento;

    // correo electrónico
    private String email;

    // teléfono de contacto
    private String telefono;

    // fecha de nacimiento
    private LocalDate fechaNacimiento;

    // género del cliente
    private String genero;

    // constructor vacío
    public Cliente() {}

    // constructor completo
    public Cliente(String id, String nombre,
                   String apellido,
                   TipoDocumento tipoDocumento,
                   String numeroDocumento,
                   String email,
                   String telefono,
                   LocalDate fechaNacimiento,
                   String genero) {

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

    // ─── getters y setters ───────────────────────────────────

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getNombre() {
        return nombre;
    }

    public void setNombre(String nombre) {
        this.nombre = nombre;
    }

    public String getApellido() {
        return apellido;
    }

    public void setApellido(String ap) {
        this.apellido = ap;
    }

    public TipoDocumento getTipoDocumento() {
        return tipoDocumento;
    }

    public void setTipoDocumento(TipoDocumento td) {
        this.tipoDocumento = td;
    }

    public String getNumeroDocumento() {
        return numeroDocumento;
    }

    public void setNumeroDocumento(String num) {
        this.numeroDocumento = num;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getTelefono() {
        return telefono;
    }

    public void setTelefono(String tel) {
        this.telefono = tel;
    }

    public LocalDate getFechaNacimiento() {
        return fechaNacimiento;
    }

    public void setFechaNacimiento(LocalDate fn) {
        this.fechaNacimiento = fn;
    }

    public String getGenero() {
        return genero;
    }

    public void setGenero(String genero) {
        this.genero = genero;
    }

    // ─── helpers ─────────────────────────────────────────────

    // obtener nombre completo del cliente
    public String getNombreCompleto() {

        return nombre + " " + apellido;
    }

    // representación rápida del objeto
    @Override
    public String toString() {

        return "Cliente{id='" + id
                + "', nombre='"
                + getNombreCompleto()
                + "'}";
    }
}