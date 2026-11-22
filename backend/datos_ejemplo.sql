-- =====================================================================
-- Lista de Compras — datos de ejemplo para pruebas y sustentación.
--
-- BORRA todos los productos y deja estos 5, con ids desde 1.
-- Se puede ejecutar cuantas veces se quiera (ej. antes de la sustentación,
-- para quitar lo que quedó de los ensayos). Ejecutar como root:
--   mysql -u root -p < datos_ejemplo.sql
-- =====================================================================

SET NAMES utf8mb4;
USE lista_compras;

TRUNCATE TABLE productos;

INSERT INTO productos (nombre, cantidad, unidad, estado) VALUES
  ('Leche',  2,    'litros',   'pendiente'),
  ('Pan',    1,    'unidad',   'pendiente'),
  ('Huevos', 12,   'unidades', 'comprado'),
  ('Arroz',  1.5,  'kg',       'pendiente'),
  ('Café',   500,  'g',        'comprado');
