package com.mycompany.herramientas.service;

import com.mycompany.herramientas.config.AppConfig;
import com.mycompany.herramientas.config.DatabaseConnection;
import com.mycompany.herramientas.dao.AsistenciaDAO;
import com.mycompany.herramientas.dao.ClienteDAO;
import com.mycompany.herramientas.dao.ContratoDAO;
import com.mycompany.herramientas.model.Asistencia;
import com.mycompany.herramientas.model.Cliente;
import com.mycompany.herramientas.model.Contrato;

import java.sql.SQLException;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * Reglas de negocio para el registro de asistencia / check-in (RF-04, RF-05).
 *
 * Flujo de check-in:
 *   1. Buscar cliente por número de documento.
 *   2. Verificar que tenga contrato activo y vigente (RF-04).
 *   3. Verificar que no haya ya un registro de asistencia hoy para ese contrato
 *      (respeta el UNIQUE (id_contrato, fecha) de la BD).
 *   4. Registrar la asistencia con estado 'asistio' y hora_ingreso = ahora.
 *
 * Resultado tipado (ResultadoCheckIn) para que el controlador sepa exactamente
 * qué pasó sin comparar strings mágicos.
 */
public class AsistenciaService {

    private static final Logger LOGGER = Logger.getLogger(AsistenciaService.class.getName());

    private final ClienteDAO    clienteDAO;
    private final ContratoDAO   contratoDAO;
    private final AsistenciaDAO asistenciaDAO;

    public AsistenciaService() {
        this.clienteDAO    = new ClienteDAO();
        this.contratoDAO   = new ContratoDAO();
        this.asistenciaDAO = new AsistenciaDAO();
    }

    public AsistenciaService(ClienteDAO clienteDAO,
                              ContratoDAO contratoDAO,
                              AsistenciaDAO asistenciaDAO) {
        this.clienteDAO    = clienteDAO;
        this.contratoDAO   = contratoDAO;
        this.asistenciaDAO = asistenciaDAO;
    }

    // ── Tipos de resultado ───────────────────────────────────────────────────

    public enum TipoResultado {
        OK,                   // Ingreso autorizado y registrado
        CLIENTE_NO_ENCONTRADO,// El documento no corresponde a ningún cliente
        SIN_CONTRATO_ACTIVO,  // El cliente existe pero no tiene contrato vigente
        YA_REGISTRADO_HOY,    // Ya hizo check-in hoy (UNIQUE de BD)
        ERROR_BD              // Error interno de base de datos
    }

    public static final class ResultadoCheckIn {

        private final TipoResultado tipo;
        private final Cliente       cliente;
        private final Contrato      contrato;
        private final String        mensaje;

        private ResultadoCheckIn(TipoResultado tipo, Cliente cliente,
                                  Contrato contrato, String mensaje) {
            this.tipo     = tipo;
            this.cliente  = cliente;
            this.contrato = contrato;
            this.mensaje  = mensaje;
        }

        public TipoResultado getTipo()     { return tipo; }
        public Cliente       getCliente()  { return cliente; }
        public Contrato      getContrato() { return contrato; }
        public String        getMensaje()  { return mensaje; }
        public boolean       isExitoso()   { return tipo == TipoResultado.OK; }

        static ResultadoCheckIn ok(Cliente c, Contrato con) {
            return new ResultadoCheckIn(TipoResultado.OK, c, con,
                    "Ingreso autorizado para " + c.getNombreCompleto());
        }
        static ResultadoCheckIn clienteNoEncontrado(String doc) {
            return new ResultadoCheckIn(TipoResultado.CLIENTE_NO_ENCONTRADO,
                    null, null,
                    "No se encontró ningún cliente con el documento: " + doc);
        }
        static ResultadoCheckIn sinContrato(Cliente c) {
            return new ResultadoCheckIn(TipoResultado.SIN_CONTRATO_ACTIVO,
                    c, null,
                    c.getNombreCompleto() + " no tiene una membresía activa.");
        }
        static ResultadoCheckIn yaRegistrado(Cliente c, Contrato con) {
            return new ResultadoCheckIn(TipoResultado.YA_REGISTRADO_HOY,
                    c, con,
                    c.getNombreCompleto() + " ya registró ingreso hoy ("
                    + LocalDate.now() + ").");
        }
        static ResultadoCheckIn errorBd() {
            return new ResultadoCheckIn(TipoResultado.ERROR_BD,
                    null, null,
                    "Error interno. Intenta nuevamente.");
        }
    }

    // ── Check-in ─────────────────────────────────────────────────────────────

    /**
     * Registra el ingreso de un cliente al gimnasio.
     *
     * @param numeroDocumento el número de documento escaneado o ingresado
     *                        en la recepción
     * @return ResultadoCheckIn con el tipo de resultado y datos del cliente
     */
    public ResultadoCheckIn registrarCheckIn(String numeroDocumento) {

        if (!DocumentoValidator.esFormatoBasicoValido(numeroDocumento)) {
            return ResultadoCheckIn.clienteNoEncontrado(
                    numeroDocumento == null ? "(vacío)" : numeroDocumento);
        }

        String docLimpio = numeroDocumento.trim();

        try {
            // ── 1. Buscar cliente ────────────────────────────────────────────
            Cliente cliente = clienteDAO.findByDocument(docLimpio);
            if (cliente == null) {
                return ResultadoCheckIn.clienteNoEncontrado(docLimpio);
            }

            // ── 2. Verificar contrato activo (RF-04) ─────────────────────────
            Contrato contrato = contratoDAO.findActiveByClienteId(cliente.getId());
            if (contrato == null) {
                return ResultadoCheckIn.sinContrato(cliente);
            }

            // ── 3. Verificar UNIQUE (id_contrato, fecha) ─────────────────────
            boolean yaRegistrado = asistenciaDAO.existeHoy(contrato.getId(), LocalDate.now());
            if (yaRegistrado) {
                return ResultadoCheckIn.yaRegistrado(cliente, contrato);
            }

            // ── 4. Registrar asistencia ──────────────────────────────────────
            Asistencia asistencia = new Asistencia();
            asistencia.setContrato(contrato);
            asistencia.setFecha(LocalDate.now());
            asistencia.setEstado(AppConfig.ASISTENCIA_ASISTIO);
            asistencia.setHoraIngreso(LocalTime.now().withNano(0)); // sin nanosegundos

            DatabaseConnection.beginTransaction();
            asistenciaDAO.save(asistencia);
            DatabaseConnection.commit();

            LOGGER.info("Check-in registrado: " + cliente.getNombreCompleto()
                    + " | contrato: " + contrato.getId()
                    + " | hora: " + asistencia.getHoraIngreso());

            return ResultadoCheckIn.ok(cliente, contrato);

        } catch (SQLException e) {
            DatabaseConnection.rollback();
            LOGGER.log(Level.SEVERE,
                    "Error de BD al registrar check-in para doc: " + docLimpio, e);
            return ResultadoCheckIn.errorBd();
        } finally {
            DatabaseConnection.closeConnection();
        }
    }
}