import { t as __exportAll } from "./rolldown-runtime_D7D4PA-g.mjs";
import { D as addAttribute, M as createComponent, S as renderTemplate, T as maybeRenderHead, b as renderComponent, j as createAstro, v as renderScript } from "./render_CHac7bFQ.mjs";
import { t as db } from "./db_B6tuQof6.mjs";
import "./compiler_DiaTUwMm.mjs";
import { n as $$Layout, t as getI18n } from "./i18n_DqAIjw1h.mjs";
import { t as $$Sidebar } from "./Sidebar_BCGhOHoz.mjs";
import { t as formatCLP } from "./utils_CLLqVgH_.mjs";
//#region src/pages/budgets.astro
var budgets_exports = /* @__PURE__ */ __exportAll({
	default: () => $$Budgets,
	file: () => $$file,
	url: () => $$url
});
createAstro("https://astro.build");
var $$Budgets = createComponent(($$result, $$props, $$slots) => {
	const Astro = $$result.createAstro($$props, $$slots);
	Astro.self = $$Budgets;
	const user = Astro.locals.user;
	const { lang, t } = getI18n(Astro);
	const currency = Astro.cookies.get("currency")?.value || "CLP";
	const now = /* @__PURE__ */ new Date();
	const currentYear = now.getFullYear();
	const currentMonth = String(now.getMonth() + 1).padStart(2, "0");
	const startOfMonth = `${currentYear}-${currentMonth}-01`;
	const endOfMonth = `${currentYear}-${currentMonth}-31`;
	const budgets = db.prepare(`
  SELECT b.id, b.amount as budget_limit, c.name as category_name, c.icon as category_icon, c.id as category_id
  FROM budgets b
  JOIN categories c ON b.category_id = c.id
  WHERE b.start_date = ?
`).all(startOfMonth).map((b) => {
		const spent = db.prepare(`
    SELECT SUM(amount) as total FROM transactions 
    WHERE category_id = ? AND type = 'expense' AND date >= ? AND date <= ?
  `).get(b.category_id, startOfMonth, endOfMonth)?.total || 0;
		const percent = b.budget_limit > 0 ? Math.min(100, Math.round(spent / b.budget_limit * 100)) : 0;
		const bars = Math.min(10, Math.max(0, Math.round(percent / 10)));
		const progress_bar = "[" + "█".repeat(bars) + "░".repeat(10 - bars) + "]";
		return {
			...b,
			spent,
			percent,
			progress_bar
		};
	});
	const allExpenseCategories = db.prepare(`
  SELECT id, name, icon FROM categories WHERE type = 'expense' ORDER BY name ASC
`).all();
	return renderTemplate`${renderComponent($$result, "Layout", $$Layout, { "title": "FinTrack - " + (lang === "es" ? "Presupuestos" : "Budgets") }, { "default": ($$result) => renderTemplate`${maybeRenderHead($$result)}<div class="flex flex-col md:flex-row min-h-screen"><!-- Sidebar / Panel de Control -->${renderComponent($$result, "Sidebar", $$Sidebar, {
		"active": "budgets",
		"username": user?.username || "admin"
	})}<!-- Main Content Area --><main class="flex-1 p-6 space-y-6 overflow-y-auto font-mono"><!-- Top Title Command --><div class="border-b border-border-subtle pb-4"><h1 class="text-xl text-main font-bold">${t.cat_budgets}</h1><p class="text-xs text-secondary mt-1">${t.budgets_subtitle}</p></div><div class="grid grid-cols-1 lg:grid-cols-12 gap-6"><!-- Left Side: Lista de Presupuestos --><section class="lg:col-span-8 space-y-6"><div class="terminal-window m-0"><div class="terminal-header"><span>fintrack — budgets_status.log — ${budgets.length} ${lang === "es" ? "activos" : "active"}</span></div><div class="terminal-body space-y-6">${budgets.length === 0 ? renderTemplate`<div class="text-secondary p-2 border border-dashed border-border-subtle bg-bg text-center text-sm">${lang === "es" ? "No se han configurado presupuestos mensuales. Utiliza el formulario de la derecha para definir tu primer límite." : "No monthly budgets configured. Use the form on the right to set your first limit."}</div>` : renderTemplate`<div class="space-y-4">${budgets.map((b) => renderTemplate`<div class="border border-border-subtle p-4 bg-bg-subtle text-sm"><div class="flex justify-between font-bold mb-2"><span class="text-main">${b.category_icon} ${b.category_name}</span><span class="text-secondary">${formatCLP(b.spent, currency)} / <span class="text-main">${formatCLP(b.budget_limit, currency)}</span></span></div><div class="flex items-center gap-4 text-xs font-mono"><span class="text-accent">${b.progress_bar}</span><span${addAttribute(b.percent >= 100 ? "text-red-500 font-bold" : b.percent >= 80 ? "text-yellow-500" : "text-green-500", "class")}>${b.percent}% ${b.percent >= 100 ? lang === "es" ? "[EXCEDIDO]" : "[EXCEEDED]" : ""}</span></div></div>`)}</div>`}</div></div></section><!-- Right Side: Configurar Presupuesto --><aside class="lg:col-span-4 space-y-6"><div class="terminal-window m-0"><div class="terminal-header"><span>${t.write_budget_sh}</span></div><div class="terminal-body text-xs space-y-3"><form id="budget-form" class="space-y-3"><div><label class="block text-secondary mb-1">${t.label_category}</label><select id="budget-category" class="w-full bg-surface-main border border-border-main text-main p-2 focus:outline-none focus:border-accent">${allExpenseCategories.map((cat) => renderTemplate`<option${addAttribute(cat.id, "value")}>${cat.icon} ${cat.name}</option>`)}</select></div><div><label class="block text-secondary mb-1">${lang === "es" ? "LÍMITE MENSUAL" : "MONTHLY LIMIT"}</label><input type="number" id="budget-amount" step="0.01" required placeholder="0.00" class="w-full bg-surface-main border border-border-main text-main p-2 focus:outline-none focus:border-accent"></div><button type="submit" class="w-full bg-border-main hover:bg-accent text-bg hover:text-bg font-bold py-2 transition-colors cursor-pointer">${t.btn_set}</button></form></div></div></aside></div></main></div>` })}${renderScript($$result, "/home/castolo/desarrollos/FinTrack/src/pages/budgets.astro?astro&type=script&index=0&lang.ts")}`;
}, "/home/castolo/desarrollos/FinTrack/src/pages/budgets.astro", void 0);
var $$file = "/home/castolo/desarrollos/FinTrack/src/pages/budgets.astro";
var $$url = "/budgets";
//#endregion
//#region \0virtual:astro:page:src/pages/budgets@_@astro
var page = () => budgets_exports;
//#endregion
export { page };
