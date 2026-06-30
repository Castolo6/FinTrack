import { t as __exportAll } from "./rolldown-runtime_D7D4PA-g.mjs";
import { t as db } from "./db_B6tuQof6.mjs";
import bcrypt from "bcryptjs";
//#region src/pages/api/auth/setup.ts
var setup_exports = /* @__PURE__ */ __exportAll({ POST: () => POST });
var POST = async ({ request, cookies }) => {
	try {
		const { username, password } = await request.json();
		if (!username || !password || username.trim().length < 3 || password.length < 6) return new Response(JSON.stringify({ error: "El usuario debe tener al menos 3 caracteres y la contraseña al menos 6." }), { status: 400 });
		if (db.prepare("SELECT COUNT(*) as count FROM users").get().count > 0) return new Response(JSON.stringify({ error: "El administrador ya ha sido configurado." }), { status: 400 });
		const userId = crypto.randomUUID();
		const passwordHash = bcrypt.hashSync(password, 10);
		db.prepare("INSERT INTO users (id, username, password_hash) VALUES (?, ?, ?)").run(userId, username.trim(), passwordHash);
		const sessionId = crypto.randomUUID();
		const expiresAt = Math.floor(Date.now() / 1e3) + 720 * 60 * 60;
		db.prepare("INSERT INTO sessions (id, user_id, expires_at) VALUES (?, ?, ?)").run(sessionId, userId, expiresAt);
		cookies.set("session_id", sessionId, {
			path: "/",
			httpOnly: true,
			secure: false,
			sameSite: "lax",
			maxAge: 720 * 60 * 60
		});
		return new Response(JSON.stringify({ success: true }), { status: 201 });
	} catch (error) {
		return new Response(JSON.stringify({ error: "Error del servidor: " + error.message }), { status: 500 });
	}
};
//#endregion
//#region \0virtual:astro:page:src/pages/api/auth/setup@_@ts
var page = () => setup_exports;
//#endregion
export { page };
