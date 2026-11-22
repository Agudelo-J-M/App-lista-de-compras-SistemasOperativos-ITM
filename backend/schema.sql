-- =====================================================================
-- Lista de Compras — esquema de base de datos (MySQL 8.0.16+ / MariaDB 10.4+)
--
-- Ejecutar UNA vez dentro de la VM, como root:
--   mysql -u root -p < schema.sql
-- Luego cargar los datos de ejemplo con datos_ejemplo.sql.
--
-- Antes de ejecutarlo: cambiar la contraseña de 'app_compras' (abajo).
-- =====================================================================

-- Para que las tildes (ej. "Café") se guarden bien aunque la consola use otra codificación.
SET NAMES utf8mb4;

CREATE DATABASE IF NOT EXISTS lista_compras
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE lista_compras;

CREATE TABLE IF NOT EXISTS productos (
  id        INT            NOT NULL AUTO_INCREMENT,
  nombre    VARCHAR(120)   NOT NULL,
  cantidad  DECIMAL(10,2)  NOT NULL DEFAULT 1,
  unidad    VARCHAR(30)    NOT NULL DEFAULT '',
  estado    ENUM('pendiente', 'comprado') NOT NULL DEFAULT 'pendiente',
  PRIMARY KEY (id),
  CONSTRAINT chk_productos_nombre   CHECK (CHAR_LENGTH(TRIM(nombre)) > 0),
  CONSTRAINT chk_productos_cantidad CHECK (cantidad > 0)
) ENGINE = InnoDB;

-- Usuario que usa la API. La API corre en la misma VM, así que basta 'localhost'.
CREATE USER IF NOT EXISTS 'app_compras'@'localhost' IDENTIFIED BY 'CambiarEstaClave123!';
GRANT SELECT, INSERT, UPDATE, DELETE ON lista_compras.productos TO 'app_compras'@'localhost';
FLUSH PRIVILEGES;
