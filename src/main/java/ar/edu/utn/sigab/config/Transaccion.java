package ar.edu.utn.sigab.config;

import java.sql.Connection;
import java.sql.SQLException;

/**
 * Corre un bloque de código con una conexión a la base.
 *
 * Con ejecutar(), todo lo que haga el bloque es una sola transacción: si termina bien
 * se hace commit y si tira una excepción se hace rollback, así no queda nada a medias.
 *
 *   int id = Transaccion.ejecutar(con -> {
 *       // una o varias operaciones con la misma conexión
 *       return algunDao.insertar(con, objeto);
 *   });
 */
public final class Transaccion {

    /** Código de error de MySQL para "Duplicate entry" en una clave UNIQUE. */
    private static final int MYSQL_DUPLICADO = 1062;

    @FunctionalInterface
    public interface Bloque<T> {
        T ejecutar(Connection con) throws SQLException;
    }

    private Transaccion() {
    }

    public static <T> T ejecutar(Bloque<T> bloque) {
        try (Connection con = Conexion.obtener()) {
            con.setAutoCommit(false);
            try {
                T resultado = bloque.ejecutar(con);
                con.commit();
                return resultado;
            } catch (SQLException | RuntimeException e) {
                deshacer(con, e);
                throw e;
            }
        } catch (SQLException e) {
            throw traducir(e);
        }
    }

    /** Para lecturas: no abre transacción. */
    public static <T> T consultar(Bloque<T> bloque) {
        try (Connection con = Conexion.obtener()) {
            return bloque.ejecutar(con);
        } catch (SQLException e) {
            throw traducir(e);
        }
    }

    private static void deshacer(Connection con, Exception original) {
        try {
            con.rollback();
        } catch (SQLException e) {
            // Que no tape el error original
            original.addSuppressed(e);
        }
    }

    private static DaoException traducir(SQLException e) {
        if (e.getErrorCode() == MYSQL_DUPLICADO) {
            return new RegistroDuplicadoException("Ya existe un registro con ese valor: " + e.getMessage(), e);
        }
        return new DaoException("Error de base de datos: " + e.getMessage(), e);
    }
}
