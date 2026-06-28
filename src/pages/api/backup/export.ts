import type { APIRoute } from 'astro';
import { db } from '../../../lib/db';

export const GET: APIRoute = async ({ locals }) => {
  try {
    // Solo permitir a usuarios autenticados
    if (!locals.user) {
      return new Response(JSON.stringify({ error: 'No autorizado.' }), { status: 401 });
    }

    // Obtener todos los datos de las tablas
    const users = db.prepare('SELECT id, username, password_hash, created_at FROM users').all();
    const accounts = db.prepare('SELECT id, name, type, balance, currency, created_at FROM accounts').all();
    const categories = db.prepare('SELECT id, name, type, icon, color, parent_id FROM categories').all();
    const transactions = db.prepare('SELECT id, account_id, category_id, amount, type, date, description, destination_account_id, created_at FROM transactions').all();
    const budgets = db.prepare('SELECT id, category_id, amount, period, start_date, end_date FROM budgets').all();

    const backupData = {
      version: '1.0.0',
      timestamp: Date.now(),
      data: {
        users,
        accounts,
        categories,
        transactions,
        budgets
      }
    };

    return new Response(JSON.stringify(backupData, null, 2), {
      status: 200,
      headers: {
        'Content-Type': 'application/json',
        'Content-Disposition': `attachment; filename="fintrack_backup_${Date.now()}.json"`
      }
    });
  } catch (error: any) {
    return new Response(JSON.stringify({ error: 'Error al exportar respaldo: ' + error.message }), { status: 500 });
  }
};
