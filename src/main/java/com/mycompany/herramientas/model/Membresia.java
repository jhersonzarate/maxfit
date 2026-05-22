package com.mycompany.herramientas.model;

import java.math.BigDecimal;

/**
 * Plan de membresía del gimnasio.
 *
 * Alineado a la tabla Membresias del SQL:
 *   id               VARCHAR(20) PK,
 *   nombre_membresia VARCHAR(100),
 *   precio           DECIMAL(10,2),
 *   duracion_meses   INT,
 *   descripcion      VARCHAR(200)
 *
 * NOTA: la tabla Membresias NO tiene columna estado.
 * Todos los planes registrados están disponibles para asignar a contratos.
 * Si en el futuro se requiere activar/desactivar planes, se debe agregar
 * la columna estado a la tabla en la BD primero.
 *
 * Se usa BigDecimal para el precio porque double puede generar
 * errores de redondeo en operaciones monetarias.
 */
public class Membresia {

    private String     id;               // Ej: MEM-STD
    private String     nombreMembresia;  // Ej: Plan Estándar Mensual
    private BigDecimal precio;           // DECIMAL(10,2) → BigDecimal, nunca double
    private int        duracionMeses;    // Ej: 1, 3, 12
    private String     descripcion;      // NULL permitido

    public Membresia() {}

    public Membresia(String id, String nombreMembresia, BigDecimal precio,
                     int duracionMeses, String descripcion) {
        this.id              = id;
        this.nombreMembresia = nombreMembresia;
        this.precio          = precio;
        this.duracionMeses   = duracionMeses;
        this.descripcion     = descripcion;
    }

    // -----------------------------------------------------------------------
    // Getters y Setters
    // -----------------------------------------------------------------------

    public String getId()                          { return id; }
    public void   setId(String id)                 { this.id = id; }

    public String getNombreMembresia()                          { return nombreMembresia; }
    public void   setNombreMembresia(String nombreMembresia)    { this.nombreMembresia = nombreMembresia; }

    public BigDecimal getPrecio()                  { return precio; }
    public void       setPrecio(BigDecimal precio) { this.precio = precio; }

    public int  getDuracionMeses()                   { return duracionMeses; }
    public void setDuracionMeses(int duracionMeses)  { this.duracionMeses = duracionMeses; }

    public String getDescripcion()                   { return descripcion; }
    public void   setDescripcion(String descripcion) { this.descripcion = descripcion; }

    // -----------------------------------------------------------------------
    // Helpers
    // -----------------------------------------------------------------------

    /**
     * Descripción formateada para mostrar en selects del JSP.
     * Ej: "Plan Estándar Mensual — S/ 120.00 (1 mes)"
     */
    public String getResumen() {
        return nombreMembresia + " — S/ " + precio
                + " (" + duracionMeses + (duracionMeses == 1 ? " mes)" : " meses)");
    }

    @Override
    public String toString() {
        return "Membresia{id='" + id + "', nombre='" + nombreMembresia
                + "', precio=" + precio + "}";
    }
}