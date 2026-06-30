import { t as __exportAll } from "./rolldown-runtime_D7D4PA-g.mjs";
import { t as db } from "./db_B6tuQof6.mjs";
//#region src/pages/api/backup/restore.ts
var restore_exports = /* @__PURE__ */ __exportAll({ POST: () => POST });
var POST = async ({ request, locals, cookies }) => {
	try {
		if (!locals.user) return new Response(JSON.stringify({ error: "No autorizado." }), { status: 401 });
		const { data } = await request.json();
		if (!data || !data.users || !data.accounts || !data.categories || !data.transactions || !data.budgets) return new Response(JSON.stringify({ error: "El formato del archivo de respaldo es inválido." }), { status: 400 });
		db.transaction(() => {
			db.prepare("DELETE FROM sessions").run();
			db.prepare("DELETE FROM budgets").run();
			db.prepare("DELETE FROM transactions").run();
			db.prepare("DELETE FROM categories").run();
			db.prepare("DELETE FROM accounts").run();
			db.prepare("DELETE FROM users").run();
			const insertUser = db.prepare(`
        INSERT INTO users (id, username, password_hash, created_at)
        VALUES (@id, @username, @password_hash, @created_at)
      `);
			for (const user of data.users) insertUser.run(user);
			const insertAccount = db.prepare(`
        INSERT INTO accounts (id, name, type, balance, currency, created_at)
        VALUES (@id, @name, @type, @balance, @currency, @created_at)
      `);
			for (const account of data.accounts) insertAccount.run(account);
			const insertCategory = db.prepare(`
        INSERT INTO categories (id, name, type, icon, color, parent_id)
        VALUES (@id, @name, @type, @icon, @color, @parent_id)
      `);
			for (const category of data.categories) insertCategory.run(category);
			const insertTransaction = db.prepare(`
        INSERT INTO transactions (id, account_id, category_id, amount, type, date, description, destination_account_id, created_at)
        VALUES (@id, @account_id, @category_id, @amount, @type, @date, @description, @destination_account_id, @created_at)
      `);
			for (const tx of data.transactions) insertTransaction.run(tx);
			const insertBudget = db.prepare(`
        INSERT INTO budgets (id, category_id, amount, period, start_date, end_date)
        VALUES (@id, @category_id, @amount, @period, @start_date, @end_date)
      `);
			for (const budget of data.budgets) insertBudget.run(budget);
		})();
		cookies.delete("session_id", { path: "/" });
		return new Response(JSON.stringify({ success: true }), { status: 200 });
	} catch (error) {
		return new Response(JSON.stringify({ error: "Error al restaurar respaldo: " + error.message }), { status: 500 });
	}
};
//#endregion
//#region \0virtual:astro:page:src/pages/api/backup/restore@_@ts
var page = () => restore_exports;
//#endregion
export { page };
