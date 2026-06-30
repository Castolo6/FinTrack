import { t as __exportAll } from "./rolldown-runtime_D7D4PA-g.mjs";
import { D as addAttribute, M as createComponent, O as defineScriptVars, S as renderTemplate, T as maybeRenderHead, b as renderComponent, j as createAstro } from "./render_CHac7bFQ.mjs";
import { t as db } from "./db_B6tuQof6.mjs";
import "./compiler_DiaTUwMm.mjs";
import { n as $$Layout, t as getI18n } from "./i18n_DqAIjw1h.mjs";
import { t as $$Sidebar } from "./Sidebar_BCGhOHoz.mjs";
import { t as formatCLP } from "./utils_CLLqVgH_.mjs";
//#region src/components/FinanceCharts.astro
createAstro("https://astro.build");
var $$FinanceCharts = createComponent(($$result, $$props, $$slots) => {
	const Astro = $$result.createAstro($$props, $$slots);
	Astro.self = $$FinanceCharts;
	const { startDate, endDate } = Astro.props;
	const { lang, t } = getI18n(Astro);
	const currency = Astro.cookies.get("currency")?.value || "CLP";
	const categoryExpenses = db.prepare(`
  SELECT c.name, c.color, c.icon, SUM(t.amount) as total
  FROM transactions t
  JOIN categories c ON t.category_id = c.id
  WHERE t.type = 'expense' AND t.date >= ? AND t.date <= ?
  GROUP BY c.id
  ORDER BY total DESC
`).all(startDate, endDate);
	const totalExpenses = categoryExpenses.reduce((sum, item) => sum + item.total, 0);
	const categoryData = categoryExpenses.map((item) => {
		const percent = totalExpenses > 0 ? Math.round(item.total / totalExpenses * 100) : 0;
		const barsCount = Math.round(percent / 10);
		const progressBar = "[" + "█".repeat(barsCount) + "░".repeat(10 - barsCount) + "]";
		return {
			...item,
			percent,
			progressBar
		};
	});
	const summary = db.prepare(`
  SELECT 
    SUM(CASE WHEN type = 'income' THEN amount ELSE 0 END) as income,
    SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END) as expense
  FROM transactions
  WHERE date >= ? AND date <= ?
`).get(startDate, endDate);
	const totalIncome = summary?.income || 0;
	const totalExpense = summary?.expense || 0;
	const maxAmount = Math.max(totalIncome, totalExpense) || 1;
	const incomeBarHeight = Math.round(totalIncome / maxAmount * 150);
	const expenseBarHeight = Math.round(totalExpense / maxAmount * 150);
	return renderTemplate`${maybeRenderHead($$result)}<div class="grid grid-cols-1 lg:grid-cols-2 gap-6"><!-- Gráfico de Comparación Ingresos vs Gastos (SVG) --><div class="terminal-window m-0"><div class="terminal-header"><span>> chart --compare=cashflow</span></div><div class="terminal-body font-mono text-sm flex flex-col justify-between h-[250px]"><h2 class="text-xs uppercase text-secondary mb-4">${lang === "es" ? "[ FLUJO_CAJA_MENSUAL ]" : "[ MONTHLY_CASH_FLOW ]"}</h2>${totalIncome === 0 && totalExpense === 0 ? renderTemplate`<div class="flex-1 flex items-center justify-center text-muted-text text-xs border border-dashed border-border-subtle bg-bg">[ NO DATA TO PLOT ]</div>` : renderTemplate`<div class="flex-1 flex items-end justify-around pb-2 border-b border-border-main"><!-- Columna Ingresos --><div class="flex flex-col items-center w-24"><span class="text-green-500 text-xs font-bold mb-2">${formatCLP(totalIncome, currency)}</span><div class="w-12 bg-green-500 border border-green-700 transition-all duration-500"${addAttribute(`height: ${incomeBarHeight}px;`, "style")}></div><span class="text-xs text-secondary mt-2">${lang === "es" ? "INGRESOS" : "INCOME"}</span></div><!-- Columna Gastos --><div class="flex flex-col items-center w-24"><span class="text-red-500 text-xs font-bold mb-2">${formatCLP(totalExpense, currency)}</span><div class="w-12 bg-red-500 border border-red-700 transition-all duration-500"${addAttribute(`height: ${expenseBarHeight}px;`, "style")}></div><span class="text-xs text-secondary mt-2">${lang === "es" ? "GASTOS" : "EXPENSES"}</span></div></div>`}</div></div><!-- Desglose de Gastos por Categoría (Terminal Style) --><div class="terminal-window m-0"><div class="terminal-header"><span>> chart --group=categories</span></div><div class="terminal-body font-mono text-sm flex flex-col justify-between h-[250px] overflow-y-auto"><h2 class="text-xs uppercase text-secondary mb-4">${lang === "es" ? "[ DISTRIBUCION_DE_GASTOS ]" : "[ EXPENSE_DISTRIBUTION ]"}</h2>${categoryData.length === 0 ? renderTemplate`<div class="flex-1 flex items-center justify-center text-muted-text text-xs border border-dashed border-border-subtle bg-bg">[ NO DATA TO PLOT ]</div>` : renderTemplate`<div class="space-y-3">${categoryData.map((item) => renderTemplate`<div class="space-y-1 text-xs"><div class="flex justify-between"><span>${item.icon} ${item.name}</span><span class="text-secondary">${formatCLP(item.total, currency)} <span class="text-main font-bold">(${item.percent}%)</span></span></div><div class="flex items-center gap-2"><span class="text-accent font-bold">${item.progressBar}</span></div></div>`)}</div>`}</div></div></div>`;
}, "/home/castolo/desarrollos/FinTrack/src/components/FinanceCharts.astro", void 0);
//#endregion
//#region src/pages/index.astro
var pages_exports = /* @__PURE__ */ __exportAll({
	default: () => $$Index,
	file: () => $$file,
	url: () => ""
});
createAstro("https://astro.build");
var $$Index = createComponent(($$result, $$props, $$slots) => {
	const Astro = $$result.createAstro($$props, $$slots);
	Astro.self = $$Index;
	const { lang, t } = getI18n(Astro);
	const currency = Astro.cookies.get("currency")?.value || "CLP";
	const user = Astro.locals.user;
	const netWorth = db.prepare("SELECT SUM(balance) as total FROM accounts").get()?.total || 0;
	const url = Astro.url;
	const selectedPeriod = url.searchParams.get("period") || "month";
	const selectedValue = url.searchParams.get("value") || "";
	const now = /* @__PURE__ */ new Date();
	const currentYear = now.getFullYear();
	const currentMonth = String(now.getMonth() + 1).padStart(2, "0");
	let start = "1970-01-01";
	let end = "9999-12-31";
	let activeMonth = `${currentYear}-${currentMonth}`;
	let activeYear = String(currentYear);
	if (selectedPeriod === "month") {
		const monthValue = selectedValue && /^\d{4}-\d{2}$/.test(selectedValue) ? selectedValue : `${currentYear}-${currentMonth}`;
		activeMonth = monthValue;
		const [y, m] = monthValue.split("-");
		start = `${y}-${m}-01`;
		end = `${y}-${m}-31`;
	} else if (selectedPeriod === "year") {
		const yearValue = selectedValue && /^\d{4}$/.test(selectedValue) ? selectedValue : String(currentYear);
		activeYear = yearValue;
		start = `${yearValue}-01-01`;
		end = `${yearValue}-12-31`;
	} else {
		start = "1970-01-01";
		end = "9999-12-31";
	}
	const startOfMonth = start;
	const endOfMonth = end;
	const monthlyIncome = db.prepare(`
  SELECT SUM(amount) as total FROM transactions 
  WHERE type = 'income' AND date >= ? AND date <= ?
`).get(startOfMonth, endOfMonth)?.total || 0;
	const monthlyExpenses = db.prepare(`
  SELECT SUM(amount) as total FROM transactions 
  WHERE type = 'expense' AND date >= ? AND date <= ?
`).get(startOfMonth, endOfMonth)?.total || 0;
	const savings = monthlyIncome - monthlyExpenses;
	const savingsRate = monthlyIncome > 0 ? Math.round(savings / monthlyIncome * 100) : 0;
	const accounts = db.prepare("SELECT * FROM accounts ORDER BY name ASC").all();
	const recentTransactions = db.prepare(`
  SELECT t.*, a.name as account_name, c.name as category_name, c.icon as category_icon
  FROM transactions t
  JOIN accounts a ON t.account_id = a.id
  JOIN categories c ON t.category_id = c.id
  WHERE t.date >= ? AND t.date <= ?
  ORDER BY t.date DESC, t.created_at DESC
  LIMIT 5
`).all(startOfMonth, endOfMonth);
	const expenseCategories = db.prepare("SELECT * FROM categories WHERE type = 'expense' ORDER BY name ASC").all();
	const incomeCategories = db.prepare("SELECT * FROM categories WHERE type = 'income' ORDER BY name ASC").all();
	return renderTemplate`${renderComponent($$result, "Layout", $$Layout, { "title": "FinTrack - Terminal Dashboard" }, { "default": ($$result) => renderTemplate`${maybeRenderHead($$result)}<div class="flex flex-col md:flex-row min-h-screen"><!-- Sidebar / Panel de Control -->${renderComponent($$result, "Sidebar", $$Sidebar, {
		"active": "dashboard",
		"username": user?.username || "admin"
	})}<!-- Main Content Area --><main class="flex-1 p-6 space-y-6 overflow-y-auto"><!-- Top Title Command & Time Filter --><div class="border-b border-border-subtle pb-4 flex flex-col xl:flex-row xl:items-center xl:justify-between gap-4"><div><h1 class="text-xl font-mono text-main font-bold">${t.systeminfo}</h1><p class="text-xs text-secondary font-mono mt-1">${t.last_update} ${now.toLocaleString()}</p></div><!-- Time Filter Form --><form method="GET" id="filter-form" class="font-mono text-xs flex flex-wrap items-center gap-3"><div class="flex items-center gap-1.5"><label class="text-secondary uppercase">${t.range}</label><select name="period" onchange="document.getElementsByName('value').forEach(el =&gt; el.value = ''); this.form.submit()" class="bg-surface-main border border-border-main text-main p-1.5 focus:outline-none focus:border-accent font-bold cursor-pointer"><option value="month"${addAttribute(selectedPeriod === "month", "selected")}>${t.monthly}</option><option value="year"${addAttribute(selectedPeriod === "year", "selected")}>${t.yearly}</option><option value="total"${addAttribute(selectedPeriod === "total", "selected")}>${t.total}</option></select></div>${selectedPeriod === "month" && renderTemplate`<div class="flex items-center gap-1.5"><label class="text-secondary uppercase">${t.month}</label><input type="month" name="value"${addAttribute(activeMonth, "value")} onchange="this.form.submit()" class="bg-surface-main border border-border-main text-main p-1.5 focus:outline-none focus:border-accent font-bold cursor-pointer"></div>`}${selectedPeriod === "year" && renderTemplate`<div class="flex items-center gap-1.5"><label class="text-secondary uppercase">${t.year}</label><select name="value" onchange="this.form.submit()" class="bg-surface-main border border-border-main text-main p-1.5 focus:outline-none focus:border-accent font-bold cursor-pointer">${[
		currentYear - 2,
		currentYear - 1,
		currentYear,
		currentYear + 1
	].map((y) => renderTemplate`<option${addAttribute(String(y), "value")}${addAttribute(activeYear === String(y), "selected")}>${y}</option>`)}</select></div>`}</form></div><!-- Financial Metrics Grid --><div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 font-mono"><div class="border border-border-main bg-surface-main p-4"><div class="text-xs text-secondary uppercase">${t.net_worth}</div><div class="text-2xl font-bold text-main mt-2">${formatCLP(netWorth, currency)}</div></div><div class="border border-border-main bg-surface-main p-4"><div class="text-xs text-secondary uppercase">${selectedPeriod === "month" ? t.incomes_month : selectedPeriod === "year" ? t.incomes_year : t.incomes_total}</div><div class="text-2xl font-bold text-green-500 mt-2">+${formatCLP(monthlyIncome, currency)}</div></div><div class="border border-border-main bg-surface-main p-4"><div class="text-xs text-secondary uppercase">${selectedPeriod === "month" ? t.expenses_month : selectedPeriod === "year" ? t.expenses_year : t.expenses_total}</div><div class="text-2xl font-bold text-red-500 mt-2">-${formatCLP(monthlyExpenses, currency)}</div></div><div class="border border-border-main bg-surface-main p-4"><div class="text-xs text-secondary uppercase">${t.savings_rate}</div><div${addAttribute(["text-2xl font-bold mt-2", {
		"text-green-500": savingsRate > 0,
		"text-main": savingsRate <= 0
	}], "class:list")}>${savingsRate}%</div></div></div><!-- Charts Section -->${renderComponent($$result, "FinanceCharts", $$FinanceCharts, {
		"startDate": startOfMonth,
		"endDate": endOfMonth
	})}<!-- Interactive Grid: Cuentas y Registro de Datos --><div class="grid grid-cols-1 lg:grid-cols-12 gap-6"><!-- Left Side: Cuentas y Transacciones --><section class="lg:col-span-8 space-y-6"><!-- Cuentas --><div class="terminal-window m-0"><div class="terminal-header"><span>${t.ls_accounts}</span></div><div class="terminal-body font-mono text-sm space-y-4">${accounts.length === 0 ? renderTemplate`<div class="text-secondary p-2 border border-dashed border-border-subtle bg-bg text-center">${t.no_accounts}</div>` : renderTemplate`<div class="grid grid-cols-1 sm:grid-cols-2 gap-4">${accounts.map((acc) => renderTemplate`<div class="border border-border-subtle p-3 bg-bg-subtle flex justify-between items-center"><div><div class="font-bold text-main">${acc.name}</div><div class="text-xs text-secondary uppercase">${acc.type}</div></div><div class="font-bold text-main">${formatCLP(acc.balance, currency)}</div></div>`)}</div>`}</div></div><!-- Transacciones Recientes --><div class="terminal-window m-0"><div class="terminal-header"><span>${t.tail_transactions}</span></div><div class="terminal-body font-mono text-sm">${recentTransactions.length === 0 ? renderTemplate`<div class="text-secondary p-2 border border-dashed border-border-subtle bg-bg text-center">${t.no_transactions}</div>` : renderTemplate`<div class="overflow-x-auto"><table class="w-full text-left border-collapse"><thead><tr class="border-b border-border-main text-secondary text-xs uppercase"><th class="py-2 px-1">${t.table_date}</th><th class="py-2 px-1">${t.table_category}</th><th class="py-2 px-1">${t.table_account}</th><th class="py-2 px-1">${t.table_description}</th><th class="py-2 px-1 text-right">${t.table_amount}</th></tr></thead><tbody class="divide-y divide-border-subtle">${recentTransactions.map((t) => renderTemplate`<tr class="hover:bg-surface-main"><td class="py-2 px-1 text-xs text-secondary whitespace-nowrap">${t.date}</td><td class="py-2 px-1 whitespace-nowrap">${t.category_icon} ${t.category_name}</td><td class="py-2 px-1 text-xs text-secondary">${t.account_name}</td><td class="py-2 px-1">${t.description || "-"}</td><td${addAttribute(`py-2 px-1 text-right font-bold ${t.type === "income" ? "text-green-500" : "text-red-500"}`, "class")}>${t.type === "income" ? "+" : "-"}${formatCLP(t.amount, currency)}</td></tr>`)}</tbody></table></div>`}</div></div></section><!-- Right Side: Formularios Rápidos (Cuentas y Transacciones) --><aside class="lg:col-span-4 space-y-6"><!-- Registrar Transacción --><div class="terminal-window m-0"><div class="terminal-header"><span>${t.write_tx_sh}</span></div><div class="terminal-body font-mono text-xs">${accounts.length === 0 ? renderTemplate`<p class="text-secondary text-center">${t.no_accounts_to_register}</p>` : renderTemplate`<form id="tx-form" class="space-y-3"><div><label class="block text-secondary mb-1">${t.label_type}</label><select id="tx-type" class="w-full bg-surface-main border border-border-main text-main p-2 focus:outline-none focus:border-accent"><option value="expense">${t.option_expense}</option><option value="income">${t.option_income}</option></select></div><div><label class="block text-secondary mb-1">${t.label_account}</label><select id="tx-account" class="w-full bg-surface-main border border-border-main text-main p-2 focus:outline-none focus:border-accent">${accounts.map((acc) => renderTemplate`<option${addAttribute(acc.id, "value")}>${acc.name} (${formatCLP(acc.balance, currency)})</option>`)}</select></div><div><label class="block text-secondary mb-1">${t.label_category}</label><select id="tx-category" class="w-full bg-surface-main border border-border-main text-main p-2 focus:outline-none focus:border-accent">${expenseCategories.map((cat) => renderTemplate`<option${addAttribute(cat.id, "value")}>${cat.icon} ${cat.name}</option>`)}</select></div><div><label class="block text-secondary mb-1">${t.label_amount}</label><input type="number" id="tx-amount" step="0.01" required placeholder="0.00" class="w-full bg-surface-main border border-border-main text-main p-2 focus:outline-none focus:border-accent"></div><div><label class="block text-secondary mb-1">${t.label_date}</label><input type="date" id="tx-date" required class="w-full bg-surface-main border border-border-main text-main p-2 focus:outline-none focus:border-accent"></div><div><label class="block text-secondary mb-1">${t.label_description}</label><input type="text" id="tx-desc" placeholder="Detalles de transacción" class="w-full bg-surface-main border border-border-main text-main p-2 focus:outline-none focus:border-accent"></div><button type="submit" class="w-full bg-border-main hover:bg-accent text-bg hover:text-bg font-bold py-2 transition-colors cursor-pointer">${t.btn_register}</button></form>`}</div></div><!-- Crear Cuenta --><div class="terminal-window m-0"><div class="terminal-header"><span>${t.write_acc_sh}</span></div><div class="terminal-body font-mono text-xs"><form id="account-form" class="space-y-3"><div><label class="block text-secondary mb-1">${t.label_acc_name}</label><input type="text" id="acc-name" required placeholder="ej: Billetera, Banco principal" class="w-full bg-surface-main border border-border-main text-main p-2 focus:outline-none focus:border-accent"></div><div><label class="block text-secondary mb-1">${t.label_acc_type}</label><select id="acc-type" class="w-full bg-surface-main border border-border-main text-main p-2 focus:outline-none focus:border-accent"><option value="cash">${t.option_cash}</option><option value="bank">${t.option_bank}</option><option value="credit_card">${t.option_credit_card}</option><option value="investment">${t.option_investment}</option><option value="other">${t.option_other}</option></select></div><div><label class="block text-secondary mb-1">${t.label_acc_balance}</label><input type="number" id="acc-balance" step="0.01" value="0.00" class="w-full bg-surface-main border border-border-main text-main p-2 focus:outline-none focus:border-accent"></div><button type="submit" class="w-full bg-border-main hover:bg-accent text-bg hover:text-bg font-bold py-2 transition-colors cursor-pointer">${t.btn_create_account}</button></form></div></div></aside></div></main></div>` })}<script>(function(){${defineScriptVars({
		expenseCategories,
		incomeCategories
	})}
  // Poner fecha actual por defecto en el input de fecha
  const dateInput = document.getElementById('tx-date');
  if (dateInput) {
    const today = new Date().toISOString().split('T')[0];
    dateInput.value = today;
  }

  // Dinamizar categorías de transacciones según el tipo (gasto o ingreso)
  const txTypeSelect = document.getElementById('tx-type');
  const txCategorySelect = document.getElementById('tx-category');

  if (txTypeSelect && txCategorySelect) {
    txTypeSelect.addEventListener('change', (e) => {
      const type = e.target.value;
      const categories = type === 'income' ? incomeCategories : expenseCategories;
      
      txCategorySelect.innerHTML = '';
      categories.forEach(cat => {
        const option = document.createElement('option');
        option.value = cat.id;
        option.textContent = \`\${cat.icon} \${cat.name}\`;
        txCategorySelect.appendChild(option);
      });
    });
  }

  // Crear Cuenta
  const accountForm = document.getElementById('account-form');
  if (accountForm) {
    accountForm.addEventListener('submit', async (e) => {
      e.preventDefault();
      const name = document.getElementById('acc-name').value;
      const type = document.getElementById('acc-type').value;
      const balance = parseFloat(document.getElementById('acc-balance').value || '0');

      const match = document.cookie.match(/currency=([^;]+)/);
      const currency = match ? match[1] : 'CLP';

      try {
        const res = await fetch('/api/accounts', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ name, type, balance, currency })
        });
        if (!res.ok) throw new Error('Error al crear la cuenta');
        window.location.reload();
      } catch (err) {
        alert(err.message);
      }
    });
  }

  // Registrar Transacción
  const txForm = document.getElementById('tx-form');
  if (txForm) {
    txForm.addEventListener('submit', async (e) => {
      e.preventDefault();
      const type = document.getElementById('tx-type').value;
      const account_id = document.getElementById('tx-account').value;
      const category_id = document.getElementById('tx-category').value;
      const amount = parseFloat(document.getElementById('tx-amount').value);
      const date = document.getElementById('tx-date').value;
      const description = document.getElementById('tx-desc').value;

      try {
        const res = await fetch('/api/transactions', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ type, account_id, category_id, amount, date, description })
        });
        if (!res.ok) throw new Error('Error al registrar la transacción');
        window.location.reload();
      } catch (err) {
        alert(err.message);
      }
    });
  }
})();<\/script>`;
}, "/home/castolo/desarrollos/FinTrack/src/pages/index.astro", void 0);
var $$file = "/home/castolo/desarrollos/FinTrack/src/pages/index.astro";
//#endregion
//#region \0virtual:astro:page:src/pages/index@_@astro
var page = () => pages_exports;
//#endregion
export { page };
