function createMySqlRepository(pool) {
  const columnas = 'id, nombre, cantidad, unidad, estado';

  return {
    async listar() {
      const [filas] = await pool.query(
        `SELECT ${columnas} FROM productos ORDER BY id`,
      );
      return filas;
    },

    async obtener(id) {
      const [filas] = await pool.query(
        `SELECT ${columnas} FROM productos WHERE id = ?`,
        [id],
      );
      return filas[0] || null;
    },

    async crear(producto) {
      const [resultado] = await pool.query(
        'INSERT INTO productos (nombre, cantidad, unidad, estado) VALUES (?, ?, ?, ?)',
        [producto.nombre, producto.cantidad, producto.unidad, producto.estado],
      );
      return this.obtener(resultado.insertId);
    },

    async actualizar(id, producto) {
      const [resultado] = await pool.query(
        'UPDATE productos SET nombre = ?, cantidad = ?, unidad = ?, estado = ? WHERE id = ?',
        [
          producto.nombre,
          producto.cantidad,
          producto.unidad,
          producto.estado,
          id,
        ],
      );
      if (resultado.affectedRows === 0) return null;
      return this.obtener(id);
    },

    async eliminar(id) {
      const [resultado] = await pool.query(
        'DELETE FROM productos WHERE id = ?',
        [id],
      );
      return resultado.affectedRows > 0;
    },
  };
}

module.exports = { createMySqlRepository };
