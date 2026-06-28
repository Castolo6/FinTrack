import type { APIRoute } from 'astro';
import { db } from '../../../lib/db';

export const POST: APIRoute = async ({ request, locals, cookies }) => {
  try {
    // Solo permitir a usuarios autenticados
    if (!locals.user) {
      return new Response(JSON.stringify({ error: 'No autorizado.' }), { status: 401 });
    }

    const payload = await request.json();
    const { data } = payload;

    if (!data || !data.users || !data.accounts || !data.categories || !data.transactions || !data.budgets) {
      return new Response(JSON.stringify({ error: 'El formato del archivo de respaldo es inválido.' }), { status: 400 });
    }

    // Transacción atómica de base de datos para limpiar y restaurar toda la información
    const restoreDatabase = db.transaction(() => {
      // 1. Limpiar tablas existentes en orden de dependencia
      db.prepare('DELETE FROM sessions').run();
      db.prepare('DELETE FROM budgets').run();
      db.prepare('DELETE FROM transactions').run();
      db.prepare('DELETE FROM categories').run();
      db.prepare('DELETE FROM accounts').run();
      db.prepare('DELETE FROM users').run();

      // 2. Restaurar Usuarios
      const insertUser = db.prepare(`
        INSERT INTO users (id, username, password_hash, created_at)
        VALUES (@id, @username, @password_hash, @created_at)
      `);
      for (const user of data.users) {
        insertUser.run(user);
      }

      // 3. Restaurar Cuentas
      const insertAccount = db.prepare(`
        INSERT INTO accounts (id, name, type, balance, currency, created_at)
        VALUES (@id, @name, @type, @balance, @currency, @created_at)
      `);
      for (const account of data.accounts) {
        insertAccount.run(account);
      }

      // 4. Restaurar Categorías
      const insertCategory = db.prepare(`
        INSERT INTO categories (id, name, type, icon, color, parent_id)
        VALUES (@id, @name, @type, @icon, @color, @parent_id)
      `);
      for (const category of data.categories) {
        insertCategory.run(category);
      }

      // 5. Restaurar Transacciones
      const insertTransaction = db.prepare(`
        INSERT INTO transactions (id, account_id, category_id, amount, type, date, description, destination_account_id, created_at)
        VALUES (@id, @account_id, @category_id, @amount, @type, @date, @description, @destination_account_id, @created_at)
      `);
      for (const tx of data.transactions) {
        insertTransaction.run(tx);
      }

      // 6. Restaurar Presupuestos
      const insertBudget = db.prepare(`
        INSERT INTO budgets (id, category_id, amount, period, start_date, end_date)
        VALUES (@id, @category_id, @amount, @period, @start_date, @end_date)
      `);
      for (const budget of data.budgets) {
        insertBudget.run(budget);
      }
    });

    // Ejecutar la restauración
    restoreDatabase();

    // Borrar la sesión actual del usuario para obligarlo a loguearse con la nueva base de datos restaurada
    cookies.delete('session_id', { path: '/' });

    return new Response(JSON.stringify({ success: true }), { status: 200 });
  } catch (error: any) {
    return new Response(JSON.stringify({ error: 'Error al restaurar respaldo: ' + error.message }), { status: 500 });
  }
};
