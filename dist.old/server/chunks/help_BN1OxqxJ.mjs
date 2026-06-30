import { t as __exportAll } from "./rolldown-runtime_D7D4PA-g.mjs";
import { M as createComponent, S as renderTemplate, T as maybeRenderHead, b as renderComponent, j as createAstro } from "./render_CHac7bFQ.mjs";
import "./compiler_DiaTUwMm.mjs";
import { n as $$Layout, t as getI18n } from "./i18n_DqAIjw1h.mjs";
import { t as $$Sidebar } from "./Sidebar_BCGhOHoz.mjs";
//#region src/pages/help.astro
var help_exports = /* @__PURE__ */ __exportAll({
	default: () => $$Help,
	file: () => $$file,
	url: () => $$url
});
createAstro("https://astro.build");
var $$Help = createComponent(($$result, $$props, $$slots) => {
	const Astro = $$result.createAstro($$props, $$slots);
	Astro.self = $$Help;
	const user = Astro.locals.user;
	const { lang, t } = getI18n(Astro);
	return renderTemplate`${renderComponent($$result, "Layout", $$Layout, { "title": "FinTrack - " + (lang === "es" ? "Ayuda" : "Help") }, { "default": ($$result) => renderTemplate`${maybeRenderHead($$result)}<div class="flex flex-col md:flex-row min-h-screen"><!-- Sidebar / Panel de Control -->${renderComponent($$result, "Sidebar", $$Sidebar, {
		"active": "help",
		"username": user?.username || "admin"
	})}<!-- Main Content Area --><main class="flex-1 p-6 space-y-6 overflow-y-auto"><!-- Top Title Command --><div class="border-b border-border-subtle pb-4"><h1 class="text-xl font-mono text-main font-bold">${t.help_man}</h1><p class="text-xs text-secondary font-mono mt-1">${t.help_subtitle}</p></div><!-- General Info Panel --><div class="border border-border-main p-4 bg-surface-main space-y-2 text-xs font-mono"><div class="text-main font-bold">${t.help_system_title}</div><p class="text-secondary leading-relaxed">${t.help_system_desc}</p></div><!-- Modules Documentation Grid --><div class="space-y-6 font-mono"><!-- Dashboard --><div class="terminal-window m-0"><div class="terminal-header"><span>> help --dashboard</span><span class="text-muted-text">${t.module} 1 ${t.of} 7</span></div><div class="terminal-body text-sm space-y-3"><h2 class="text-main font-bold text-base">${t.help_dashboard_title}</h2><p class="text-secondary leading-relaxed">${t.help_dashboard_desc}</p><ul class="list-disc pl-5 space-y-1 text-xs text-secondary">${t.help_dashboard_items.map((item) => renderTemplate`<li>${item}</li>`)}</ul></div></div><!-- Transacciones --><div class="terminal-window m-0"><div class="terminal-header"><span>> help --transactions</span><span class="text-muted-text">${t.module} 2 ${t.of} 7</span></div><div class="terminal-body text-sm space-y-3"><h2 class="text-main font-bold text-base">${t.help_transactions_title}</h2><p class="text-secondary leading-relaxed">${t.help_transactions_desc}</p><ul class="list-disc pl-5 space-y-1 text-xs text-secondary">${t.help_transactions_items.map((item) => renderTemplate`<li>${item}</li>`)}</ul></div></div><!-- Presupuestos --><div class="terminal-window m-0"><div class="terminal-header"><span>> help --budgets</span><span class="text-muted-text">${t.module} 3 ${t.of} 7</span></div><div class="terminal-body text-sm space-y-3"><h2 class="text-main font-bold text-base">${t.help_budgets_title}</h2><p class="text-secondary leading-relaxed">${t.help_budgets_desc}</p><ul class="list-disc pl-5 space-y-1 text-xs text-secondary">${t.help_budgets_items.map((item) => renderTemplate`<li>${item}</li>`)}</ul></div></div><!-- Graficas --><div class="terminal-window m-0"><div class="terminal-header"><span>> help --charts</span><span class="text-muted-text">${t.module} 4 ${t.of} 7</span></div><div class="terminal-body text-sm space-y-3"><h2 class="text-main font-bold text-base">${t.help_charts_title}</h2><p class="text-secondary leading-relaxed">${t.help_charts_desc}</p><ul class="list-disc pl-5 space-y-1 text-xs text-secondary">${t.help_charts_items.map((item) => renderTemplate`<li>${item}</li>`)}</ul></div></div><!-- Objetivos --><div class="terminal-window m-0"><div class="terminal-header"><span>> help --goals</span><span class="text-muted-text">${t.module} 5 ${t.of} 7</span></div><div class="terminal-body text-sm space-y-3"><h2 class="text-main font-bold text-base">${t.help_goals_title}</h2><p class="text-secondary leading-relaxed">${t.help_goals_desc}</p><ul class="list-disc pl-5 space-y-1 text-xs text-secondary">${t.help_goals_items.map((item) => renderTemplate`<li>${item}</li>`)}</ul></div></div><!-- Analisis --><div class="terminal-window m-0"><div class="terminal-header"><span>> help --analysis</span><span class="text-muted-text">${t.module} 6 ${t.of} 7</span></div><div class="terminal-body text-sm space-y-3"><h2 class="text-main font-bold text-base">${t.help_analysis_title}</h2><p class="text-secondary leading-relaxed">${t.help_analysis_desc}</p><ul class="list-disc pl-5 space-y-1 text-xs text-secondary">${t.help_analysis_items.map((item) => renderTemplate`<li>${item}</li>`)}</ul></div></div><!-- Respaldos --><div class="terminal-window m-0"><div class="terminal-header"><span>> help --settings</span><span class="text-muted-text">${t.module} 7 ${t.of} 7</span></div><div class="terminal-body text-sm space-y-3"><h2 class="text-main font-bold text-base">${t.help_settings_title}</h2><p class="text-secondary leading-relaxed">${t.help_settings_desc}</p><ul class="list-disc pl-5 space-y-1 text-xs text-secondary">${t.help_settings_items.map((item) => renderTemplate`<li>${item}</li>`)}</ul></div></div></div></main></div>` })}`;
}, "/home/castolo/desarrollos/FinTrack/src/pages/help.astro", void 0);
var $$file = "/home/castolo/desarrollos/FinTrack/src/pages/help.astro";
var $$url = "/help";
//#endregion
//#region \0virtual:astro:page:src/pages/help@_@astro
var page = () => help_exports;
//#endregion
export { page };
