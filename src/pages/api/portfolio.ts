import type { APIRoute } from 'astro';
import { db } from '../../lib/db';

/**
 * GET /api/portfolio
 * Retorna resumen del portafolio: inversiones, créditos y patrimonio neto.
 */
export const GET: APIRoute = async ({ locals }) => {
  try {
    if (!locals.user) {
      return new Response(JSON.stringify({ error: 'No autorizado.' }), { status: 401 });
    }

    // Obtener todas las inversiones
    const investments = db.prepare('SELECT * FROM investments ORDER BY created_at DESC').all();

    // Obtener todos los créditos
    const credits = db.prepare('SELECT * FROM credits ORDER BY created_at DESC').all();

    // Calcular totales de inversiones
    const totalInvested = (investments as any[]).reduce((sum, inv) => sum + inv.invested_amount, 0);
    const totalCurrentValue = (investments as any[]).reduce((sum, inv) => sum + inv.current_value, 0);
    const totalReturn = totalCurrentValue - totalInvested;
    const returnPercentage = totalInvested > 0 ? ((totalReturn / totalInvested) * 100) : 0;

    // Calcular totales de créditos
    const totalDebt = (credits as any[]).reduce((sum, cr) => sum + cr.remaining_amount, 0);
    const totalOriginalDebt = (credits as any[]).reduce((sum, cr) => sum + cr.total_amount, 0);
    const totalPaid = totalOriginalDebt - totalDebt;

    // Obtener saldo total de cuentas
    const accountsTotal = db.prepare('SELECT COALESCE(SUM(balance), 0) as total FROM accounts').get() as { total: number };

    // Obtener total ahorrado en bolsillos/objetivos
    const savingsTotal = db.prepare('SELECT COALESCE(SUM(current_amount), 0) as total FROM saving_goals').get() as { total: number };

    // Patrimonio neto = cuentas + inversiones (valor actual) + ahorros - deudas
    const netWorth = accountsTotal.total + totalCurrentValue + savingsTotal.total - totalDebt;

    const summary = {
      investments: {
        items: investments,
        total_invested: totalInvested,
        total_current_value: totalCurrentValue,
        total_return: totalReturn,
        return_percentage: Math.round(returnPercentage * 100) / 100,
        count: investments.length,
      },
      credits: {
        items: credits,
        total_original_debt: totalOriginalDebt,
        total_remaining: totalDebt,
        total_paid: totalPaid,
        count: credits.length,
      },
      net_worth: {
        accounts: accountsTotal.total,
        investments: totalCurrentValue,
        savings: savingsTotal.total,
        debts: -totalDebt,
        total: Math.round(netWorth * 100) / 100,
      },
    };

    return new Response(JSON.stringify(summary), { status: 200 });
  } catch (error: any) {
    return new Response(
      JSON.stringify({ error: 'Error del servidor: ' + error.message }),
      { status: 500 }
    );
  }
};

/**
 * POST /api/portfolio
 * Acciones: create_investment, update_investment, delete_investment,
 *           create_credit, pay_credit, delete_credit
 */
export const POST: APIRoute = async ({ request, locals }) => {
  try {
    if (!locals.user) {
      return new Response(JSON.stringify({ error: 'No autorizado.' }), { status: 401 });
    }

    const data = await request.json();
    const { action } = data;

    switch (action) {
      case 'create_investment':
        return handleCreateInvestment(data);
      case 'update_investment':
        return handleUpdateInvestment(data);
      case 'delete_investment':
        return handleDeleteInvestment(data);
      case 'create_credit':
        return handleCreateCredit(data);
      case 'pay_credit':
        return handlePayCredit(data);
      case 'delete_credit':
        return handleDeleteCredit(data);
      default:
        return new Response(
          JSON.stringify({ error: `Acción no válida: ${action}` }),
          { status: 400 }
        );
    }
  } catch (error: any) {
    return new Response(
      JSON.stringify({ error: 'Error del servidor: ' + error.message }),
      { status: 500 }
    );
  }
};

// ─── Handlers de Inversiones ───────────────────────────────────────────────────

function handleCreateInvestment(data: any): Response {
  const { name, platform, type = 'other', invested_amount = 0, current_value, currency = 'CLP', start_date, notes, account_id } = data;

  if (!name) {
    return new Response(
      JSON.stringify({ error: 'El nombre de la inversión es obligatorio.' }),
      { status: 400 }
    );
  }

  if (invested_amount > 0 && !account_id) {
    return new Response(
      JSON.stringify({ error: 'Se requiere seleccionar una cuenta de origen para el monto invertido.' }),
      { status: 400 }
    );
  }

  const validTypes = ['fund', 'stock', 'crypto', 'deposit', 'other'];
  if (!validTypes.includes(type)) {
    return new Response(
      JSON.stringify({ error: `Tipo de inversión no válido. Debe ser uno de: ${validTypes.join(', ')}` }),
      { status: 400 }
    );
  }

  // Validar saldo suficiente
  if (invested_amount > 0 && account_id) {
    const accountCheck = db.prepare('SELECT type, balance FROM accounts WHERE id = ?').get(account_id) as { type: string; balance: number } | undefined;
    if (!accountCheck) {
      return new Response(JSON.stringify({ error: 'La cuenta de origen no existe.' }), { status: 404 });
    }
    if (accountCheck.type !== 'credit_card' && accountCheck.balance < invested_amount) {
      return new Response(
        JSON.stringify({ error: `Saldo insuficiente. Disponible: ${accountCheck.balance}, requerido: ${invested_amount}.` }),
        { status: 400 }
      );
    }
  }

  const id = crypto.randomUUID();
  const finalCurrentValue = current_value !== undefined ? current_value : invested_amount;

  const executePost = db.transaction(() => {
    db.prepare(`
      INSERT INTO investments (id, name, platform, type, invested_amount, current_value, currency, start_date, notes, source_account_id)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `).run(id, name.trim(), platform?.trim() || null, type, invested_amount, finalCurrentValue, currency, start_date || null, notes?.trim() || null, account_id || null);

    if (invested_amount > 0 && account_id) {
      db.prepare('UPDATE accounts SET balance = balance - ? WHERE id = ?').run(invested_amount, account_id);
      
      let category = db.prepare("SELECT id FROM categories WHERE name = 'Inversión' AND type = 'allocation'").get() as { id: string } | undefined;
      if (!category) {
        const newCatId = crypto.randomUUID();
        db.prepare("INSERT INTO categories (id, name, type, icon, color) VALUES (?, 'Inversión', 'allocation', '📈', '#06b6d4')").run(newCatId);
        category = { id: newCatId };
      }

      const txId = crypto.randomUUID();
      const today = new Date().toISOString().split('T')[0];
      db.prepare(`
        INSERT INTO transactions (id, account_id, category_id, amount, type, date, description, related_entity_id, related_entity_type)
        VALUES (?, ?, ?, ?, 'allocation', ?, ?, ?, 'investment')
      `).run(txId, account_id, category.id, invested_amount, today, `Inversión: ${name.trim()}`, id);
    }
  });

  executePost();

  return new Response(JSON.stringify({ success: true, id }), { status: 201 });
}

function handleUpdateInvestment(data: any): Response {
  const { id, name, platform, type, invested_amount, current_value, currency, start_date, notes } = data;

  if (!id) {
    return new Response(
      JSON.stringify({ error: 'El ID de la inversión es obligatorio.' }),
      { status: 400 }
    );
  }

  // Verificar que la inversión existe
  const existing = db.prepare('SELECT id FROM investments WHERE id = ?').get(id);
  if (!existing) {
    return new Response(
      JSON.stringify({ error: 'La inversión no existe.' }),
      { status: 404 }
    );
  }

  if (type) {
    const validTypes = ['fund', 'stock', 'crypto', 'deposit', 'other'];
    if (!validTypes.includes(type)) {
      return new Response(
        JSON.stringify({ error: `Tipo de inversión no válido. Debe ser uno de: ${validTypes.join(', ')}` }),
        { status: 400 }
      );
    }
  }

  // Construir actualización dinámica solo con los campos proporcionados
  const updates: string[] = [];
  const values: any[] = [];

  if (name !== undefined) { updates.push('name = ?'); values.push(name.trim()); }
  if (platform !== undefined) { updates.push('platform = ?'); values.push(platform?.trim() || null); }
  if (type !== undefined) { updates.push('type = ?'); values.push(type); }
  if (invested_amount !== undefined) { updates.push('invested_amount = ?'); values.push(invested_amount); }
  if (current_value !== undefined) { updates.push('current_value = ?'); values.push(current_value); }
  if (currency !== undefined) { updates.push('currency = ?'); values.push(currency); }
  if (start_date !== undefined) { updates.push('start_date = ?'); values.push(start_date || null); }
  if (notes !== undefined) { updates.push('notes = ?'); values.push(notes?.trim() || null); }

  if (updates.length === 0) {
    return new Response(
      JSON.stringify({ error: 'No se proporcionaron campos para actualizar.' }),
      { status: 400 }
    );
  }

  values.push(id);
  db.prepare(`UPDATE investments SET ${updates.join(', ')} WHERE id = ?`).run(...values);

  return new Response(JSON.stringify({ success: true }), { status: 200 });
}

function handleDeleteInvestment(data: any): Response {
  const { id } = data;

  if (!id) {
    return new Response(
      JSON.stringify({ error: 'El ID de la inversión es obligatorio.' }),
      { status: 400 }
    );
  }

  const investment = db.prepare(
    'SELECT name, invested_amount, source_account_id FROM investments WHERE id = ?'
  ).get(id) as { name: string; invested_amount: number; source_account_id: string | null } | undefined;

  if (!investment) {
    return new Response(
      JSON.stringify({ error: 'La inversión no existe.' }),
      { status: 404 }
    );
  }

  const executeDelete = db.transaction(() => {
    // 1. Si hay monto invertido y cuenta de origen, devolver el dinero
    if (investment.invested_amount > 0 && investment.source_account_id) {
      const account = db.prepare('SELECT id FROM accounts WHERE id = ?').get(investment.source_account_id);
      if (account) {
        db.prepare('UPDATE accounts SET balance = balance + ? WHERE id = ?')
          .run(investment.invested_amount, investment.source_account_id);

        let category = db.prepare(
          "SELECT id FROM categories WHERE name = 'Otros Ingresos' AND type = 'income'"
        ).get() as { id: string } | undefined;

        if (!category) {
          const newCatId = crypto.randomUUID();
          db.prepare(
            "INSERT INTO categories (id, name, type, icon, color) VALUES (?, 'Otros Ingresos', 'income', '💵', '#10b981')"
          ).run(newCatId);
          category = { id: newCatId };
        }

        const txId = crypto.randomUUID();
        const today = new Date().toISOString().split('T')[0];
        db.prepare(`
          INSERT INTO transactions (id, account_id, category_id, amount, type, date, description)
          VALUES (?, ?, ?, ?, 'income', ?, ?)
        `).run(txId, investment.source_account_id, category.id, investment.invested_amount, today,
          `Devolución por eliminación de inversión: ${investment.name}`);
      }
    }

    // 2. Desvincular transacciones relacionadas
    db.prepare(
      "UPDATE transactions SET related_entity_id = NULL, related_entity_type = NULL WHERE related_entity_id = ? AND related_entity_type = 'investment'"
    ).run(id);

    // 3. Eliminar la inversión
    db.prepare('DELETE FROM investments WHERE id = ?').run(id);
  });

  executeDelete();

  return new Response(JSON.stringify({ success: true }), { status: 200 });
}

// ─── Handlers de Créditos ──────────────────────────────────────────────────────

function handleCreateCredit(data: any): Response {
  const { name, total_amount, remaining_amount, monthly_payment, interest_rate, start_date, end_date, institution } = data;

  if (!name || total_amount === undefined || total_amount <= 0) {
    return new Response(
      JSON.stringify({ error: 'El nombre y un monto total válido son obligatorios.' }),
      { status: 400 }
    );
  }

  const id = crypto.randomUUID();
  const finalRemaining = remaining_amount !== undefined ? remaining_amount : total_amount;

  db.prepare(`
    INSERT INTO credits (id, name, total_amount, remaining_amount, monthly_payment, interest_rate, start_date, end_date, institution)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
  `).run(
    id,
    name.trim(),
    total_amount,
    finalRemaining,
    monthly_payment || null,
    interest_rate || null,
    start_date || null,
    end_date || null,
    institution?.trim() || null
  );

  return new Response(JSON.stringify({ success: true, id }), { status: 201 });
}

function handlePayCredit(data: any): Response {
  const { id, amount, account_id } = data;

  if (!id || !amount || amount <= 0) {
    return new Response(
      JSON.stringify({ error: 'El ID del crédito y un monto de pago válido son obligatorios.' }),
      { status: 400 }
    );
  }

  // Verificar que el crédito existe
  const credit = db.prepare('SELECT name, remaining_amount FROM credits WHERE id = ?')
    .get(id) as { name: string; remaining_amount: number } | undefined;

  if (!credit) {
    return new Response(
      JSON.stringify({ error: 'El crédito no existe.' }),
      { status: 404 }
    );
  }

  const paymentAmount = Math.min(amount, credit.remaining_amount);
  const newRemaining = credit.remaining_amount - paymentAmount;

  const executePayment = db.transaction(() => {
    // 1. Actualizar el saldo restante del crédito
    db.prepare('UPDATE credits SET remaining_amount = ? WHERE id = ?').run(newRemaining, id);

    // 2. Si se proporcionó cuenta, descontar el pago y registrar transacción
    if (account_id) {
      const account = db.prepare('SELECT name, balance FROM accounts WHERE id = ?')
        .get(account_id) as { name: string; balance: number } | undefined;

      if (account) {
        // Validar saldo suficiente (excepto tarjetas de crédito)
        const accType = db.prepare('SELECT type FROM accounts WHERE id = ?').get(account_id) as { type: string } | undefined;
        if (accType && accType.type !== 'credit_card' && account.balance < paymentAmount) {
          throw new Error(`Saldo insuficiente en la cuenta. Disponible: ${account.balance}, requerido: ${paymentAmount}.`);
        }

        // Descontar de la cuenta
        db.prepare('UPDATE accounts SET balance = balance - ? WHERE id = ?').run(paymentAmount, account_id);

        // Buscar/crear categoría "Pago de Crédito"
        let category = db.prepare(
          "SELECT id FROM categories WHERE name = 'Pago de Crédito' AND type = 'allocation'"
        ).get() as { id: string } | undefined;

        if (!category) {
          const newCatId = crypto.randomUUID();
          db.prepare(
            "INSERT INTO categories (id, name, type, icon, color) VALUES (?, 'Pago de Crédito', 'allocation', '🏦', '#f59e0b')"
          ).run(newCatId);
          category = { id: newCatId };
        }

        // Registrar la transacción como allocation
        const txId = crypto.randomUUID();
        const today = new Date().toISOString().split('T')[0];
        db.prepare(`
          INSERT INTO transactions (id, account_id, category_id, amount, type, date, description, related_entity_id, related_entity_type)
          VALUES (?, ?, ?, ?, 'allocation', ?, ?, ?, 'credit')
        `).run(txId, account_id, category.id, paymentAmount, today, `Pago de crédito: ${credit.name}`, id);
      }
    }
  });

  executePayment();

  return new Response(
    JSON.stringify({ success: true, payment_applied: paymentAmount, new_remaining: newRemaining }),
    { status: 200 }
  );
}

function handleDeleteCredit(data: any): Response {
  const { id } = data;

  if (!id) {
    return new Response(
      JSON.stringify({ error: 'El ID del crédito es obligatorio.' }),
      { status: 400 }
    );
  }

  const credit = db.prepare(
    'SELECT name, total_amount, remaining_amount FROM credits WHERE id = ?'
  ).get(id) as { name: string; total_amount: number; remaining_amount: number } | undefined;

  if (!credit) {
    return new Response(
      JSON.stringify({ error: 'El crédito no existe.' }),
      { status: 404 }
    );
  }

  const executeDelete = db.transaction(() => {
    // 1. Desvincular transacciones de pago relacionadas (mantener historial)
    db.prepare(
      "UPDATE transactions SET related_entity_id = NULL, related_entity_type = NULL WHERE related_entity_id = ? AND related_entity_type = 'credit'"
    ).run(id);

    // 2. Eliminar el crédito
    db.prepare('DELETE FROM credits WHERE id = ?').run(id);
  });

  executeDelete();

  return new Response(JSON.stringify({ success: true }), { status: 200 });
}
