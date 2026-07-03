import { defineMiddleware } from 'astro:middleware';
import { db } from './lib/db';

export const onRequest = defineMiddleware(async (context, next) => {
  const url = new URL(context.url);
  const pathName = url.pathname;

  // Rutas públicas que no requieren autenticación
  const isPublicRoute =
    pathName === '/login' ||
    pathName === '/setup' ||
    pathName.startsWith('/api/auth/');

  // Verificar si existe algún usuario en la base de datos
  const userCount = db.prepare('SELECT COUNT(*) as count FROM users').get() as { count: number };
  const hasUsers = userCount.count > 0;

  // Si no hay usuarios en la base de datos, forzar la redirección a /setup para crear la contraseña
  if (!hasUsers && pathName !== '/setup' && !pathName.startsWith('/api/auth/setup')) {
    return context.redirect('/setup');
  }

  // Leer la cookie de sesión
  const sessionId = context.cookies.get('session_id')?.value;

  let currentUser = null;

  if (sessionId) {
    // Buscar la sesión en la base de datos y verificar que no esté expirada
    const session = db.prepare(`
      SELECT s.id as session_id, s.expires_at, u.id as user_id, u.username 
      FROM sessions s 
      JOIN users u ON s.user_id = u.id 
      WHERE s.id = ?
    `).get(sessionId) as { session_id: string; expires_at: number; user_id: string; username: string } | undefined;

    if (session) {
      const now = Math.floor(Date.now() / 1000);
      if (session.expires_at > now) {
        currentUser = {
          id: session.user_id,
          username: session.username,
        };
        // Adjuntar datos de usuario a locals
        context.locals.user = currentUser;
      } else {
        // Eliminar sesión expirada de SQLite
        db.prepare('DELETE FROM sessions WHERE id = ?').run(sessionId);
        context.cookies.delete('session_id');
      }
    }
  }

  // Si no hay sesión activa y no es una ruta pública, redirigir a /login
  if (!currentUser && !isPublicRoute) {
    return context.redirect('/login');
  }

  // Si ya está autenticado e intenta ir a /login o /setup, redirigir al dashboard
  if (currentUser && (pathName === '/login' || pathName === '/setup')) {
    return context.redirect('/');
  }

  return next();
});
