import type { APIRoute } from 'astro';
import { db } from '../../../lib/db';

export const POST: APIRoute = async ({ request, locals, cookies }) => {
  try {
    if (!locals.user) {
      return new Response(JSON.stringify({ error: 'No autorizado.' }), { status: 401 });
    }

    const payload = await request.json();
    const data = payload.data || payload;

    if (!data) {
      return new Response(JSON.stringify({ error: 'El formato del archivo de respaldo es inválido.' }), { status: 400 });
    }

    const restoreDatabase = db.transaction(() => {
      // 1. Limpiar solo si existen en el backup
      db.prepare('DELETE FROM sessions').run();
      if (data.credits) db.prepare('DELETE FROM credits').run();
      if (data.investments) db.prepare('DELETE FROM investments').run();
      if (data.saving_goals) db.prepare('DELETE FROM saving_goals').run();
      if (data.budgets) db.prepare('DELETE FROM budgets').run();
      if (data.transactions) db.prepare('DELETE FROM transactions').run();
      if (data.categories) db.prepare('DELETE FROM categories').run();
      if (data.accounts) db.prepare('DELETE FROM accounts').run();
      if (data.users) db.prepare('DELETE FROM users').run();

      // Función auxiliar para inserción dinámica
      const restoreTable = (tableName: string, rows: any[]) => {
        if (!rows || rows.length === 0) return;
        const columns = Object.keys(rows[0]);
        const placeholders = columns.map(c => `@${c}`).join(', ');
        const stmt = db.prepare(`INSERT INTO ${tableName} (${columns.join(', ')}) VALUES (${placeholders})`);
        for (const row of rows) {
          try { stmt.run(row); } catch (e) { console.error(`Error en ${tableName}:`, e); }
        }
      };

      if (data.users) restoreTable('users', data.users);
      if (data.accounts) restoreTable('accounts', data.accounts);
      if (data.categories) restoreTable('categories', data.categories);
      if (data.transactions) restoreTable('transactions', data.transactions);
      if (data.budgets) restoreTable('budgets', data.budgets);
      if (data.saving_goals) restoreTable('saving_goals', data.saving_goals);
      if (data.investments) restoreTable('investments', data.investments);
      if (data.credits) restoreTable('credits', data.credits);
    });

    restoreDatabase();

    // Borrar la sesión actual del usuario si se restauraron usuarios
    if (data.users) {
      cookies.delete('session_id', { path: '/' });
    }

    return new Response(JSON.stringify({ success: true }), { status: 200 });
  } catch (error: any) {
    return new Response(JSON.stringify({ error: 'Error al restaurar respaldo: ' + error.message }), { status: 500 });
  }
};
