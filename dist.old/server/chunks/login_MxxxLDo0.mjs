import { t as __exportAll } from "./rolldown-runtime_D7D4PA-g.mjs";
import { D as addAttribute, M as createComponent, S as renderTemplate, T as maybeRenderHead, b as renderComponent, j as createAstro, v as renderScript } from "./render_CHac7bFQ.mjs";
import "./compiler_DiaTUwMm.mjs";
import { n as $$Layout, t as getI18n } from "./i18n_DqAIjw1h.mjs";
//#region src/pages/login.astro
var login_exports = /* @__PURE__ */ __exportAll({
	default: () => $$Login,
	file: () => $$file,
	url: () => $$url
});
createAstro("https://astro.build");
var $$Login = createComponent(($$result, $$props, $$slots) => {
	const Astro = $$result.createAstro($$props, $$slots);
	Astro.self = $$Login;
	const { lang, t } = getI18n(Astro);
	return renderTemplate`${renderComponent($$result, "Layout", $$Layout, { "title": "FinTrack - " + (lang === "es" ? "Iniciar Sesión" : "Login") }, { "default": ($$result) => renderTemplate`${maybeRenderHead($$result)}<main class="flex items-center justify-center min-h-screen p-4"><div class="w-full max-w-md terminal-window"><!-- Terminal Header --><div class="terminal-header"><span>${t.login_title}</span><div class="terminal-buttons"><span class="terminal-button"></span><span class="terminal-button"></span><span class="terminal-button"></span></div></div><!-- Terminal Body --><div class="terminal-body"><h1 class="text-2xl font-bold mb-2 text-main font-mono">${t.login_header}</h1><p class="text-secondary text-sm mb-6 font-mono">${t.login_desc}</p><form id="login-form" class="space-y-4"><div><label for="username" class="block text-xs uppercase font-bold text-secondary mb-1 font-mono">[ ${t.user} ]</label><div class="flex items-center border border-border-main bg-surface-main"><span class="pl-3 pr-1 text-secondary font-mono">></span><input type="text" id="username" name="username" placeholder="admin" required class="w-full bg-transparent border-0 py-2 px-1 focus:ring-0 focus:outline-none text-main font-mono text-sm placeholder:text-muted-text"></div></div><div><label for="password" class="block text-xs uppercase font-bold text-secondary mb-1 font-mono">${t.label_password}</label><div class="flex items-center border border-border-main bg-surface-main"><span class="pl-3 pr-1 text-secondary font-mono">></span><input type="password" id="password" name="password" placeholder="••••••••" required class="w-full bg-transparent border-0 py-2 px-1 focus:ring-0 focus:outline-none text-main font-mono text-sm placeholder:text-muted-text"></div></div><!-- Error Output --><div id="error-output" class="hidden text-red-500 text-xs font-mono border border-red-900 bg-red-950/20 p-2"><!-- Dinámico --></div><!-- Submit Button --><button type="submit" class="w-full bg-border-main hover:bg-accent text-bg hover:text-bg font-bold py-2 font-mono transition-colors text-sm uppercase cursor-pointer">${t.btn_login}</button><!-- Language Switcher in Login --><div class="mt-4 pt-4 border-t border-border-subtle flex justify-between items-center text-[10px] font-mono text-secondary"><span>${t.lang_label}</span><div class="flex gap-1.5"><button type="button" id="btn-lang-es"${addAttribute(`px-1.5 py-0.5 border cursor-pointer transition-colors ${lang === "es" ? "bg-border-main text-bg border-border-main" : "bg-surface-main text-secondary border-border-subtle hover:text-main hover:border-border-main"}`, "class")}>ES</button><button type="button" id="btn-lang-en"${addAttribute(`px-1.5 py-0.5 border cursor-pointer transition-colors ${lang === "en" ? "bg-border-main text-bg border-border-main" : "bg-surface-main text-secondary border-border-subtle hover:text-main hover:border-border-main"}`, "class")}>EN</button></div></div></form></div></div></main>` })}${renderScript($$result, "/home/castolo/desarrollos/FinTrack/src/pages/login.astro?astro&type=script&index=0&lang.ts")}`;
}, "/home/castolo/desarrollos/FinTrack/src/pages/login.astro", void 0);
var $$file = "/home/castolo/desarrollos/FinTrack/src/pages/login.astro";
var $$url = "/login";
//#endregion
//#region \0virtual:astro:page:src/pages/login@_@astro
var page = () => login_exports;
//#endregion
export { page };
