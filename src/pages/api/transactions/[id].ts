import type { APIRoute } from 'astro';
import { db } from '../../../lib/db';

export const DELETE: APIRoute = async ({ params, locals }) => {
  try {
    // Solo permitir a usuarios autenticados
    if (!locals.user) {
      return new Response(JSON.stringify({ error: 'No autorizado.' }), { status: 401 });
    }

    const { id } = params;

    if (!id) {
      return new Response(JSON.stringify({ error: 'ID de transacción inválido.' }), { status: 400 });
    }

    // Buscar la transacción para saber el importe, tipo y cuenta afectada
    const tx = db.prepare('SELECT amount, type, account_id FROM transactions WHERE id = ?')
      .get(id) as { amount: number; type: string; account_id: string } | undefined;

    if (!tx) {
      return new Response(JSON.stringify({ error: 'La transacción no existe.' }), { status: 404 });
    }

    // Ejecutar borrado y revertir el saldo de la cuenta dentro de una transacción SQL
    const deleteTx = db.transaction(() => {
      // 1. Eliminar la transacción
      db.prepare('DELETE FROM transactions WHERE id = ?').run(id);

      // 2. Revertir el saldo de la cuenta (gasto resta saldo, por lo que sumamos al revertir; ingreso suma, por lo que restamos)
      const reversionAdjustment = tx.type === 'income' ? -tx.amount : tx.amount;
      db.prepare('UPDATE accounts SET balance = balance + ? WHERE id = ?')
        .run(reversionAdjustment, tx.account_id);
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
