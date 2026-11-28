package ar.edu.utn.sigab.config;

import ar.edu.utn.sigab.dao.AuditoriaDao;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assumptions.assumeTrue;

/**
 * Prueba Transaccion contra la base de verdad. Si no hay conexión (sin .env o MySQL
 * apagado) los tests se saltean. Ningún test deja filas guardadas.
 */
class TransaccionTest {

    @BeforeAll
    static void hayBase() {
        boolean conecta;
        try (Connection con = Conexion.obtener()) {
            conecta = con.isValid(2);
        } catch (SQLException e) {
            conecta = false;
        }
        assumeTrue(conecta, "No hay conexión a la base, se saltean los tests de Transaccion");
    }

    @Test
    void siElBloqueFallaNoQuedaNada() {
        String marca = "test-" + System.nanoTime();

        assertThrows(IllegalStateException.class, () -> Transaccion.ejecutar(con -> {
            int usuarioId = insertarUsuario(con, marca);
            new AuditoriaDao().registrarUsuario(con, usuarioId, "PRUEBA", "auditoria", marca);
            throw new IllegalStateException("falla a propósito");
        }));

        assertEquals(0, contar("SELECT COUNT(*) FROM auditoria WHERE detalle = ?", marca));
        assertEquals(0, contar("SELECT COUNT(*) FROM usuario WHERE nombre_usuario = ?", marca));
    }

    @Test
    void rolRepetidoEsRegistroDuplicado() {
        assertThrows(RegistroDuplicadoException.class, () -> Transaccion.ejecutar(con -> {
            try (Statement st = con.createStatement()) {
                return st.executeUpdate("INSERT INTO rol (nombre) VALUES ('Administrador')");
            }
        }));
    }

    /** Usuario temporal para que la fila de auditoria tenga a quién apuntar. */
    private static int insertarUsuario(Connection con, String marca) throws SQLException {
        String sql = "INSERT INTO usuario (legajo, nombre, apellido, dni, email, nombre_usuario, password_hash, rol_id) "
                + "SELECT ?, 'Test', 'Test', ?, ?, ?, 'x', rol_id FROM rol WHERE nombre = 'Administrador'";
        String corto = marca.substring(marca.length() - 15);
        try (PreparedStatement ps = con.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setString(1, corto);
            ps.setString(2, corto);
            ps.setString(3, marca + "@test.local");
            ps.setString(4, marca);
            ps.executeUpdate();
            try (ResultSet rs = ps.getGeneratedKeys()) {
                rs.next();
                return rs.getInt(1);
            }
        }
    }

    private static int contar(String sql, String valor) {
        return Transaccion.consultar(con -> {
            try (PreparedStatement ps = con.prepareStatement(sql)) {
                ps.setString(1, valor);
                try (ResultSet rs = ps.executeQuery()) {
                    rs.next();
                    return rs.getInt(1);
                }
            }
        });
    }
}
