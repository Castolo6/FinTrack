import type { APIRoute } from 'astro';
import { db } from '../../../lib/db';

export const POST: APIRoute = async ({ locals }) => {
  try {
    if (!locals.user) {
      return new Response(JSON.stringify({ error: 'No autorizado.' }), { status: 401 });
    }

    const accounts = db.prepare('SELECT id, name, balance FROM accounts').all() as Array<{
      id: string; name: string; balance: number;
    }>;

    const report: Array<{ name: string; old_balance: number; new_balance: number; diff: number }> = [];

    const recalculate = db.transaction(() => {
      for (const account of accounts) {
        const incomes = db.prepare(
          "SELECT COALESCE(SUM(amount), 0) as total FROM transactions WHERE account_id = ? AND type = 'income'"
        ).get(account.id) as { total: number };

        const expenses = db.prepare(
          "SELECT COALESCE(SUM(amount), 0) as total FROM transactions WHERE account_id = ? AND type = 'expense'"
        ).get(account.id) as { total: number };

        const allocations = db.prepare(
          "SELECT COALESCE(SUM(amount), 0) as total FROM transactions WHERE account_id = ? AND type = 'allocation'"
        ).get(account.id) as { total: number };

        const transfersOut = db.prepare(
          "SELECT COALESCE(SUM(amount), 0) as total FROM transactions WHERE account_id = ? AND type = 'transfer'"
        ).get(account.id) as { total: number };

        const transfersIn = db.prepare(
          "SELECT COALESCE(SUM(amount), 0) as total FROM transactions WHERE destination_account_id = ? AND type = 'transfer'"
        ).get(account.id) as { total: number };

        const newBalance = incomes.total - expenses.total - allocations.total - transfersOut.total + transfersIn.total;

        db.prepare('UPDATE accounts SET balance = ? WHERE id = ?').run(newBalance, account.id);

        report.push({
          name: account.name,
          old_balance: account.balance,
          new_balance: newBalance,
          diff: Math.round((newBalance - account.balance) * 100) / 100,
        });
      }
    });

    recalculate();

    return new Response(
      JSON.stringify({ success: true, report }),
      { status: 200 }
    );
  } catch (error: any) {
    return new Response(
      JSON.stringify({ error: 'Error al recalcular saldos: ' + error.message }),
      { status: 500 }
    );
  }
};
