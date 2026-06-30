import type { APIRoute } from 'astro';
import { db } from '../../lib/db';

export const POST: APIRoute = async ({ request, locals }) => {
  try {
    if (!locals.user) {
      return new Response(JSON.stringify({ error: 'No autorizado.' }), { status: 401 });
    }

    const data = await request.json();
    const { name, type, balance = 0, currency = 'CLP', credit_limit = 0 } = data;

    if (!name || !type) {
      return new Response(
        JSON.stringify({ error: 'El nombre y el tipo de cuenta son obligatorios.' }),
        { status: 400 }
      );
    }

    const validTypes = ['cash', 'bank', 'credit_card', 'investment', 'other'];
    if (!validTypes.includes(type)) {
      return new Response(
        JSON.stringify({ error: `Tipo de cuenta no válido. Debe ser uno de: ${validTypes.join(', ')}` }),
        { status: 400 }
      );
    }

    const existingAccount = db.prepare('SELECT id FROM accounts WHERE LOWER(name) = LOWER(?) AND type = ?').get(name.trim(), type);
    if (existingAccount) {
      return new Response(
        JSON.stringify({ error: `Ya existe una cuenta con el nombre "${name.trim()}" de este tipo.` }),
        { status: 400 }
      );
    }

    const id = crypto.randomUUID();

    const createAccount = db.transaction(() => {
      // 1. Crear la cuenta
      db.prepare(`
        INSERT INTO accounts (id, name, type, balance, currency, credit_limit)
        VALUES (?, ?, ?, ?, ?, ?)
      `).run(id, name.trim(), type, balance, currency, type === 'credit_card' ? credit_limit : 0);

      // 2. Si tiene saldo inicial, registrar transacción de apertura
      if (balance !== 0) {
        const isPositive = balance > 0;
        const txType = isPositive ? 'income' : 'expense';
        const catName = isPositive ? 'Otros Ingresos' : 'Otros Gastos';
        const catType = isPositive ? 'income' : 'expense';

        let category = db.prepare('SELECT id FROM categories WHERE name = ? AND type = ?')
          .get(catName, catType) as { id: string } | undefined;

        if (!category) {
          const newCatId = crypto.randomUUID();
          const icon = isPositive ? '💵' : '💸';
          const color = isPositive ? '#10b981' : '#ef4444';
          db.prepare('INSERT INTO categories (id, name, type, icon, color) VALUES (?, ?, ?, ?, ?)')
            .run(newCatId, catName, catType, icon, color);
          category = { id: newCatId };
        }

        const txId = crypto.randomUUID();
        const today = new Date().toISOString().split('T')[0];
        db.prepare(`
          INSERT INTO transactions (id, account_id, category_id, amount, type, date, description)
          VALUES (?, ?, ?, ?, ?, ?, ?)
        `).run(txId, id, category.id, Math.abs(balance), txType, today, `Saldo inicial: ${name.trim()}`);
      }
    });

    createAccount();

    return new Response(JSON.stringify({ success: true, id }), { status: 201 });
  } catch (error: any) {
    return new Response(
      JSON.stringify({ error: 'Error del servidor: ' + error.message }),
      { status: 500 }
    );
  }
};
