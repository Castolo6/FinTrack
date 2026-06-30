import { t as __exportAll } from "./rolldown-runtime_D7D4PA-g.mjs";
import { D as addAttribute, M as createComponent, S as renderTemplate, T as maybeRenderHead, b as renderComponent, j as createAstro, v as renderScript } from "./render_CHac7bFQ.mjs";
import { t as db } from "./db_B6tuQof6.mjs";
import "./compiler_DiaTUwMm.mjs";
import { n as $$Layout, t as getI18n } from "./i18n_DqAIjw1h.mjs";
import { t as $$Sidebar } from "./Sidebar_BCGhOHoz.mjs";
import { t as formatCLP } from "./utils_CLLqVgH_.mjs";
//#region src/pages/transactions.astro
var transactions_exports = /* @__PURE__ */ __exportAll({
	default: () => $$Transactions,
	file: () => $$file,
	url: () => $$url
});
createAstro("https://astro.build");
var $$Transactions = createComponent(($$result, $$props, $$slots) => {
	const Astro = $$result.createAstro($$props, $$slots);
	Astro.self = $$Transactions;
	const user = Astro.locals.user;
	const { lang, t } = getI18n(Astro);
	const currency = Astro.cookies.get("currency")?.value || "CLP";
	const accounts = db.prepare("SELECT id, name FROM accounts ORDER BY name ASC").all();
	const transactions = db.prepare(`
  SELECT t.*, a.name as account_name, c.name as category_name, c.icon as category_icon
  FROM transactions t
  JOIN accounts a ON t.account_id = a.id
  JOIN categories c ON t.category_id = c.id
  ORDER BY t.date DESC, t.created_at DESC
`).all();
	return renderTemplate`${renderComponent($$result, "Layout", $$Layout, { "title": "FinTrack - " + (lang === "es" ? "Registro de Transacciones" : "Transactions Log") }, { "default": ($$result) => renderTemplate`${maybeRenderHead($$result)}<div class="flex flex-col md:flex-row min-h-screen"><!-- Sidebar / Panel de Control -->${renderComponent($$result, "Sidebar", $$Sidebar, {
		"active": "transactions",
		"username": user?.username || "admin"
	})}<!-- Main Content Area --><main class="flex-1 p-6 space-y-6 overflow-y-auto font-mono"><!-- Top Title Command --><div class="border-b border-border-subtle pb-4"><h1 class="text-xl text-main font-bold">${t.grep_transactions}</h1><p class="text-xs text-secondary mt-1">${t.transactions_subtitle}</p></div><!-- Filter Controls (Terminal Style) --><div class="border border-border-main p-4 bg-surface-main space-y-3"><div class="text-xs text-secondary font-bold">${lang === "es" ? "[ FILTRAR_LOGS ]" : "[ FILTER_LOGS ]"}</div><div class="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-5 gap-4 text-xs"><div><label class="block text-secondary mb-1">${lang === "es" ? "BUSCADOR" : "SEARCH"}</label><input type="text" id="filter-search"${addAttribute(t.search_placeholder, "placeholder")} class="w-full bg-bg border border-border-main text-main p-2 focus:outline-none focus:border-accent"></div><div><label class="block text-secondary mb-1">${t.label_type}</label><select id="filter-type" class="w-full bg-bg border border-border-main text-main p-2 focus:outline-none focus:border-accent"><option value="all">${lang === "es" ? "TODOS (*)" : "ALL (*)"}</option><option value="expense">${t.option_expense}</option><option value="income">${t.option_income}</option></select></div><div><label class="block text-secondary mb-1">${t.label_account}</label><select id="filter-account" class="w-full bg-bg border border-border-main text-main p-2 focus:outline-none focus:border-accent"><option value="all">${lang === "es" ? "TODAS (*)" : "ALL (*)"}</option>${accounts.map((acc) => renderTemplate`<option${addAttribute(acc.name, "value")}>${acc.name}</option>`)}</select></div><div><label class="block text-secondary mb-1">${lang === "es" ? "MES" : "MONTH"}</label><input type="month" id="filter-month" class="w-full bg-bg border border-border-main text-main p-2 focus:outline-none focus:border-accent cursor-pointer"></div><div class="flex items-end"><button id="clear-filters" class="w-full bg-bg-subtle hover:bg-border-main border border-border-main text-secondary hover:text-bg font-bold py-2 transition-colors cursor-pointer uppercase">${lang === "es" ? "[ LIMPIAR_FILTROS ]" : "[ CLEAR_FILTERS ]"}</button></div></div></div><!-- Transactions Log Window --><div class="terminal-window m-0"><div class="terminal-header"><span>fintrack — transactions.log — <span id="visible-count">${transactions.length}</span> / ${transactions.length} ${lang === "es" ? "registros" : "records"}</span></div><div class="terminal-body font-mono text-sm p-0"><div class="overflow-x-auto"><table class="w-full text-left border-collapse"><thead><tr class="border-b border-border-main text-secondary text-xs uppercase bg-bg-subtle"><th class="py-3 px-4">${t.table_date}</th><th class="py-3 px-4">${t.label_category}</th><th class="py-3 px-4">${t.table_account}</th><th class="py-3 px-4">${t.table_description}</th><th class="py-3 px-4 text-right">${t.table_amount}</th><th class="py-3 px-4 text-center">${t.action}</th></tr></thead><tbody id="transactions-table-body" class="divide-y divide-border-subtle">${transactions.map((t) => renderTemplate`<tr class="hover:bg-surface-main transaction-row"${addAttribute(t.type, "data-type")}${addAttribute(t.account_name, "data-account")}${addAttribute(t.description || "", "data-desc")}${addAttribute(t.date, "data-date")}><td class="py-2 px-4 text-xs text-secondary whitespace-nowrap">${t.date}</td><td class="py-2 px-4 whitespace-nowrap">${t.category_icon} ${t.category_name}</td><td class="py-2 px-4 text-xs text-secondary">${t.account_name}</td><td class="py-2 px-4 transaction-desc">${t.description || "-"}</td><td${addAttribute(`py-2 px-4 text-right font-bold whitespace-nowrap ${t.type === "income" ? "text-green-500" : "text-red-500"}`, "class")}>${t.type === "income" ? "+" : "-"}${formatCLP(t.amount, currency)}</td><td class="py-2 px-4 text-center"><button class="delete-btn text-xs text-red-500 hover:text-red-300 font-bold underline cursor-pointer bg-transparent border-0"${addAttribute(t.id, "data-id")}>${t.delete}</button></td></tr>`)}</tbody></table></div></div></div></main></div>` })}${renderScript($$result, "/home/castolo/desarrollos/FinTrack/src/pages/transactions.astro?astro&type=script&index=0&lang.ts")}`;
}, "/home/castolo/desarrollos/FinTrack/src/pages/transactions.astro", void 0);
var $$file = "/home/castolo/desarrollos/FinTrack/src/pages/transactions.astro";
var $$url = "/transactions";
//#endregion
//#region \0virtual:astro:page:src/pages/transactions@_@astro
var page = () => transactions_exports;
//#endregion
export { page };
