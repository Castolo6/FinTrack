import { t as __exportAll } from "./rolldown-runtime_D7D4PA-g.mjs";
import { t as db } from "./db_B6tuQof6.mjs";
//#region src/pages/api/goals/[id].ts
var _id__exports = /* @__PURE__ */ __exportAll({ DELETE: () => DELETE });
var DELETE = async ({ params, locals }) => {
	try {
		if (!locals.user) return new Response(JSON.stringify({ error: "No autorizado." }), { status: 401 });
		const { id } = params;
		if (!id) return new Response(JSON.stringify({ error: "ID inválido." }), { status: 400 });
		db.prepare("DELETE FROM saving_goals WHERE id = ?").run(id);
		return new Response(JSON.stringify({ success: true }), { status: 200 });
	} catch (error) {
		return new Response(JSON.stringify({ error: "Error del servidor: " + error.message }), { status: 500 });
	}
};
//#endregion
//#region \0virtual:astro:page:src/pages/api/goals/[id]@_@ts
var page = () => _id__exports;
//#endregion
export { page };
