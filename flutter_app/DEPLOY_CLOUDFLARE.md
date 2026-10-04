# Despliegue automático en Cloudflare Pages

Cada `push` a `feature-light-version` compila la app Flutter y la publica en
Cloudflare Pages sin subir archivos a mano. Todo el proyecto se crea **una sola
vez**; después nunca más hay que tocar el panel.

```
git push  →  GitHub Actions (Flutter analyze + test + build)  →  wrangler pages deploy  →  fintrack.castolo.dev
```

Workflow: `.github/workflows/deploy-cloudflare.yml`.

---

## Paso 1 — Crear el proyecto Pages (una sola vez)

Opción A, desde el panel:

1. **Workers & Pages → Create application → Pages → Upload assets**
2. Nombre del proyecto: `fintrack` (debe coincidir exactamente con el del panel de Cloudflare).
3. **Production branch:** `feature-light-version` (en Settings → Builds & deployments)
4. Sube una vez el contenido de `flutter_app/build/web` para que exista el primer deploy.

Opción B, desde la terminal (misma configuración):

```bash
npx wrangler pages project create fintrack --production-branch feature-light-version
npx wrangler pages deploy flutter_app/build/web --project-name fintrack --branch feature-light-version
```

> **Importante:** la rama de producción del proyecto debe ser
> `feature-light-version`, o los despliegues quedarían como *preview* y el
> dominio personalizado no se actualizaría.

## Paso 2 — Dominio personalizado (una sola vez)

1. En el proyecto Pages → **Custom domains → Set up a custom domain** → `fintrack.castolo.dev`.
2. Si el dominio hoy está en un Worker, elimínalo de ese Worker antes de asignarlo:
   Cloudflare → DNS → registro `fintrack` → debe quedar **proxied (nube naranja)**
   y el CNAME apuntando al proyecto Pages.

## Paso 3 — Secretos en GitHub (una sola vez)

1. Cloudflare → avatar → **My Profile → API Tokens → Create Token**.
2. Permisos: **Account → Cloudflare Pages → Edit** (o plantilla *Edit Cloudflare Workers*),
   alcance: tu cuenta. Copia el token **una sola vez**.
3. En GitHub: `Castolo6/FinTrack` → **Settings → Secrets and variables → Actions → New repository secret**:

| Nombre | Valor |
| --- | --- |
| `CLOUDFLARE_API_TOKEN` | el token del paso 1 |
| `CLOUDFLARE_ACCOUNT_ID` | Workers & Pages → barra lateral derecha (o de la URL del dashboard) |

⚠️ No los pegues en el chat, en issues ni en el repositorio. Solo existen como
secretos de GitHub; el workflow los inyecta en tiempo de ejecución.

## Paso 4 — Dominios autorizados en Firebase (una sola vez)

**Firebase Console → Authentication → Settings → Authorized domains → Add domain:**

- `fintrack.pages.dev`
- `fintrack.castolo.dev`

Sin esto, el registro e inicio de sesión fallan desde la app publicada.

---

## Cómo se despliega

```bash
git add flutter_app
git commit -m "feat(...): ..."
git push origin feature-light-version
```

GitHub Actions ejecuta: `flutter pub get` → `flutter analyze` → `flutter test`
→ `flutter build web --release` → `wrangler pages deploy`.
En 2–4 minutos la web nueva está en línea (refresca con `Ctrl+F5`).

El flujo también se puede lanzar a mano desde la pestaña **Actions** del
repositorio con el botón **Run workflow**.

## Solución de problemas

| Error | Causa y solución |
| --- | --- |
| `Falta el secreto CLOUDFLARE_API_TOKEN` | No se crearon los secretos del paso 3 (o están mal escritos). |
| `Authentication failed` / `10000` | Token inválido o sin permiso *Cloudflare Pages: Edit*. Crea uno nuevo. |
| `project not found` | El proyecto `fintrack` no existe (paso 1) o el account id es de otra cuenta. |
| Deploy sale como *preview* | La rama de producción del proyecto no es `feature-light-version` (Settings → Builds & deployments). |
| `The specified domain is already assigned` | El dominio sigue en otro proyecto/Worker; libéralo antes de asignarlo (paso 2). |
| GitHub rechaza ejecutar el workflow | La rama o Actions están restringidas (Settings → Actions → General → Allowed actions). |

## Despliegue puntual desde tu equipo (sin GitHub)

Si un día necesitas publicar a mano:

```bash
cd flutter_app
flutter build web --release
npx wrangler pages deploy build/web --project-name fintrack --branch feature-light-version
```

No borres ni recreas el proyecto: `pages deploy` agrega un despliegue nuevo al
proyecto existente y el anterior queda disponible para volver atrás
(Pages → Deployments → Rollback).
