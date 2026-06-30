import type { APIRoute } from 'astro';
import { db } from '../../../lib/db';

export const DELETE: APIRoute = async ({ params, locals }) => {
  try {
    if (!locals.user) {
      return new Response(JSON.stringify({ error: 'No autorizado.' }), { status: 401 });
    }

    const { id } = params;

    if (!id) {
      return new Response(JSON.stringify({ error: 'ID de transacción inválido.' }), { status: 400 });
    }

    // Buscar la transacción completa
    const tx = db.prepare(
      'SELECT amount, type, account_id, destination_account_id, related_entity_id, related_entity_type FROM transactions WHERE id = ? AND deleted_at IS NULL'
    ).get(id) as {
      amount: number;
      type: string;
      account_id: string;
      destination_account_id: string | null;
      related_entity_id: string | null;
      related_entity_type: string | null;
    } | undefined;

    if (!tx) {
      return new Response(JSON.stringify({ error: 'La transacción no existe.' }), { status: 404 });
    }

    const deleteTx = db.transaction(() => {
      // 1. Eliminar la transacción
      db.prepare('UPDATE transactions SET deleted_at = CURRENT_TIMESTAMP WHERE id = ?').run(id);

      // 2. Revertir el saldo de la cuenta de origen
      const reversionAdjustment = tx.type === 'income' ? -tx.amount : tx.amount;
      db.prepare('UPDATE accounts SET balance = balance + ? WHERE id = ?')
        .run(reversionAdjustment, tx.account_id);

      // 3. Si era transferencia, revertir también la cuenta destino
      if (tx.type === 'transfer' && tx.destination_account_id) {
        db.prepare('UPDATE accounts SET balance = balance - ? WHERE id = ?')
          .run(tx.amount, tx.destination_account_id);
      }

      // 4. Si era allocation vinculada a una entidad, revertir la entidad
      if (tx.related_entity_id && tx.related_entity_type) {
        if (tx.related_entity_type === 'saving_goal') {
          // Revertir el depósito al bolsillo
          db.prepare(
            'UPDATE saving_goals SET current_amount = MAX(0, current_amount - ?) WHERE id = ?'
          ).run(tx.amount, tx.related_entity_id);
        } else if (tx.related_entity_type === 'credit') {
          // Revertir el pago del crédito (incrementar remaining_amount)
          db.prepare(
            'UPDATE credits SET remaining_amount = remaining_amount + ? WHERE id = ?'
          ).run(tx.amount, tx.related_entity_id);
        }
      }
    });

    deleteTx();

    return new Response(JSON.stringify({ success: true }), { status: 200 });
  } catch (error: any) {
    return new Response(
      JSON.stringify({ error: 'Error del servidor: ' + error.message }),
      { status: 500 }
    );
  }
};
