# 💻 FinTrack — Terminal Personal Finance Manager

FinTrack es un gestor de finanzas personales local-first diseñado con una estética retro de terminal hacker inspirado en CachyOS (monocromo, tipografía monoespaciada, bordes planos, colores cian, verde bosque y fondo azul-gris oscuro).

Ofrece total control, privacidad y soberanía de datos al procesar la base de datos de manera local y realizar auditorías de inteligencia artificial sin conexión a internet.

---

## 🔍 ¿Qué es?
FinTrack es una aplicación web de servidor (Astro SSR) con arquitectura local-first. Está pensada para ingenieros de software, entusiastas de la terminal y usuarios que valoran la privacidad de sus registros financieros. En lugar de delegar tus datos a la nube, FinTrack opera sobre una base de datos SQLite local y ejecuta una agente inteligente local (Moneypenny) a través de Ollama.

---

## 🛠️ ¿Qué hace? (Funcionalidades)

1. **Dashboard de Consola (`cat ./transacciones.log`)**:
   * Métricas generales (saldos, ingresos, egresos, presupuestos y ahorros).
   * Visualización en tiempo real de transacciones filtradas automáticamente por el mes seleccionado.

2. **Gestión de Transacciones**:
   * Registro rápido de ingresos y egresos.
   * Filtro interactivo por mes en formato de calendario retro.
   * Contador dinámico de registros coincidentes.

3. **Módulo de Presupuestos**:
   * Límites de gasto por categoría con restablecimiento automático mensual.
   * Barras de progreso visuales en ASCII (`[████░░░░░░]`) y alertas de sobrefacturación.

4. **Visualización Gráfica (`charts.sh`)**:
   * Gráficos interactivos de pastel y barras para categorización de gastos e ingresos.
   * Selector dinámico para alternar entre flujos de Gastos/Egresos e Ingresos/Entradas.

5. **Bolsillos y Objetivos de Ahorro (`saving_goals.db`)**:
   * Creación de objetivos con plazos límite (deadlines) y aplicaciones/plataformas de ahorro específicas.
   * Acciones rápidas en un solo paso para `[DEPOSITAR]` y `[RETIRAR]` saldo vinculados a cuentas reales.

6. **Auditoría Financiera de IA (`moneypenny --analyze`)**:
   * Auditoría inteligente e interactiva dividida en 4 áreas de prompt específicas:
     * **Situación Actual**: Análisis estructural de capital y presupuestos mensuales.
     * **Auditoría de Fugas**: Detección de consumos hormiga, ineficiencias y proyección de su impacto anual.
     * **Planes de Mejora**: Sugerencias concretas y hábitos frugales a corto plazo.
     * **Viabilidad de Objetivos**: Cálculo porcentual de probabilidad de éxito, justificación lógica y cálculo del aporte mensual exacto en CLP necesario para cumplir cada meta en su plazo.
   * **Persistencia (Caché)**: Almacena los reportes en SQLite para consulta instantánea fuera de línea y ofrece un disparador para `[REGENERAR_REPORTE]`.

7. **Respaldos y Migraciones**:
   * Exportación instantánea de la base de datos completa a un archivo JSON portable.
   * Restauración y mezcla de datos mediante carga de archivos de respaldo.

8. **Navegación Móvil e Interfaz Responsiva**:
   * Barra de navegación inferior dinámica (`MobileTabBar`) para accesibilidad rápida en smartphones.
   * Diseño completamente adaptativo a cualquier tamaño de pantalla manteniendo la estética retro de consola.

---

## ⚙️ ¿Con qué lo hace? (Tecnologías)

* **Core Framework**: [Astro](https://astro.build/) configurado en modo SSR (Server-Side Rendering) con adaptador independiente `@astrojs/node` ejecutándose en el puerto `4321`.
* **Base de Datos**: [SQLite](https://sqlite.org/) a través del driver nativo síncrono ultra-rápido `better-sqlite3`.
* **Motor Estilístico**: [TailwindCSS](https://tailwindcss.com/) y CSS nativo personalizado, configurando un esquema `color-scheme: dark` para adaptar los menús nativos del navegador al tema oscuro.
* **Componentes Interactivos**: [React](https://react.dev/) para la reactividad de gráficas e inputs dinámicos de calendario.
* **Inteligencia Actoral Local**: [Ollama](https://ollama.com/) ejecutando el modelo **`gemma2:9b`** con el nombre de agente **`Moneypenny`**.

---

## 🚀 Instalación y Despliegue Local

### 1. Requisitos Previos
Asegúrate de tener instalados:
* **Node.js** v18 o superior.
* **Ollama** ejecutándose de manera local (`ollama serve`).

### 2. Configurar la IA Local (Gemma2) paso a paso
Para habilitar las funciones de auditoría inteligente y análisis financiero, necesitas configurar Ollama con el modelo `gemma2`.
1. Descarga e instala [Ollama](https://ollama.com/) en tu sistema.
2. Abre tu terminal y ejecuta el comando para descargar el modelo:
   ```bash
   ollama pull gemma2:9b
   ```
3. Verifica que el modelo se haya instalado correctamente:
   ```bash
   ollama list
   ```
   *(Asegúrate de que `gemma2:9b` aparezca en la lista)*.
4. Mantén Ollama en ejecución en segundo plano (`ollama serve` o abriendo la aplicación). FinTrack se conectará automáticamente a su API local.

### 3. Configurar Backups en Google Drive
Para habilitar las copias de seguridad de tu base de datos local hacia la nube:
1. Ve a la [Consola de Google Cloud](https://console.cloud.google.com/) y crea un nuevo proyecto.
2. Habilita la **Google Drive API** dentro del panel "APIs y Servicios".
3. Ve a "Credenciales" > "Crear credenciales" > "Cuenta de servicio".
4. Dentro de la cuenta de servicio creada, genera una nueva clave (Key) en formato **JSON** y descárgala.
5. Renombra ese archivo a `google-credentials.json` y colócalo en la raíz del proyecto (junto a `package.json`).
6. Crea una carpeta en tu Google Drive personal para guardar los backups y **compártela** (con permisos de Editor) usando el correo electrónico de tu Cuenta de Servicio.

### 4. Levantar FinTrack
1. Clona el repositorio e ingresa a la carpeta del proyecto.
2. Instala las dependencias de Node:
   ```bash
   npm install
   ```
3. Ejecuta el servidor de desarrollo local:
   ```bash
   npm run dev
   ```
4. Abre [http://localhost:4321](http://localhost:4321) en tu navegador.
5. Sigue las instrucciones en pantalla en el módulo `/setup` para crear tu cuenta de administrador local (las contraseñas se cifran con `bcryptjs` en la base de datos).

---

## 🧞 Comandos de Desarrollo

| Comando | Acción |
| :--- | :--- |
| `npm run dev` | Inicia el servidor de desarrollo local en `localhost:4321`. |
| `npm run build` | Compila la aplicación de producción optimizada en `./dist/`. |
| `npm run preview` | Previsualiza localmente la compilación de producción. |

---

## 🔒 Privacidad y gitignore
El archivo `.gitignore` está configurado para evitar la subida accidental de información confidencial a GitHub:
* `fintrack.db*` (SQLite local con tus transacciones e historial) está ignorado.
* `.env` y `.env.production` están ignorados.
* `.vscode/` y archivos `.DS_Store` están ignorados.
