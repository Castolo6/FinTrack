import type { APIRoute } from 'astro';
import { db } from '../../lib/db';

export const GET: APIRoute = async ({ locals }) => {
  try {
    if (!locals.user) {
      return new Response(JSON.stringify({ error: 'No autorizado.' }), { status: 401 });
    }

    // Obtener elementos eliminados (solo transacciones por ahora para evitar problemas de dependencias)
    const deletedTransactions = db.prepare(`
      SELECT t.id, t.amount, t.type, t.date, t.description, t.deleted_at, 
             c.name as category_name, c.icon as category_icon, c.color as category_color,
             a.name as account_name
      FROM transactions t
      LEFT JOIN categories c ON t.category_id = c.id
      LEFT JOIN accounts a ON t.account_id = a.id
      WHERE t.deleted_at IS NOT NULL
      ORDER BY t.deleted_at DESC
    `).all();

    return new Response(JSON.stringify({ 
      success: true, 
      trash: {
        transactions: deletedTransactions
      } 
    }), { status: 200 });

  } catch (error: any) {
    return new Response(
      JSON.stringify({ error: 'Error al obtener la papelera: ' + error.message }),
      { status: 500 }
    );
  }
};
