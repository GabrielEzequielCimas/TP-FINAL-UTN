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
  legajo          VARCHAR(20)  NOT NULL,
  nombre          VARCHAR(80)  NOT NULL,
  apellido        VARCHAR(80)  NOT NULL,
  dni             VARCHAR(15)  NOT NULL,
  email           VARCHAR(120) NOT NULL,
  nombre_usuario  VARCHAR(50)  NOT NULL,
  password_hash   VARCHAR(255) NOT NULL,            -- BCrypt, nunca texto plano
  rol_id          INT NOT NULL,
  estado          ENUM('activo','inactivo') NOT NULL DEFAULT 'activo',
  CONSTRAINT uq_usuario_legajo         UNIQUE (legajo),
  CONSTRAINT uq_usuario_dni            UNIQUE (dni),
  CONSTRAINT uq_usuario_email          UNIQUE (email),
  CONSTRAINT uq_usuario_nombre_usuario UNIQUE (nombre_usuario),
  CONSTRAINT fk_usuario_rol FOREIGN KEY (rol_id) REFERENCES rol (rol_id)
) ENGINE=InnoDB;


-- R2 - Estudiantes y datos académicos

CREATE TABLE carrera (
  carrera_id      INT AUTO_INCREMENT PRIMARY KEY,
  codigo          VARCHAR(20)  NOT NULL,
  nombre          VARCHAR(120) NOT NULL,
  duracion_anios  TINYINT      NOT NULL,
  descripcion     VARCHAR(255) NULL,
  estado          ENUM('activa','inactiva') NOT NULL DEFAULT 'activa',
  CONSTRAINT uq_carrera_codigo UNIQUE (codigo),
  CONSTRAINT uq_carrera_nombre UNIQUE (nombre)
) ENGINE=InnoDB;

CREATE TABLE materia (
  materia_id   INT AUTO_INCREMENT PRIMARY KEY,
  codigo       VARCHAR(20)  NOT NULL,
  nombre       VARCHAR(120) NOT NULL,
  descripcion  VARCHAR(255) NULL,
  estado       ENUM('activa','inactiva') NOT NULL DEFAULT 'activa',
  CONSTRAINT uq_materia_codigo UNIQUE (codigo)
) ENGINE=InnoDB;

CREATE TABLE plan_estudio (
  plan_estudio_id  INT AUTO_INCREMENT PRIMARY KEY,
  codigo           VARCHAR(20)  NOT NULL,
  nombre           VARCHAR(120) NOT NULL,
  carrera_id       INT  NOT NULL,
  anio_vigencia    YEAR NOT NULL,
  estado           ENUM('activo','inactivo') NOT NULL DEFAULT 'activo',
  CONSTRAINT uq_plan_estudio_codigo UNIQUE (codigo),
  CONSTRAINT fk_plan_estudio_carrera FOREIGN KEY (carrera_id) REFERENCES carrera (carrera_id)
) ENGINE=InnoDB;

CREATE TABLE plan_estudio_materia (
  plan_estudio_id   INT     NOT NULL,
  materia_id        INT     NOT NULL,
  anio_nivel        TINYINT NOT NULL,
  fecha_asignacion  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  estado            ENUM('activo','inactivo') NOT NULL DEFAULT 'activo',
  PRIMARY KEY (plan_estudio_id, materia_id),
  CONSTRAINT fk_plan_estudio_materia_plan_estudio FOREIGN KEY (plan_estudio_id) REFERENCES plan_estudio (plan_estudio_id),
  CONSTRAINT fk_plan_estudio_materia_materia      FOREIGN KEY (materia_id)      REFERENCES materia (materia_id)
) ENGINE=InnoDB;

-- R10 - Cuenta del estudiante para el portal de autogestión.
-- Se crea antes que estudiante porque estudiante la referencia.
-- El login se hace con el legajo de estudiante; acá solo van los
-- datos de autenticación, para no repetirlos.
CREATE TABLE cuenta_acceso (
  cuenta_acceso_id   INT AUTO_INCREMENT PRIMARY KEY,
  password_hash      VARCHAR(255) NOT NULL,           -- BCrypt, nunca texto plano
  intentos_fallidos  TINYINT NOT NULL DEFAULT 0,
  fecha_creacion     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  estado             ENUM('activo','inactivo','bloqueado') NOT NULL DEFAULT 'activo'
) ENGINE=InnoDB;

-- La carrera del estudiante se obtiene por su plan de estudio.
-- cuenta_acceso_id queda NULL hasta que el estudiante activa el portal.
CREATE TABLE estudiante (
  estudiante_id      INT AUTO_INCREMENT PRIMARY KEY,
  legajo             VARCHAR(20)  NOT NULL,
  nombre             VARCHAR(80)  NOT NULL,
  apellido           VARCHAR(80)  NOT NULL,
  dni                VARCHAR(15)  NOT NULL,
  email              VARCHAR(120) NOT NULL,
  telefono           VARCHAR(30)  NOT NULL,
  plan_estudio_id    INT NOT NULL,
  cuenta_acceso_id   INT NULL,
  estado             ENUM('activo','inactivo') NOT NULL DEFAULT 'activo',
  CONSTRAINT uq_estudiante_legajo        UNIQUE (legajo),
  CONSTRAINT uq_estudiante_dni           UNIQUE (dni),
  CONSTRAINT uq_estudiante_email         UNIQUE (email),
  CONSTRAINT uq_estudiante_telefono      UNIQUE (telefono),
  CONSTRAINT uq_estudiante_cuenta_acceso UNIQUE (cuenta_acceso_id),
  CONSTRAINT fk_estudiante_plan_estudio  FOREIGN KEY (plan_estudio_id)  REFERENCES plan_estudio (plan_estudio_id),
  CONSTRAINT fk_estudiante_cuenta_acceso FOREIGN KEY (cuenta_acceso_id) REFERENCES cuenta_acceso (cuenta_acceso_id)
) ENGINE=InnoDB;

-- R10 - Ingresos y salidas del portal (control de sesiones).
CREATE TABLE historial_acceso (
  historial_acceso_id  BIGINT AUTO_INCREMENT PRIMARY KEY,
  cuenta_acceso_id     INT NOT NULL,
  fecha_hora           DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  ip_origen            VARCHAR(45) NOT NULL,           -- alcanza para IPv6
  tipo_evento          ENUM('login_exitoso','login_fallido','logout','bloqueo') NOT NULL,
  CONSTRAINT fk_historial_acceso_cuenta_acceso FOREIGN KEY (cuenta_acceso_id) REFERENCES cuenta_acceso (cuenta_acceso_id)
) ENGINE=InnoDB;

CREATE TABLE periodo_lectivo (
  periodo_lectivo_id  INT AUTO_INCREMENT PRIMARY KEY,
  codigo              VARCHAR(20) NOT NULL,
  descripcion         VARCHAR(50) NOT NULL,
  fecha_inicio        DATE NOT NULL,
  fecha_fin           DATE NOT NULL,
  estado              ENUM('abierto','cerrado') NOT NULL DEFAULT 'abierto',
  CONSTRAINT uq_periodo_lectivo_codigo UNIQUE (codigo)
) ENGINE=InnoDB;

CREATE TABLE trayectoria_academica (
  trayectoria_academica_id  INT AUTO_INCREMENT PRIMARY KEY,
  estudiante_id             INT NOT NULL,
  materia_id                INT NOT NULL,
  periodo_lectivo_id        INT NOT NULL,
  situacion                 ENUM('cursando','regular','aprobada','desaprobada','libre') NOT NULL,
  calificacion              DECIMAL(4,2) NULL,
  fecha_actualizacion       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT uq_trayectoria_academica UNIQUE (estudiante_id, materia_id, periodo_lectivo_id),
  CONSTRAINT fk_trayectoria_academica_estudiante      FOREIGN KEY (estudiante_id)      REFERENCES estudiante (estudiante_id),
  CONSTRAINT fk_trayectoria_academica_materia         FOREIGN KEY (materia_id)         REFERENCES materia (materia_id),
  CONSTRAINT fk_trayectoria_academica_periodo_lectivo FOREIGN KEY (periodo_lectivo_id) REFERENCES periodo_lectivo (periodo_lectivo_id)
) ENGINE=InnoDB;

-- Registro de operaciones. La hace un usuario del personal o un
-- estudiante desde el portal, por eso las dos FK aceptan NULL.
CREATE TABLE auditoria (
  auditoria_id    BIGINT AUTO_INCREMENT PRIMARY KEY,
  fecha_hora      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  usuario_id      INT NULL,
  estudiante_id   INT NULL,
  tipo_operacion  VARCHAR(30) NOT NULL,
  tabla_afectada  VARCHAR(50) NOT NULL,
  detalle         TEXT NULL,
  CONSTRAINT fk_auditoria_usuario    FOREIGN KEY (usuario_id)    REFERENCES usuario (usuario_id),
  CONSTRAINT fk_auditoria_estudiante FOREIGN KEY (estudiante_id) REFERENCES estudiante (estudiante_id)
) ENGINE=InnoDB;


-- R3 - Aranceles

-- tipo_aplicacion indica si el arancel es de una carrera o de un
-- estudiante puntual; se completa la FK que corresponde.
CREATE TABLE arancel (
  arancel_id           INT AUTO_INCREMENT PRIMARY KEY,
  codigo               VARCHAR(20)  NOT NULL,
  nombre               VARCHAR(100) NOT NULL,
  tipo_aplicacion      ENUM('carrera','estudiante') NOT NULL,
  carrera_id           INT NULL,
  estudiante_id        INT NULL,
  valor                DECIMAL(12,2) NOT NULL,
  cantidad_cuotas      TINYINT       NOT NULL,
  tasa_recargo         DECIMAL(5,2)  NOT NULL DEFAULT 0,
  regla_actualizacion  VARCHAR(255) NULL,
  fecha_inicio         DATE NOT NULL,
  fecha_fin            DATE NULL,
  estado               ENUM('activo','inactivo') NOT NULL DEFAULT 'activo',
  CONSTRAINT uq_arancel_codigo UNIQUE (codigo),
  CONSTRAINT fk_arancel_carrera    FOREIGN KEY (carrera_id)    REFERENCES carrera (carrera_id),
  CONSTRAINT fk_arancel_estudiante FOREIGN KEY (estudiante_id) REFERENCES estudiante (estudiante_id)
) ENGINE=InnoDB;

-- Cada cambio de valor de un arancel deja acá el valor anterior.
CREATE TABLE historial_arancel (
  historial_arancel_id  INT AUTO_INCREMENT PRIMARY KEY,
  arancel_id            INT NOT NULL,
  valor_anterior        DECIMAL(12,2) NOT NULL,
  fecha_inicio          DATE NOT NULL,
  fecha_fin             DATE NOT NULL,
  motivo                VARCHAR(255) NOT NULL,
  fecha_modificacion    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  usuario_id            INT NOT NULL,
  CONSTRAINT fk_historial_arancel_arancel FOREIGN KEY (arancel_id) REFERENCES arancel (arancel_id),
  CONSTRAINT fk_historial_arancel_usuario FOREIGN KEY (usuario_id) REFERENCES usuario (usuario_id)
) ENGINE=InnoDB;

CREATE TABLE bonificacion (
  bonificacion_id  INT AUTO_INCREMENT PRIMARY KEY,
  arancel_id       INT NOT NULL,
  tipo             ENUM('porcentaje','monto_fijo') NOT NULL,
  valor            DECIMAL(12,2) NOT NULL,
  fecha_inicio     DATE NOT NULL,
  fecha_fin        DATE NULL,
  estado           ENUM('activa','inactiva') NOT NULL DEFAULT 'activa',
  CONSTRAINT fk_bonificacion_arancel FOREIGN KEY (arancel_id) REFERENCES arancel (arancel_id)
) ENGINE=InnoDB;


-- R6 - Planes de pago (se crea antes que cuota porque cuota la referencia)

CREATE TABLE plan_pago (
  plan_pago_id        INT AUTO_INCREMENT PRIMARY KEY,
  estudiante_id       INT NOT NULL,
  fecha_alta          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  monto_refinanciado  DECIMAL(12,2) NOT NULL,
  tasa_interes        DECIMAL(5,2)  NOT NULL,
  monto_interes       DECIMAL(12,2) NOT NULL,
  cantidad_cuotas     TINYINT NOT NULL,
  usuario_id          INT NOT NULL,
  estado              ENUM('activo','inactivo') NOT NULL DEFAULT 'activo',
  CONSTRAINT fk_plan_pago_estudiante FOREIGN KEY (estudiante_id) REFERENCES estudiante (estudiante_id),
  CONSTRAINT fk_plan_pago_usuario    FOREIGN KEY (usuario_id)    REFERENCES usuario (usuario_id)
) ENGINE=InnoDB;


-- R7 - Becas 

CREATE TABLE convocatoria (
  convocatoria_id             INT AUTO_INCREMENT PRIMARY KEY,
  nombre                      VARCHAR(120) NOT NULL,
  fecha_inicio                DATE NOT NULL,
  fecha_fin                   DATE NOT NULL,
  promedio_minimo             DECIMAL(4,2) NULL,
  materias_aprobadas_minimas  SMALLINT NULL,
  criterio_evaluacion         TEXT NULL,
  cupo                        INT NOT NULL,
  estado                      ENUM('activa','inactiva') NOT NULL DEFAULT 'activa',
  CONSTRAINT uq_convocatoria_nombre_fecha UNIQUE (nombre, fecha_inicio)
) ENGINE=InnoDB;

-- Guarda el promedio y las materias aprobadas que tenía el estudiante
-- al momento de solicitar, para que la evaluación sea reproducible.
CREATE TABLE solicitud_beca (
  solicitud_beca_id     INT AUTO_INCREMENT PRIMARY KEY,
  estudiante_id         INT NOT NULL,
  convocatoria_id       INT NOT NULL,
  fecha_solicitud       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  materias_aprobadas    SMALLINT NOT NULL,
  promedio              DECIMAL(4,2) NOT NULL,
  resultado_evaluacion  TEXT NULL,
  fecha_evaluacion      DATETIME NULL,
  estado                ENUM('pendiente','aprobada','rechazada') NOT NULL DEFAULT 'pendiente',
  CONSTRAINT uq_solicitud_beca_estudiante_convocatoria UNIQUE (estudiante_id, convocatoria_id),
  CONSTRAINT fk_solicitud_beca_estudiante   FOREIGN KEY (estudiante_id)   REFERENCES estudiante (estudiante_id),
  CONSTRAINT fk_solicitud_beca_convocatoria FOREIGN KEY (convocatoria_id) REFERENCES convocatoria (convocatoria_id)
) ENGINE=InnoDB;

-- Una solicitud aprobada genera como máximo una beca (relación 1 a 1).
CREATE TABLE beca (
  beca_id            INT AUTO_INCREMENT PRIMARY KEY,
  solicitud_beca_id  INT NOT NULL,
  porcentaje         DECIMAL(5,2) NOT NULL,
  motivo             VARCHAR(255) NOT NULL,
  fecha_inicio       DATE NOT NULL,
  fecha_fin          DATE NULL,
  estado             ENUM('activa','inactiva') NOT NULL DEFAULT 'activa',
  CONSTRAINT uq_beca_solicitud_beca UNIQUE (solicitud_beca_id),
  CONSTRAINT fk_beca_solicitud_beca FOREIGN KEY (solicitud_beca_id) REFERENCES solicitud_beca (solicitud_beca_id)
) ENGINE=InnoDB;

-- R4 - Cuotas


-- Una cuota sale de un arancel (cuota normal) o de un plan de pago
-- (cuota de refinanciación). Guarda cómo se calculó el monto:
-- monto = monto_base - monto_bonificacion - monto_beca.
-- El estado "vencida" no se guarda: se calcula con fecha_vencimiento.
CREATE TABLE cuota (
  cuota_id            INT AUTO_INCREMENT PRIMARY KEY,
  estudiante_id       INT NOT NULL,
  periodo_lectivo_id  INT NOT NULL,
  arancel_id          INT NULL,
  plan_pago_id        INT NULL,
  beca_id             INT NULL,
  numero_cuota        TINYINT NOT NULL,
  monto_base          DECIMAL(12,2) NOT NULL,
  monto_bonificacion  DECIMAL(12,2) NOT NULL DEFAULT 0,
  monto_beca          DECIMAL(12,2) NOT NULL DEFAULT 0,
  monto               DECIMAL(12,2) NOT NULL,
  saldo               DECIMAL(12,2) NOT NULL,
  fecha_vencimiento   DATE NOT NULL,
  estado              ENUM('pendiente','pagada','refinanciada','anulada') NOT NULL DEFAULT 'pendiente',
  CONSTRAINT fk_cuota_estudiante      FOREIGN KEY (estudiante_id)      REFERENCES estudiante (estudiante_id),
  CONSTRAINT fk_cuota_periodo_lectivo FOREIGN KEY (periodo_lectivo_id) REFERENCES periodo_lectivo (periodo_lectivo_id),
  CONSTRAINT fk_cuota_arancel         FOREIGN KEY (arancel_id)         REFERENCES arancel (arancel_id),
  CONSTRAINT fk_cuota_plan_pago       FOREIGN KEY (plan_pago_id)       REFERENCES plan_pago (plan_pago_id),
  CONSTRAINT fk_cuota_beca            FOREIGN KEY (beca_id)            REFERENCES beca (beca_id)
) ENGINE=InnoDB;

CREATE TABLE comprobante (
  comprobante_id  INT AUTO_INCREMENT PRIMARY KEY,
  numero          VARCHAR(20) NOT NULL,
  cuota_id        INT NOT NULL,
  fecha_emision   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  importe         DECIMAL(12,2) NOT NULL,
  recargo         DECIMAL(12,2) NOT NULL DEFAULT 0,
  importe_total   DECIMAL(12,2) NOT NULL,
  CONSTRAINT uq_comprobante_numero UNIQUE (numero),
  CONSTRAINT fk_comprobante_cuota FOREIGN KEY (cuota_id) REFERENCES cuota (cuota_id)
) ENGINE=InnoDB;


-- R5 - Cobranzas y cuenta corriente

CREATE TABLE pago (
  pago_id       INT AUTO_INCREMENT PRIMARY KEY,
  cuota_id      INT NOT NULL,
  monto_pagado  DECIMAL(12,2) NOT NULL,
  medio_pago    ENUM('efectivo','transferencia','tarjeta_debito','tarjeta_credito') NOT NULL,
  fecha_pago    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  usuario_id    INT NOT NULL,
  estado        ENUM('activo','inactivo') NOT NULL DEFAULT 'activo',
  CONSTRAINT fk_pago_cuota   FOREIGN KEY (cuota_id)   REFERENCES cuota (cuota_id),
  CONSTRAINT fk_pago_usuario FOREIGN KEY (usuario_id) REFERENCES usuario (usuario_id)
) ENGINE=InnoDB;

-- Cuenta corriente como libro: saldo = SUM(debe) - SUM(haber).
-- Para corregir algo se agrega un movimiento inverso, nunca se edita.
CREATE TABLE movimiento_cuenta (
  movimiento_cuenta_id  BIGINT AUTO_INCREMENT PRIMARY KEY,
  estudiante_id         INT NOT NULL,
  fecha_hora            DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  tipo                  ENUM('cuota','pago','recargo','anulacion','plan_pago') NOT NULL,
  descripcion           VARCHAR(255) NULL,
  debe                  DECIMAL(12,2) NOT NULL DEFAULT 0,
  haber                 DECIMAL(12,2) NOT NULL DEFAULT 0,
  cuota_id              INT NULL,
  pago_id               INT NULL,
  CONSTRAINT fk_movimiento_cuenta_estudiante FOREIGN KEY (estudiante_id) REFERENCES estudiante (estudiante_id),
  CONSTRAINT fk_movimiento_cuenta_cuota      FOREIGN KEY (cuota_id)      REFERENCES cuota (cuota_id),
  CONSTRAINT fk_movimiento_cuenta_pago       FOREIGN KEY (pago_id)       REFERENCES pago (pago_id)
) ENGINE=InnoDB;


-- R6 - Morosidad: cuotas vencidas que entran en un plan de pago

CREATE TABLE plan_pago_detalle (
  plan_pago_id        INT NOT NULL,
  cuota_id            INT NOT NULL,
  saldo_refinanciado  DECIMAL(12,2) NOT NULL,
  dias_mora           SMALLINT NOT NULL,
  PRIMARY KEY (plan_pago_id, cuota_id),
  CONSTRAINT fk_plan_pago_detalle_plan_pago FOREIGN KEY (plan_pago_id) REFERENCES plan_pago (plan_pago_id),
  CONSTRAINT fk_plan_pago_detalle_cuota     FOREIGN KEY (cuota_id)     REFERENCES cuota (cuota_id)
) ENGINE=InnoDB;


-- R8 - Reportes


CREATE TABLE reporte_generado (
  reporte_generado_id  INT AUTO_INCREMENT PRIMARY KEY,
  tipo                 ENUM('cobranzas','morosidad','becas','aranceles','situacion_estudiante') NOT NULL,
  filtros              TEXT NULL,
  formato_exportacion  ENUM('pdf','excel','csv') NULL,   -- NULL si no se exportó
  fecha_hora           DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  usuario_id           INT NOT NULL,
  CONSTRAINT fk_reporte_generado_usuario FOREIGN KEY (usuario_id) REFERENCES usuario (usuario_id)
) ENGINE=InnoDB;


-- R9 - Configuración

CREATE TABLE parametro (
  parametro_id  INT AUTO_INCREMENT PRIMARY KEY,
  codigo        VARCHAR(50)  NOT NULL,
  nombre        VARCHAR(100) NOT NULL,
  categoria     VARCHAR(50)  NOT NULL,
  tipo_dato     ENUM('entero','decimal','texto','booleano','fecha') NOT NULL,
  valor         VARCHAR(255) NOT NULL,
  valor_minimo  VARCHAR(50) NULL,
  valor_maximo  VARCHAR(50) NULL,
  CONSTRAINT uq_parametro_codigo UNIQUE (codigo)
) ENGINE=InnoDB;

CREATE TABLE parametro_historial (
  parametro_historial_id  INT AUTO_INCREMENT PRIMARY KEY,
  parametro_id            INT NOT NULL,
  valor_anterior          VARCHAR(255) NOT NULL,
  valor_nuevo             VARCHAR(255) NOT NULL,
  fecha_desde             DATETIME NOT NULL,
  fecha_hasta             DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  motivo                  VARCHAR(255) NOT NULL,
  usuario_id              INT NOT NULL,
  CONSTRAINT fk_parametro_historial_parametro FOREIGN KEY (parametro_id) REFERENCES parametro (parametro_id),
  CONSTRAINT fk_parametro_historial_usuario   FOREIGN KEY (usuario_id)   REFERENCES usuario (usuario_id)
) ENGINE=InnoDB;

-- Auditoría de solo lectura

DELIMITER $$
CREATE TRIGGER tr_auditoria_no_update BEFORE UPDATE ON auditoria
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El log de auditoria es de solo lectura';
END$$

CREATE TRIGGER tr_auditoria_no_delete BEFORE DELETE ON auditoria
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El log de auditoria es de solo lectura';
END$$
DELIMITER ;


-- Vistas de apoyo (no son tablas: se calculan al consultarlas)

-- Saldo de cuenta corriente por estudiante.
CREATE VIEW v_saldo_estudiante AS
SELECT e.estudiante_id,
       e.dni,
       COALESCE(SUM(m.debe), 0)                             AS total_debe,
       COALESCE(SUM(m.haber), 0)                            AS total_haber,
       COALESCE(SUM(m.debe), 0) - COALESCE(SUM(m.haber), 0) AS saldo
FROM estudiante e
LEFT JOIN movimiento_cuenta m ON m.estudiante_id = e.estudiante_id
GROUP BY e.estudiante_id, e.dni;

-- Cuotas impagas ya vencidas, con días de mora a hoy (morosidad).
CREATE VIEW v_cuota_vencida AS
SELECT c.cuota_id,
       c.estudiante_id,
       e.dni,
       pe.carrera_id,
       c.periodo_lectivo_id,
       c.fecha_vencimiento,
       c.saldo,
       DATEDIFF(CURRENT_DATE, c.fecha_vencimiento) AS dias_mora
FROM cuota c
JOIN estudiante e    ON e.estudiante_id    = c.estudiante_id
JOIN plan_estudio pe ON pe.plan_estudio_id = e.plan_estudio_id
WHERE c.estado = 'pendiente'
  AND c.saldo > 0
  AND c.fecha_vencimiento < CURRENT_DATE;


-- Datos iniciales

INSERT INTO rol (nombre, descripcion) VALUES
  ('Administrador', 'Acceso total al sistema'),
  ('Tesoreria',     'Aranceles, cuotas, cobranzas y morosidad'),
  ('Academico',     'Carreras, planes, estudiantes y datos académicos'),
  ('Comite Becas',  'Convocatorias, evaluación y asignación de becas'),
  ('Auditor',       'Consulta de reportes y log de auditoría');

INSERT INTO permiso (nombre, descripcion) VALUES
  ('USUARIOS_ADMINISTRAR',   'Alta, baja y modificación de usuarios, roles y permisos'),
  ('ACADEMICO_ADMINISTRAR',  'Gestión de carreras, materias, planes y estudiantes'),
  ('ARANCELES_CONFIGURAR',   'Configuración de aranceles y bonificaciones'),
  ('CUOTAS_GENERAR',         'Generación, anulación y regeneración de cuotas'),
  ('COBRANZAS_REGISTRAR',    'Registro y cancelación de pagos'),
  ('MOROSIDAD_GESTIONAR',    'Planes de pago y refinanciaciones'),
  ('BECAS_ADMINISTRAR',      'Convocatorias, evaluación y asignación de becas'),
  ('REPORTES_VER',           'Generación y exportación de reportes'),
  ('PARAMETROS_CONFIGURAR',  'Parámetros del sistema y períodos lectivos'),
  ('AUDITORIA_VER',          'Consulta y exportación del log de auditoría');

-- Administrador: todos los permisos.
INSERT INTO rol_permiso (rol_id, permiso_id)
SELECT r.rol_id, p.permiso_id FROM rol r CROSS JOIN permiso p WHERE r.nombre = 'Administrador';

INSERT INTO rol_permiso (rol_id, permiso_id)
SELECT r.rol_id, p.permiso_id FROM rol r JOIN permiso p
  ON (r.nombre = 'Tesoreria'    AND p.nombre IN ('ARANCELES_CONFIGURAR','CUOTAS_GENERAR','COBRANZAS_REGISTRAR','MOROSIDAD_GESTIONAR','REPORTES_VER'))
  OR (r.nombre = 'Academico'    AND p.nombre IN ('ACADEMICO_ADMINISTRAR','REPORTES_VER'))
  OR (r.nombre = 'Comite Becas' AND p.nombre IN ('BECAS_ADMINISTRAR','REPORTES_VER'))
  OR (r.nombre = 'Auditor'      AND p.nombre IN ('REPORTES_VER','AUDITORIA_VER'));

INSERT INTO parametro (codigo, nombre, categoria, tipo_dato, valor, valor_minimo, valor_maximo) VALUES
  ('TASA_INTERES_MORA_MENSUAL', 'Tasa de interés por mora mensual (%)', 'morosidad', 'decimal', '5.00', '0', '100'),
  ('DIAS_GRACIA_DEFECTO',       'Días de gracia por defecto',            'cuotas',    'entero',  '5',    '0', '60'),
  ('DIA_VENCIMIENTO_DEFECTO',   'Día del mes de vencimiento',            'cuotas',    'entero',  '10',   '1', '28'),
  ('MAX_CUOTAS_PLAN_PAGO',      'Máximo de cuotas de un plan de pago',   'morosidad', 'entero',  '12',   '1', '48'),
  ('MAX_INTENTOS_LOGIN',        'Intentos fallidos antes de bloquear',   'seguridad', 'entero',  '5',    '1', '20'),
  ('LONGITUD_MIN_PASSWORD',     'Longitud mínima de contraseña',         'seguridad', 'entero',  '8',    '6', '64');
