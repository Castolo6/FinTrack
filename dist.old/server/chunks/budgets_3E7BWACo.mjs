import { t as __exportAll } from "./rolldown-runtime_D7D4PA-g.mjs";
import { t as db } from "./db_B6tuQof6.mjs";
//#region src/pages/api/budgets.ts
var budgets_exports = /* @__PURE__ */ __exportAll({ POST: () => POST });
var POST = async ({ request, locals }) => {
	try {
		if (!locals.user) return new Response(JSON.stringify({ error: "No autorizado." }), { status: 401 });
		const { category_id, amount } = await request.json();
		if (!category_id || amount === void 0 || amount <= 0) return new Response(JSON.stringify({ error: "La categoría y un monto válido son obligatorios." }), { status: 400 });
		const now = /* @__PURE__ */ new Date();
		const year = now.getFullYear();
		const month = String(now.getMonth() + 1).padStart(2, "0");
		const start_date = `${year}-${month}-01`;
		const end_date = `${year}-${month}-31`;
		const existingBudget = db.prepare(`
      SELECT id FROM budgets 
      WHERE category_id = ? AND start_date = ?
    `).get(category_id, start_date);
		if (existingBudget) {
			db.prepare("UPDATE budgets SET amount = ? WHERE id = ?").run(amount, existingBudget.id);
			return new Response(JSON.stringify({
				success: true,
				id: existingBudget.id
			}), { status: 200 });
		} else {
			const id = crypto.randomUUID();
			db.prepare(`
        INSERT INTO budgets (id, category_id, amount, period, start_date, end_date)
        VALUES (?, ?, ?, 'monthly', ?, ?)
      `).run(id, category_id, amount, start_date, end_date);
			return new Response(JSON.stringify({
				success: true,
				id
			}), { status: 201 });
		}
	} catch (error) {
		return new Response(JSON.stringify({ error: "Error del servidor: " + error.message }), { status: 500 });
	}
};
//#endregion
//#region \0virtual:astro:page:src/pages/api/budgets@_@ts
var page = () => budgets_exports;
//#endregion
export { page };
