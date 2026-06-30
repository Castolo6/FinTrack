import { t as __exportAll } from "./rolldown-runtime_D7D4PA-g.mjs";
import { t as db } from "./db_B6tuQof6.mjs";
//#region src/pages/api/transactions.ts
var transactions_exports = /* @__PURE__ */ __exportAll({ POST: () => POST });
var POST = async ({ request }) => {
	try {
		const { type, account_id, category_id, amount, date, description } = await request.json();
		if (!type || !account_id || !category_id || amount === void 0 || !date) return new Response(JSON.stringify({ error: "Todos los campos obligatorios deben estar presentes." }), { status: 400 });
		const id = crypto.randomUUID();
		db.transaction(() => {
			db.prepare(`
        INSERT INTO transactions (id, account_id, category_id, amount, type, date, description)
        VALUES (?, ?, ?, ?, ?, ?, ?)
      `).run(id, account_id, category_id, amount, type, date, description?.trim() || null);
			const adjustment = type === "income" ? amount : -amount;
			db.prepare(`
        UPDATE accounts 
        SET balance = balance + ? 
        WHERE id = ?
      `).run(adjustment, account_id);
		})();
		return new Response(JSON.stringify({
			success: true,
			id
		}), { status: 201 });
	} catch (error) {
		return new Response(JSON.stringify({ error: "Error del servidor: " + error.message }), { status: 500 });
	}
};
//#endregion
//#region \0virtual:astro:page:src/pages/api/transactions@_@ts
var page = () => transactions_exports;
//#endregion
export { page };
