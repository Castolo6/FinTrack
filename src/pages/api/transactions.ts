import type { APIRoute } from 'astro';
import { db } from '../../lib/db';

export const POST: APIRoute = async ({ request, locals }) => {
  try {
    if (!locals.user) {
      return new Response(JSON.stringify({ error: 'No autorizado.' }), { status: 401 });
    }

    const data = await request.json();
    const { type, account_id, category_id, amount, date, description, destination_account_id, related_entity_id, related_entity_type } = data;

    const validTypes = ['income', 'expense', 'allocation', 'transfer'];
    if (!type || !validTypes.includes(type) || !account_id || !category_id || amount === undefined || amount <= 0 || !date) {
      return new Response(
        JSON.stringify({ error: 'Todos los campos obligatorios deben estar presentes y el tipo debe ser válido.' }),
        { status: 400 }
      );
    }

    // Validar que la cuenta existe y obtener su tipo y saldo
    const account = db.prepare('SELECT id, type as account_type, balance, credit_limit FROM accounts WHERE id = ?')
      .get(account_id) as { id: string; account_type: string; balance: number; credit_limit: number } | undefined;

    if (!account) {
      return new Response(
        JSON.stringify({ error: 'La cuenta de origen no existe.' }),
        { status: 404 }
      );
    }

    // Validar saldo suficiente o cupo para gastos, asignaciones y transferencias
    if (['expense', 'allocation', 'transfer'].includes(type)) {
      if (account.account_type === 'credit_card' || account.account_type === 'credit') {
        const available = (account.credit_limit || 0) + account.balance;
        if (available < amount) {
          return new Response(
            JSON.stringify({ error: `Cupo insuficiente. Disponible: ${available}, requerido: ${amount}.` }),
            { status: 400 }
          );
        }
      } else {
        if (account.balance < amount) {
          return new Response(
            JSON.stringify({ error: `Saldo insuficiente en la cuenta. Disponible: ${account.balance}, requerido: ${amount}.` }),
            { status: 400 }
          );
        }
      }
    }

    // Validar cuenta destino para transferencias
    let destinationAccount = null;
    if (type === 'transfer') {
      if (!destination_account_id) {
        return new Response(
          JSON.stringify({ error: 'Se requiere una cuenta de destino para transferencias.' }),
          { status: 400 }
        );
      }
      if (destination_account_id === account_id) {
        return new Response(
          JSON.stringify({ error: 'La cuenta de origen y destino no pueden ser la misma.' }),
          { status: 400 }
        );
      }
      destinationAccount = db.prepare('SELECT id FROM accounts WHERE id = ?').get(destination_account_id);
      if (!destinationAccount) {
        return new Response(
          JSON.stringify({ error: 'La cuenta de destino no existe.' }),
          { status: 404 }
        );
      }
    }

    const id = crypto.randomUUID();

    // Transacción de base de datos para insertar la transacción y actualizar las cuentas
    const performTransaction = db.transaction(() => {
      // 1. Insertar la transacción
      db.prepare(`
        INSERT INTO transactions (id, account_id, category_id, amount, type, date, description, destination_account_id, related_entity_id, related_entity_type)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      `).run(
        id, account_id, category_id, amount, type, date,
        description?.trim() || null,
        type === 'transfer' ? destination_account_id : null,
        related_entity_id || null,
        related_entity_type || null
      );

      // 2. Actualizar el saldo de la cuenta de origen
      const adjustment = type === 'income' ? amount : -amount;
      db.prepare('UPDATE accounts SET balance = balance + ? WHERE id = ?').run(adjustment, account_id);

      // 3. Si es transferencia, sumar al destino
      if (type === 'transfer' && destination_account_id) {
        db.prepare('UPDATE accounts SET balance = balance + ? WHERE id = ?').run(amount, destination_account_id);
      }
    });

    performTransaction();

    return new Response(JSON.stringify({ success: true, id }), { status: 201 });
  } catch (error: any) {
    return new Response(
      JSON.stringify({ error: 'Error del servidor: ' + error.message }),
      { status: 500 }
    );
  }
};
