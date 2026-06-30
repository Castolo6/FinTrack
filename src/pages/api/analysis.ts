import type { APIRoute } from 'astro';
import { db } from '../../lib/db';
import { formatCLP } from '../../lib/utils';

export const POST: APIRoute = async ({ request, locals, cookies }) => {
  try {
    // 1. Verificar autenticación
    if (!locals.user) {
      return new Response(JSON.stringify({ error: 'No autorizado.' }), { status: 401 });
    }

    // 2. Obtener tipo de análisis del cuerpo de la petición
    const body = await request.json();
    const { type } = body; // 'situacion' | 'fugas' | 'mejoras' | 'objetivos'
    const currency = cookies.get('currency')?.value || 'CLP';

    if (!type || !['situacion', 'fugas', 'mejoras', 'objetivos'].includes(type)) {
      return new Response(JSON.stringify({ error: 'Tipo de análisis inválido o ausente.' }), { status: 400 });
    }

    // 3. Recopilar información financiera de la DB
    // A. Cuentas
    const accounts = db.prepare('SELECT name, type, balance, currency FROM accounts').all() as Array<{
      name: string;
      type: string;
      balance: number;
      currency: string;
    }>;

    // B. Presupuestos del mes en curso
    const now = new Date();
    const currentYear = now.getFullYear();
    const currentMonth = String(now.getMonth() + 1).padStart(2, '0');
    const startOfMonth = `${currentYear}-${currentMonth}-01`;
    const endOfMonth = `${currentYear}-${currentMonth}-31`;

    const budgetsList = db.prepare(`
      SELECT b.amount as budget_limit, c.name as category_name, c.id as category_id
      FROM budgets b
      JOIN categories c ON b.category_id = c.id
      WHERE b.start_date = ?
    `).all(startOfMonth) as Array<{ budget_limit: number; category_name: string; category_id: string }>;

    const budgets = budgetsList.map(b => {
      const spentResult = db.prepare(`
        SELECT SUM(amount) as total FROM transactions 
        WHERE category_id = ? AND type = 'expense' AND date >= ? AND date <= ?
      `).get(b.category_id, startOfMonth, endOfMonth) as { total: number | null };
      const spent = spentResult?.total || 0;
      const percent = b.budget_limit > 0 ? Math.round((spent / b.budget_limit) * 100) : 0;
      return { ...b, spent, percent };
    });

    // C. Objetivos de ahorro (Bolsillos)
    const goals = db.prepare('SELECT name, target_amount, current_amount, saving_platform, deadline FROM saving_goals').all() as Array<{
      name: string;
      target_amount: number;
      current_amount: number;
      saving_platform: string | null;
      deadline: string | null;
    }>;

    // C2. Inversiones
    let investments: Array<{name: string; type: string; invested_amount: number; current_value: number; platform: string | null;}> = [];
    try {
      investments = db.prepare('SELECT name, type, invested_amount, current_value, platform FROM investments').all() as typeof investments;
    } catch(e) {}

    // C3. Créditos
    let credits: Array<{name: string; total_amount: number; remaining_amount: number; monthly_payment: number | null; interest_rate: number | null;}> = [];
    try {
      credits = db.prepare('SELECT name, total_amount, remaining_amount, monthly_payment, interest_rate FROM credits').all() as typeof credits;
    } catch(e) {}

    // D. Últimas transacciones (filtradas por mes actual, excepto para metas)
    let recentTransactions;
    if (type === 'objetivos') {
      // Para objetivos/metas, traer las últimas 50 transacciones históricas generales
      recentTransactions = db.prepare(`
        SELECT t.date, t.type, t.amount, t.description, c.name as category_name, a.name as account_name
        FROM transactions t
        JOIN accounts a ON t.account_id = a.id
        JOIN categories c ON t.category_id = c.id
        ORDER BY t.date DESC, t.created_at DESC
        LIMIT 50
      `).all() as Array<{
        date: string;
        type: string;
        amount: number;
        description: string | null;
        category_name: string;
        account_name: string;
      }>;
    } else {
      // Para los otros análisis (situacion, fugas, mejoras), traer SOLO las transacciones del mes en curso
      recentTransactions = db.prepare(`
        SELECT t.date, t.type, t.amount, t.description, c.name as category_name, a.name as account_name
        FROM transactions t
        JOIN accounts a ON t.account_id = a.id
        JOIN categories c ON t.category_id = c.id
        WHERE t.date >= ? AND t.date <= ?
        ORDER BY t.date DESC, t.created_at DESC
      `).all(startOfMonth, endOfMonth) as Array<{
        date: string;
        type: string;
        amount: number;
        description: string | null;
        category_name: string;
        account_name: string;
      }>;
    }

    // 4. Configurar instrucciones del prompt específicas según el botón clickeado
    const daysInMonth = new Date(currentYear, now.getMonth() + 1, 0).getDate();
    const currentDay = now.getDate();
    const daysRemaining = daysInMonth - currentDay;
    const monthProgress = Math.round((currentDay / daysInMonth) * 100);

    let targetedInstructions = '';
    if (type === 'situacion') {
      targetedInstructions = `Eres Moneypenny, asesora financiera personal certificada. Realiza un DIAGNÓSTICO FINANCIERO EJECUTIVO del estado actual del usuario.

METODOLOGÍA DE ANÁLISIS:
1. **Salud Patrimonial**: Calcula el patrimonio neto total (suma de todos los saldos). Evalúa si la distribución de capital entre cuentas es eficiente o si hay capital ocioso que debería estar generando rendimiento.
2. **Pulso Presupuestario**: Estamos en el día ${currentDay} de ${daysInMonth} del mes (${monthProgress}% del mes transcurrido). Compara el porcentaje de presupuesto consumido vs el porcentaje del mes transcurrido para cada categoría. Si el gasto supera proporcionalmente el avance del mes, señálalo como zona de riesgo.
3. **Ratio Ingreso/Gasto**: Calcula la relación entre ingresos y gastos del mes. Un ratio saludable es >1.3 (ahorrando al menos 30%). Indica el ratio real.
4. **Colchón de Emergencia**: Evalúa si el usuario tiene liquidez suficiente para cubrir al menos 1 mes de gastos sin ingresos.

FORMATO DE RESPUESTA:
- Usa encabezados Markdown (##) para cada sección.
- Incluye cifras concretas en ${currency}, no generalidades.
- Cierra con un VEREDICTO de 1 línea sobre la salud financiera general. Debes usar EXCLUSIVAMENTE uno de estos tres tokens para el estado: [VERDE: ESTABLE], [AMARILLO: EN RIESGO], o [ROJO: CRÍTICO].
- NO repitas los saldos de cuentas ni los límites presupuestarios literalmente, el usuario ya los conoce.`;
    } else if (type === 'fugas') {
      targetedInstructions = `Eres Moneypenny, auditora financiera forense especializada en detección de fugas de capital. Ejecuta una AUDITORÍA DE FUGAS Y GASTOS FANTASMA sobre las transacciones del mes.

PROTOCOLO DE AUDITORÍA:
1. **Gastos Hormiga**: Identifica transacciones pequeñas recurrentes que individualmente parecen insignificantes pero que en conjunto representan una fuga considerable. Calcula su acumulado mensual y proyección anual.
2. **Suscripciones y Pagos Recurrentes**: Detecta patrones de pagos periódicos. Evalúa si existen duplicidades o servicios potencialmente infrautilizados.
3. **Gastos Impulsivos**: Señala egresos que rompen el patrón normal de gasto del usuario (montos inusuales, categorías atípicas, frecuencia anormal).
4. **Sobregasto por Categoría**: Identifica categorías donde el gasto del mes ya supera el presupuesto asignado o está en camino de superarlo (estamos al ${monthProgress}% del mes).

SISTEMA DE ALERTAS — Clasifica CADA fuga detectada con uno de estos niveles de severidad:
- 🔴 **CRITICAL** — Fuga que supera el 10% del ingreso mensual o compromete la estabilidad financiera. Requiere acción inmediata.
- ⚠️ **WARNING** — Fuga entre el 3% y 10% del ingreso mensual. Patrón de gasto que se está convirtiendo en hábito costoso y debe corregirse este mes.
- 🟡 **CAUTION** — Fuga menor al 3% del ingreso mensual, pero con tendencia creciente o potencial de escalar si no se monitorea.

FORMATO DE RESPUESTA:
- Cada fuga detectada debe comenzar con su etiqueta de severidad (🔴/⚠️/🟡).
- Incluye el **impacto mensual** y la **proyección anual** en ${currency} para cada fuga.
- Cierra con un RESUMEN DE AUDITORÍA: total de fugas detectadas, monto total fugado en el mes, y el porcentaje que esto representa sobre los ingresos del mes.
- NO listes transacciones individuales. Agrupa por patrón de comportamiento.`;
    } else if (type === 'mejoras') {
      targetedInstructions = `Eres Moneypenny, consultora financiera estratégica especializada en optimización de finanzas personales. Diseña un PLAN TÁCTICO DE OPTIMIZACIÓN FINANCIERA personalizado.

ESTRUCTURA DEL PLAN:
1. **Recortes Inmediatos (esta semana)**: De 2 a 3 acciones que el usuario puede ejecutar HOY para reducir gastos. Sé específico: indica exactamente qué categoría recortar, cuánto ahorraría, y la alternativa concreta (ej. "Reemplazar X por Y ahorra ~${currency} Z/mes").
2. **Optimización de Flujo (este mes)**: De 2 a 3 estrategias para redistribuir el capital de forma más eficiente entre cuentas. Si hay capital ocioso en cuentas corrientes, sugiere moverlo a instrumentos que generen rendimiento.
3. **Hábitos Frugales de Alto Impacto (largo plazo)**: De 2 a 3 cambios de hábito concretos basados en los patrones de gasto detectados. Incluye la proyección de ahorro anual de cada hábito.
4. **Meta de Ahorro Sugerida**: Basándote en los ingresos y gastos actuales, sugiere un porcentaje realista de ahorro mensual y el monto exacto en ${currency}. Quedan ${daysRemaining} días para cerrar el mes.

FORMATO DE RESPUESTA:
- Usa encabezados Markdown (##) y viñetas numeradas para cada medida.
- Cada medida debe incluir: la acción concreta, el ahorro estimado en ${currency}, y la dificultad de implementación.
- REGLA ESTRICTA PARA LA DIFICULTAD: Debes usar EXCLUSIVAMENTE uno de estos tres tokens para indicar la dificultad: [VERDE: FÁCIL], [AMARILLO: MEDIA], o [ROJO: DIFÍCIL]. No uses el texto crudo.
- NO incluyas consejos genéricos tipo "ahorra más" o "gasta menos". Cada punto debe ser accionable y cuantificado.`;
    } else {
      targetedInstructions = `Eres Moneypenny, analista financiera cuantitativa especializada en proyecciones y viabilidad de patrimonio. Realiza un ANÁLISIS MATEMÁTICO DE VIABILIDAD del portafolio completo del usuario (ahorros, inversiones y deudas).

METODOLOGÍA DE ANÁLISIS:
1. **Bolsillos de Ahorro**: Para cada objetivo, calcula el porcentaje completado, meses restantes y aporte mensual requerido. 
   - REGLA ESTRICTA DE FORMATO: Debes mostrar la probabilidad de cumplimiento usando ÚNICAMENTE uno de estos tres tokens exactos (reemplaza X con el número real): [VERDE: X%], [AMARILLO: X%], o [ROJO: X%]. No uses otras palabras para la probabilidad.
2. **Deudas y Créditos**: Analiza las cuotas mensuales comprometidas de los créditos. Señala cuáles créditos deberían prepagarse primero (efecto avalancha o bola de nieve) basándote en la tasa de interés o en el saldo pendiente.
3. **Inversiones**: Revisa el desempeño actual de las inversiones (Ganancia/Pérdida). Sugiere si el usuario tiene una distribución equilibrada o si presenta riesgo de concentración.
4. **Viabilidad Global**: Marca la salud del portafolio como ✅ FACTIBLE, ⚠️ EN RIESGO o 🔴 INVIABLE (basado en el ratio de deuda vs liquidez y metas).

FORMATO DE RESPUESTA:
- Usa bloques claros para [ 1. AHORROS ], [ 2. DEUDAS ] y [ 3. INVERSIONES ].
- Incluye montos exactos en ${currency} y porcentajes precisos.
- RECUERDA PARA AHORROS: Usa los tokens [VERDE: X%], [AMARILLO: X%] o [ROJO: X%] literalmente.
- Cierra con una RECOMENDACIÓN ESTRATÉGICA para el patrimonio global (qué deuda pagar primero, dónde invertir el excedente, qué objetivo pausar).
- NO repitas los montos acumulados o totales literalmente a modo de lista. Analiza y concluye.`;
    }

    // 5. Unificar con los datos reales
    let prompt = `${targetedInstructions}

DATOS FINANCIEROS REALES DEL USUARIO:

=== CUENTAS ACTIVAS ===
${accounts.map(acc => `- ${acc.name} (${acc.type.toUpperCase()}): ${formatCLP(acc.balance, currency)} ${acc.currency}`).join('\n') || 'No hay cuentas registradas.'}

=== ESTADO DE PRESUPUESTOS (Mes: ${currentMonth}/${currentYear}) ===
${budgets.map(b => `- Categoría: ${b.category_name} | Límite: ${formatCLP(b.budget_limit, currency)} | Gastado: ${formatCLP(b.spent, currency)} (${b.percent}% ocupado)`).join('\n') || 'No hay presupuestos configurados para este mes.'}

=== OBJETIVOS DE AHORRO Y BOLSILLOS ===
${goals.map(g => `- Bolsillo: ${g.name} | Acumulado: ${formatCLP(g.current_amount, currency)} / Meta: ${formatCLP(g.target_amount, currency)} | Plazo: ${g.deadline || 'Sin plazo'} (Plataforma: ${g.saving_platform || 'No especificada'})`).join('\n') || 'No hay objetivos de ahorro creados.'}

=== INVERSIONES ===
${investments.map(i => `- ${i.name} (${i.type}): Invertido ${formatCLP(i.invested_amount, currency)} | Actual: ${formatCLP(i.current_value, currency)} | Plataforma: ${i.platform || 'N/A'}`).join('\n') || 'No hay inversiones registradas.'}

=== CRÉDITOS Y DEUDAS ===
${credits.map(c => `- ${c.name}: Deuda Total ${formatCLP(c.total_amount, currency)} | Pendiente: ${formatCLP(c.remaining_amount, currency)} | Cuota: ${c.monthly_payment ? formatCLP(c.monthly_payment, currency)+'/mes' : 'N/A'} | Tasa: ${c.interest_rate ? c.interest_rate+'%' : 'N/A'}`).join('\n') || 'No hay créditos registrados.'}

=== HISTORIAL DE TRANSACCIONES RECIENTES ===
${recentTransactions.map(t => `- [${t.date}] [${t.type.toUpperCase()}] ${t.category_name} en ${t.account_name} | ${formatCLP(t.amount, currency)} | Desc: ${t.description || 'Sin detalle'}`).join('\n') || 'No hay transacciones registradas.'}

Responde directamente en formato Markdown de forma limpia, directa y con viñetas puntuales. Evita explicaciones generales. NO incluyas tablas o listas redundantes de cuentas, saldos, presupuestos o transacciones que el usuario ya conoce. Ve al grano, sé preciso y analítico. Moneda del usuario: ${currency}.`;

    // 6. Invocar a la API de Moneypenny local para generar el reporte específico
    const startTime = Date.now();
    const agentResponse = await fetch('http://localhost:8000/api/v1/agent', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        prompt: prompt
      })
    });

    if (!agentResponse.ok) {
      throw new Error(`Moneypenny API retornó un error: ${agentResponse.statusText}`);
    }

    const endTime = Date.now();
    const execTimeMs = endTime - startTime;
    const execTimeSec = (execTimeMs / 1000).toFixed(2);

    const data = await agentResponse.json();
    
    // Estimación aproximada de tokens (1 token ≈ 4 caracteres)
    const inTokens = Math.round(prompt.length / 4);
    const outTokens = Math.round((data.output?.length || 0) / 4);

    const metricsHeader = `> **EXEC_TIME:** ${execTimeSec}s | **TOKENS_IN:** ~${inTokens} | **TOKENS_OUT:** ~${outTokens}\n\n`;
    const finalOutput = metricsHeader + data.output;

    // Guardar el último análisis generado en el caché de la base de datos
    db.prepare(`
      INSERT INTO analysis_cache (type, content, updated_at)
      VALUES (?, ?, ?)
      ON CONFLICT(type) DO UPDATE SET content = excluded.content, updated_at = excluded.updated_at
    `).run(type, finalOutput, Date.now());

    return new Response(JSON.stringify({ success: true, analysis: finalOutput }), { status: 200 });

  } catch (error: any) {
    return new Response(
      JSON.stringify({ error: 'Error al ejecutar el análisis con Moneypenny: ' + error.message }),
      { status: 500 }
    );
  }
};
