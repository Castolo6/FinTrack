import type { APIRoute } from 'astro';
import { db } from '../../lib/db';

export const POST: APIRoute = async ({ request, locals }) => {
  try {
    // Solo permitir a usuarios autenticados
    if (!locals.user) {
      return new Response(JSON.stringify({ error: 'No autorizado.' }), { status: 401 });
    }

    const data = await request.json();
    const { category_id, amount } = data;

    if (!category_id || amount === undefined || amount <= 0) {
      return new Response(
        JSON.stringify({ error: 'La categoría y un monto válido son obligatorios.' }),
        { status: 400 }
      );
    }

    // Calcular fechas para el mes en curso automáticamente
    const now = new Date();
    const year = now.getFullYear();
    const month = String(now.getMonth() + 1).padStart(2, '0');
    const start_date = `${year}-${month}-01`;
    const end_date = `${year}-${month}-31`;

    // Verificar si ya existe un presupuesto para esta categoría en este mes
    const existingBudget = db.prepare(`
      SELECT id FROM budgets 
      WHERE category_id = ? AND start_date = ?
    `).get(category_id, start_date) as { id: string } | undefined;

    if (existingBudget) {
      // Actualizar monto
      db.prepare('UPDATE budgets SET amount = ? WHERE id = ?')
        .run(amount, existingBudget.id);
      return new Response(JSON.stringify({ success: true, id: existingBudget.id }), { status: 200 });
    } else {
      // Insertar nuevo presupuesto
      const id = crypto.randomUUID();
      db.prepare(`
        INSERT INTO budgets (id, category_id, amount, period, start_date, end_date)
        VALUES (?, ?, ?, 'monthly', ?, ?)
      `).run(id, category_id, amount, start_date, end_date);
      return new Response(JSON.stringify({ success: true, id }), { status: 201 });
    }

  } catch (error: any) {
    return new Response(
      JSON.stringify({ error: 'Error del servidor: ' + error.message }),
      { status: 500 }
    );
  }
};
