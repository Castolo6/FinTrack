import type { APIRoute } from 'astro';
import { db } from '../../../lib/db';
import bcrypt from 'bcryptjs';

export const POST: APIRoute = async ({ request, cookies }) => {
  try {
    const data = await request.json();
    const { username, password } = data;

    if (!username || !password || username.trim().length < 3 || password.length < 6) {
      return new Response(
        JSON.stringify({ error: 'El usuario debe tener al menos 3 caracteres y la contraseña al menos 6.' }),
        { status: 400 }
      );
    }

    // Verificar si ya existe algún usuario en la base de datos
    const userCount = db.prepare('SELECT COUNT(*) as count FROM users').get() as { count: number };
    if (userCount.count > 0) {
      return new Response(
        JSON.stringify({ error: 'El administrador ya ha sido configurado.' }),
        { status: 400 }
      );
    }

    const userId = crypto.randomUUID();
    // Encriptar la contraseña de forma segura
    const passwordHash = bcrypt.hashSync(password, 10);

    // Insertar usuario
    db.prepare('INSERT INTO users (id, username, password_hash) VALUES (?, ?, ?)')
      .run(userId, username.trim(), passwordHash);

    // Crear sesión inicial de 30 días
    const sessionId = crypto.randomUUID();
    const expiresAt = Math.floor(Date.now() / 1000) + 30 * 24 * 60 * 60; // 30 días

    db.prepare('INSERT INTO sessions (id, user_id, expires_at) VALUES (?, ?, ?)')
      .run(sessionId, userId, expiresAt);

    // Establecer la cookie de sesión
    cookies.set('session_id', sessionId, {
      path: '/',
      httpOnly: true,
      secure: false, // Permitir en red local sin HTTPS
      sameSite: 'lax', // Lax es más permisivo para redirecciones locales
      maxAge: 30 * 24 * 60 * 60, // 30 días en segundos
    });

    return new Response(JSON.stringify({ success: true }), { status: 201 });
  } catch (error: any) {
    return new Response(
      JSON.stringify({ error: 'Error del servidor: ' + error.message }),
      { status: 500 }
    );
  }
};
