import type { APIRoute } from 'astro';
import { db } from '../../../lib/db';
import bcrypt from 'bcryptjs';

export const POST: APIRoute = async ({ request, cookies }) => {
  try {
    const data = await request.json();
    const { username, password } = data;

    if (!username || !password) {
      return new Response(
        JSON.stringify({ error: 'El usuario y la contraseña son obligatorios.' }),
        { status: 400 }
      );
    }

    // Buscar usuario en SQLite
    const user = db.prepare('SELECT id, username, password_hash FROM users WHERE username = ?')
      .get(username.trim()) as { id: string; username: string; password_hash: string } | undefined;

    if (!user) {
      return new Response(
        JSON.stringify({ error: 'Credenciales inválidas.' }),
        { status: 400 }
      );
    }

    // Verificar contraseña
    const passwordMatch = bcrypt.compareSync(password, user.password_hash);
    if (!passwordMatch) {
      return new Response(
        JSON.stringify({ error: 'Credenciales inválidas.' }),
        { status: 400 }
      );
    }

    // Crear sesión de 30 días
    const sessionId = crypto.randomUUID();
    const expiresAt = Math.floor(Date.now() / 1000) + 30 * 24 * 60 * 60; // 30 días

    db.prepare('INSERT INTO sessions (id, user_id, expires_at) VALUES (?, ?, ?)')
      .run(sessionId, user.id, expiresAt);

    // Establecer la cookie de sesión
    cookies.set('session_id', sessionId, {
      path: '/',
      httpOnly: true,
      secure: false, // Permitir en red local sin HTTPS
      sameSite: 'lax', // Lax es más permisivo para redirecciones locales
      maxAge: 30 * 24 * 60 * 60, // 30 días
    });

    return new Response(JSON.stringify({ success: true }), { status: 200 });
  } catch (error: any) {
    return new Response(
      JSON.stringify({ error: 'Error del servidor: ' + error.message }),
      { status: 500 }
    );
  }
};
