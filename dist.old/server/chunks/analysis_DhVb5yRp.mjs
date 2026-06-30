import { t as __exportAll } from "./rolldown-runtime_D7D4PA-g.mjs";
import { t as db } from "./db_B6tuQof6.mjs";
import { t as formatCLP } from "./utils_CLLqVgH_.mjs";
//#region src/pages/api/analysis.ts
var analysis_exports = /* @__PURE__ */ __exportAll({ POST: () => POST });
var POST = async ({ request, locals, cookies }) => {
	try {
		if (!locals.user) return new Response(JSON.stringify({ error: "No autorizado." }), { status: 401 });
		const { type } = await request.json();
		const currency = cookies.get("currency")?.value || "CLP";
		if (!type || ![
			"situacion",
			"fugas",
			"mejoras",
			"objetivos"
		].includes(type)) return new Response(JSON.stringify({ error: "Tipo de análisis inválido o ausente." }), { status: 400 });
		const accounts = db.prepare("SELECT name, type, balance, currency FROM accounts").all();
		const now = /* @__PURE__ */ new Date();
		const currentYear = now.getFullYear();
		const currentMonth = String(now.getMonth() + 1).padStart(2, "0");
		const startOfMonth = `${currentYear}-${currentMonth}-01`;
		const endOfMonth = `${currentYear}-${currentMonth}-31`;
		const budgets = db.prepare(`
      SELECT b.amount as budget_limit, c.name as category_name, c.id as category_id
      FROM budgets b
      JOIN categories c ON b.category_id = c.id
      WHERE b.start_date = ?
    `).all(startOfMonth).map((b) => {
			const spent = db.prepare(`
        SELECT SUM(amount) as total FROM transactions 
        WHERE category_id = ? AND type = 'expense' AND date >= ? AND date <= ?
      `).get(b.category_id, startOfMonth, endOfMonth)?.total || 0;
			const percent = b.budget_limit > 0 ? Math.round(spent / b.budget_limit * 100) : 0;
			return {
				...b,
				spent,
				percent
			};
		});
		const goals = db.prepare("SELECT name, target_amount, current_amount, saving_platform, deadline FROM saving_goals").all();
		let recentTransactions;
		if (type === "objetivos") recentTransactions = db.prepare(`
        SELECT t.date, t.type, t.amount, t.description, c.name as category_name, a.name as account_name
        FROM transactions t
        JOIN accounts a ON t.account_id = a.id
        JOIN categories c ON t.category_id = c.id
        ORDER BY t.date DESC, t.created_at DESC
        LIMIT 50
      `).all();
		else recentTransactions = db.prepare(`
        SELECT t.date, t.type, t.amount, t.description, c.name as category_name, a.name as account_name
        FROM transactions t
        JOIN accounts a ON t.account_id = a.id
        JOIN categories c ON t.category_id = c.id
        WHERE t.date >= ? AND t.date <= ?
        ORDER BY t.date DESC, t.created_at DESC
      `).all(startOfMonth, endOfMonth);
		let targetedInstructions = "";
		if (type === "situacion") targetedInstructions = `Actúa como Vesper, tu asesor financiero personal de alto rendimiento. Realiza un análisis crítico, ejecutivo y puntual de la SITUACIÓN FINANCIERA ACTUAL.
- Analiza el balance global de capital y detecta si la distribución actual de liquidez entre cuentas es óptima o si hay ineficiencias (ej. capital ocioso en cuentas corrientes o falta de fondos de reserva).
- Audita si el ritmo de gasto actual en los presupuestos del mes compromete la estabilidad general, señalando las categorías con mayor riesgo de sobregiro.
- Sé directo, preciso y responde únicamente con viñetas analíticas de alto valor. NO repitas saldos de cuentas ni límites presupuestarios.`;
		else if (type === "fugas") targetedInstructions = `Actúa como Vesper, tu asesor financiero personal de alto rendimiento. Audita las transacciones del mes buscando FUGAS DE DINERO e ineficiencias de gasto.
- Detecta comportamientos de gasto innecesarios, consumos hormiga acumulativos, posibles suscripciones redundantes, o egresos sin sentido.
- Explica la causa raíz detectada en el patrón de transacciones y calcula el impacto financiero anual proyectado (ej. "Gastar $X diarios en Y equivale a $Z al año").
- Sé directo y responde en viñetas analíticas precisas. NO listes transacciones individuales ni hagas tablas de consumos.`;
		else if (type === "mejoras") targetedInstructions = `Actúa como Vesper, tu asesor financiero personal de alto rendimiento. Diseña un PLAN DE ACCIÓN Y MEJORA frugal e inteligente.
- Propón de 3 a 5 medidas concretas y técnicas para reducir gastos en las categorías más críticas del mes actual.
- Diseña una estrategia práctica para automatizar u optimizar el flujo de efectivo local (reglas de ahorro, frugalidad inteligente).
- Sé directo y responde en puntos concretos y accionables. Evita generalidades financieras.`;
		else targetedInstructions = `Actúa como Vesper, tu asesor financiero personal de alto rendimiento. Analiza matemáticamente la VIABILIDAD Y AVANCE DE LOS OBJETIVOS DE AHORRO.
- Para cada objetivo, calcula y muestra un PORCENTAJE estimado de probabilidad de cumplimiento (de 0% a 100%) y explica detalladamente el PORQUÉ de dicha probabilidad (ej. basándote en la tasa de ahorro requerida vs real, tiempo restante en meses y capital acumulado).
- Indica claramente cuáles objetivos son FACTIBLES y cuáles están en RIESGO DE INCUMPLIMIENTO.
- Calcula e indica explícitamente para cada objetivo la CANTIDAD MENSUAL exacta en la moneda seleccionada (${currency}) que se debe aportar o depositar de ahora en adelante para lograr cumplirlo con éxito dentro de su fecha límite (deadline).
- Responde en puntos concisos y precisos. NO repitas las metas o montos acumulados si no es para aportar la cantidad mensual requerida, el porcentaje o el análisis de la probabilidad.`;
		let prompt = `${targetedInstructions}

DATOS FINANCIEROS REALES DEL USUARIO:

=== CUENTAS ACTIVAS ===
${accounts.map((acc) => `- ${acc.name} (${acc.type.toUpperCase()}): ${formatCLP(acc.balance, currency)} ${acc.currency}`).join("\n") || "No hay cuentas registradas."}

=== ESTADO DE PRESUPUESTOS (Mes: ${currentMonth}/${currentYear}) ===
${budgets.map((b) => `- Categoría: ${b.category_name} | Límite: ${formatCLP(b.budget_limit, currency)} | Gastado: ${formatCLP(b.spent, currency)} (${b.percent}% ocupado)`).join("\n") || "No hay presupuestos configurados para este mes."}

=== OBJETIVOS DE AHORRO Y BOLSILLOS ===
${goals.map((g) => `- Bolsillo: ${g.name} | Acumulado: ${formatCLP(g.current_amount, currency)} / Meta: ${formatCLP(g.target_amount, currency)} | Plazo: ${g.deadline || "Sin plazo"} (Plataforma: ${g.saving_platform || "No especificada"})`).join("\n") || "No hay objetivos de ahorro creados."}

=== HISTORIAL DE TRANSACCIONES RECIENTES ===
${recentTransactions.map((t) => `- [${t.date}] [${t.type.toUpperCase()}] ${t.category_name} en ${t.account_name} | ${formatCLP(t.amount, currency)} | Desc: ${t.description || "Sin detalle"}`).join("\n") || "No hay transacciones registradas."}

Responde directamente en formato Markdown de forma limpia, directa y con viñetas puntuales. Evita explicaciones generales. NO incluyas tablas o listas redundantes de cuentas, saldos, presupuestos o transacciones que el usuario ya conoce. Ve al grano, sé preciso y analítico. Moneda del usuario: ${currency}.`;
		const ollamaResponse = await fetch("http://localhost:11434/api/generate", {
			method: "POST",
			headers: { "Content-Type": "application/json" },
			body: JSON.stringify({
				model: "vesper-pro",
				prompt,
				stream: false
			})
		});
		if (!ollamaResponse.ok) throw new Error(`Ollama retornó un error: ${ollamaResponse.statusText}`);
		const data = await ollamaResponse.json();
		db.prepare(`
      INSERT INTO analysis_cache (type, content, updated_at)
      VALUES (?, ?, ?)
      ON CONFLICT(type) DO UPDATE SET content = excluded.content, updated_at = excluded.updated_at
    `).run(type, data.response, Date.now());
		return new Response(JSON.stringify({
			success: true,
			analysis: data.response
		}), { status: 200 });
	} catch (error) {
		return new Response(JSON.stringify({ error: "Error al ejecutar el análisis con Vesper Pro: " + error.message }), { status: 500 });
	}
};
//#endregion
//#region \0virtual:astro:page:src/pages/api/analysis@_@ts
var page = () => analysis_exports;
//#endregion
export { page };
