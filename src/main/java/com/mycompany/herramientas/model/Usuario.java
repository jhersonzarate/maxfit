package com.mycompany.herramientas.model;

/**
 * Cuenta de acceso al sistema del personal. ID generado con prefijo USR-AÑO-CORRELATIVO.
 *
 * Alineado a la tabla Usuarios del SQL:
 *   id              VARCHAR(20) PK,
 *   email           VARCHAR(150) UNIQUE,
 *   passwordUsuario VARCHAR(255)   ← hash BCrypt ($2a$12$...), NUNCA texto plano,
 *   id_rol          VARCHAR(20) FK → Roles,
 *   id_empleado     VARCHAR(20) UNIQUE NULL FK → Empleados,
 *   estado          VARCHAR(10) CHECK('activo','inactivo') DEFAULT 'activo'
 *
 * Seguridad (RNF-03):
 *   - passwordUsuario almacena SOLO el hash BCrypt generado por PasswordService.
 *   - Nunca exponer el hash en la vista: no usar toString() con password.
 *   - La verificación se hace con BCrypt.checkpw(rawPassword, hash) en AuthService.
 *
 * El campo id_empleado es UNIQUE y NULL: un usuario puede no tener empleado asociado
 * (caso extremo), y un empleado solo puede tener una cuenta.
 *
 * Roles según AppConfig: ROL-ADMIN, ROL-RECEP, ROL-TRAINER.
 */
public class Usuario {

    private String   id;               // Ej: USR-2026-0001
    private String   email;            // UNIQUE en BD
    private String   passwordUsuario;  // Hash BCrypt — nunca texto plano
    private Rol      rol;              // FK → Roles (objeto completo)
    private Empleado empleado;         // FK → Empleados, puede ser null
    private String   estado;           // 'activo' | 'inactivo'

    public Usuario() {}

    /**
     * Constructor completo. El parámetro passwordHash debe ser ya el hash BCrypt,
     * no la contraseña original. Usa PasswordService.hashear() antes de llamar esto.
     */
    public Usuario(String id, String email, String passwordHash,
                   Rol rol, Empleado empleado, String estado) {
        this.id              = id;
        this.email           = email;
        this.passwordUsuario = passwordHash;
        this.rol             = rol;
        this.empleado        = empleado;
        this.estado          = estado;
    }

    // -----------------------------------------------------------------------
    // Getters y Setters
    // -----------------------------------------------------------------------

    public String   getId()                    { return id; }
    public void     setId(String id)           { this.id = id; }

    public String   getEmail()                 { return email; }
    public void     setEmail(String email)     { this.email = email; }

    /** Devuelve el hash BCrypt almacenado. Solo debe usarse en AuthService, no en vistas. */
    public String   getPasswordUsuario()                     { return passwordUsuario; }
    public void     setPasswordUsuario(String passwordHash)  { this.passwordUsuario = passwordHash; }

    public Rol      getRol()                   { return rol; }
    public void     setRol(Rol rol)            { this.rol = rol; }

    public Empleado getEmpleado()              { return empleado; }
    public void     setEmpleado(Empleado e)    { this.empleado = e; }

    public String   getEstado()                { return estado; }
    public void     setEstado(String estado)   { this.estado = estado; }

    // -----------------------------------------------------------------------
    // Helpers
    // -----------------------------------------------------------------------

    public boolean isActivo() {
        return "activo".equalsIgnoreCase(estado);
    }

    /** ID del rol para comparar con las constantes de AppConfig (ROL_ADMIN, ROL_RECEP…). */
    public String getIdRol() {
        return rol != null ? rol.getId() : null;
    }

    /** Nombre del empleado para mostrarlo en la navbar o en tablas. */
    public String getNombreEmpleado() {
        return (empleado != null) ? empleado.getNombreCompleto() : email;
    }

    /**
     * toString excluye la contraseña para evitar que aparezca en logs.
     */
    @Override
    public String toString() {
        return "Usuario{id='" + id + "', email='" + email
                + "', rol='" + (rol != null ? rol.getId() : "?")
                + "', estado='" + estado + "'}";
    }
}