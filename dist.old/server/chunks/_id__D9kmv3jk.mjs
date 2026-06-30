import { t as __exportAll } from "./rolldown-runtime_D7D4PA-g.mjs";
import { t as db } from "./db_B6tuQof6.mjs";
//#region src/pages/api/transactions/[id].ts
var _id__exports = /* @__PURE__ */ __exportAll({ DELETE: () => DELETE });
var DELETE = async ({ params, locals }) => {
	try {
		if (!locals.user) return new Response(JSON.stringify({ error: "No autorizado." }), { status: 401 });
		const { id } = params;
		if (!id) return new Response(JSON.stringify({ error: "ID de transacción inválido." }), { status: 400 });
		const tx = db.prepare("SELECT amount, type, account_id FROM transactions WHERE id = ?").get(id);
		if (!tx) return new Response(JSON.stringify({ error: "La transacción no existe." }), { status: 404 });
		db.transaction(() => {
			db.prepare("DELETE FROM transactions WHERE id = ?").run(id);
			const reversionAdjustment = tx.type === "income" ? -tx.amount : tx.amount;
			db.prepare("UPDATE accounts SET balance = balance + ? WHERE id = ?").run(reversionAdjustment, tx.account_id);
		})();
		return new Response(JSON.stringify({ success: true }), { status: 200 });
	} catch (error) {
		return new Response(JSON.stringify({ error: "Error del servidor: " + error.message }), { status: 500 });
	}
};
//#endregion
//#region \0virtual:astro:page:src/pages/api/transactions/[id]@_@ts
var page = () => _id__exports;
//#endregion
export { page };
