# Despliegue automático en Cloudflare Workers

Cada `push` a `feature-light-version` compila Flutter Web y actualiza el Worker
estático existente `fintrack`, que atiende `fintrack.castolo.dev`. No se crea ni
se elimina el Worker en cada despliegue.

```
git push → GitHub Actions (analyze + test + build) → wrangler deploy → fintrack.castolo.dev
```

Workflow: `.github/workflows/deploy-cloudflare.yml`  
Configuración de Wrangler: `wrangler.jsonc` (estáticos en `flutter_app/build/web`).

## Configuración única

1. Conserva el Worker existente llamado `fintrack` y el dominio personalizado.
   No conectes el proyecto a Pages ni crees otro recurso.
2. En GitHub, `Castolo6/FinTrack` → **Settings → Secrets and variables → Actions**,
   crea estos *repository secrets*:

   | Nombre | Valor |
   | --- | --- |
   | `CLOUDFLARE_API_TOKEN` | Token de Cloudflare con permiso **Account → Workers Scripts → Edit/Write**, limitado a la cuenta que contiene `fintrack`. |
   | `CLOUDFLARE_ACCOUNT_ID` | Account ID de esa misma cuenta. |

   ⚠️ No uses `Pages Write` para este Worker. No pegues el token en el chat ni
   lo agregues al repositorio. Si ya creaste un token con `Pages Write`, crea
   uno nuevo con `Workers Scripts: Edit/Write` y reemplaza el secreto de GitHub.

3. En Firebase Authentication → Settings → Authorized domains, confirma que
   esté `fintrack.castolo.dev`.

## Despliegue

Después de guardar los secretos y publicar el workflow, cada push a la rama
`feature-light-version` ejecuta `flutter analyze`, `flutter test`,
`flutter build web --release` y `wrangler deploy --config wrangler.jsonc`.
Si alguna prueba falla, no se despliega. El resultado se ve en GitHub → Actions.

También se puede iniciar a mano desde **Actions → Deploy FinTrack en Cloudflare Workers → Run workflow**.

## Errores comunes

| Error | Causa / solución |
| --- | --- |
| `script not found` o `Authentication failed` | El token está mal, pertenece a otra cuenta o no tiene `Workers Scripts: Edit/Write`. Actualiza `CLOUDFLARE_API_TOKEN`. |
| `workers_dev` o Worker no encontrado | Revisa que `CLOUDFLARE_ACCOUNT_ID` sea la cuenta correcta y que `wrangler.jsonc` diga `"name": "fintrack"`. |
| `Pages project does not exist` | Se está usando `wrangler pages deploy`; el recurso actual es un Worker. El workflow debe ejecutar `wrangler deploy`. |
| `fintrack.castolo.dev` no actualiza | Confirma en Cloudflare que el dominio personalizado siga asociado al Worker `fintrack`; revisa caché con Ctrl+F5. |

## Despliegue manual de respaldo

Desde la raíz del repositorio, con un token `Workers Scripts: Edit/Write`
configurado localmente:

```bash
cd flutter_app
flutter build web --release
cd ..
npx wrangler deploy --config wrangler.jsonc
```
