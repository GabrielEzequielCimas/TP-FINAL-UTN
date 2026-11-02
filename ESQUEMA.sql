DROP DATABASE IF EXISTS sigab;
CREATE DATABASE sigab
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_0900_ai_ci;
USE sigab;


-- R1 - Usuarios, roles y permisos

CREATE TABLE rol (
  rol_id       INT AUTO_INCREMENT PRIMARY KEY,
  nombre       VARCHAR(50)  NOT NULL,
  descripcion  VARCHAR(255) NULL,
  estado       ENUM('activo','inactivo') NOT NULL DEFAULT 'activo',
  CONSTRAINT uq_rol_nombre UNIQUE (nombre)
) ENGINE=InnoDB;

CREATE TABLE permiso (
  permiso_id   INT AUTO_INCREMENT PRIMARY KEY,
  nombre       VARCHAR(80)  NOT NULL,
  descripcion  VARCHAR(255) NULL,
  estado       ENUM('activo','inactivo') NOT NULL DEFAULT 'activo',
  CONSTRAINT uq_permiso_nombre UNIQUE (nombre)
) ENGINE=InnoDB;

CREATE TABLE rol_permiso (
  rol_id            INT NOT NULL,
  permiso_id        INT NOT NULL,
  fecha_asignacion  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  estado            ENUM('activo','inactivo') NOT NULL DEFAULT 'activo',
  PRIMARY KEY (rol_id, permiso_id),
  CONSTRAINT fk_rol_permiso_rol     FOREIGN KEY (rol_id)     REFERENCES rol (rol_id),
  CONSTRAINT fk_rol_permiso_permiso FOREIGN KEY (permiso_id) REFERENCES permiso (permiso_id)
) ENGINE=InnoDB;

-- Personal de la institución que opera el sistema.
CREATE TABLE usuario (
  usuario_id      INT AUTO_INCREMENT PRIMARY KEY,
  nombre          VARCHAR(80)  NOT NULL,
  apellido        VARCHAR(80)  NOT NULL,
  dni             VARCHAR(15)  NOT NULL,
  email           VARCHAR(120) NOT NULL,
  nombre_usuario  VARCHAR(50)  NOT NULL,
  password_hash   VARCHAR(255) NOT NULL,            -- BCrypt, nunca texto plano
  rol_id          INT NOT NULL,
  estado          ENUM('activo','inactivo') NOT NULL DEFAULT 'activo',
  CONSTRAINT uq_usuario_dni            UNIQUE (dni),
  CONSTRAINT uq_usuario_email          UNIQUE (email),
  CONSTRAINT uq_usuario_nombre_usuario UNIQUE (nombre_usuario),
  CONSTRAINT fk_usuario_rol FOREIGN KEY (rol_id) REFERENCES rol (rol_id)
) ENGINE=InnoDB;