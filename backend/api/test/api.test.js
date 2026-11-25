const test = require('node:test');
const assert = require('node:assert/strict');

const { createApp } = require('../app');

function repositorioEnMemoria() {
  let productos = [];
  let siguienteId = 1;

  return {
    async listar() {
      return productos.map((p) => ({ ...p }));
    },
    async obtener(id) {
      const producto = productos.find((p) => p.id === id);
      return producto ? { ...producto } : null;
    },
    async crear(producto) {
      const creado = { id: siguienteId++, ...producto };
      productos.push(creado);
      return { ...creado };
    },
    async actualizar(id, producto) {
      const indice = productos.findIndex((p) => p.id === id);
      if (indice === -1) return null;
      productos[indice] = { id, ...producto };
      return { ...productos[indice] };
    },
    async eliminar(id) {
      const antes = productos.length;
      productos = productos.filter((p) => p.id !== id);
      return productos.length !== antes;
    },
  };
}

async function levantarApi() {
  const app = createApp(repositorioEnMemoria());
  const servidor = app.listen(0, '127.0.0.1');
  await new Promise((resolver) => servidor.once('listening', resolver));
  const { port } = servidor.address();
  return {
    url: `http://127.0.0.1:${port}/api`,
    cerrar: () => new Promise((resolver) => servidor.close(resolver)),
  };
}

const cuerpo = JSON.stringify({
  nombre: 'Queso',
  cantidad: 1,
  unidad: 'kg',
  estado: 'pendiente',
});

test('GET /productos devuelve un array', async () => {
  const api = await levantarApi();
  try {
    const res = await fetch(`${api.url}/productos`);
    assert.equal(res.status, 200);
    assert.deepEqual(await res.json(), []);
  } finally {
    await api.cerrar();
  }
});

test('POST /productos crea y devuelve 201 con id', async () => {
  const api = await levantarApi();
  try {
    const res = await fetch(`${api.url}/productos`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: cuerpo,
    });
    assert.equal(res.status, 201);
    const producto = await res.json();
    assert.equal(producto.id, 1);
    assert.equal(producto.nombre, 'Queso');
    assert.equal(producto.cantidad, 1);
    assert.equal(producto.unidad, 'kg');
    assert.equal(producto.estado, 'pendiente');

    const lista = await (await fetch(`${api.url}/productos`)).json();
    assert.equal(lista.length, 1);
  } finally {
    await api.cerrar();
  }
});

test('PUT /productos/:id reemplaza los cuatro campos', async () => {
  const api = await levantarApi();
  try {
    await fetch(`${api.url}/productos`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: cuerpo,
    });

    const res = await fetch(`${api.url}/productos/1`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        nombre: 'Queso',
        cantidad: 1,
        unidad: 'kg',
        estado: 'comprado',
      }),
    });
    assert.equal(res.status, 200);
    const producto = await res.json();
    assert.equal(producto.estado, 'comprado');
  } finally {
    await api.cerrar();
  }
});

test('DELETE /productos/:id responde 204 y luego 404', async () => {
  const api = await levantarApi();
  try {
    await fetch(`${api.url}/productos`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: cuerpo,
    });

    const borrar = await fetch(`${api.url}/productos/1`, { method: 'DELETE' });
    assert.equal(borrar.status, 204);

    const consultar = await fetch(`${api.url}/productos/1`);
    assert.equal(consultar.status, 404);
  } finally {
    await api.cerrar();
  }
});

test('POST con nombre vacío responde 400 con mensaje', async () => {
  const api = await levantarApi();
  try {
    const res = await fetch(`${api.url}/productos`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ nombre: '   ', cantidad: 0 }),
    });
    assert.equal(res.status, 400);
    const { error } = await res.json();
    assert.equal(error, 'El nombre es obligatorio.');
  } finally {
    await api.cerrar();
  }
});

test('POST con JSON mal formado responde 400', async () => {
  const api = await levantarApi();
  try {
    const res = await fetch(`${api.url}/productos`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: '{nombre: "Queso"',
    });
    assert.equal(res.status, 400);
    const { error } = await res.json();
    assert.equal(error, 'JSON mal formado.');
  } finally {
    await api.cerrar();
  }
});

test('PUT y DELETE sobre un id inexistente responden 404', async () => {
  const api = await levantarApi();
  try {
    const actualizar = await fetch(`${api.url}/productos/999`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: cuerpo,
    });
    assert.equal(actualizar.status, 404);

    const borrar = await fetch(`${api.url}/productos/999`, { method: 'DELETE' });
    assert.equal(borrar.status, 404);
  } finally {
    await api.cerrar();
  }
});
