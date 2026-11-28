# TP-FINAL-UTN

SIGAB - Sistema de Gestión de Aranceles y Becas. TP final.

## Qué hace falta

- JDK 17 en adelante
- Maven
- MySQL 8 en adelante

## Base de datos

```
mysql -u root -p < sql/ESQUEMA.sql
```

Cuidado que ESQUEMA.sql borra la base sigab si ya existe.

## Configuración

Copiar `.env.example` como `.env` y poner el usuario y la clave de MySQL. El `.env` no se sube al repo. Se copia adentro del build al compilar, así que si lo cambian hay que volver a compilar.

## Compilar

```
mvn clean package
```

## Probar la conexión

```
mvn -q compile exec:java -Dexec.mainClass=ar.edu.utn.sigab.config.PruebaConexion
```

Si está todo bien muestra la versión de MySQL y cuántas tablas tiene la base.

## Tests

`mvn clean package` también corre los tests. Los de transacciones (rollback y registros duplicados) usan la base del `.env` y no dejan nada guardado; si no hay conexión, se saltean.
