import Database from "better-sqlite3";
import path from "path";
var db = new Database(path.resolve(process.cwd(), "fintrack.db"), {});
db.pragma("foreign_keys = ON");
/**
* Inicializa y crea todas las tablas de base de datos (Migraciones iniciales)
*/
function initDatabase() {
	db.exec(`
    -- Tabla de Usuarios (Seguridad)
    CREATE TABLE IF NOT EXISTS users (
        id TEXT PRIMARY KEY,
        username TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

    -- Tabla de Sesiones (Tokens de sesión)
    CREATE TABLE IF NOT EXISTS sessions (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        expires_at INTEGER NOT NULL,
        FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
    );

    -- Tabla de Cuentas Financieras
    CREATE TABLE IF NOT EXISTS accounts (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT CHECK(type IN ('cash', 'bank', 'credit_card', 'investment', 'other')) NOT NULL,
        balance REAL NOT NULL DEFAULT 0.0,
        currency TEXT NOT NULL DEFAULT 'CLP',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

    -- Tabla de Categorías (Ingreso o Gasto)
    CREATE TABLE IF NOT EXISTS categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT CHECK(type IN ('income', 'expense')) NOT NULL,
        icon TEXT,
        color TEXT,
        parent_id TEXT,
        FOREIGN KEY(parent_id) REFERENCES categories(id) ON DELETE SET NULL
    );

    -- Tabla de Transacciones
    CREATE TABLE IF NOT EXISTS transactions (
        id TEXT PRIMARY KEY,
        account_id TEXT NOT NULL,
        category_id TEXT NOT NULL,
        amount REAL NOT NULL,
        type TEXT CHECK(type IN ('income', 'expense', 'transfer')) NOT NULL,
        date TEXT NOT NULL, -- Formato YYYY-MM-DD
        description TEXT,
        destination_account_id TEXT, -- Solo para transferencias entre cuentas
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY(account_id) REFERENCES accounts(id) ON DELETE CASCADE,
        FOREIGN KEY(category_id) REFERENCES categories(id) ON DELETE RESTRICT,
        FOREIGN KEY(destination_account_id) REFERENCES accounts(id) ON DELETE SET NULL
    );

    -- Tabla de Presupuestos
    CREATE TABLE IF NOT EXISTS budgets (
        id TEXT PRIMARY KEY,
        category_id TEXT NOT NULL,
        amount REAL NOT NULL,
        period TEXT NOT NULL DEFAULT 'monthly',
        start_date TEXT NOT NULL,
        end_date TEXT NOT NULL,
        FOREIGN KEY(category_id) REFERENCES categories(id) ON DELETE CASCADE
    );

    -- Tabla de Objetivos de Ahorro y Bolsillos
    CREATE TABLE IF NOT EXISTS saving_goals (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        target_amount REAL NOT NULL,
        current_amount REAL NOT NULL DEFAULT 0.0,
        saving_platform TEXT, -- Plataforma o aplicación donde se guarda el dinero
        deadline TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

    -- Tabla de Caché de Análisis de IA (Vesper)
    CREATE TABLE IF NOT EXISTS analysis_cache (
        type TEXT PRIMARY KEY,
        content TEXT NOT NULL,
        updated_at INTEGER NOT NULL
    );
  `);
	try {
		db.prepare("ALTER TABLE saving_goals ADD COLUMN saving_platform TEXT").run();
	} catch (e) {}
	if (db.prepare("SELECT COUNT(*) as count FROM categories").get().count === 0) {
		const insertCategory = db.prepare(`
      INSERT INTO categories (id, name, type, icon, color) VALUES (?, ?, ?, ?, ?)
    `);
		db.transaction(() => {
			insertCategory.run(crypto.randomUUID(), "Comida", "expense", "🍕", "#ef4444");
			insertCategory.run(crypto.randomUUID(), "Transporte", "expense", "🚗", "#f97316");
			insertCategory.run(crypto.randomUUID(), "Vivienda", "expense", "🏠", "#3b82f6");
			insertCategory.run(crypto.randomUUID(), "Servicios", "expense", "⚡", "#eab308");
			insertCategory.run(crypto.randomUUID(), "Entretenimiento", "expense", "🎬", "#a855f7");
			insertCategory.run(crypto.randomUUID(), "Salario", "income", "💼", "#22c55e");
			insertCategory.run(crypto.randomUUID(), "Inversiones", "income", "📈", "#06b6d4");
			insertCategory.run(crypto.randomUUID(), "Otros Ingresos", "income", "💵", "#10b981");
		})();
	}
	console.log("✅ Base de datos SQLite y categorías por defecto inicializadas con éxito.");
}
initDatabase();
//#endregion
export { db as t };
