import Database from 'better-sqlite3';
import path from 'path';
import crypto from 'crypto';

// Definir la ruta física del archivo de base de datos
const dbPath = path.resolve(process.cwd(), 'fintrack.db');

// Iniciar la conexión a SQLite (Singleton)
export const db = new Database(dbPath, {
  // Descomentar para ver el log de consultas en la consola de desarrollo
  // verbose: console.log
});

// Habilitar claves foráneas
db.pragma('foreign_keys = ON');

/**
 * Inicializa y crea todas las tablas de base de datos (Migraciones iniciales)
 */
export function initDatabase() {
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
        type TEXT CHECK(type IN ('cash', 'bank', 'credit_card', 'credit', 'investment', 'other')) NOT NULL,
        balance REAL NOT NULL DEFAULT 0.0,
        currency TEXT NOT NULL DEFAULT 'CLP',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

    -- Tabla de Categorías (Ingreso o Gasto)
    CREATE TABLE IF NOT EXISTS categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT CHECK(type IN ('income', 'expense', 'allocation')) NOT NULL,
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
        type TEXT CHECK(type IN ('income', 'expense', 'allocation', 'transfer')) NOT NULL,
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

    -- Tabla de Inversiones (Portfolio)
    CREATE TABLE IF NOT EXISTS investments (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        platform TEXT,
        type TEXT CHECK(type IN ('fund', 'stock', 'crypto', 'deposit', 'real_estate', 'vehicle', 'other')) NOT NULL DEFAULT 'other',
        invested_amount REAL NOT NULL DEFAULT 0.0,
        current_value REAL NOT NULL DEFAULT 0.0,
        currency TEXT NOT NULL DEFAULT 'CLP',
        start_date TEXT,
        notes TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

    -- Tabla de Créditos (Portfolio)
    CREATE TABLE IF NOT EXISTS credits (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        total_amount REAL NOT NULL,
        remaining_amount REAL NOT NULL,
        monthly_payment REAL,
        interest_rate REAL,
        start_date TEXT,
        end_date TEXT,
        institution TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

    -- Tabla de Caché de Análisis de IA (Moneypenny)
    CREATE TABLE IF NOT EXISTS analysis_cache (
        type TEXT PRIMARY KEY,
        content TEXT NOT NULL,
        updated_at INTEGER NOT NULL
    );
  `);

  // Intentar agregar la columna por si la tabla ya existía
  try {
    db.prepare('ALTER TABLE saving_goals ADD COLUMN saving_platform TEXT').run();
  } catch (e) {
    // La columna ya existe, ignorar
  }

  // Migración: columnas de vínculo en transacciones
  try {
    db.prepare('ALTER TABLE transactions ADD COLUMN related_entity_id TEXT').run();
  } catch (e) { /* La columna ya existe */ }
  try {
    db.prepare('ALTER TABLE transactions ADD COLUMN related_entity_type TEXT').run();
  } catch (e) { /* La columna ya existe */ }

  // Migración: cuenta de origen en objetivos de ahorro
  try {
    db.prepare('ALTER TABLE saving_goals ADD COLUMN source_account_id TEXT').run();
  } catch (e) { /* La columna ya existe */ }

  // Migración: cuenta de origen en inversiones
  try {
    db.prepare('ALTER TABLE investments ADD COLUMN source_account_id TEXT').run();
  } catch (e) { /* La columna ya existe */ }

  // Migración: Soft Delete (deleted_at)
  const tablesForSoftDelete = ['transactions', 'saving_goals', 'investments', 'credits'];
  for (const table of tablesForSoftDelete) {
    try {
      db.prepare(`ALTER TABLE ${table} ADD COLUMN deleted_at TIMESTAMP NULL`).run();
    } catch (e) { /* La columna ya existe */ }
  }

  // Migración: Límite de crédito para tarjetas
  try {
    db.prepare('ALTER TABLE accounts ADD COLUMN credit_limit REAL DEFAULT 0.0').run();
  } catch (e) { /* La columna ya existe */ }

  // Crear algunas categorías por defecto si la tabla está vacía
  const categoriesCount = db.prepare('SELECT COUNT(*) as count FROM categories').get() as { count: number };
  if (categoriesCount.count === 0) {
    const insertCategory = db.prepare(`
      INSERT INTO categories (id, name, type, icon, color) VALUES (?, ?, ?, ?, ?)
    `);

    // Transacción para insertar las categorías básicas de ejemplo
    const insertDefaults = db.transaction(() => {
      // Gastos
      insertCategory.run(crypto.randomUUID(), 'Comida', 'expense', '🍕', '#ef4444');
      insertCategory.run(crypto.randomUUID(), 'Transporte', 'expense', '🚗', '#f97316');
      insertCategory.run(crypto.randomUUID(), 'Vivienda', 'expense', '🏠', '#3b82f6');
      insertCategory.run(crypto.randomUUID(), 'Servicios', 'expense', '⚡', '#eab308');
      insertCategory.run(crypto.randomUUID(), 'Entretenimiento', 'expense', '🎬', '#a855f7');
      
      // Ingresos
      insertCategory.run(crypto.randomUUID(), 'Salario', 'income', '💼', '#22c55e');
      insertCategory.run(crypto.randomUUID(), 'Inversiones', 'income', '📈', '#06b6d4');
      insertCategory.run(crypto.randomUUID(), 'Otros Ingresos', 'income', '💵', '#10b981');

      // Asignaciones
      insertCategory.run(crypto.randomUUID(), 'Ahorro', 'allocation', '💰', '#1dc7b5');
      insertCategory.run(crypto.randomUUID(), 'Inversión', 'allocation', '📈', '#06b6d4');
      insertCategory.run(crypto.randomUUID(), 'Pago de Crédito', 'allocation', '🏦', '#f59e0b');
      insertCategory.run(crypto.randomUUID(), 'Fondo de Emergencia', 'allocation', '🛡️', '#8b5cf6');
    });

    insertDefaults();
  }

  console.log('✅ Base de datos SQLite y categorías por defecto inicializadas con éxito.');
}

/**
 * Migración: Reclasifica la categoría 'Ahorro' y sus transacciones de 'expense' a 'allocation'.
 * También recrea las tablas categories y transactions con los nuevos CHECK constraints.
 * Idempotente: se puede ejecutar múltiples veces sin problemas.
 */
function migrateToAllocation() {
  try {
    db.transaction(() => {
      // 1. Reclasificar categoría 'Ahorro' de expense → allocation si aún no se ha hecho
      const ahorroAsExpense = db.prepare(
        "SELECT id FROM categories WHERE name = 'Ahorro' AND type = 'expense'"
      ).get() as { id: string } | undefined;

      if (ahorroAsExpense) {
        db.prepare("UPDATE categories SET type = 'allocation' WHERE id = ?").run(ahorroAsExpense.id);
        db.prepare(
          "UPDATE transactions SET type = 'allocation' WHERE category_id = ? AND type = 'expense'"
        ).run(ahorroAsExpense.id);
        console.log('✅ Categoría Ahorro reclasificada a allocation.');
      }

      // 2. Asegurar que todas las categorías de allocation existan
      const allocationCategories = [
        { name: 'Ahorro', icon: '💰', color: '#1dc7b5' },
        { name: 'Inversión', icon: '📈', color: '#06b6d4' },
        { name: 'Pago de Crédito', icon: '🏦', color: '#f59e0b' },
        { name: 'Fondo de Emergencia', icon: '🛡️', color: '#8b5cf6' },
      ];

      for (const cat of allocationCategories) {
        const exists = db.prepare(
          "SELECT id FROM categories WHERE name = ? AND type = 'allocation'"
        ).get(cat.name);

        if (!exists) {
          db.prepare(
            "INSERT INTO categories (id, name, type, icon, color) VALUES (?, ?, 'allocation', ?, ?)"
          ).run(crypto.randomUUID(), cat.name, cat.icon, cat.color);
          console.log(`✅ Categoría allocation '${cat.name}' creada.`);
        }
      }
    })();

    console.log('✅ Migración allocation completada.');
  } catch (error: any) {
    console.error('⚠️ Error en migración allocation:', error.message);
  }
}

// Ejecutar inicialización al cargar el módulo
initDatabase();
migrateToAllocation();

/**
 * Migración: Actualiza la tabla investments para permitir tipos 'real_estate' y 'vehicle'
 */
function migrateInvestmentsTypes() {
  try {
    const tableInfo = db.prepare("SELECT sql FROM sqlite_master WHERE type='table' AND name='investments'").get() as { sql: string } | undefined;
    
    if (tableInfo && tableInfo.sql.includes("('fund', 'stock', 'crypto', 'deposit', 'other')")) {
      db.transaction(() => {
        // Deshabilitar momentáneamente foreign keys para poder recrear
        db.pragma('foreign_keys = OFF');
        
        // Crear nueva tabla con la restricción actualizada
        db.exec(`
          CREATE TABLE investments_new (
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              platform TEXT,
              type TEXT CHECK(type IN ('fund', 'stock', 'crypto', 'deposit', 'real_estate', 'vehicle', 'other')) NOT NULL DEFAULT 'other',
              invested_amount REAL NOT NULL DEFAULT 0.0,
              current_value REAL NOT NULL DEFAULT 0.0,
              currency TEXT NOT NULL DEFAULT 'CLP',
              start_date TEXT,
              notes TEXT,
              created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
              source_account_id TEXT,
              deleted_at TIMESTAMP NULL
          );
        `);
        
        // Copiar datos existentes
        db.exec(`INSERT INTO investments_new SELECT * FROM investments;`);
        
        // Eliminar tabla vieja
        db.exec(`DROP TABLE investments;`);
        
        // Renombrar nueva tabla
        db.exec(`ALTER TABLE investments_new RENAME TO investments;`);
        
        // Reactivar foreign keys
        db.pragma('foreign_keys = ON');
        
        console.log('✅ Tabla investments migrada exitosamente (tipos real_estate y vehicle permitidos).');
      })();
    }
  } catch (error: any) {
    console.error('⚠️ Error en migración migrateInvestmentsTypes:', error.message);
  }
}

migrateInvestmentsTypes();
