const mysql = require('mysql2/promise');

function createPool() {
  return mysql.createPool({
    host: process.env.DB_HOST || '127.0.0.1',
    port: Number(process.env.DB_PORT || 3306),
    user: process.env.DB_USER || 'app_compras',
    password: process.env.DB_PASSWORD || '',
    database: process.env.DB_NAME || 'lista_compras',
    waitForConnections: true,
    connectionLimit: 5,
    decimalNumbers: true,
    charset: 'utf8mb4',
  });
}

module.exports = { createPool };
