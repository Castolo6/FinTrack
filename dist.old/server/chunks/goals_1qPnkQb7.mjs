import { t as __exportAll } from "./rolldown-runtime_D7D4PA-g.mjs";
import { t as db } from "./db_B6tuQof6.mjs";
//#region src/pages/api/goals.ts
var goals_exports = /* @__PURE__ */ __exportAll({
	PATCH: () => PATCH,
	POST: () => POST
});
var POST = async ({ request, locals }) => {
	try {
		if (!locals.user) return new Response(JSON.stringify({ error: "No autorizado." }), { status: 401 });
		const { name, target_amount, current_amount = 0, saving_platform, account_id, deadline } = await request.json();
		if (!name || target_amount === void 0 || target_amount <= 0) return new Response(JSON.stringify({ error: "El nombre y un monto objetivo válido son obligatorios." }), { status: 400 });
		let account = null;
		if (current_amount > 0) {
			if (!account_id) return new Response(JSON.stringify({ error: "Se requiere una cuenta de origen si se ingresa un monto inicial." }), { status: 400 });
			account = db.prepare("SELECT name, balance FROM accounts WHERE id = ?").get(account_id);
			if (!account) return new Response(JSON.stringify({ error: "La cuenta de origen seleccionada no existe." }), { status: 404 });
		}
		const id = crypto.randomUUID();
		db.transaction(() => {
			db.prepare(`
        INSERT INTO saving_goals (id, name, target_amount, current_amount, saving_platform, deadline)
        VALUES (?, ?, ?, ?, ?, ?)
      `).run(id, name.trim(), target_amount, current_amount, saving_platform?.trim() || null, deadline || null);
			if (current_amount > 0 && account_id && account) {
				const newBalance = account.balance - current_amount;
				db.prepare("UPDATE accounts SET balance = ? WHERE id = ?").run(newBalance, account_id);
				let category = db.prepare("SELECT id FROM categories WHERE name = 'Ahorro' AND type = 'expense'").get();
				if (!category) {
					const newCatId = crypto.randomUUID();
					db.prepare("INSERT INTO categories (id, name, type, icon, color) VALUES (?, 'Ahorro', 'expense', '💰', '#1dc7b5')").run(newCatId);
					category = { id: newCatId };
				}
				const txId = crypto.randomUUID();
				const today = (/* @__PURE__ */ new Date()).toISOString().split("T")[0];
				db.prepare(`
          INSERT INTO transactions (id, account_id, category_id, amount, type, date, description)
          VALUES (?, ?, ?, ?, 'expense', ?, ?)
        `).run(txId, account_id, category.id, current_amount, today, `Aporte inicial bolsillo: ${name.trim()}`);
			}
		})();
		return new Response(JSON.stringify({
			success: true,
			id
		}), { status: 201 });
	} catch (error) {
		return new Response(JSON.stringify({ error: "Error del servidor: " + error.message }), { status: 500 });
	}
};
var PATCH = async ({ request, locals }) => {
	try {
		if (!locals.user) return new Response(JSON.stringify({ error: "No autorizado." }), { status: 401 });
		const { id, amount, action, account_id, reason } = await request.json();
		if (!id || amount === void 0 || amount <= 0 || !action || !account_id) return new Response(JSON.stringify({ error: "ID, importe, cuenta y acción son requeridos." }), { status: 400 });
		const goal = db.prepare("SELECT name, current_amount, target_amount FROM saving_goals WHERE id = ?").get(id);
		if (!goal) return new Response(JSON.stringify({ error: "El objetivo no existe." }), { status: 404 });
		const account = db.prepare("SELECT name, balance FROM accounts WHERE id = ?").get(account_id);
		if (!account) return new Response(JSON.stringify({ error: "La cuenta seleccionada no existe." }), { status: 404 });
		const catName = action === "deposit" ? "Ahorro" : "Retiro de Ahorro";
		const catType = action === "deposit" ? "expense" : "income";
		const catIcon = "💰";
		const catColor = "#1dc7b5";
		let category = db.prepare("SELECT id FROM categories WHERE name = ? AND type = ?").get(catName, catType);
		if (!category) {
			const newCatId = crypto.randomUUID();
			db.prepare("INSERT INTO categories (id, name, type, icon, color) VALUES (?, ?, ?, ?, ?)").run(newCatId, catName, catType, catIcon, catColor);
			category = { id: newCatId };
		}
		db.transaction(() => {
			let newGoalAmount = goal.current_amount;
			let newAccountBalance = account.balance;
			if (action === "deposit") {
				newGoalAmount += amount;
				newAccountBalance -= amount;
			} else {
				const actualWithdraw = Math.min(goal.current_amount, amount);
				newGoalAmount -= actualWithdraw;
				newAccountBalance += actualWithdraw;
			}
			db.prepare("UPDATE accounts SET balance = ? WHERE id = ?").run(newAccountBalance, account_id);
			db.prepare("UPDATE saving_goals SET current_amount = ? WHERE id = ?").run(newGoalAmount, id);
			const txId = crypto.randomUUID();
			const today = (/* @__PURE__ */ new Date()).toISOString().split("T")[0];
			const desc = action === "deposit" ? `Depósito a bolsillo: ${goal.name}` : `Retiro desde bolsillo: ${goal.name}${reason ? " (" + reason.trim() + ")" : ""}`;
			db.prepare(`
        INSERT INTO transactions (id, account_id, category_id, amount, type, date, description)
        VALUES (?, ?, ?, ?, ?, ?, ?)
      `).run(txId, account_id, category.id, amount, catType, today, desc);
		})();
		return new Response(JSON.stringify({ success: true }), { status: 200 });
	} catch (error) {
		return new Response(JSON.stringify({ error: "Error del servidor: " + error.message }), { status: 500 });
	}
};
//#endregion
//#region \0virtual:astro:page:src/pages/api/goals@_@ts
var page = () => goals_exports;
//#endregion
export { page };
