import { t as __exportAll } from "./rolldown-runtime_D7D4PA-g.mjs";
import { M as createComponent, S as renderTemplate, T as maybeRenderHead, b as renderComponent, j as createAstro, v as renderScript } from "./render_CHac7bFQ.mjs";
import "./compiler_DiaTUwMm.mjs";
import { n as $$Layout, t as getI18n } from "./i18n_DqAIjw1h.mjs";
import { t as $$Sidebar } from "./Sidebar_BCGhOHoz.mjs";
//#region src/pages/settings.astro
var settings_exports = /* @__PURE__ */ __exportAll({
	default: () => $$Settings,
	file: () => $$file,
	url: () => $$url
});
createAstro("https://astro.build");
var $$Settings = createComponent(($$result, $$props, $$slots) => {
	const Astro = $$result.createAstro($$props, $$slots);
	Astro.self = $$Settings;
	const user = Astro.locals.user;
	const { lang, t } = getI18n(Astro);
	return renderTemplate`${renderComponent($$result, "Layout", $$Layout, { "title": "FinTrack - " + (lang === "es" ? "Respaldos" : "Backups") }, { "default": ($$result) => renderTemplate`${maybeRenderHead($$result)}<div class="flex flex-col md:flex-row min-h-screen"><!-- Sidebar / Panel de Control -->${renderComponent($$result, "Sidebar", $$Sidebar, {
		"active": "settings",
		"username": user?.username || "admin"
	})}<!-- Main Content Area --><main class="flex-1 p-6 space-y-6 overflow-y-auto"><!-- Top Title Command --><div class="border-b border-border-subtle pb-4"><h1 class="text-xl font-mono text-main font-bold">${t.settings_title}</h1><p class="text-xs text-secondary font-mono mt-1">${t.settings_subtitle}</p></div><!-- Panels Grid --><div class="grid grid-cols-1 md:grid-cols-2 gap-6"><!-- Export Panel --><div class="terminal-window m-0"><div class="terminal-header"><span>${`> export --database=sqlite`}</span></div><div class="terminal-body font-mono text-sm space-y-4"><h2 class="text-lg font-bold text-main">${lang === "es" ? "Exportar Respaldo" : "Export Backup"}</h2><p class="text-secondary text-xs">${lang === "es" ? "Descarga una copia completa de tus finanzas en formato JSON. Esta copia incluye tus usuarios, cuentas, categorías registradas, transacciones y presupuestos." : "Download a complete copy of your finances in JSON format. This copy includes your users, accounts, registered categories, transactions, and budgets."}</p><a href="/api/backup/export" download class="inline-block text-center bg-border-main hover:bg-accent text-bg hover:text-bg font-bold py-2 px-4 font-mono transition-colors text-xs uppercase cursor-pointer">${lang === "es" ? "[ DESCARGAR_RESPALDO_JSON ]" : "[ DOWNLOAD_JSON_BACKUP ]"}</a></div></div><!-- Import Panel --><div class="terminal-window m-0"><div class="terminal-header"><span>${`> import --file=fintrack_backup.json`}</span></div><div class="terminal-body font-mono text-sm space-y-4"><h2 class="text-lg font-bold text-main">${lang === "es" ? "Restaurar Respaldo" : "Restore Backup"}</h2><p class="text-secondary text-xs">${lang === "es" ? "Sube un archivo de respaldo JSON previamente exportado. PRECAUCIÓN: Esto sobrescribirá y reemplazará todos tus datos financieros actuales de forma permanente." : "Upload a previously exported JSON backup file. CAUTION: This will overwrite and replace all your current financial data permanently."}</p><form id="restore-form" class="space-y-4"><div class="border border-dashed border-border-main p-4 bg-surface-main text-center cursor-pointer relative hover:border-accent"><input type="file" id="backup-file" accept=".json" required class="absolute inset-0 w-full h-full opacity-0 cursor-pointer"><span id="file-label" class="text-xs text-secondary font-mono">${lang === "es" ? "Seleccionar archivo .json" : "Select .json file"}</span></div><!-- Status Output --><div id="status-output" class="hidden text-xs p-2 border"></div><button type="submit" class="w-full bg-red-950/20 hover:bg-red-800 border border-red-900 text-red-500 hover:text-bg font-bold py-2 font-mono transition-colors text-xs uppercase cursor-pointer">${lang === "es" ? "[ EJECUTAR_RESTAURACION ]" : "[ EXECUTE_RESTORE ]"}</button></form></div></div></div></main></div>` })}${renderScript($$result, "/home/castolo/desarrollos/FinTrack/src/pages/settings.astro?astro&type=script&index=0&lang.ts")}`;
}, "/home/castolo/desarrollos/FinTrack/src/pages/settings.astro", void 0);
var $$file = "/home/castolo/desarrollos/FinTrack/src/pages/settings.astro";
var $$url = "/settings";
//#endregion
//#region \0virtual:astro:page:src/pages/settings@_@astro
var page = () => settings_exports;
//#endregion
export { page };
