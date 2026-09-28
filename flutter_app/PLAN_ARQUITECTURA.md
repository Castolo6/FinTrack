# FinTrack Personal — Plan de arquitectura y diseño

## 1. Objetivo

Crear una aplicación web responsive para administrar finanzas personales desde un navegador, con posibilidad futura de instalarla como PWA.

La aplicación permitirá registrar cuentas y movimientos manualmente, llevar presupuestos y objetivos de ahorro, y comparar los gastos de una tarjeta con el texto o PDF de su estado de cuenta.

> **La conciliación será solo de comparación:** no creará, editará ni eliminará movimientos, y no cambiará saldos ni presupuestos.

## 2. Stack y arquitectura

```text
Flutter Web
  ├── Firebase Authentication
  │     ├── Correo y contraseña
  │     └── Google
  ├── Cloud Firestore: información financiera
  ├── Firebase Storage: PDF privado del estado de cuenta
  └── Firebase Cloud Functions
        ├── Guardar movimientos de forma consistente
        └── Extraer texto del PDF para compararlo

GitHub Actions: compila Flutter Web
Cloudflare Pages: publica build/web
```

- **Flutter Web** crea la interfaz para escritorio y móvil.
- **Firebase Authentication** identifica a cada usuario.
- **Cloud Firestore** guarda cuentas, movimientos, presupuestos y objetivos, separados por usuario.
- **Firebase Storage** guarda los PDF con acceso privado.
- **Cloudflare Pages** aloja la versión web.
- **GitHub Actions** puede compilar la app y desplegar el resultado en Cloudflare Pages. Es una ruta práctica porque el entorno de compilación de Pages no necesariamente incluye Flutter.

Firebase y Cloudflare deben configurarse con las cuentas y el dominio reales antes de publicar.

## 3. Moneda y modelo financiero

La moneda de la aplicación será **peso chileno (CLP)**. Los importes se guardarán como números enteros de pesos, sin cálculos en coma flotante. Si un estado muestra también un importe extranjero —por ejemplo, USD— se conservará como dato informativo; para comparar se usará el importe cobrado en CLP.

### Tipos de cuentas

- **Activos:** cuentas bancarias, efectivo, billeteras o apps de pago y cuentas de ahorro.
- **Tarjetas de crédito:** límite, deuda y disponible estimado.
- **Préstamos y créditos:** total a pagar ya calculado, número y valor de cuotas, primera fecha de vencimiento y seguimiento de pagos. La última cuota se ajusta por diferencias de redondeo.
- **Bienes:** inmuebles, vehículos u otros activos con una valoración que el usuario puede actualizar.

Los saldos se calcularán a partir de los movimientos, no cambiando manualmente el saldo como mecanismo habitual.

### Reglas para los movimientos

- Una compra con tarjeta registra el gasto, consume su presupuesto y aumenta la deuda de la tarjeta.
- Pagar la tarjeta desde una cuenta bancaria reduce el saldo del banco y la deuda; aumenta el disponible de la tarjeta. No se registra como un segundo gasto.
- Una transferencia entre cuentas propias no cuenta como gasto.
- En un crédito se distingue el abono al capital de los intereses.
- Las devoluciones se registran como reversos del gasto correspondiente.
- Una meta puede ser una asignación presupuestaria. Si se mueve el dinero a una cuenta de ahorro, también se registra esa transferencia.

Las operaciones que afecten varias cuentas se guardarán de forma consistente para evitar saldos incompletos.

## 4. Función de comparación del estado de cuenta

### Entradas

El usuario selecciona una tarjeta y un periodo, y proporciona el estado mediante:

- Texto pegado, como el ejemplo compartido.
- PDF del estado de cuenta, si se habilita esa entrada.

La comparación se hace contra los gastos que el usuario **ya ingresó manualmente** para esa tarjeta y ese periodo.

### Datos que se comparan

- Fecha de operación.
- Importe cobrado en CLP.
- Descripción del comercio, como referencia para validar la coincidencia.

El lector deberá entender fechas `DD/MM/YYYY` y valores como `$ 21.990`. Los nombres de comercios pueden venir con prefijos de procesadores —por ejemplo, `PAYU *UBER EATS`—, por lo que se normalizarán para sugerir coincidencias sin ocultar el texto original.

### Resultado

La pantalla mostrará cuatro grupos:

1. **Coinciden:** misma fecha, importe en CLP y descripción (ignorando mayúsculas, acentos y puntuación).
2. **Solo en tus gastos:** lo ingresaste en la app, pero no aparece en el estado.
3. **Solo en el estado:** aparece un cargo, pero no hay un gasto manual correspondiente.
4. **Posibles coincidencias:** coinciden la fecha y el importe, pero la descripción difiere; requiere revisión manual.

Cada cargo solo puede emparejarse con un gasto. Esto evita que dos cargos repetidos del mismo comercio se marquen como una sola coincidencia. Una posible coincidencia se mostrará como tal; la app no la confirmará silenciosamente. Las fechas deben ser el mismo día; ambos extremos del rango elegido se incluyen.

Las comisiones, intereses e impuestos que figuren como cargos también pueden aparecer como **solo en el estado** si no existe un gasto manual asociado. Los pagos y abonos no se compararán contra gastos de compra. La comparación no cambia registros por sí sola; cada cargo **solo en el estado** tendrá una acción explícita para agregarlo como gasto a la tarjeta seleccionada, previa confirmación. No se verificará el saldo total de la tarjeta.

### Ejemplo

Gasto ingresado manualmente:

```text
21/09/2026 · MERPAGO · CLP 11.000
```

Línea del estado:

```text
21/09/2026 · MERPAGO*KRISPYKREME · $ 11.000
```

La app la mostrará como **posible coincidencia** porque la fecha y el importe son iguales, pero la descripción difiere. Si confirmas el cargo desde **Solo en el estado**, podrás agregarlo explícitamente a tus movimientos.

## 5. Estructura de datos en Firebase

Cada persona tendrá sus datos bajo su propio identificador:

```text
users/{userId}
  accounts/{accountId}
  transactions/{transactionId}
  categories/{categoryId}
  budgets/{budgetId}
  goals/{goalId}
  assets/{assetId}
  reconciliations/{reconciliationId}

Storage:
  users/{userId}/statements/{statementId}.pdf
```

Una conciliación, si se conserva para poder revisarla después, tendrá sus resultados separados de los movimientos. Guardar un informe de comparación **no creará ni cambiará gastos**.

## 6. Pantallas y diseño

El diseño priorizará claridad, lectura rápida y una acción principal visible. En escritorio tendrá navegación lateral; en móvil, navegación inferior.

```text
┌ FinTrack ─────────────┬───────────────────────────────────┐
│ Resumen               │ Resumen del mes                   │
│ Cuentas               │ Patrimonio · Gastos · Presupuestos│
│ Movimientos           │ Actividad reciente                │
│ Presupuestos          │                                   │
│ Objetivos             │ [ + Añadir gasto ]                │
│ Tarjetas              │                                   │
│ Comparar estado       │                                   │
└───────────────────────┴───────────────────────────────────┘
```

Pantallas principales:

- **Resumen:** saldos, patrimonio estimado, gastos del mes y alertas de presupuesto.
- **Cuentas y tarjetas:** saldo, deuda, disponible y movimientos.
- **Añadir movimiento:** importe CLP, fecha, comercio, categoría, cuenta o tarjeta.
- **Presupuestos:** límite mensual y gasto registrado por categoría.
- **Objetivos:** monto objetivo, fecha y progreso.
- **Comparar estado:** elegir tarjeta y periodo, pegar texto o subir PDF, revisar coincidencias y diferencias.

Estilo visual propuesto: **Material Design 3**, con lenguaje visual plano inspirado en las aplicaciones de Google, fondos neutros, texto de alto contraste y color semántico para estados financieros.

## 7. Seguridad

- Las reglas de Firestore y Storage limitarán cada usuario a sus propios datos.
- Los PDF serán privados y no se expondrán mediante enlaces públicos.
- Las credenciales y contraseñas se gestionarán con Firebase Authentication.
- La configuración web de Firebase no reemplaza las reglas de seguridad.
- No se guardarán datos completos de la tarjeta bancaria; bastan nombre, últimos dígitos opcionales y datos necesarios para la app.

## 8. Entregas sugeridas

1. **Base:** inicio de sesión, cuentas, tarjetas y registro manual de movimientos.
2. **Organización:** presupuestos, objetivos, pagos de tarjeta, préstamos y resumen.
3. **Comparación:** texto pegado, parser del formato compartido, pantalla de resultados y pruebas con cargos repetidos.
4. **PDF y despliegue:** extracción de texto del PDF, reglas de acceso y publicación en Cloudflare Pages.

La comparación con texto pegado puede ser la primera versión: permite validar la lógica antes de añadir lectura de PDF.

## 9. Estado actual

`flutter_app/` contiene un prototipo funcional con tema oscuro Material 3 e Inter, navegación responsive, CRUD local de cuentas, movimientos, presupuestos, objetivos y categorías, transferencias, pagos de tarjetas y créditos en cuotas, comparación de texto pegado de estados de cuenta y un módulo de reportes con rango de fechas, gráficos e indicadores.

Los datos siguen almacenados en memoria de prueba y se reinician al recargar. Firebase Authentication y Firestore todavía no están conectados. La comparación de texto no modifica movimientos automáticamente; los cargos del estado se agregan solo mediante la acción confirmada **Agregar a la app**. La extracción directa de PDF sigue pendiente.

## 10. Propuesta visual: Material Design 3 estilo Google

### Dirección visual

- Interfaz plana, limpia y funcional; evitar texturas, brillos, gradientes decorativos y sombras fuertes.
- Usar componentes Material 3 de Flutter para botones, campos, diálogos, menús y navegación.
- Fondos claros y superficies blancas para que cifras y tablas sean fáciles de leer.
- Esquinas suavemente redondeadas, sin convertir todos los controles en cápsulas.
- Reservar el color para acciones, selección y estados; no colorear cada elemento sin necesidad.

### Paleta clara

| Token | Color | Uso |
|---|---|---|
| `primary` | `#1A73E8` | Acción principal, selección y enlaces; azul Google. |
| `primaryContainer` | `#E8F0FE` | Elementos seleccionados y fondos informativos suaves. |
| `background` | `#F8F9FA` | Fondo general de la aplicación. |
| `surface` | `#FFFFFF` | Tarjetas, paneles, formularios y diálogos. |
| `textPrimary` | `#202124` | Texto principal y cifras. |
| `textSecondary` | `#5F6368` | Descripciones, etiquetas y datos secundarios. |
| `outline` | `#DADCE0` | Bordes, divisores y contornos de campos. |
| `success` | `#188038` | Ingresos, metas cumplidas y coincidencias confirmadas. |
| `successContainer` | `#E6F4EA` | Fondo suave para estados positivos. |
| `warning` | `#B06000` | Presupuestos próximos al límite y revisión pendiente. |
| `warningContainer` | `#FEF7E0` | Fondo suave para avisos. |
| `error` | `#D93025` | Errores, cargos no reconocidos y presupuestos excedidos. |
| `errorContainer` | `#FCE8E6` | Fondo suave para errores y diferencias importantes. |

Los colores de estado siempre se acompañarán de texto e icono; no se comunicarán diferencias únicamente mediante color.

### Modo oscuro opcional

Dejar prevista una variante oscura basada en Material 3, activable después de completar y validar el tema claro:

| Token | Color sugerido |
|---|---|
| `background` | `#202124` |
| `surface` | `#292A2D` |
| `surfaceContainer` | `#303134` |
| `textPrimary` | `#E8EAED` |
| `textSecondary` | `#BDC1C6` |
| `primary` | `#8AB4F8` |
| `success` | `#81C995` |
| `warning` | `#FDD663` |
| `error` | `#F28B82` |

### Tipografía y cifras

- Usar **Inter**, disponible en Google Fonts, por su alta legibilidad en pantallas pequeñas, textos e importes financieros.
- Títulos de página: 28–32 px; títulos de sección: 20–24 px; texto y formularios: 14–16 px.
- Importes destacados: 28–36 px según el espacio disponible.
- Usar cifras tabulares cuando estén disponibles para alinear importes en listas.
- Presentar CLP en formato chileno, por ejemplo **`$ 21.990`**, y fechas de forma legible, como **`21 sept 2026`**.

### Espaciado, bordes e iconografía

- Usar una escala consistente de espaciado: **4, 8, 12, 16, 24 y 32 px**.
- Radio habitual de tarjetas y campos: **8–12 px**; botones principales: **20–24 px**.
- Elevación mínima: preferir cambios de superficie y bordes sutiles a sombras notorias.
- Usar iconos Material Symbols o Material Icons y acompañar los iconos importantes con etiquetas.
- Mantener áreas táctiles de al menos **48 × 48 px**.

### Patrones de interfaz

1. **Navegación responsive:** `NavigationRail` o panel lateral en escritorio; barra inferior de 4–5 destinos en móvil. Las secciones secundarias van dentro de cada destino.
2. **Resumen en tarjetas:** indicadores principales en tarjetas simples; cuadrícula en escritorio y lista vertical en móvil.
3. **Listas financieras:** comercio y categoría a la izquierda; fecha y cuenta como información secundaria; importe alineado a la derecha. Usar color de estado con moderación.
4. **Acción principal visible:** botón `Añadir movimiento` destacado en el resumen y accesible desde móvil mediante botón de acción flotante o botón inferior.
5. **Formulario de movimiento:** formulario corto con importe, fecha, comercio, categoría y cuenta/tarjeta. Revelar campos adicionales solo cuando correspondan; por ejemplo, cuotas al elegir tarjeta.
6. **Presupuesto visual:** barra de progreso con importe usado y límite; cambiar a aviso al acercarse al límite y a error al excederlo. Mostrar siempre los valores además de la barra.
7. **Estados de pantalla:** incluir carga con skeleton, estados vacíos con explicación y acción clara, confirmaciones y errores recuperables.
8. **Confirmaciones y errores:** preferir mensajes breves junto al campo o una notificación discreta; reservar diálogos para acciones que requieran decisión explícita.
9. **Gráficos accesibles:** títulos, leyendas e importes legibles; no depender solo de colores para distinguir categorías.

### Patrón específico: comparación de estado de cuenta

- Encabezado con nombre de tarjeta y periodo seleccionado.
- Resumen superior con contadores: **Coinciden**, **Solo en mis gastos**, **Solo en el estado** y **Revisar**.
- En escritorio, comparación de registros y cargos en dos columnas; en móvil, secciones apiladas con filtros por resultado.
- Cada fila muestra fecha, comercio original, importe CLP y estado con etiqueta e icono.
- Las posibles coincidencias se presentan como sugerencias, claramente distintas de una coincidencia confirmada.
- Acciones permitidas: cambiar filtro, abrir detalles, copiar o exportar el informe. La pantalla no ofrecerá acciones para crear, editar o borrar movimientos.

### Tema de Flutter

Implementar los colores y tipografías como tokens en un `ThemeData` central con `ColorScheme.fromSeed`, y usar componentes Material 3 (`useMaterial3: true`). Evitar definir colores aislados dentro de cada pantalla; así, el tema oscuro y futuros ajustes se podrán mantener desde un solo lugar.
