package ar.edu.utn.sigab.config;

/** Se intentó guardar un valor que ya existe en una columna UNIQUE (por ejemplo, un nombre de rol repetido). */
public class RegistroDuplicadoException extends DaoException {

    public RegistroDuplicadoException(String mensaje, Throwable causa) {
        super(mensaje, causa);
    }
}
