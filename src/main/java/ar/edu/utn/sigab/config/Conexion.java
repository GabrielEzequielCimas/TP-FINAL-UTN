package ar.edu.utn.sigab.config;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.Reader;
import java.nio.charset.StandardCharsets;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.HashMap;
import java.util.Map;

/**
 * Abre conexiones a MySQL.
 *
 * Los datos de conexión salen de las variables de entorno SIGAB_DB_URL, SIGAB_DB_USER
 * y SIGAB_DB_PASSWORD. Si no están definidas, se buscan en el .env de la raíz del
 * proyecto, que Maven copia al classpath al compilar.
 */
public final class Conexion {

    private static final Map<String, String> ENV = cargarEnv();

    private Conexion() {
    }

    public static Connection obtener() throws SQLException {
        String url = valor("SIGAB_DB_URL");
        String usuario = valor("SIGAB_DB_USER");
        String password = valor("SIGAB_DB_PASSWORD");
        if (url == null || usuario == null || password == null) {
            throw new SQLException("Falta configurar la base: copiá .env.example como .env, "
                    + "completá SIGAB_DB_URL, SIGAB_DB_USER y SIGAB_DB_PASSWORD y volvé a compilar");
        }
        return DriverManager.getConnection(url, usuario, password);
    }

    private static String valor(String clave) {
        String v = System.getenv(clave);
        if (v == null || v.isBlank()) {
            v = ENV.get(clave);
        }
        return (v == null || v.isBlank()) ? null : v;
    }

    private static Map<String, String> cargarEnv() {
        try (InputStream in = Conexion.class.getClassLoader().getResourceAsStream(".env")) {
            if (in == null) {
                return new HashMap<>();
            }
            return leerEnv(new InputStreamReader(in, StandardCharsets.UTF_8));
        } catch (IOException e) {
            throw new IllegalStateException("No se pudo leer el .env", e);
        }
    }

    /** Lee líneas CLAVE=valor. Ignora líneas vacías, comentarios con # y líneas sin =. */
    static Map<String, String> leerEnv(Reader reader) throws IOException {
        Map<String, String> valores = new HashMap<>();
        BufferedReader br = new BufferedReader(reader);
        String linea;
        while ((linea = br.readLine()) != null) {
            linea = linea.strip();
            int igual = linea.indexOf('=');
            if (linea.startsWith("#") || igual <= 0) {
                continue;
            }
            String clave = linea.substring(0, igual).strip();
            String valor = linea.substring(igual + 1).strip();
            if (valor.length() >= 2 && (valor.startsWith("\"") || valor.startsWith("'"))
                    && valor.endsWith(valor.substring(0, 1))) {
                valor = valor.substring(1, valor.length() - 1);
            }
            valores.put(clave, valor);
        }
        return valores;
    }
}
