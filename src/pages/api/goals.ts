import type { APIRoute } from 'astro';
import { db } from '../../lib/db';

// Crear nuevo objetivo o bolsillo
export const POST: APIRoute = async ({ request, locals }) => {
  try {
    if (!locals.user) {
      return new Response(JSON.stringify({ error: 'No autorizado.' }), { status: 401 });
    }

    const data = await request.json();
    const { name, target_amount, current_amount = 0, saving_platform, account_id, deadline } = data;

    if (!name || target_amount === undefined || target_amount <= 0) {
      return new Response(
        JSON.stringify({ error: 'El nombre y un monto objetivo válido son obligatorios.' }),
        { status: 400 }
      );
    }

    // Si hay un monto inicial, verificar que se haya seleccionado cuenta y que exista
    let account = null;
    if (current_amount > 0) {
      if (!account_id) {
        return new Response(
          JSON.stringify({ error: 'Se requiere una cuenta de origen si se ingresa un monto inicial.' }),
          { status: 400 }
        );
      }
      account = db.prepare('SELECT name, balance FROM accounts WHERE id = ?').get(account_id) as { name: string; balance: number } | undefined;
      if (!account) {
        return new Response(
          JSON.stringify({ error: 'La cuenta de origen seleccionada no existe.' }),
          { status: 404 }
        );
      }
    }

    const id = crypto.randomUUID();

    // Ejecutar creación del objetivo y deducción de cuenta de forma atómica
    const executePostTransaction = db.transaction(() => {
      // 1. Crear el bolsillo/objetivo
      db.prepare(`
        INSERT INTO saving_goals (id, name, target_amount, current_amount, saving_platform, deadline, source_account_id)
        VALUES (?, ?, ?, ?, ?, ?, ?)
      `).run(id, name.trim(), target_amount, current_amount, saving_platform?.trim() || null, deadline || null, account_id || null);

      // 2. Si hay monto inicial, descontar de la cuenta y registrar transacción
      if (current_amount > 0 && account_id && account) {
        const newBalance = account.balance - current_amount;
        db.prepare('UPDATE accounts SET balance = ? WHERE id = ?').run(newBalance, account_id);

        // Buscar/crear categoría "Ahorro"
        let category = db.prepare("SELECT id FROM categories WHERE name = 'Ahorro' AND type = 'allocation'").get() as { id: string } | undefined;
        if (!category) {
          const newCatId = crypto.randomUUID();
          db.prepare("INSERT INTO categories (id, name, type, icon, color) VALUES (?, 'Ahorro', 'allocation', '💰', '#1dc7b5')").run(newCatId);
          category = { id: newCatId };
        }

        const txId = crypto.randomUUID();
        const today = new Date().toISOString().split('T')[0];
        db.prepare(`
          INSERT INTO transactions (id, account_id, category_id, amount, type, date, description, related_entity_id, related_entity_type)
          VALUES (?, ?, ?, ?, 'allocation', ?, ?, ?, 'saving_goal')
        `).run(txId, account_id, category.id, current_amount, today, `Aporte inicial bolsillo: ${name.trim()}`, id);
      }
    });

    executePostTransaction();

    return new Response(JSON.stringify({ success: true, id }), { status: 201 });
  } catch (error: any) {
    return new Response(
      JSON.stringify({ error: 'Error del servidor: ' + error.message }),
      { status: 500 }
    );
  }
};

// Agregar o retirar fondos de un bolsillo/objetivo
export const PATCH: APIRoute = async ({ request, locals }) => {
  try {
    if (!locals.user) {
      return new Response(JSON.stringify({ error: 'No autorizado.' }), { status: 401 });
    }

    const data = await request.json();
    const { id, amount, action, account_id, reason } = data; // action: 'deposit' | 'withdraw'

    if (!id || amount === undefined || amount <= 0 || !action || !account_id) {
      return new Response(
        JSON.stringify({ error: 'ID, importe, cuenta y acción son requeridos.' }),
        { status: 400 }
      );
    }

    // Buscar el objetivo
    const goal = db.prepare('SELECT name, current_amount, target_amount FROM saving_goals WHERE id = ? AND deleted_at IS NULL')
      .get(id) as { name: string; current_amount: number; target_amount: number } | undefined;

    if (!goal) {
      return new Response(JSON.stringify({ error: 'El objetivo no existe.' }), { status: 404 });
    }

    // Buscar la cuenta
    const account = db.prepare('SELECT name, balance FROM accounts WHERE id = ?')
      .get(account_id) as { name: string; balance: number } | undefined;

    if (!account) {
      return new Response(JSON.stringify({ error: 'La cuenta seleccionada no existe.' }), { status: 404 });
    }

    // Validar saldo suficiente para depósitos (excepto tarjetas de crédito)
    if (action === 'deposit') {
      const accountType = db.prepare('SELECT type FROM accounts WHERE id = ?').get(account_id) as { type: string } | undefined;
      if (accountType && accountType.type !== 'credit_card' && account.balance < amount) {
        return new Response(
          JSON.stringify({ error: `Saldo insuficiente. Disponible: ${account.balance}, requerido: ${amount}.` }),
          { status: 400 }
        );
      }
    }

    // Obtener o crear la categoría de Ahorro
    const catName = action === 'deposit' ? 'Ahorro' : 'Retiro de Ahorro';
    const catType = action === 'deposit' ? 'allocation' : 'income';
    const catIcon = '💰';
    const catColor = '#1dc7b5';

    let category = db.prepare('SELECT id FROM categories WHERE name = ? AND type = ?')
      .get(catName, catType) as { id: string } | undefined;

    if (!category) {
      const newCatId = crypto.randomUUID();
      db.prepare('INSERT INTO categories (id, name, type, icon, color) VALUES (?, ?, ?, ?, ?)')
        .run(newCatId, catName, catType, catIcon, catColor);
      category = { id: newCatId };
    }

    // Ejecutar todo en una transacción atómica de SQLite
    const executeTransaction = db.transaction(() => {
      let newGoalAmount = goal.current_amount;
      let newAccountBalance = account.balance;

      if (action === 'deposit') {
        newGoalAmount += amount;
        newAccountBalance -= amount;
      } else {
        // En retiro, no podemos retirar más de lo que tiene el bolsillo
        const actualWithdraw = Math.min(goal.current_amount, amount);
        newGoalAmount -= actualWithdraw;
        newAccountBalance += actualWithdraw;
      }

      // 1. Actualizar balance de cuenta
      db.prepare('UPDATE accounts SET balance = ? WHERE id = ?').run(newAccountBalance, account_id);

      // 2. Actualizar monto actual del objetivo
      db.prepare('UPDATE saving_goals SET current_amount = ? WHERE id = ?').run(newGoalAmount, id);

      // 3. Registrar la transacción
      const txId = crypto.randomUUID();
      const today = new Date().toISOString().split('T')[0];
      const desc = action === 'deposit' 
        ? `Depósito a bolsillo: ${goal.name}`
        : `Retiro desde bolsillo: ${goal.name}${reason ? ' (' + reason.trim() + ')' : ''}`;

      // Usar el monto real movido (actualWithdraw para retiros, amount para depósitos)
      const txAmount = action === 'withdraw' ? Math.min(goal.current_amount, amount) : amount;
      db.prepare(`
        INSERT INTO transactions (id, account_id, category_id, amount, type, date, description, related_entity_id, related_entity_type)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'saving_goal')
      `).run(txId, account_id, category!.id, txAmount, catType, today, desc, id);
    });

    executeTransaction();

    return new Response(JSON.stringify({ success: true }), { status: 200 });
  } catch (error: any) {
    return new Response(
      JSON.stringify({ error: 'Error del servidor: ' + error.message }),
      { status: 500 }
    );
  }
};
