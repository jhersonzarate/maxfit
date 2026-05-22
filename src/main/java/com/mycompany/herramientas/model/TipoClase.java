package com.mycompany.herramientas.model;

/**
 * Tipo de clase grupal del gimnasio (TCL-CARDIO, TCL-YOGA, TCL-BOX, TCL-FUNCIONAL).
 *
 * Alineado a la tabla TipoClases del SQL:
 *   id VARCHAR(20) PK, nombre VARCHAR(50)
 *
 * Es un catálogo fijo: los IDs se insertan manualmente y se referencian
 * desde AppConfig con las constantes TCL_*.
 */
public class TipoClase {

    private String id;     // Ej: TCL-YOGA
    private String nombre; // Ej: Yoga

    public TipoClase() {}

    public TipoClase(String id, String nombre) {
        this.id     = id;
        this.nombre = nombre;
    }

    public String getId()                { return id; }
    public void   setId(String id)       { this.id = id; }

    public String getNombre()            { return nombre; }
    public void   setNombre(String n)    { this.nombre = n; }

    @Override
    public String toString() {
        return "TipoClase{id='" + id + "', nombre='" + nombre + "'}";
    }
}