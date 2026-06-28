import type { APIRoute } from 'astro';
import { db } from '../../lib/db';

export const POST: APIRoute = async ({ request }) => {
  try {
    const data = await request.json();
    const { name, type, balance = 0, currency = 'CLP' } = data;

    if (!name || !type) {
      return new Response(
        JSON.stringify({ error: 'El nombre y el tipo de cuenta son obligatorios.' }),
        { status: 400 }
      );
    }

    const id = crypto.randomUUID();

    db.prepare(`
      INSERT INTO accounts (id, name, type, balance, currency)
      VALUES (?, ?, ?, ?, ?)
    `).run(id, name.trim(), type, balance, currency);

    return new Response(JSON.stringify({ success: true, id }), { status: 201 });
  } catch (error: any) {
    return new Response(
      JSON.stringify({ error: 'Error del servidor: ' + error.message }),
      { status: 500 }
    );
  }
};
