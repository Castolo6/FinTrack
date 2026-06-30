import { t as __exportAll } from "./rolldown-runtime_D7D4PA-g.mjs";
import { t as db } from "./db_B6tuQof6.mjs";
//#region src/pages/api/accounts.ts
var accounts_exports = /* @__PURE__ */ __exportAll({ POST: () => POST });
var POST = async ({ request }) => {
	try {
		const { name, type, balance = 0, currency = "CLP" } = await request.json();
		if (!name || !type) return new Response(JSON.stringify({ error: "El nombre y el tipo de cuenta son obligatorios." }), { status: 400 });
		const id = crypto.randomUUID();
		db.prepare(`
      INSERT INTO accounts (id, name, type, balance, currency)
      VALUES (?, ?, ?, ?, ?)
    `).run(id, name.trim(), type, balance, currency);
		return new Response(JSON.stringify({
			success: true,
			id
		}), { status: 201 });
	} catch (error) {
		return new Response(JSON.stringify({ error: "Error del servidor: " + error.message }), { status: 500 });
	}
};
//#endregion
//#region \0virtual:astro:page:src/pages/api/accounts@_@ts
var page = () => accounts_exports;
//#endregion
export { page };
