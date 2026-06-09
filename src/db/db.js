const Database = require('better-sqlite3');

const db = new Database('data.sqlite');
db.pragma('journal_mode = WAL');

module.exports = db;
