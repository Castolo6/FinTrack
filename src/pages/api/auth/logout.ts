import type { APIRoute } from 'astro';
import { db } from '../../../lib/db';

export const POST: APIRoute = async ({ cookies }) => {
  const sessionId = cookies.get('session_id')?.value;

  if (sessionId) {
    // Eliminar la sesión de la base de datos
    db.prepare('DELETE FROM sessions WHERE id = ?').run(sessionId);
    // Borrar la cookie
    cookies.delete('session_id', { path: '/' });
  }

  return new Response(JSON.stringify({ success: true }), { status: 200 });
};

// También soportar método GET para desloguearse directamente desde un enlace
export const GET: APIRoute = async ({ cookies, redirect }) => {
  const sessionId = cookies.get('session_id')?.value;

  if (sessionId) {
    db.prepare('DELETE FROM sessions WHERE id = ?').run(sessionId);
    cookies.delete('session_id', { path: '/' });
  }

  return redirect('/login');
};
