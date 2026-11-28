package ar.edu.utn.sigab.config;

/** Error al trabajar con la base. Envuelve la SQLException para no arrastrarla por todas las capas. */
public class DaoException extends RuntimeException {

    public DaoException(String mensaje, Throwable causa) {
        super(mensaje, causa);
    }
}
