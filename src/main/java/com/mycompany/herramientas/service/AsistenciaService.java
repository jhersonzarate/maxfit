package com.mycompany.herramientas.service;

import com.mycompany.herramientas.config.AppConfig;
import com.mycompany.herramientas.config.DatabaseConnection;
import com.mycompany.herramientas.dao.AsistenciaDAO;
import com.mycompany.herramientas.dao.ClienteDAO;
import com.mycompany.herramientas.dao.ContratoDAO;
import com.mycompany.herramientas.model.Asistencia;
import com.mycompany.herramientas.model.Cliente;
import com.mycompany.herramientas.model.Contrato;

import java.sql.Connection;
import java.sql.SQLException;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.logging.Level;
import java.util.logging.Logger;

// reglas de negocio para registro de asistencia (check-in)
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

    // ─── RESULTADO ─────────────────────────────────────────────

    public enum TipoResultado {
        OK,
        CLIENTE_NO_ENCONTRADO,
        SIN_CONTRATO_ACTIVO,
        YA_REGISTRADO_HOY,
        ERROR_BD
    }

    public static final class ResultadoCheckIn {

        private final TipoResultado tipo;
        private final Cliente cliente;
        private final Contrato contrato;
        private final String mensaje;

        private ResultadoCheckIn(TipoResultado tipo, Cliente cliente,
                                 Contrato contrato, String mensaje) {
            this.tipo = tipo;
            this.cliente = cliente;
            this.contrato = contrato;
            this.mensaje = mensaje;
        }

        public TipoResultado getTipo() { return tipo; }
        public Cliente getCliente() { return cliente; }
        public Contrato getContrato() { return contrato; }
        public String getMensaje() { return mensaje; }
        public boolean isExitoso() { return tipo == TipoResultado.OK; }

        static ResultadoCheckIn ok(Cliente c, Contrato con) {
            return new ResultadoCheckIn(TipoResultado.OK, c, con,
                    "Ingreso autorizado: " + c.getNombreCompleto());
        }

        static ResultadoCheckIn clienteNoEncontrado(String doc) {
            return new ResultadoCheckIn(TipoResultado.CLIENTE_NO_ENCONTRADO,
                    null, null,
                    "Cliente no encontrado: " + doc);
        }

        static ResultadoCheckIn sinContrato(Cliente c) {
            return new ResultadoCheckIn(TipoResultado.SIN_CONTRATO_ACTIVO,
                    c, null,
                    c.getNombreCompleto() + " no tiene contrato activo.");
        }

        static ResultadoCheckIn yaRegistrado(Cliente c, Contrato con) {
            return new ResultadoCheckIn(TipoResultado.YA_REGISTRADO_HOY,
                    c, con,
                    c.getNombreCompleto() + " ya registró ingreso hoy.");
        }

        static ResultadoCheckIn errorBd() {
            return new ResultadoCheckIn(TipoResultado.ERROR_BD,
                    null, null,
                    "Error interno.");
        }
    }

    // ─── CHECK-IN ─────────────────────────────────────────────

    public ResultadoCheckIn registrarCheckIn(String numeroDocumento) {

        if (!DocumentoValidator.esFormatoBasicoValido(numeroDocumento)) {
            return ResultadoCheckIn.clienteNoEncontrado(
                    numeroDocumento == null ? "(vacío)" : numeroDocumento);
        }

        String docLimpio = numeroDocumento.trim();

        try {

            // buscar cliente
            Cliente cliente = clienteDAO.findByDocument(docLimpio);
            if (cliente == null) {
                return ResultadoCheckIn.clienteNoEncontrado(docLimpio);
            }

            // contrato activo
            Contrato contrato = contratoDAO.findActiveByClienteId(cliente.getId());
            if (contrato == null) {
                return ResultadoCheckIn.sinContrato(cliente);
            }

            // ya registrado hoy
            boolean yaRegistrado = asistenciaDAO.existeHoy(
                    contrato.getId(),
                    LocalDate.now()
            );

            if (yaRegistrado) {
                return ResultadoCheckIn.yaRegistrado(cliente, contrato);
            }

            // registrar asistencia
            Asistencia asistencia = new Asistencia();
            asistencia.setContrato(contrato);
            asistencia.setFecha(LocalDate.now());
            asistencia.setEstado(AppConfig.ASISTENCIA_ASISTIO);
            asistencia.setHoraIngreso(LocalTime.now().withNano(0));

            DatabaseConnection.beginTransaction();
            Connection txCon = DatabaseConnection.getConnection();

            asistenciaDAO.save(txCon, asistencia);

            DatabaseConnection.commit();

            LOGGER.info("Check-in OK: " + cliente.getNombreCompleto());

            return ResultadoCheckIn.ok(cliente, contrato);

        } catch (SQLException e) {

            DatabaseConnection.rollback();
            LOGGER.log(Level.SEVERE, "Error check-in: " + numeroDocumento, e);

            return ResultadoCheckIn.errorBd();

        } finally {

            DatabaseConnection.closeConnection();
        }
    }
}