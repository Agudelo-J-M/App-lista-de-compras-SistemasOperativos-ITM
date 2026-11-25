const express = require('express');

const ESTADOS = ['pendiente', 'comprado'];
const CANTIDAD_MAXIMA = 99999999.99;

function validarProducto(cuerpo) {
  if (cuerpo === null || typeof cuerpo !== 'object' || Array.isArray(cuerpo)) {
    return { error: 'El cuerpo debe ser un objeto JSON.' };
  }

  const nombre = typeof cuerpo.nombre === 'string' ? cuerpo.nombre.trim() : '';
  if (nombre.length === 0) {
    return { error: 'El nombre es obligatorio.' };
  }
  if (nombre.length > 120) {
    return { error: 'El nombre no puede superar los 120 caracteres.' };
  }

  const cantidad =
    typeof cuerpo.cantidad === 'string' && cuerpo.cantidad.trim() !== ''
      ? Number(cuerpo.cantidad)
      : cuerpo.cantidad;
  if (typeof cantidad !== 'number' || !Number.isFinite(cantidad) || cantidad <= 0) {
    return { error: 'La cantidad debe ser un número mayor que 0.' };
  }
  if (cantidad > CANTIDAD_MAXIMA) {
    return { error: 'La cantidad es demasiado grande (máximo 99999999.99).' };
  }

  const unidad =
    cuerpo.unidad === undefined || cuerpo.unidad === null ? '' : cuerpo.unidad;
  if (typeof unidad !== 'string') {
    return { error: 'La unidad debe ser texto.' };
  }
  if (unidad.length > 30) {
    return { error: 'La unidad no puede superar los 30 caracteres.' };
  }

  const estado = cuerpo.estado === undefined ? 'pendiente' : cuerpo.estado;
  if (!ESTADOS.includes(estado)) {
    return { error: 'El estado debe ser "pendiente" o "comprado".' };
  }

  return { producto: { nombre, cantidad, unidad, estado } };
}

function idDeParametro(valor) {
  const id = Number(valor);
  return Number.isInteger(id) && id > 0 ? id : null;
}

const ruta = (manejador) => (req, res, next) =>
  Promise.resolve(manejador(req, res, next)).catch(next);

function createApp(repositorio) {
  const app = express();
  app.disable('x-powered-by');
  app.use(express.json({ limit: '100kb' }));

  app.get('/api/salud', (req, res) => {
    res.json({ ok: true });
  });

  app.get(
    '/api/productos',
    ruta(async (req, res) => {
      res.json(await repositorio.listar());
    }),
  );

  app.get(
    '/api/productos/:id',
    ruta(async (req, res) => {
      const id = idDeParametro(req.params.id);
      if (id === null) {
        return res.status(400).json({ error: 'El id debe ser un número entero positivo.' });
      }
      const producto = await repositorio.obtener(id);
      if (!producto) {
        return res.status(404).json({ error: 'El producto no existe.' });
      }
      res.json(producto);
    }),
  );

  app.post(
    '/api/productos',
    ruta(async (req, res) => {
      const { error, producto } = validarProducto(req.body);
      if (error) return res.status(400).json({ error });
      res.status(201).json(await repositorio.crear(producto));
    }),
  );

  app.put(
    '/api/productos/:id',
    ruta(async (req, res) => {
      const id = idDeParametro(req.params.id);
      if (id === null) {
        return res.status(400).json({ error: 'El id debe ser un número entero positivo.' });
      }
      const { error, producto } = validarProducto(req.body);
      if (error) return res.status(400).json({ error });
      const actualizado = await repositorio.actualizar(id, producto);
      if (!actualizado) {
        return res.status(404).json({ error: 'El producto no existe.' });
      }
      res.json(actualizado);
    }),
  );

  app.delete(
    '/api/productos/:id',
    ruta(async (req, res) => {
      const id = idDeParametro(req.params.id);
      if (id === null) {
        return res.status(400).json({ error: 'El id debe ser un número entero positivo.' });
      }
      const eliminado = await repositorio.eliminar(id);
      if (!eliminado) {
        return res.status(404).json({ error: 'El producto no existe.' });
      }
      res.status(204).end();
    }),
  );

  app.use((req, res) => {
    res.status(404).json({ error: 'Recurso no encontrado.' });
  });

  app.use((err, req, res, next) => {
    if (err.type === 'entity.parse.failed') {
      return res.status(400).json({ error: 'JSON mal formado.' });
    }
    if (err.type === 'entity.too.large') {
      return res
        .status(400)
        .json({ error: 'El cuerpo de la petición es demasiado grande.' });
    }
    console.error(err);
    res.status(500).json({ error: 'Error interno del servidor.' });
  });

  return app;
}

module.exports = { createApp };
