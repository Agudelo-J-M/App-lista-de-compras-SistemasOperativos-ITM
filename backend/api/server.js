require('dotenv').config();

const { createApp } = require('./app');
const { createPool } = require('./db');
const { createMySqlRepository } = require('./repository');

const puerto = Number(process.env.PORT || 3000);
const host = process.env.HOST || '0.0.0.0';

const pool = createPool();
const app = createApp(createMySqlRepository(pool));

const servidor = app.listen(puerto, host, () => {
  console.log(`API Lista de Compras escuchando en http://${host}:${puerto}/api`);
});

function detener(senal) {
  console.log(`${senal}: cerrando la API...`);
  servidor.close(async () => {
    await pool.end();
    process.exit(0);
  });
  setTimeout(() => process.exit(1), 5000).unref();
}

process.on('SIGTERM', () => detener('SIGTERM'));
process.on('SIGINT', () => detener('SIGINT'));
