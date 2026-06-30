import { t as __exportAll } from "./rolldown-runtime_D7D4PA-g.mjs";
import { t as db } from "./db_B6tuQof6.mjs";
import bcrypt from "bcryptjs";
//#region src/pages/api/auth/login.ts
var login_exports = /* @__PURE__ */ __exportAll({ POST: () => POST });
var POST = async ({ request, cookies }) => {
	try {
		const { username, password } = await request.json();
		if (!username || !password) return new Response(JSON.stringify({ error: "El usuario y la contraseña son obligatorios." }), { status: 400 });
		const user = db.prepare("SELECT id, username, password_hash FROM users WHERE username = ?").get(username.trim());
		if (!user) return new Response(JSON.stringify({ error: "Credenciales inválidas." }), { status: 400 });
		if (!bcrypt.compareSync(password, user.password_hash)) return new Response(JSON.stringify({ error: "Credenciales inválidas." }), { status: 400 });
		const sessionId = crypto.randomUUID();
		const expiresAt = Math.floor(Date.now() / 1e3) + 720 * 60 * 60;
		db.prepare("INSERT INTO sessions (id, user_id, expires_at) VALUES (?, ?, ?)").run(sessionId, user.id, expiresAt);
		cookies.set("session_id", sessionId, {
			path: "/",
			httpOnly: true,
			secure: false,
			sameSite: "lax",
			maxAge: 720 * 60 * 60
		});
		return new Response(JSON.stringify({ success: true }), { status: 200 });
	} catch (error) {
		return new Response(JSON.stringify({ error: "Error del servidor: " + error.message }), { status: 500 });
	}
};
//#endregion
//#region \0virtual:astro:page:src/pages/api/auth/login@_@ts
var page = () => login_exports;
//#endregion
export { page };
