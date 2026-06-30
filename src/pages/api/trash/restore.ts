import type { APIRoute } from 'astro';
import { db } from '../../../lib/db';

export const POST: APIRoute = async ({ request, locals }) => {
  try {
    if (!locals.user) {
      return new Response(JSON.stringify({ error: 'No autorizado.' }), { status: 401 });
    }

    const { id, type } = await request.json();

    if (!id || type !== 'transaction') {
      return new Response(JSON.stringify({ error: 'Datos inválidos.' }), { status: 400 });
    }

    // Buscar la transacción eliminada
    const tx = db.prepare(
      'SELECT amount, type, account_id, destination_account_id, related_entity_id, related_entity_type FROM transactions WHERE id = ? AND deleted_at IS NOT NULL'
    ).get(id) as {
      amount: number;
      type: string;
      account_id: string;
      destination_account_id: string | null;
      related_entity_id: string | null;
      related_entity_type: string | null;
    } | undefined;

    if (!tx) {
      return new Response(JSON.stringify({ error: 'La transacción no se encontró en la papelera.' }), { status: 404 });
    }

    const restoreTx = db.transaction(() => {
      // 1. Restaurar la transacción (quitar deleted_at)
      db.prepare('UPDATE transactions SET deleted_at = NULL WHERE id = ?').run(id);

      // 2. Volver a aplicar el saldo en la cuenta de origen
      const adjustment = tx.type === 'income' ? tx.amount : -tx.amount;
      db.prepare('UPDATE accounts SET balance = balance + ? WHERE id = ?')
        .run(adjustment, tx.account_id);

      // 3. Si era transferencia, sumar también a la cuenta destino
      if (tx.type === 'transfer' && tx.destination_account_id) {
        db.prepare('UPDATE accounts SET balance = balance + ? WHERE id = ?')
          .run(tx.amount, tx.destination_account_id);
      }

      // 4. Si era allocation vinculada a una entidad, volver a aplicarla
      if (tx.related_entity_id && tx.related_entity_type) {
        if (tx.related_entity_type === 'saving_goal') {
          // Volver a sumar al bolsillo
          db.prepare(
            'UPDATE saving_goals SET current_amount = current_amount + ? WHERE id = ?'
          ).run(tx.amount, tx.related_entity_id);
        } else if (tx.related_entity_type === 'credit') {
          // Volver a restar del crédito
          db.prepare(
            'UPDATE credits SET remaining_amount = MAX(0, remaining_amount - ?) WHERE id = ?'
          ).run(tx.amount, tx.related_entity_id);
        }
      }
    });

    restoreTx();

    return new Response(JSON.stringify({ success: true }), { status: 200 });
  } catch (error: any) {
    return new Response(
      JSON.stringify({ error: 'Error del servidor al restaurar: ' + error.message }),
      { status: 500 }
    );
  }
};
