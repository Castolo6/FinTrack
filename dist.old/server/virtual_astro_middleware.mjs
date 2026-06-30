import { F as sequence, G as defineMiddleware } from "./chunks/render_CHac7bFQ.mjs";
import { t as db } from "./chunks/db_B6tuQof6.mjs";
//#endregion
//#region \0virtual:astro:middleware
var onRequest = sequence(defineMiddleware(async (context, next) => {
	const pathName = new URL(context.url).pathname;
	const isPublicRoute = pathName === "/login" || pathName === "/setup" || pathName.startsWith("/api/auth/");
	if (!(db.prepare("SELECT COUNT(*) as count FROM users").get().count > 0) && pathName !== "/setup" && !pathName.startsWith("/api/auth/setup")) return context.redirect("/setup");
	const sessionId = context.cookies.get("session_id")?.value;
	let currentUser = null;
	if (sessionId) {
		const session = db.prepare(`
      SELECT s.id as session_id, s.expires_at, u.id as user_id, u.username 
      FROM sessions s 
      JOIN users u ON s.user_id = u.id 
      WHERE s.id = ?
    `).get(sessionId);
		if (session) {
			const now = Math.floor(Date.now() / 1e3);
			if (session.expires_at > now) {
				currentUser = {
					id: session.user_id,
					username: session.username
				};
				context.locals.user = currentUser;
			} else {
				db.prepare("DELETE FROM sessions WHERE id = ?").run(sessionId);
				context.cookies.delete("session_id");
			}
		}
	}
	if (!currentUser && !isPublicRoute) return context.redirect("/login");
	if (currentUser && (pathName === "/login" || pathName === "/setup")) return context.redirect("/");
	return next();
}));
//#endregion
export { onRequest };
