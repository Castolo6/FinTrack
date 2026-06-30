import { t as __exportAll } from "./rolldown-runtime_D7D4PA-g.mjs";
import { t as db } from "./db_B6tuQof6.mjs";
//#region src/pages/api/auth/logout.ts
var logout_exports = /* @__PURE__ */ __exportAll({
	GET: () => GET,
	POST: () => POST
});
var POST = async ({ cookies }) => {
	const sessionId = cookies.get("session_id")?.value;
	if (sessionId) {
		db.prepare("DELETE FROM sessions WHERE id = ?").run(sessionId);
		cookies.delete("session_id", { path: "/" });
	}
	return new Response(JSON.stringify({ success: true }), { status: 200 });
};
var GET = async ({ cookies, redirect }) => {
	const sessionId = cookies.get("session_id")?.value;
	if (sessionId) {
		db.prepare("DELETE FROM sessions WHERE id = ?").run(sessionId);
		cookies.delete("session_id", { path: "/" });
	}
	return redirect("/login");
};
//#endregion
//#region \0virtual:astro:page:src/pages/api/auth/logout@_@ts
var page = () => logout_exports;
//#endregion
export { page };
