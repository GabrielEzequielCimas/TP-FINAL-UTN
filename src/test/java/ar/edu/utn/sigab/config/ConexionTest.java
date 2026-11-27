package ar.edu.utn.sigab.config;

import org.junit.jupiter.api.Test;

import java.io.IOException;
import java.io.StringReader;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;

class ConexionTest {

    @Test
    void leeElEnv() throws IOException {
        String env = """
                # comentario
                SIGAB_DB_URL=jdbc:mysql://localhost:3306/sigab?useSSL=false&characterEncoding=UTF-8

                SIGAB_DB_USER = sigab_app
                SIGAB_DB_PASSWORD="con espacios"
                OTRA='x'
                linea sin igual
                """;
        Map<String, String> valores = Conexion.leerEnv(new StringReader(env));

        assertEquals("jdbc:mysql://localhost:3306/sigab?useSSL=false&characterEncoding=UTF-8",
                valores.get("SIGAB_DB_URL"));
        assertEquals("sigab_app", valores.get("SIGAB_DB_USER"));
        assertEquals("con espacios", valores.get("SIGAB_DB_PASSWORD"));
        assertEquals("x", valores.get("OTRA"));
        assertFalse(valores.containsKey("# comentario"));
        assertEquals(4, valores.size());
    }
}
