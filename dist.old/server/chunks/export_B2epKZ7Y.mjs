import { t as __exportAll } from "./rolldown-runtime_D7D4PA-g.mjs";
import { t as db } from "./db_B6tuQof6.mjs";
//#region src/pages/api/backup/export.ts
var export_exports = /* @__PURE__ */ __exportAll({ GET: () => GET });
var GET = async ({ locals }) => {
	try {
		if (!locals.user) return new Response(JSON.stringify({ error: "No autorizado." }), { status: 401 });
		const users = db.prepare("SELECT id, username, password_hash, created_at FROM users").all();
		const accounts = db.prepare("SELECT id, name, type, balance, currency, created_at FROM accounts").all();
		const categories = db.prepare("SELECT id, name, type, icon, color, parent_id FROM categories").all();
		const transactions = db.prepare("SELECT id, account_id, category_id, amount, type, date, description, destination_account_id, created_at FROM transactions").all();
		const budgets = db.prepare("SELECT id, category_id, amount, period, start_date, end_date FROM budgets").all();
		return new Response(JSON.stringify({
			version: "1.0.0",
			timestamp: Date.now(),
			data: {
				users,
				accounts,
				categories,
				transactions,
				budgets
			}
		}, null, 2), {
			status: 200,
			headers: {
				"Content-Type": "application/json",
				"Content-Disposition": `attachment; filename="fintrack_backup_${Date.now()}.json"`
			}
		});
	} catch (error) {
		return new Response(JSON.stringify({ error: "Error al exportar respaldo: " + error.message }), { status: 500 });
	}
};
//#endregion
//#region \0virtual:astro:page:src/pages/api/backup/export@_@ts
var page = () => export_exports;
//#endregion
export { page };
