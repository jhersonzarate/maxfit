package com.mycompany.herramientas.model;

// usuario del sistema (acceso y seguridad)
public class Usuario {

    // ─── atributos ─────────────────────────────────────────────

    private String   id;               // Ej: USR-2026-0001
    private String   email;            // correo único
    private String   passwordUsuario;  // hash BCrypt
    private Rol      rol;              // rol del sistema
    private Empleado empleado;         // puede ser null
    private String   estado;           // activo | inactivo

    public Usuario() {}

    // constructor completo (password ya debe venir hasheado)
    public Usuario(String id, String email, String passwordHash,
                   Rol rol, Empleado empleado, String estado) {
        this.id              = id;
        this.email           = email;
        this.passwordUsuario = passwordHash;
        this.rol             = rol;
        this.empleado        = empleado;
        this.estado          = estado;
    }

    // ─── getters y setters ────────────────────────────────────

    public String getId()                    { return id; }
    public void   setId(String id)           { this.id = id; }

    public String getEmail()                 { return email; }
    public void   setEmail(String email)     { this.email = email; }

    // hash BCrypt (no usar en vistas)
    public String getPasswordUsuario()                     { return passwordUsuario; }
    public void   setPasswordUsuario(String passwordHash)  { this.passwordUsuario = passwordHash; }

    public Rol    getRol()                   { return rol; }
    public void   setRol(Rol rol)            { this.rol = rol; }

    public Empleado getEmpleado()              { return empleado; }
    public void     setEmpleado(Empleado e)    { this.empleado = e; }

    public String getEstado()                { return estado; }
    public void   setEstado(String estado)   { this.estado = estado; }

    // ─── helpers ──────────────────────────────────────────────

    // validar si usuario está activo
    public boolean isActivo() {
        return "activo".equalsIgnoreCase(estado);
    }

    // obtener id del rol
    public String getIdRol() {
        return rol != null ? rol.getId() : null;
    }

    // nombre del empleado o fallback email
    public String getNombreEmpleado() {
        return (empleado != null) ? empleado.getNombreCompleto() : email;
    }

    @Override
    public String toString() {
        return "Usuario{id='" + id + "', email='" + email
                + "', rol='" + (rol != null ? rol.getId() : "?")
                + "', estado='" + estado + "'}";
    }
}