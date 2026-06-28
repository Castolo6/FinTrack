import type { APIRoute } from 'astro';
import { db } from '../../lib/db';

export const POST: APIRoute = async ({ request }) => {
  try {
    const data = await request.json();
    const { type, account_id, category_id, amount, date, description } = data;

    if (!type || !account_id || !category_id || amount === undefined || !date) {
      return new Response(
        JSON.stringify({ error: 'Todos los campos obligatorios deben estar presentes.' }),
        { status: 400 }
      );
    }

    const id = crypto.randomUUID();

    // Transacción de base de datos para insertar la transacción y actualizar la cuenta
    const performTransaction = db.transaction(() => {
      // 1. Insertar la transacción
      db.prepare(`
        INSERT INTO transactions (id, account_id, category_id, amount, type, date, description)
        VALUES (?, ?, ?, ?, ?, ?, ?)
      `).run(id, account_id, category_id, amount, type, date, description?.trim() || null);

      // 2. Actualizar el saldo de la cuenta
      const adjustment = type === 'income' ? amount : -amount;
      db.prepare(`
        UPDATE accounts 
        SET balance = balance + ? 
        WHERE id = ?
      `).run(adjustment, account_id);
    });

    // Ejecutar transacción
    performTransaction();

    return new Response(JSON.stringify({ success: true, id }), { status: 201 });
  } catch (error: any) {
    return new Response(
      JSON.stringify({ error: 'Error del servidor: ' + error.message }),
      { status: 500 }
    );
  }
};
