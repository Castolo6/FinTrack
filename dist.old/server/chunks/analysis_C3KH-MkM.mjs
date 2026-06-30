import { t as __exportAll } from "./rolldown-runtime_D7D4PA-g.mjs";
import { M as createComponent, O as defineScriptVars, S as renderTemplate, T as maybeRenderHead, b as renderComponent, j as createAstro } from "./render_CHac7bFQ.mjs";
import { t as db } from "./db_B6tuQof6.mjs";
import "./compiler_DiaTUwMm.mjs";
import { n as $$Layout, t as getI18n } from "./i18n_DqAIjw1h.mjs";
import { t as $$Sidebar } from "./Sidebar_BCGhOHoz.mjs";
//#region src/pages/analysis.astro
var analysis_exports = /* @__PURE__ */ __exportAll({
	default: () => $$Analysis,
	file: () => $$file,
	url: () => $$url
});
createAstro("https://astro.build");
var $$Analysis = createComponent(($$result, $$props, $$slots) => {
	const Astro = $$result.createAstro($$props, $$slots);
	Astro.self = $$Analysis;
	const user = Astro.locals.user;
	const { lang, t } = getI18n(Astro);
	const savedAnalyses = db.prepare("SELECT type, content, updated_at FROM analysis_cache").all();
	return renderTemplate`${renderComponent($$result, "Layout", $$Layout, { "title": "FinTrack - " + (lang === "es" ? "Análisis Vesper Pro IA" : "Vesper Pro AI Analysis") }, { "default": ($$result) => renderTemplate`${maybeRenderHead($$result)}<div class="flex flex-col md:flex-row min-h-screen"><!-- Sidebar / Panel de Control -->${renderComponent($$result, "Sidebar", $$Sidebar, {
		"active": "analysis",
		"username": user?.username || "admin"
	})}<!-- Main Content Area --><main class="flex-1 p-6 space-y-6 overflow-y-auto font-mono"><!-- Top Title Command --><div class="border-b border-border-subtle pb-4"><h1 class="text-xl text-main font-bold">${t.vesper_analyze}</h1><p class="text-xs text-secondary mt-1">${t.analysis_subtitle}</p></div><!-- Vesper System Description Panel --><div class="border border-border-main p-4 bg-surface-main space-y-2 text-xs"><div class="text-main font-bold">${t.vesper_info_title}</div><p class="text-secondary leading-relaxed">${t.vesper_info_desc}</p></div><!-- Collapsible Prompts Audit Panel --><details class="border border-border-subtle bg-bg p-3 text-[11px] font-mono cursor-pointer"><summary class="text-secondary font-bold hover:text-main select-none">${lang === "es" ? "[+] MOSTRAR PROMPTS DE INSTRUCCIÓN (VESPER PRO SYSTEM INSTRUCTIONS)" : "[+] SHOW SYSTEM INSTRUCTIONS PROMPTS (VESPER PRO)"}</summary><div class="mt-3 space-y-4 text-[10px] cursor-text border-t border-border-subtle pt-3"><div><span class="text-main font-bold">[ PROMPT: ${t.tab_situacion} ]</span><pre class="bg-bg-subtle p-2 border border-border-subtle text-muted-text whitespace-pre-wrap mt-1">${lang === "es" ? `Actúa como Vesper, tu asesor financiero personal de alto rendimiento. Realiza un análisis crítico, ejecutivo y puntual de la SITUACIÓN FINANCIERA ACTUAL.
- Analiza el balance global de capital y detecta si la distribución actual de liquidez entre cuentas es óptima o si hay ineficiencias (ej. capital ocioso en cuentas corrientes o falta de fondos de reserva).
- Audita si el ritmo de gasto actual en los presupuestos del mes compromete la estabilidad general, señalando las categorías con mayor riesgo de sobregiro.
- Sé directo, preciso y responde únicamente con viñetas analíticas de alto valor. NO repitas saldos de cuentas ni límites presupuestarios.` : `Act as Vesper, your high-performance personal financial advisor. Perform a critical, executive, and punctual analysis of the CURRENT FINANCIAL SITUATION.
- Analyze the global balance of capital and detect if the current distribution of liquidity among accounts is optimal or if there are inefficiencies (e.g. idle capital in checking accounts or lack of reserve funds).
- Audit if the current spending rate in the month's budgets compromises general stability, highlighting categories with the highest risk of overdraft.
- Be direct, precise, and respond only with high-value analytical bullet points. DO NOT repeat account balances or budget limits.`}</pre></div><div><span class="text-main font-bold">[ PROMPT: ${t.tab_fugas} ]</span><pre class="bg-bg-subtle p-2 border border-border-subtle text-muted-text whitespace-pre-wrap mt-1">${lang === "es" ? `Actúa como Vesper, tu asesor financiero personal de alto rendimiento. Audita las transacciones del mes buscando FUGAS DE DINERO e ineficiencias de gasto.
- Detecta comportamientos de gasto innecesarios, consumos hormiga acumulativos, posibles suscripciones redundantes, o egresos sin sentido.
- Explica la causa raíz detectada en el patrón de transacciones y calcula el impacto financiero anual proyectado (ej. "Gastar $X diarios en Y equivale a $Z al año").
- Sé directo y responde en viñetas analíticas precisas. NO listes transacciones individuales ni hagas tablas de consumos.` : `Act as Vesper, your high-performance personal financial advisor. Audit the month's transactions looking for MONEY LEAKAGES and spending inefficiencies.
- Detect unnecessary spending behaviors, cumulative minor expenses, possible redundant subscriptions, or senseless outflows.
- Explain the root cause detected in the transaction pattern and calculate the projected annual financial impact (e.g. "Spending $X daily on Y equals $Z per year").
- Be direct and respond in precise analytical bullet points. DO NOT list individual transactions or make consumption tables.`}</pre></div><div><span class="text-main font-bold">[ PROMPT: ${t.tab_mejoras} ]</span><pre class="bg-bg-subtle p-2 border border-border-subtle text-muted-text whitespace-pre-wrap mt-1">${lang === "es" ? `Actúa como Vesper, tu asesor financiero personal de alto rendimiento. Diseña un PLAN DE ACCIÓN Y MEJORA frugal e inteligente.
- Propón de 3 a 5 medidas concretas y técnicas para reducir gastos en las categorías más críticas del mes actual.
- Diseña una estrategia práctica para automatizar u optimizar el flujo de efectivo local (reglas de ahorro, frugalidad inteligente).
- Sé directo y responde en puntos concretos y accionables. Evita generalidades financieras.` : `Act as Vesper, your high-performance personal financial advisor. Design a frugal and smart ACTION AND IMPROVEMENT PLAN.
- Propose 3 to 5 concrete and technical measures to reduce expenses in the most critical categories of the current month.
- Design a practical strategy to automate or optimize local cash flow (savings rules, smart frugality).
- Be direct and respond in concrete, actionable points. Avoid financial generalities.`}</pre></div><div><span class="text-main font-bold">[ PROMPT: ${t.tab_objetivos} ]</span><pre class="bg-bg-subtle p-2 border border-border-subtle text-muted-text whitespace-pre-wrap mt-1">${lang === "es" ? `Actúa como Vesper, tu asesor financiero personal de alto rendimiento. Analiza matemáticamente la VIABILIDAD Y AVANCE DE LOS OBJETIVOS DE AHORRO.
- Para cada objetivo, calcula y muestra un PORCENTAJE estimado de probabilidad de cumplimiento (de 0% a 100%) y explica detalladamente el PORQUÉ de dicha probabilidad (ej. basándote en la tasa de ahorro requerida vs real, tiempo restante en meses y capital acumulado).
- Indica claramente cuáles objetivos son FACTIBLES y cuáles están en RIESGO DE INCUMPLIMIENTO.
- Calcula e indica explícitamente para cada objetivo la CANTIDAD MENSUAL exacta en pesos (CLP) que se debe aportar o depositar de ahora en adelante para lograr cumplirlo con éxito dentro de su fecha límite (deadline).
- Responde en puntos concisos y precisos. NO repitas las metas o montos acumulados si no es para aportar la cantidad mensual requerida, el porcentaje o el análisis de la probabilidad.` : `Act as Vesper, your high-performance personal financial advisor. Mathematically analyze the SAVINGS GOALS VIABILITY AND PROGRESS.
- For each goal, calculate and display an estimated completion PERCENTAGE (from 0% to 100%) and explain in detail the WHY of said probability (e.g. based on required vs actual savings rate, remaining time in months, and accumulated capital).
- Clearly indicate which goals are FEASIBLE and which are AT RISK OF NON-COMPLIANCE.
- Explicitly calculate and state for each goal the exact MONTHLY AMOUNT in pesos (CLP or selected currency) that must be contributed or deposited from now on to successfully achieve it within its deadline.
- Respond in concise and precise points. DO NOT repeat goals or accumulated amounts unless it is to provide the required monthly amount, the percentage, or the analysis of the probability.`}</pre></div></div></details><!-- Actions & Terminal Output Window --><div class="space-y-4"><!-- 4 Botones de Acción Independientes --><div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-2"><button data-type="situacion" id="btn-situacion" class="analysis-trigger bg-bg-subtle hover:bg-border-main border border-border-main text-main hover:text-bg font-bold py-2 px-3 transition-colors cursor-pointer text-xs uppercase">${lang === "es" ? "[ 01_AUDITAR_SITUACION ]" : "[ 01_AUDIT_SITUATION ]"}</button><button data-type="fugas" id="btn-fugas" class="analysis-trigger bg-bg-subtle hover:bg-border-main border border-border-main text-main hover:text-bg font-bold py-2 px-3 transition-colors cursor-pointer text-xs uppercase">${lang === "es" ? "[ 02_AUDITAR_FUGAS ]" : "[ 02_AUDIT_LEAKAGES ]"}</button><button data-type="mejoras" id="btn-mejoras" class="analysis-trigger bg-bg-subtle hover:bg-border-main border border-border-main text-main hover:text-bg font-bold py-2 px-3 transition-colors cursor-pointer text-xs uppercase">${lang === "es" ? "[ 03_PLANES_MEJORA ]" : "[ 03_IMPROVEMENT_PLANS ]"}</button><button data-type="objetivos" id="btn-objetivos" class="analysis-trigger bg-bg-subtle hover:bg-border-main border border-border-main text-main hover:text-bg font-bold py-2 px-3 transition-colors cursor-pointer text-xs uppercase">${lang === "es" ? "[ 04_VIABILIDAD_OBJETIVOS ]" : "[ 04_GOALS_VIABILITY ]"}</button></div><div class="flex flex-wrap justify-between items-center gap-2 text-xs"><div class="text-secondary font-bold select-none">> vesper-pro --mode=interactive</div><div class="flex items-center gap-2"><!-- Botón para forzar una nueva generación --><button id="refresh-analysis-btn" class="hidden bg-bg border border-accent text-accent hover:bg-accent hover:text-bg font-bold py-1 px-2 transition-colors cursor-pointer uppercase text-[10px]">${t.btn_regenerate}</button><div id="status-badge" class="text-[10px] text-muted-text uppercase font-bold border border-border-subtle px-2 py-1 bg-bg-subtle">STATUS: READY</div></div></div><!-- Terminal Output Window --><div class="terminal-window m-0"><div class="terminal-header"><span>vesper-pro@fintrack — stdout — bash 80x24</span><div class="terminal-buttons"><span class="terminal-button"></span><span class="terminal-button"></span><span class="terminal-button"></span></div></div><div class="terminal-body bg-bg text-main font-mono text-xs md:text-sm min-h-[350px] max-h-[650px] overflow-y-auto p-4 border border-t-0 border-border-subtle" id="terminal-stdout-container"><!-- Terminal output body content --><div class="whitespace-pre-wrap leading-relaxed" id="terminal-stdout">${lang === "es" ? "> Selecciona una de las auditorías de Vesper Pro en los botones superiores para ejecutar su prompt correspondiente sobre los datos de la base de datos local." : "> Select one of the Vesper Pro audits on the top buttons to execute its corresponding prompt on the local database."}</div></div></div></div></main></div>` })}<script>(function(){${defineScriptVars({ savedAnalyses })}
  const statusBadge = document.getElementById('status-badge');
  const terminalStdout = document.getElementById('terminal-stdout');
  const terminalStdoutContainer = document.getElementById('terminal-stdout-container');
  const triggerButtons = document.querySelectorAll('.analysis-trigger');
  const refreshBtn = document.getElementById('refresh-analysis-btn');

  let currentAnimationId = null;
  let activeType = null;

  const isEn = document.cookie.includes('lang=en');

  // Cargar datos cacheados
  const cachedAnalyses = {};
  savedAnalyses.forEach(item => {
    cachedAnalyses[item.type] = {
      content: item.content,
      updated_at: item.updated_at
    };
  });

  function formatTimestamp(ts) {
    const d = new Date(ts);
    const day = String(d.getDate()).padStart(2, '0');
    const month = String(d.getMonth() + 1).padStart(2, '0');
    const hours = String(d.getHours()).padStart(2, '0');
    const minutes = String(d.getMinutes()).padStart(2, '0');
    return \`\${day}/\${month} \${hours}:\${minutes}\`;
  }

  // Resalta visualmente el botón del tipo de análisis activo
  function highlightButton(type) {
    triggerButtons.forEach(btn => {
      const btnType = btn.getAttribute('data-type');
      if (btnType === type) {
        btn.classList.remove('bg-bg-subtle', 'text-main');
        btn.classList.add('bg-border-main', 'text-bg');
      } else {
        btn.classList.remove('bg-border-main', 'text-bg');
        btn.classList.add('bg-bg-subtle', 'text-main');
      }
    });
  }

  // Muestra un análisis (ya sea de caché o nuevo)
  function showAnalysis(type, content, isNew = false, timestamp = null) {
    activeType = type;
    highlightButton(type);

    // Cancelar animación anterior si existe
    if (currentAnimationId !== null) {
      cancelAnimationFrame(currentAnimationId);
      currentAnimationId = null;
    }

    if (refreshBtn) refreshBtn.classList.remove('hidden');

    const formattedTime = timestamp ? formatTimestamp(timestamp) : formatTimestamp(Date.now());
    if (statusBadge) {
      statusBadge.textContent = isNew ? \`STATUS: FRESH\` : \`CACHED (\${formattedTime})\`;
    }

    if (!terminalStdout) return;

    if (isNew) {
      // Efecto typewriter para nuevos reportes
      terminalStdout.innerHTML = '';
      let index = 0;
      const charsPerTick = 15;
      
      function typeWriter() {
        if (index < content.length) {
          terminalStdout.innerHTML += content.substr(index, charsPerTick);
          index += charsPerTick;
          if (terminalStdoutContainer) {
            terminalStdoutContainer.scrollTop = terminalStdoutContainer.scrollHeight;
          }
          currentAnimationId = requestAnimationFrame(typeWriter);
        } else {
          currentAnimationId = null;
        }
      }
      typeWriter();
    } else {
      // Render instantáneo para caché
      terminalStdout.innerHTML = content;
      if (terminalStdoutContainer) {
        terminalStdoutContainer.scrollTop = 0;
      }
    }
  }

  // Ejecuta la consulta de IA en vivo
  async function runQuery(type) {
    const clickedBtn = document.getElementById(\`btn-\${type}\`);
    const originalLabel = clickedBtn ? clickedBtn.textContent : '';

    // Detener animaciones activas
    if (currentAnimationId !== null) {
      cancelAnimationFrame(currentAnimationId);
      currentAnimationId = null;
    }

    // Deshabilitar botones durante la consulta
    triggerButtons.forEach(btn => {
      btn.disabled = true;
      btn.classList.add('opacity-40', 'cursor-not-allowed');
    });
    if (clickedBtn) clickedBtn.textContent = isEn ? '[ PROCESSING... ]' : '[ PROCESANDO... ]';
    if (refreshBtn) refreshBtn.classList.add('hidden');

    if (statusBadge) statusBadge.textContent = \`STATUS: AUDITING_\${type.toUpperCase()}\`;

    const labels = isEn ? {
      situacion: 'GENERAL STATUS',
      fugas: 'MONEY LEAKAGE DETECTION',
      mejoras: 'IMPROVEMENT PLAN & EFFICIENCY',
      objetivos: 'GOALS VIABILITY & PROGRESS'
    } : {
      situacion: 'ESTATUS GENERAL',
      fugas: 'DETECCIÓN DE FUGAS DE DINERO',
      mejoras: 'PLAN DE MEJORA Y EFICIENCIA',
      objetivos: 'VIABILIDAD Y AVANCE DE OBJETIVOS'
    };

    if (terminalStdout) {
      terminalStdout.innerHTML = isEn
        ? \`> Starting prompt for: \${labels[type]}...\\n> Querying balances and transactions of current month...\\n> Sending context to local Vesper Pro...\\n\\n[════════════════════════════════════════] RUNNING PROMPT...\`
        : \`> Iniciando prompt para: \${labels[type]}...\\n> Consultando balances y transacciones del mes actual...\\n> Enviando contexto a Vesper Pro local...\\n\\n[════════════════════════════════════════] EJECUTANDO PROMPT...\`;
    }

    try {
      const response = await fetch('/api/analysis', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ type })
      });

      const data = await response.json();

      if (!response.ok) {
        throw new Error(data.error || (isEn ? 'Unknown error invoking local Vesper Pro agent.' : 'Error desconocido al invocar al agente Vesper Pro.'));
      }

      // Guardar en la caché en memoria del cliente
      cachedAnalyses[type] = {
        content: data.analysis,
        updated_at: Date.now()
      };

      // Mostrar con animación typewriter
      showAnalysis(type, data.analysis, true, Date.now());

    } catch (err) {
      if (statusBadge) statusBadge.textContent = 'STATUS: ERROR';
      if (terminalStdout) {
        terminalStdout.innerHTML = isEn
          ? \`\\n> CRITICAL ERROR: \${err.message}\\n> Make sure Ollama is running with "vesper-pro" model available.\`
          : \`\\n> ERROR CRÍTICO: \${err.message}\\n> Asegúrate de que Ollama esté corriendo con el modelo "vesper-pro" disponible.\`;
      }
    } finally {
      // Rehabilitar botones
      triggerButtons.forEach(btn => {
        btn.disabled = false;
        btn.classList.remove('opacity-40', 'cursor-not-allowed');
      });
      if (clickedBtn) clickedBtn.textContent = originalLabel;
    }
  }

  // Enlazar botones principales
  triggerButtons.forEach(btn => {
    btn.addEventListener('click', () => {
      const type = btn.getAttribute('data-type');
      if (!type) return;

      // Si ya está cacheado, mostrar al instante
      if (cachedAnalyses[type]) {
        showAnalysis(type, cachedAnalyses[type].content, false, cachedAnalyses[type].updated_at);
      } else {
        // Si no está cacheado, correr la consulta IA
        runQuery(type);
      }
    });
  });

  // Enlazar botón Regenerar reporte
  refreshBtn?.addEventListener('click', () => {
    if (activeType) {
      runQuery(activeType);
    }
  });

  // CARGAR AL INICIO: Mostrar el reporte más reciente si hay alguno guardado
  let mostRecentType = null;
  let maxTime = 0;
  for (const key in cachedAnalyses) {
    if (cachedAnalyses[key].updated_at > maxTime) {
      maxTime = cachedAnalyses[key].updated_at;
      mostRecentType = key;
    }
  }

  if (mostRecentType) {
    showAnalysis(mostRecentType, cachedAnalyses[mostRecentType].content, false, cachedAnalyses[mostRecentType].updated_at);
  }
})();<\/script>`;
}, "/home/castolo/desarrollos/FinTrack/src/pages/analysis.astro", void 0);
var $$file = "/home/castolo/desarrollos/FinTrack/src/pages/analysis.astro";
var $$url = "/analysis";
//#endregion
//#region \0virtual:astro:page:src/pages/analysis@_@astro
var page = () => analysis_exports;
//#endregion
export { page };
