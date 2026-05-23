package com.mycompany.herramientas.service;

import com.mycompany.herramientas.config.DatabaseConnection;
import com.mycompany.herramientas.dao.ClaseDAO;
import com.mycompany.herramientas.dao.ClienteDAO;
import com.mycompany.herramientas.dao.InscripcionDAO;
import com.mycompany.herramientas.model.Clase;
import com.mycompany.herramientas.model.Cliente;
import com.mycompany.herramientas.model.InscripcionClase;

import java.sql.SQLException;
import java.util.Collections;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * Reglas de negocio para inscripción a clases grupales (RF-11).
 *
 * Flujo de inscripción:
 *   1. Verificar que el cliente exista.
 *   2. Verificar que la clase exista y esté vigente.
 *   3. Verificar que el cliente NO esté ya inscrito en esa clase.
 *   4. Verificar que la clase tenga cupo disponible (inscritos < capacidad_maxima).
 *   5. Registrar la inscripción dentro de una transacción.
 *
 * El paso 4 se hace dentro de la misma transacción para evitar que
 * dos hilos simultáneos lean "hay cupo" e inscriban a ambos superando el límite.
 *
 * Resultado tipado con enum para que el controlador sepa exactamente qué pasó.
 */
public class InscripcionService {

    private static final Logger LOGGER = Logger.getLogger(InscripcionService.class.getName());

    private final ClienteDAO     clienteDAO;
    private final ClaseDAO       claseDAO;
    private final InscripcionDAO inscripcionDAO;

    public InscripcionService() {
        this.clienteDAO     = new ClienteDAO();
        this.claseDAO       = new ClaseDAO();
        this.inscripcionDAO = new InscripcionDAO();
    }

    // Constructor para tests con inyección de DAOs
    public InscripcionService(ClienteDAO clienteDAO, ClaseDAO claseDAO,
                               InscripcionDAO inscripcionDAO) {
        this.clienteDAO     = clienteDAO;
        this.claseDAO       = claseDAO;
        this.inscripcionDAO = inscripcionDAO;
    }

    // ── Resultado tipado ─────────────────────────────────────────────────────

    public enum TipoResultado {
        OK,                   // Inscripción registrada
        CLIENTE_NO_EXISTE,    // El ID de cliente no existe en BD
        CLASE_NO_EXISTE,      // El ID de clase no existe en BD
        CLASE_SUSPENDIDA,     // La clase está suspendida, no acepta inscripciones
        YA_INSCRITO,          // El cliente ya está inscrito en esa clase
        SIN_CUPO,             // La clase llegó a capacidad_maxima
        ERROR_BD              // Error interno
    }

    public static final class Resultado {
        private final TipoResultado   tipo;
        private final String          mensaje;
        private final InscripcionClase inscripcion; // solo cuando tipo == OK

        private Resultado(TipoResultado tipo, String mensaje, InscripcionClase inscripcion) {
            this.tipo        = tipo;
            this.mensaje     = mensaje;
            this.inscripcion = inscripcion;
        }

        public TipoResultado   getTipo()        { return tipo; }
        public String          getMensaje()     { return mensaje; }
        public InscripcionClase getInscripcion() { return inscripcion; }
        public boolean         isExitoso()      { return tipo == TipoResultado.OK; }

        static Resultado ok(InscripcionClase ic) {
            return new Resultado(TipoResultado.OK, "Inscripción registrada correctamente.", ic);
        }
        static Resultado clienteNoExiste(String id) {
            return new Resultado(TipoResultado.CLIENTE_NO_EXISTE,
                    "No se encontró el cliente con ID: " + id, null);
        }
        static Resultado claseNoExiste(String id) {
            return new Resultado(TipoResultado.CLASE_NO_EXISTE,
                    "No se encontró la clase con ID: " + id, null);
        }
        static Resultado claseSuspendida(Clase c) {
            return new Resultado(TipoResultado.CLASE_SUSPENDIDA,
                    "La clase \"" + c.getNombreClase() + "\" está suspendida y no acepta inscripciones.", null);
        }
        static Resultado yaInscrito(Cliente cli, Clase c) {
            return new Resultado(TipoResultado.YA_INSCRITO,
                    cli.getNombreCompleto() + " ya está inscrito/a en \"" + c.getNombreClase() + "\".", null);
        }
        static Resultado sinCupo(Clase c) {
            return new Resultado(TipoResultado.SIN_CUPO,
                    "La clase \"" + c.getNombreClase() + "\" no tiene cupos disponibles (capacidad máxima: "
                    + c.getCapacidadMaxima() + ").", null);
        }
        static Resultado errorBd() {
            return new Resultado(TipoResultado.ERROR_BD,
                    "Error interno. Intenta nuevamente.", null);
        }
    }

    // ── Inscribir cliente a clase ────────────────────────────────────────────

    /**
     * Inscribe a un cliente en una clase grupal cumpliendo todas las reglas de RF-11.
     *
     * @param clienteId ID del cliente a inscribir
     * @param claseId   ID de la clase destino
     * @return Resultado tipado con isExitoso() y getMensaje()
     */
    public Resultado inscribir(String clienteId, String claseId) {

        try {
            // 1. Verificar cliente
            Cliente cliente = clienteDAO.findById(clienteId);
            if (cliente == null) return Resultado.clienteNoExiste(clienteId);

            // 2. Verificar clase
            Clase clase = claseDAO.findById(claseId);
            if (clase == null) return Resultado.claseNoExiste(claseId);

            // 3. Verificar que la clase esté vigente
            if (!clase.isVigente()) return Resultado.claseSuspendida(clase);

            // 4. Verificar que no esté ya inscrito
            if (inscripcionDAO.existeInscripcion(clienteId, claseId)) {
                return Resultado.yaInscrito(cliente, clase);
            }

            // 5. Verificar cupo disponible (dentro de transacción para evitar race condition)
            DatabaseConnection.beginTransaction();

            int inscritos       = inscripcionDAO.countInscritos(claseId);
            int capacidadMaxima = clase.getCapacidadMaxima();

            if (inscritos >= capacidadMaxima) {
                DatabaseConnection.rollback();
                return Resultado.sinCupo(clase);
            }

            // 6. Registrar inscripción
            InscripcionClase inscripcion = new InscripcionClase();
            inscripcion.setCliente(cliente);
            inscripcion.setClase(clase);
            inscripcionDAO.save(inscripcion);

            DatabaseConnection.commit();

            LOGGER.info("Inscripción exitosa: cliente=" + clienteId
                    + " | clase=" + claseId
                    + " | cupo=" + (inscritos + 1) + "/" + capacidadMaxima);

            return Resultado.ok(inscripcion);

        } catch (SQLException e) {
            DatabaseConnection.rollback();
            LOGGER.log(Level.SEVERE,
                    "Error de BD al inscribir cliente=" + clienteId + " clase=" + claseId, e);
            return Resultado.errorBd();
        } finally {
            DatabaseConnection.closeConnection();
        }
    }

    // ── Cancelar inscripción ─────────────────────────────────────────────────

    /**
     * Cancela la inscripción de un cliente en una clase.
     *
     * @param inscripcionId ID de la inscripción (PK de Inscripcion_Clases)
     * @return ContratoService.Resultado con isExitoso() y getMensaje()
     */
    public ContratoService.Resultado cancelar(String inscripcionId) {
        if (inscripcionId == null || inscripcionId.trim().isEmpty()) {
            return ContratoService.Resultado.error("ID de inscripción inválido.");
        }
        try {
            boolean ok = inscripcionDAO.delete(inscripcionId);
            if (ok) {
                LOGGER.info("Inscripción cancelada: " + inscripcionId);
                return ContratoService.Resultado.ok("Inscripción cancelada correctamente.");
            }
            return ContratoService.Resultado.error("No se encontró la inscripción.");
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error al cancelar inscripción: " + inscripcionId, e);
            return ContratoService.Resultado.error("Error interno al cancelar la inscripción.");
        }
    }

    // ── Consultas ────────────────────────────────────────────────────────────

    /**
     * Todas las inscripciones de un cliente.
     * Para el perfil del cliente: "Clases en las que está inscrito".
     *
     * CORRECCIÓN: se reemplazó List.of() por Collections.emptyList()
     * para garantizar compatibilidad con Java 8+. List.of() existe
     * desde Java 9 pero el compilador del IDE lo resolvía como versión anterior.
     */
    public List<InscripcionClase> listarPorCliente(String clienteId) {
        try {
            return inscripcionDAO.findByClienteId(clienteId);
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error al listar inscripciones del cliente: " + clienteId, e);
            return Collections.emptyList(); // ← FIX: antes era List.of()
        }
    }

    /**
     * Todos los inscritos en una clase.
     * Para la vista de detalle de clase (lista de participantes).
     *
     * CORRECCIÓN: se reemplazó List.of() por Collections.emptyList()
     * para garantizar compatibilidad con Java 8+.
     */
    public List<InscripcionClase> listarPorClase(String claseId) {
        try {
            return inscripcionDAO.findByClaseId(claseId);
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error al listar inscripciones de clase: " + claseId, e);
            return Collections.emptyList(); // ← FIX: antes era List.of()
        }
    }

    /**
     * Cupos disponibles en una clase.
     * Útil para mostrar "X / Y cupos" en la interfaz.
     *
     * @return arreglo int[]{inscritos, capacidadMaxima}, o int[]{0,0} si error
     */
    public int[] cuposInfo(String claseId) {
        try {
            int inscritos  = inscripcionDAO.countInscritos(claseId);
            int capacidad  = inscripcionDAO.getCapacidadMaxima(claseId);
            return new int[]{ inscritos, capacidad };
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error al obtener cupos de clase: " + claseId, e);
            return new int[]{ 0, 0 };
        }
    }
}