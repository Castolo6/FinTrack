import { t as __exportAll } from "./rolldown-runtime_D7D4PA-g.mjs";
import { D as addAttribute, M as createComponent, S as renderTemplate, T as maybeRenderHead, b as renderComponent, j as createAstro } from "./render_CHac7bFQ.mjs";
import { t as db } from "./db_B6tuQof6.mjs";
import "./compiler_DiaTUwMm.mjs";
import { n as $$Layout, t as getI18n } from "./i18n_DqAIjw1h.mjs";
import { t as $$Sidebar } from "./Sidebar_BCGhOHoz.mjs";
import { t as formatCLP } from "./utils_CLLqVgH_.mjs";
//#region src/pages/charts.astro
var charts_exports = /* @__PURE__ */ __exportAll({
	default: () => $$Charts,
	file: () => $$file,
	url: () => $$url
});
createAstro("https://astro.build");
var $$Charts = createComponent(($$result, $$props, $$slots) => {
	const Astro = $$result.createAstro($$props, $$slots);
	Astro.self = $$Charts;
	const user = Astro.locals.user;
	const { lang, t } = getI18n(Astro);
	const currency = Astro.cookies.get("currency")?.value || "CLP";
	const now = /* @__PURE__ */ new Date();
	const currentYear = now.getFullYear();
	const currentMonth = String(now.getMonth() + 1).padStart(2, "0");
	const startOfMonth = `${currentYear}-${currentMonth}-01`;
	const endOfMonth = `${currentYear}-${currentMonth}-31`;
	const selectedType = Astro.url.searchParams.get("type") === "income" ? "income" : "expense";
	const typeLabel = selectedType === "income" ? lang === "es" ? "INGRESO" : "INFLOW" : lang === "es" ? "GASTO" : "OUTFLOW";
	const dailyTransactionsRaw = db.prepare(`
  SELECT date, SUM(amount) as total
  FROM transactions
  WHERE type = ? AND date >= ? AND date <= ?
  GROUP BY date
  ORDER BY date ASC
`).all(selectedType, startOfMonth, endOfMonth);
	const daysInMonth = new Date(currentYear, now.getMonth() + 1, 0).getDate();
	const dailyData = [];
	for (let d = 1; d <= daysInMonth; d++) {
		const dateStr = `${currentYear}-${currentMonth}-${String(d).padStart(2, "0")}`;
		const found = dailyTransactionsRaw.find((item) => item.date === dateStr);
		dailyData.push({
			day: d,
			total: found ? found.total : 0,
			label: `${d}/${currentMonth}`
		});
	}
	const maxDaily = Math.max(...dailyData.map((d) => d.total)) || 1;
	const dailyPath = dailyData.map((d, i) => {
		const x = i / (daysInMonth - 1) * 560 + 20;
		const y = 130 - d.total / maxDaily * 110;
		return `${i === 0 ? "M" : "L"} ${x} ${y}`;
	}).join(" ");
	const dailyAreaPath = dailyPath ? `${dailyPath} L 580 130 L 20 130 Z` : "";
	const weeklyData = [
		{
			label: lang === "es" ? "Semana 1 (1-7)" : "Week 1 (1-7)",
			total: 0
		},
		{
			label: lang === "es" ? "Semana 2 (8-14)" : "Week 2 (8-14)",
			total: 0
		},
		{
			label: lang === "es" ? "Semana 3 (15-21)" : "Week 3 (15-21)",
			total: 0
		},
		{
			label: lang === "es" ? "Semana 4 (22-31)" : "Week 4 (22-31)",
			total: 0
		}
	];
	for (const d of dailyData) if (d.day <= 7) weeklyData[0].total += d.total;
	else if (d.day <= 14) weeklyData[1].total += d.total;
	else if (d.day <= 21) weeklyData[2].total += d.total;
	else weeklyData[3].total += d.total;
	const maxWeekly = Math.max(...weeklyData.map((w) => w.total)) || 1;
	const monthlyTransactionsRaw = db.prepare(`
  SELECT strftime('%m', date) as month, SUM(amount) as total
  FROM transactions
  WHERE type = ? AND strftime('%Y', date) = ?
  GROUP BY month
  ORDER BY month ASC
`).all(selectedType, String(currentYear));
	const monthlyData = (lang === "es" ? [
		"Ene",
		"Feb",
		"Mar",
		"Abr",
		"May",
		"Jun",
		"Jul",
		"Ago",
		"Sep",
		"Oct",
		"Nov",
		"Dic"
	] : [
		"Jan",
		"Feb",
		"Mar",
		"Apr",
		"May",
		"Jun",
		"Jul",
		"Aug",
		"Sep",
		"Oct",
		"Nov",
		"Dec"
	]).map((name, i) => {
		const monthNum = String(i + 1).padStart(2, "0");
		const found = monthlyTransactionsRaw.find((m) => m.month === monthNum);
		return {
			label: name,
			total: found ? found.total : 0
		};
	});
	const maxMonthly = Math.max(...monthlyData.map((m) => m.total)) || 1;
	return renderTemplate`${renderComponent($$result, "Layout", $$Layout, { "title": "FinTrack - " + (selectedType === "income" ? lang === "es" ? "Evolución de Ingresos" : "Income Evolution" : lang === "es" ? "Evolución de Gastos" : "Expense Evolution") }, { "default": ($$result) => renderTemplate`${maybeRenderHead($$result)}<div class="flex flex-col md:flex-row min-h-screen"><!-- Sidebar / Panel de Control -->${renderComponent($$result, "Sidebar", $$Sidebar, {
		"active": "charts",
		"username": user?.username || "admin"
	})}<!-- Main Content Area --><main class="flex-1 p-6 space-y-6 overflow-y-auto font-mono"><!-- Top Title Command & Tabs --><div class="border-b border-border-subtle pb-4 flex flex-col xl:flex-row xl:items-center xl:justify-between gap-4"><div><h1 class="text-xl text-main font-bold">> chart --analyze --evolution --type=${selectedType}</h1><p class="text-xs text-secondary mt-1">${lang === "es" ? `Evolución de ${selectedType === "income" ? "ingresos" : "egresos"} y comportamiento de ${selectedType === "income" ? "entradas" : "gastos"}.` : `Evolution of ${selectedType === "income" ? "incomes" : "outflows"} and behavior of ${selectedType === "income" ? "inflows" : "expenses"}.`}</p></div><!-- Pestañas de Selección de Gastos / Ingresos --><div class="flex gap-2 text-xs font-bold font-mono"><a href="?type=expense"${addAttribute(`px-3 py-1.5 border transition-colors ${selectedType === "expense" ? "bg-border-main text-bg border-border-main" : "border-border-main text-main hover:bg-surface-main"}`, "class")}>${t.chart_gastos}</a><a href="?type=income"${addAttribute(`px-3 py-1.5 border transition-colors ${selectedType === "income" ? "bg-border-main text-bg border-border-main" : "border-border-main text-main hover:bg-surface-main"}`, "class")}>${t.chart_ingresos}</a></div></div><!-- Grid de Gráficos --><div class="space-y-6"><!-- 1. Gráfico Diario (Mes en Curso) --><div class="terminal-window m-0"><div class="terminal-header"><span>${`> chart --period=daily --view=line --type=${selectedType}`}</span></div><div class="terminal-body space-y-4"><h2 class="text-xs uppercase text-secondary">${lang === "es" ? `[ ${typeLabel}_DIARIO_DEL_MES ]` : `[ MONTHLY_DAILY_${typeLabel} ]`}</h2>${maxDaily === 1 ? renderTemplate`<div class="h-[180px] flex items-center justify-center text-muted-text text-xs border border-dashed border-border-subtle bg-bg">[ NO DATA TO PLOT ]</div>` : renderTemplate`<div class="relative bg-bg border border-border-subtle p-4"><svg viewBox="0 0 600 150" class="w-full h-[180px] overflow-visible"><!-- Líneas guía horizontales --><line x1="20" y1="20" x2="580" y2="20" stroke="#0a4a44" stroke-dasharray="2"></line><line x1="20" y1="75" x2="580" y2="75" stroke="#0a4a44" stroke-dasharray="2"></line><line x1="20" y1="130" x2="580" y2="130" stroke="#0a4a44"></line><!-- Relleno de área de gráfico -->${dailyAreaPath && renderTemplate`<path${addAttribute(dailyAreaPath, "d")} fill="url(#area-gradient)" opacity="0.15"></path>`}<!-- Línea de trazado -->${dailyPath && renderTemplate`<path${addAttribute(dailyPath, "d")} fill="none" stroke="#1dc7b5" stroke-width="2"></path>`}<!-- Puntos del gráfico -->${dailyData.map((d, i) => {
		if (d.total === 0) return null;
		const x = i / (daysInMonth - 1) * 560 + 20;
		const y = 130 - d.total / maxDaily * 110;
		return renderTemplate`<g class="group cursor-pointer"><circle${addAttribute(x, "cx")}${addAttribute(y, "cy")} r="4" fill="#080c14" stroke="#1dc7b5" stroke-width="2"></circle><title>${lang === "es" ? `Día ${d.day}: ${formatCLP(d.total, currency)}` : `Day ${d.day}: ${formatCLP(d.total, currency)}`}</title></g>`;
	})}<!-- Grado de Área Definición --><defs><linearGradient id="area-gradient" x1="0" y1="0" x2="0" y2="1"><stop offset="0%" stop-color="#1dc7b5"></stop><stop offset="100%" stop-color="#080c14"></stop></linearGradient></defs></svg><div class="flex justify-between text-[10px] text-secondary mt-2 px-4 border-t border-border-subtle pt-2"><span>${lang === "es" ? "Día 1" : "Day 1"}</span><span>${lang === "es" ? `Día ${Math.round(daysInMonth / 2)}` : `Day ${Math.round(daysInMonth / 2)}`}</span><span>${lang === "es" ? `Día ${daysInMonth}` : `Day ${daysInMonth}`}</span></div></div>`}</div></div><!-- 2. Gráfico Semanal y Mensual en 2 Columnas --><div class="grid grid-cols-1 lg:grid-cols-2 gap-6"><!-- Semanal (Mes en Curso) --><div class="terminal-window m-0"><div class="terminal-header"><span>${`> chart --period=weekly --view=bar --type=${selectedType}`}</span></div><div class="terminal-body space-y-4 h-[250px] flex flex-col justify-between"><h2 class="text-xs uppercase text-secondary">${lang === "es" ? `[ ${typeLabel}_SEMANAL ]` : `[ WEEKLY_${typeLabel} ]`}</h2>${maxWeekly === 1 ? renderTemplate`<div class="flex-1 flex items-center justify-center text-muted-text text-xs border border-dashed border-border-subtle bg-bg">[ NO DATA TO PLOT ]</div>` : renderTemplate`<div class="flex-1 flex items-end justify-around pb-2 border-b border-border-subtle">${weeklyData.map((w) => {
		const barHeight = Math.round(w.total / maxWeekly * 120);
		return renderTemplate`<div class="flex flex-col items-center w-20"><span class="text-[10px] text-main font-bold mb-1">${formatCLP(w.total, currency)}</span><div class="w-8 bg-accent border border-border-main"${addAttribute(`height: ${barHeight}px;`, "style")}></div><span class="text-[9px] text-secondary text-center mt-2 whitespace-nowrap">${w.label}</span></div>`;
	})}</div>`}</div></div><!-- Mensual (Año en Curso) --><div class="terminal-window m-0"><div class="terminal-header"><span>${`> chart --period=monthly --view=bar --type=${selectedType}`}</span></div><div class="terminal-body space-y-4 h-[250px] flex flex-col justify-between"><h2 class="text-xs uppercase text-secondary">${lang === "es" ? `[ ${typeLabel}_MENSUAL_DEL_AÑO ]` : `[ YEARLY_${typeLabel} ]`}</h2>${maxMonthly === 1 ? renderTemplate`<div class="flex-1 flex items-center justify-center text-muted-text text-xs border border-dashed border-border-subtle bg-bg">[ NO DATA TO PLOT ]</div>` : renderTemplate`<div class="flex-1 flex items-end justify-between pb-1 border-b border-border-subtle overflow-x-auto"><div class="min-w-[400px] flex items-end justify-between h-full">${monthlyData.map((m) => {
		const barHeight = Math.round(m.total / maxMonthly * 120);
		return renderTemplate`<div class="flex flex-col items-center w-7">${m.total > 0 && renderTemplate`<span class="text-[8px] text-main font-bold mb-1 rotation-text select-none">${Math.round(m.total / 1e3)}k</span>`}<div class="w-4 bg-secondary border border-border-subtle"${addAttribute(`height: ${barHeight}px;`, "style")}></div><span class="text-[9px] text-secondary mt-1">${m.label}</span></div>`;
	})}</div></div>`}</div></div></div></div></main></div>` })}`;
}, "/home/castolo/desarrollos/FinTrack/src/pages/charts.astro", void 0);
var $$file = "/home/castolo/desarrollos/FinTrack/src/pages/charts.astro";
var $$url = "/charts";
//#endregion
//#region \0virtual:astro:page:src/pages/charts@_@astro
var page = () => charts_exports;
//#endregion
export { page };
