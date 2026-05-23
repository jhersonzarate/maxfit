package com.mycompany.herramientas.dao;

import com.mycompany.herramientas.config.AppConfig;
import com.mycompany.herramientas.config.DatabaseConnection;
import com.mycompany.herramientas.model.Cliente;
import com.mycompany.herramientas.model.TipoDocumento;

import java.sql.*;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.logging.Logger;

/**
 * DAO para la tabla Clientes (RF-01).
 *
 * Tablas involucradas:
 *   Clientes → TipoDocumentos (JOIN para hidratar el objeto completo)
 *
 * Columnas NULL-able en la BD:
 *   email, telefono, fecha_nacimiento, genero
 *   → manejadas con rs.wasNull() al leer y setNull() al escribir.
 *
 * La búsqueda por documento (findByDocument) se usa en el check-in del
 * recepcionista para identificar al cliente rápidamente (RF-04, RF-05).
 *
 * Formato de ID: CLI-AÑO-CORRELATIVO (ej: CLI-2026-0001)
 */
public class ClienteDAO {

    private static final Logger LOGGER = Logger.getLogger(ClienteDAO.class.getName());

    // ─── SQL ─────────────────────────────────────────────────────────────────

    private static final String SQL_SELECT_BASE =
        "SELECT c.id, c.nombre, c.apellido, c.numero_documento, " +
        "       c.email, c.telefono, c.fecha_nacimiento, c.genero, " +
        "       td.id AS td_id, td.nombre_documento, td.abreviado, " +
        "       td.tamañoMax, td.tamañoMin, td.esAlfanumerico " +
        "FROM Clientes c " +
        "INNER JOIN TipoDocumentos td ON c.id_TipoDocumento = td.id ";

    private static final String SQL_FIND_ALL =
        SQL_SELECT_BASE + "ORDER BY c.apellido, c.nombre";

    private static final String SQL_FIND_BY_ID =
        SQL_SELECT_BASE + "WHERE c.id = ?";

    private static final String SQL_FIND_BY_DOCUMENT =
        SQL_SELECT_BASE + "WHERE c.numero_documento = ?";

    /** Búsqueda libre por nombre, apellido o número de documento (buscador) */
    private static final String SQL_SEARCH =
        SQL_SELECT_BASE +
        "WHERE c.nombre LIKE ? OR c.apellido LIKE ? OR c.numero_documento LIKE ? " +
        "ORDER BY c.apellido, c.nombre";

    /** Verificación de existencia por ID — se usa en save() para evitar doble conexión */
    private static final String SQL_EXISTS =
        "SELECT COUNT(*) FROM Clientes WHERE id = ?";

    private static final String SQL_INSERT =
        "INSERT INTO Clientes " +
        "(id, nombre, apellido, id_TipoDocumento, numero_documento, " +
        " email, telefono, fecha_nacimiento, genero) " +
        "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)";

    private static final String SQL_UPDATE =
        "UPDATE Clientes SET nombre = ?, apellido = ?, id_TipoDocumento = ?, " +
        "numero_documento = ?, email = ?, telefono = ?, " +
        "fecha_nacimiento = ?, genero = ? " +
        "WHERE id = ?";

    private static final String SQL_DELETE =
        "DELETE FROM Clientes WHERE id = ?";

    private static final String SQL_COUNT =
        "SELECT COUNT(*) FROM Clientes";

    /** Correlativo para IDs con formato CLI-AÑO-CORRELATIVO */
    private static final String SQL_NEXT_ID =
        "SELECT ISNULL(MAX(CAST(SUBSTRING(id, CHARINDEX('-', id, 5)+1, 10) AS INT)), 0) + 1 " +
        "FROM Clientes WHERE id LIKE 'CLI-%'";

    // ─── Métodos públicos ─────────────────────────────────────────────────────

    /** Devuelve todos los clientes ordenados por apellido, nombre. */
    public List<Cliente> findAll() throws SQLException {
        List<Cliente> lista = new ArrayList<>();
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_FIND_ALL);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) lista.add(mapRow(rs));
        }
        return lista;
    }

    /**
     * Busca un cliente por su ID primario.
     * Devuelve null si no existe.
     */
    public Cliente findById(String id) throws SQLException {
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_FIND_BY_ID)) {
            ps.setString(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? mapRow(rs) : null;
            }
        }
    }

    /**
     * Busca cliente por número de documento.
     * Usado en el check-in de recepción (RF-04).
     * Devuelve null si no existe.
     */
    public Cliente findByDocument(String numeroDocumento) throws SQLException {
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_FIND_BY_DOCUMENT)) {
            ps.setString(1, numeroDocumento.trim());
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? mapRow(rs) : null;
            }
        }
    }

    /**
     * Búsqueda libre por nombre, apellido o documento.
     * Si query es null o vacío, devuelve todos los clientes.
     * Usa LIKE con % para búsqueda parcial (ej: "ele" encuentra "Elena").
     */
    public List<Cliente> search(String query) throws SQLException {
        if (query == null || query.trim().isEmpty()) return findAll();

        String patron = "%" + query.trim() + "%";
        List<Cliente> lista = new ArrayList<>();
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_SEARCH)) {
            ps.setString(1, patron);
            ps.setString(2, patron);
            ps.setString(3, patron);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) lista.add(mapRow(rs));
            }
        }
        return lista;
    }

    /**
     * INSERT si el cliente es nuevo, UPDATE si ya existe.
     * Si el id está vacío/null, se genera automáticamente con el formato CLI-AÑO-CORRELATIVO.
     * El id_TipoDocumento debe ser un ID válido en la tabla TipoDocumentos.
     *
     * @param cliente objeto con todos los campos (el id puede venir vacío para nuevos)
     */
    public void save(Cliente cliente) throws SQLException {
        if (cliente.getId() == null || cliente.getId().trim().isEmpty()) {
            cliente.setId(generarId());
        }
        boolean existe = exists(cliente.getId());
        try (Connection con = DatabaseConnection.getConnection()) {
            if (!existe) {
                insert(con, cliente);
            } else {
                update(con, cliente);
            }
        }
    }

    /**
     * Elimina un cliente por ID.
     * PRECAUCIÓN: la BD tiene FKs desde Contratos e Inscripcion_Clases.
     * Si el cliente tiene contratos o inscripciones, la BD lanzará un error
     * de integridad referencial — el controlador debe capturarlo y mostrar
     * un mensaje amigable al usuario.
     *
     * @return true si se eliminó, false si no existía
     */
    public boolean delete(String id) throws SQLException {
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_DELETE)) {
            ps.setString(1, id);
            return ps.executeUpdate() > 0;
        }
    }

    /** Total de clientes registrados (para el dashboard). */
    public int count() throws SQLException {
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_COUNT);
             ResultSet rs = ps.executeQuery()) {
            return rs.next() ? rs.getInt(1) : 0;
        }
    }

    // ─── Privados ─────────────────────────────────────────────────────────────

    /**
     * Verifica si ya existe un cliente con ese ID.
     * Permite decidir INSERT vs UPDATE con una sola query eficiente,
     * sin necesidad de fetchear el objeto completo ni abrir doble conexión.
     */
    private boolean exists(String id) throws SQLException {
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_EXISTS)) {
            ps.setString(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() && rs.getInt(1) > 0;
            }
        }
    }

    /**
     * Genera el ID con formato CLI-AÑO-CORRELATIVO.
     * El correlativo se obtiene de la BD para ser thread-safe en Tomcat.
     * Ejemplo: CLI-2026-0001
     */
    private String generarId() throws SQLException {
        int anio = LocalDate.now().getYear();
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_NEXT_ID);
             ResultSet rs = ps.executeQuery()) {
            int siguiente = rs.next() ? rs.getInt(1) : 1;
            return String.format("%s-%d-%04d", AppConfig.PREFIX_CLIENTE, anio, siguiente);
        }
    }

    /**
     * INSERT de nuevo cliente.
     * Posiciones: 1=id, 2=nombre, 3=apellido, 4=id_TipoDocumento,
     *             5=numero_documento, 6=email, 7=telefono,
     *             8=fecha_nacimiento, 9=genero
     */
    private void insert(Connection con, Cliente c) throws SQLException {
        try (PreparedStatement ps = con.prepareStatement(SQL_INSERT)) {
            ps.setString(1, c.getId());
            ps.setString(2, c.getNombre().trim());
            ps.setString(3, c.getApellido().trim());
            ps.setString(4, c.getTipoDocumento().getId());
            ps.setString(5, c.getNumeroDocumento().trim());
            setNullableString(ps, 6, c.getEmail());
            setNullableString(ps, 7, c.getTelefono());
            setNullableDate(ps, 8, c.getFechaNacimiento());
            setNullableString(ps, 9, c.getGenero());
            ps.executeUpdate();
            LOGGER.info("Cliente insertado: " + c.getId() + " | " + c.getNombreCompleto());
        }
    }

    /**
     * UPDATE de cliente existente.
     * Posiciones: 1=nombre, 2=apellido, 3=id_TipoDocumento,
     *             4=numero_documento, 5=email, 6=telefono,
     *             7=fecha_nacimiento, 8=genero, 9=id (WHERE)
     */
    private void update(Connection con, Cliente c) throws SQLException {
        try (PreparedStatement ps = con.prepareStatement(SQL_UPDATE)) {
            ps.setString(1, c.getNombre().trim());
            ps.setString(2, c.getApellido().trim());
            ps.setString(3, c.getTipoDocumento().getId());
            ps.setString(4, c.getNumeroDocumento().trim());
            setNullableString(ps, 5, c.getEmail());
            setNullableString(ps, 6, c.getTelefono());
            setNullableDate(ps, 7, c.getFechaNacimiento());
            setNullableString(ps, 8, c.getGenero());
            ps.setString(9, c.getId());
            ps.executeUpdate();
            LOGGER.info("Cliente actualizado: " + c.getId() + " | " + c.getNombreCompleto());
        }
    }

    /**
     * Mapea una fila del ResultSet a un objeto Cliente con su TipoDocumento.
     * Usa rs.wasNull() para las columnas NULL-able.
     */
    private Cliente mapRow(ResultSet rs) throws SQLException {
        TipoDocumento td = new TipoDocumento();
        td.setId(rs.getString("td_id"));
        td.setNombreDocumento(rs.getString("nombre_documento"));
        td.setAbreviado(rs.getString("abreviado"));
        td.setTamañoMax(rs.getInt("tamañoMax"));
        td.setTamañoMin(rs.getInt("tamañoMin"));
        td.setEsAlfanumerico(rs.getBoolean("esAlfanumerico"));

        Cliente c = new Cliente();
        c.setId(rs.getString("id"));
        c.setNombre(rs.getString("nombre"));
        c.setApellido(rs.getString("apellido"));
        c.setTipoDocumento(td);
        c.setNumeroDocumento(rs.getString("numero_documento"));

        // Columnas NULL-able — siempre verificar con wasNull()
        String email = rs.getString("email");
        c.setEmail(rs.wasNull() ? null : email);

        String tel = rs.getString("telefono");
        c.setTelefono(rs.wasNull() ? null : tel);

        Date fechaNac = rs.getDate("fecha_nacimiento");
        c.setFechaNacimiento(rs.wasNull() ? null : fechaNac.toLocalDate());

        String genero = rs.getString("genero");
        c.setGenero(rs.wasNull() ? null : genero);

        return c;
    }

    // ─── Helpers para NULL en PreparedStatement ───────────────────────────────

    /** Establece un String o NULL en el PreparedStatement. */
    private void setNullableString(PreparedStatement ps, int i, String val)
            throws SQLException {
        if (val != null && !val.trim().isEmpty()) {
            ps.setString(i, val.trim());
        } else {
            ps.setNull(i, Types.VARCHAR);
        }
    }

    /** Establece un LocalDate o NULL en el PreparedStatement. */
    private void setNullableDate(PreparedStatement ps, int i, LocalDate fecha)
            throws SQLException {
        if (fecha != null) {
            ps.setDate(i, Date.valueOf(fecha));
        } else {
            ps.setNull(i, Types.DATE);
        }
    }
}