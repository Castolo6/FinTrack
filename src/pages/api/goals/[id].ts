import type { APIRoute } from 'astro';
import { db } from '../../../lib/db';

export const DELETE: APIRoute = async ({ params, locals }) => {
  try {
    if (!locals.user) {
      return new Response(JSON.stringify({ error: 'No autorizado.' }), { status: 401 });
    }

    const { id } = params;

    if (!id) {
      return new Response(JSON.stringify({ error: 'ID inválido.' }), { status: 400 });
    }

    // Obtener el objetivo antes de eliminarlo
    const goal = db.prepare(
      'SELECT name, current_amount, source_account_id FROM saving_goals WHERE id = ? AND deleted_at IS NULL'
    ).get(id) as { name: string; current_amount: number; source_account_id: string | null } | undefined;

    if (!goal) {
      return new Response(JSON.stringify({ error: 'El objetivo no existe.' }), { status: 404 });
    }

    const deleteGoal = db.transaction(() => {
      // 1. Si hay saldo acumulado, devolverlo a la cuenta de origen
      if (goal.current_amount > 0 && goal.source_account_id) {
        const account = db.prepare('SELECT id FROM accounts WHERE id = ?').get(goal.source_account_id);
        if (account) {
          db.prepare('UPDATE accounts SET balance = balance + ? WHERE id = ?')
            .run(goal.current_amount, goal.source_account_id);

          // Registrar transacción de devolución
          let category = db.prepare(
            "SELECT id FROM categories WHERE name = 'Retiro de Ahorro' AND type = 'income'"
          ).get() as { id: string } | undefined;

          if (!category) {
            const newCatId = crypto.randomUUID();
            db.prepare(
              "INSERT INTO categories (id, name, type, icon, color) VALUES (?, 'Retiro de Ahorro', 'income', '💰', '#1dc7b5')"
            ).run(newCatId);
            category = { id: newCatId };
          }

          const txId = crypto.randomUUID();
          const today = new Date().toISOString().split('T')[0];
          db.prepare(`
            INSERT INTO transactions (id, account_id, category_id, amount, type, date, description)
            VALUES (?, ?, ?, ?, 'income', ?, ?)
          `).run(txId, goal.source_account_id, category.id, goal.current_amount, today,
            `Devolución por eliminación de bolsillo: ${goal.name}`);
        }
      }

      // 2. Desvincular transacciones relacionadas
      db.prepare(
        "UPDATE transactions SET related_entity_id = NULL, related_entity_type = NULL WHERE related_entity_id = ? AND related_entity_type = 'saving_goal'"
      ).run(id);

      // 3. Eliminar el objetivo
      db.prepare('UPDATE saving_goals SET deleted_at = CURRENT_TIMESTAMP WHERE id = ?').run(id);
    });

    deleteGoal();

    return new Response(JSON.stringify({ success: true }), { status: 200 });
  } catch (error: any) {
    return new Response(
      JSON.stringify({ error: 'Error del servidor: ' + error.message }),
      { status: 500 }
    );
  }
};
