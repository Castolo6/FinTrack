import type { APIRoute } from 'astro';
import { db } from '../../../lib/db';

export const GET: APIRoute = async ({ locals }) => {
  try {
    // Solo permitir a usuarios autenticados
    if (!locals.user) {
      return new Response(JSON.stringify({ error: 'No autorizado.' }), { status: 401 });
    }

    // Obtener todos los datos de las tablas
    const users = db.prepare('SELECT * FROM users').all();
    const accounts = db.prepare('SELECT * FROM accounts').all();
    const categories = db.prepare('SELECT * FROM categories').all();
    const transactions = db.prepare('SELECT * FROM transactions').all();
    const budgets = db.prepare('SELECT * FROM budgets').all();
    const saving_goals = db.prepare('SELECT * FROM saving_goals').all();
    const investments = db.prepare('SELECT * FROM investments').all();
    const credits = db.prepare('SELECT * FROM credits').all();

    const backupData = {
      version: '1.0.0',
      timestamp: Date.now(),
      data: {
        users,
        accounts,
        categories,
        transactions,
        budgets,
        saving_goals,
        investments,
        credits
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
