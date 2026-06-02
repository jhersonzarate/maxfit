package com.mycompany.herramientas.service;

import com.mycompany.herramientas.config.DatabaseConnection;
import com.mycompany.herramientas.dao.ClaseDAO;
import com.mycompany.herramientas.dao.ClienteDAO;
import com.mycompany.herramientas.dao.InscripcionDAO;
import com.mycompany.herramientas.model.Clase;
import com.mycompany.herramientas.model.Cliente;
import com.mycompany.herramientas.model.InscripcionClase;

import java.sql.Connection;
import java.sql.SQLException;
import java.util.Collections;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

// reglas de negocio para inscripción a clases grupales
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

    public InscripcionService(ClienteDAO clienteDAO, ClaseDAO claseDAO,
                               InscripcionDAO inscripcionDAO) {
        this.clienteDAO     = clienteDAO;
        this.claseDAO       = claseDAO;
        this.inscripcionDAO = inscripcionDAO;
    }

    // ─── RESULTADO ─────────────────────────────────────────────

    public enum TipoResultado {
        OK,
        CLIENTE_NO_EXISTE,
        CLASE_NO_EXISTE,
        CLASE_SUSPENDIDA,
        YA_INSCRITO,
        SIN_CUPO,
        ERROR_BD
    }

    public static final class Resultado {

        private final TipoResultado tipo;
        private final String mensaje;
        private final InscripcionClase inscripcion;

        private Resultado(TipoResultado tipo, String mensaje, InscripcionClase inscripcion) {
            this.tipo = tipo;
            this.mensaje = mensaje;
            this.inscripcion = inscripcion;
        }

        public TipoResultado getTipo() { return tipo; }
        public String getMensaje() { return mensaje; }
        public InscripcionClase getInscripcion() { return inscripcion; }
        public boolean isExitoso() { return tipo == TipoResultado.OK; }

        static Resultado ok(InscripcionClase ic) {
            return new Resultado(TipoResultado.OK, "Inscripción registrada correctamente.", ic);
        }

        static Resultado clienteNoExiste(String id) {
            return new Resultado(TipoResultado.CLIENTE_NO_EXISTE,
                    "No se encontró el cliente: " + id, null);
        }

        static Resultado claseNoExiste(String id) {
            return new Resultado(TipoResultado.CLASE_NO_EXISTE,
                    "No se encontró la clase: " + id, null);
        }

        static Resultado claseSuspendida(Clase c) {
            return new Resultado(TipoResultado.CLASE_SUSPENDIDA,
                    "Clase suspendida: " + c.getNombreClase(), null);
        }

        static Resultado yaInscrito(Cliente c, Clase cl) {
            return new Resultado(TipoResultado.YA_INSCRITO,
                    c.getNombreCompleto() + " ya está inscrito en " + cl.getNombreClase(), null);
        }

        static Resultado sinCupo(Clase c) {
            return new Resultado(TipoResultado.SIN_CUPO,
                    "Sin cupos en " + c.getNombreClase(), null);
        }

        static Resultado errorBd() {
            return new Resultado(TipoResultado.ERROR_BD,
                    "Error interno en la base de datos.", null);
        }
    }

    // ─── INSCRIPCIÓN ──────────────────────────────────────────

    public Resultado inscribir(String clienteId, String claseId) {

        try {

            // validar cliente
            Cliente cliente = clienteDAO.findById(clienteId);
            if (cliente == null) return Resultado.clienteNoExiste(clienteId);

            // validar clase
            Clase clase = claseDAO.findById(claseId);
            if (clase == null) return Resultado.claseNoExiste(claseId);

            // estado de clase
            if (!clase.isVigente()) return Resultado.claseSuspendida(clase);

            // ya inscrito
            if (inscripcionDAO.existeInscripcion(clienteId, claseId)) {
                return Resultado.yaInscrito(cliente, clase);
            }

            // transacción
            DatabaseConnection.beginTransaction();
            Connection txCon = DatabaseConnection.getConnection();

            int inscritos = inscripcionDAO.countInscritos(txCon, claseId);
            int capacidad = clase.getCapacidadMaxima();

            if (inscritos >= capacidad) {
                DatabaseConnection.rollback();
                return Resultado.sinCupo(clase);
            }

            InscripcionClase inscripcion = new InscripcionClase();
            inscripcion.setId(com.mycompany.herramientas.dao.IdGenerator.parInscripcion());
            inscripcion.setCliente(cliente);
            inscripcion.setClase(clase);

            inscripcionDAO.save(txCon, inscripcion);

            DatabaseConnection.commit();

            LOGGER.info("Inscripción OK: " + clienteId + " -> " + claseId);

            return Resultado.ok(inscripcion);

        } catch (SQLException e) {

            DatabaseConnection.rollback();
            LOGGER.log(Level.SEVERE,
                    "Error inscribiendo cliente=" + clienteId + " clase=" + claseId, e);

            return Resultado.errorBd();

        } finally {

            DatabaseConnection.closeConnection();
        }
    }

    // ─── CANCELAR ─────────────────────────────────────────────

    public ContratoService.Resultado cancelar(String inscripcionId) {

        if (inscripcionId == null || inscripcionId.trim().isEmpty()) {
            return ContratoService.Resultado.error("ID inválido");
        }

        try {

            boolean ok = inscripcionDAO.delete(inscripcionId);

            if (ok) {
                LOGGER.info("Inscripción cancelada: " + inscripcionId);
                return ContratoService.Resultado.ok("Cancelado correctamente");
            }

            return ContratoService.Resultado.error("No encontrado");

        } catch (SQLException e) {

            LOGGER.log(Level.SEVERE, "Error cancelando inscripción", e);
            return ContratoService.Resultado.error("Error interno");
        }
    }

    // ─── CONSULTAS ────────────────────────────────────────────

    public List<InscripcionClase> listarPorCliente(String clienteId) {

        try {
            return inscripcionDAO.findByClienteId(clienteId);
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error lista cliente", e);
            return Collections.emptyList();
        }
    }

    public List<InscripcionClase> listarPorClase(String claseId) {

        try {
            return inscripcionDAO.findByClaseId(claseId);
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error lista clase", e);
            return Collections.emptyList();
        }
    }

    // ─── CUPOS ────────────────────────────────────────────────

    public int[] cuposInfo(String claseId) {

        try {

            int inscritos = inscripcionDAO.countInscritos(claseId);
            int capacidad = inscripcionDAO.getCapacidadMaxima(claseId);

            return new int[]{inscritos, capacidad};

        } catch (SQLException e) {

            LOGGER.log(Level.SEVERE, "Error cupos clase", e);
            return new int[]{0, 0};
        }
    }
}