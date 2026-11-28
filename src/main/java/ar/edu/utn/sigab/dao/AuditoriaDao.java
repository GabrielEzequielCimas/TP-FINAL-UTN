package ar.edu.utn.sigab.dao;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.sql.Types;

/**
 * Registra operaciones en la tabla auditoria.
 *
 * Recibe la Connection para que el registro entre en la misma transacción que la
 * operación auditada. La tabla no se puede modificar ni borrar (lo impiden triggers).
 */
public class AuditoriaDao {

    private static final String SQL_INSERTAR =
            "INSERT INTO auditoria (usuario_id, estudiante_id, tipo_operacion, tabla_afectada, detalle) "
            + "VALUES (?, ?, ?, ?, ?)";

    /** Operación hecha por alguien del personal. */
    public void registrarUsuario(Connection con, int usuarioId, String tipoOperacion,
                                 String tablaAfectada, String detalle) throws SQLException {
        insertar(con, usuarioId, null, tipoOperacion, tablaAfectada, detalle);
    }

    /** Operación hecha por un estudiante desde el portal. */
    public void registrarEstudiante(Connection con, int estudianteId, String tipoOperacion,
                                    String tablaAfectada, String detalle) throws SQLException {
        insertar(con, null, estudianteId, tipoOperacion, tablaAfectada, detalle);
    }

    private void insertar(Connection con, Integer usuarioId, Integer estudianteId, String tipoOperacion,
                          String tablaAfectada, String detalle) throws SQLException {
        try (PreparedStatement ps = con.prepareStatement(SQL_INSERTAR)) {
            ps.setObject(1, usuarioId, Types.INTEGER);
            ps.setObject(2, estudianteId, Types.INTEGER);
            ps.setString(3, tipoOperacion);
            ps.setString(4, tablaAfectada);
            ps.setString(5, detalle);
            ps.executeUpdate();
        }
    }
}
