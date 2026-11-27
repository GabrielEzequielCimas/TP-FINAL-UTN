package ar.edu.utn.sigab.config;

import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;

/**
 * Prueba rápida de la conexión: se conecta e imprime la versión de MySQL y
 * cuántas tablas tiene la base.
 *
 * mvn -q compile exec:java -Dexec.mainClass=ar.edu.utn.sigab.config.PruebaConexion
 */
public class PruebaConexion {

    public static void main(String[] args) {
        String sql = "SELECT VERSION(), DATABASE(), "
                + "(SELECT COUNT(*) FROM information_schema.tables "
                + "WHERE table_schema = DATABASE() AND table_type = 'BASE TABLE')";
        try (Connection con = Conexion.obtener();
             Statement st = con.createStatement();
             ResultSet rs = st.executeQuery(sql)) {
            rs.next();
            System.out.println("Conectado a MySQL " + rs.getString(1));
            System.out.println("Base: " + rs.getString(2) + ", tablas: " + rs.getInt(3));
        } catch (SQLException e) {
            System.err.println("No se pudo conectar: " + e.getMessage());
            System.exit(1);
        }
    }
}
