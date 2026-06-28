import type { APIRoute } from 'astro';
import { db } from '../../../lib/db';

export const DELETE: APIRoute = async ({ params, locals }) => {
  try {
    if (!locals.user) {
      return new Response(JSON.stringify({ error: 'No autorizado.' }), { status: 401 });
    }

    const { id } = params;

    if (!id) {
      return new Response(JSON.stringify({ error: 'ID inválido.' }), { status: 400 });
    }

    db.prepare('DELETE FROM saving_goals WHERE id = ?').run(id);

    return new Response(JSON.stringify({ success: true }), { status: 200 });
  } catch (error: any) {
    return new Response(
      JSON.stringify({ error: 'Error del servidor: ' + error.message }),
      { status: 500 }
    );
  }
};
