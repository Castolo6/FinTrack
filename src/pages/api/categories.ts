import type { APIRoute } from 'astro';
import { db } from '../../lib/db';

export const POST: APIRoute = async ({ request, locals }) => {
  try {
    if (!locals.user) {
      return new Response(JSON.stringify({ error: 'No autorizado.' }), { status: 401 });
    }

    const data = await request.json();
    const { name, type = 'expense', icon = '🏷️', color = '#ef4444' } = data;

    if (!name) {
      return new Response(
        JSON.stringify({ error: 'El nombre de la categoría es obligatorio.' }),
        { status: 400 }
      );
    }

    const existingCat = db.prepare('SELECT id FROM categories WHERE LOWER(name) = LOWER(?) AND type = ?').get(name.trim(), type);
    if (existingCat) {
      return new Response(
        JSON.stringify({ error: `Ya existe una categoría de tipo "${type}" con el nombre "${name}".` }),
        { status: 400 }
      );
    }

    const id = crypto.randomUUID();
    db.prepare(`
      INSERT INTO categories (id, name, type, icon, color)
      VALUES (?, ?, ?, ?, ?)
    `).run(id, name.trim(), type, icon, color);

    return new Response(JSON.stringify({ success: true, id, name: name.trim(), icon }), { status: 201 });
  } catch (error: any) {
    return new Response(
      JSON.stringify({ error: 'Error del servidor: ' + error.message }),
      { status: 500 }
    );
  }
};
