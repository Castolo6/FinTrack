import type { APIRoute } from 'astro';
import { db } from '../../lib/db';
import { formatCLP } from '../../lib/utils';

export const POST: APIRoute = async ({ request, locals, cookies }) => {
  try {
    // 1. Verificar autenticación
    if (!locals.user) {
      return new Response(JSON.stringify({ error: 'No autorizado.' }), { status: 401 });
    }

    // 2. Obtener mensaje
    const body = await request.json();
    const { message } = body;
    const currency = cookies.get('currency')?.value || 'CLP';

    if (!message) {
      return new Response(JSON.stringify({ error: 'El mensaje está vacío.' }), { status: 400 });
    }

    // 3. Recopilar información financiera de la DB
    const accounts = db.prepare('SELECT name, type, balance, currency FROM accounts').all() as Array<any>;

    const now = new Date();
    const currentYear = now.getFullYear();
    const currentMonth = String(now.getMonth() + 1).padStart(2, '0');
    const startOfMonth = `${currentYear}-${currentMonth}-01`;
    const endOfMonth = `${currentYear}-${currentMonth}-31`;

    const budgetsList = db.prepare(`
      SELECT b.amount as budget_limit, c.name as category_name, c.id as category_id
      FROM budgets b
      JOIN categories c ON b.category_id = c.id
      WHERE b.start_date = ?
    `).all(startOfMonth) as Array<any>;

    const budgets = budgetsList.map(b => {
      const spentResult = db.prepare(`
        SELECT SUM(amount) as total FROM transactions 
        WHERE category_id = ? AND type = 'expense' AND date >= ? AND date <= ? AND deleted_at IS NULL
      `).get(b.category_id, startOfMonth, endOfMonth) as any;
      const spent = spentResult?.total || 0;
      const percent = b.budget_limit > 0 ? Math.round((spent / b.budget_limit) * 100) : 0;
      return { ...b, spent, percent };
    });

    const goals = db.prepare('SELECT name, target_amount, current_amount, saving_platform, deadline FROM saving_goals WHERE deleted_at IS NULL').all() as Array<any>;

    let investments: any[] = [];
    try {
      investments = db.prepare('SELECT name, type, invested_amount, current_value, platform FROM investments WHERE deleted_at IS NULL').all();
    } catch(e) {}

    let credits: any[] = [];
    try {
      credits = db.prepare('SELECT name, total_amount, remaining_amount, monthly_payment, interest_rate FROM credits WHERE deleted_at IS NULL').all();
    } catch(e) {}

    const recentTransactions = db.prepare(`
      SELECT t.date, t.type, t.amount, t.description, c.name as category_name, a.name as account_name
      FROM transactions t
      JOIN accounts a ON t.account_id = a.id
      JOIN categories c ON t.category_id = c.id
      WHERE t.deleted_at IS NULL
      ORDER BY t.date DESC, t.created_at DESC
      LIMIT 50
    `).all() as Array<any>;

    // 4. Configurar instrucciones del prompt
    const targetedInstructions = `Eres Moneypenny, asesora financiera personal. Responde la siguiente consulta del usuario usando ESTRICTAMENTE su contexto financiero actual proveído abajo. La consulta del usuario es: "${message}"`;

    let prompt = `${targetedInstructions}

DATOS FINANCIEROS REALES DEL USUARIO:

=== CUENTAS ACTIVAS ===
${accounts.map(acc => `- ${acc.name} (${acc.type.toUpperCase()}): ${formatCLP(acc.balance, currency)} ${acc.currency}`).join('\n') || 'No hay cuentas registradas.'}

=== ESTADO DE PRESUPUESTOS (Mes actual) ===
${budgets.map(b => `- Categoría: ${b.category_name} | Límite: ${formatCLP(b.budget_limit, currency)} | Gastado: ${formatCLP(b.spent, currency)} (${b.percent}% ocupado)`).join('\n') || 'No hay presupuestos configurados para este mes.'}

=== OBJETIVOS DE AHORRO Y BOLSILLOS ===
${goals.map(g => `- Bolsillo: ${g.name} | Acumulado: ${formatCLP(g.current_amount, currency)} / Meta: ${formatCLP(g.target_amount, currency)}`).join('\n') || 'No hay objetivos de ahorro.'}

=== INVERSIONES ===
${investments.map(i => `- ${i.name} (${i.type}): Invertido ${formatCLP(i.invested_amount, currency)} | Actual: ${formatCLP(i.current_value, currency)}`).join('\n') || 'No hay inversiones.'}

=== CRÉDITOS Y DEUDAS ===
${credits.map(c => `- ${c.name}: Deuda Total ${formatCLP(c.total_amount, currency)} | Pendiente: ${formatCLP(c.remaining_amount, currency)}`).join('\n') || 'No hay créditos.'}

=== ÚLTIMAS 50 TRANSACCIONES ===
${recentTransactions.map(t => `- [${t.date}] [${t.type.toUpperCase()}] ${t.category_name} en ${t.account_name} | ${formatCLP(t.amount, currency)} | Desc: ${t.description || 'Sin detalle'}`).join('\n') || 'No hay transacciones.'}

Responde directamente en formato Markdown. Sé muy analítica, directa y al grano. Evalúa si la pregunta requiere cálculos y hazlos. No uses plantillas vacías. Moneda del usuario: ${currency}.`;

    // 5. Invocar a la API de Moneypenny local
    const startTime = Date.now();
    const agentResponse = await fetch('http://localhost:8000/api/v1/agent', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ prompt: prompt })
    });

    if (!agentResponse.ok) {
      throw new Error(`Moneypenny API retornó un error: ${agentResponse.statusText}`);
    }

    const endTime = Date.now();
    const execTimeSec = ((endTime - startTime) / 1000).toFixed(2);
    const data = await agentResponse.json();
    
    const inTokens = Math.round(prompt.length / 4);
    const outTokens = Math.round((data.output?.length || 0) / 4);

    const metricsHeader = `> **EXEC_TIME:** ${execTimeSec}s | **TOKENS_IN:** ~${inTokens} | **TOKENS_OUT:** ~${outTokens}\n\n`;
    const finalOutput = metricsHeader + data.output;

    return new Response(JSON.stringify({ success: true, reply: finalOutput }), { status: 200 });

  } catch (error: any) {
    return new Response(
      JSON.stringify({ error: 'Error al consultar a Moneypenny: ' + error.message }),
      { status: 500 }
    );
  }
};
