# Configuración Firebase de FinTrack

## Proyecto conectado

- Firebase project: `fintrack-personal-cl-20260928` (FinTrack Personal CL).
- Firestore: base `(default)` en `southamerica-west1` (Santiago).
- Flutter Web: app registrada con `lib/firebase_options.dart`.
- Reglas por usuario: `firestore.rules`; cada usuario solo puede leer/escribir bajo `users/{uid}`.

## Habilitar autenticación

La app ya tiene pantallas de registro e inicio de sesión con correo/contraseña y Google. Ambos proveedores están habilitados en el proyecto. Para revisarlos o cambiar su configuración:

1. Abre [Firebase Console → Authentication](https://console.firebase.google.com/project/fintrack-personal-cl-20260928/authentication).
2. Pulsa **Get started** si aparece.
3. En **Sign-in method**, habilita **Email/Password** y **Google**. Para Google, selecciona un correo de soporte.
4. En **Settings → Authorized domains**, confirma `localhost` para desarrollo; al publicar, agrega el dominio `*.pages.dev` y el dominio personalizado de Cloudflare.

## Desplegar reglas de Firestore

Desde `flutter_app/`:

```bash
firebase deploy --only firestore:rules --project=fintrack-personal-cl-20260928
```

## Ejecutar la app

```bash
cd flutter_app
flutter run -d chrome
```

Los documentos se guardan por usuario en estas colecciones:

```text
users/{uid}/accounts
users/{uid}/categories
users/{uid}/transactions
users/{uid}/budgets
users/{uid}/goals
users/{uid}/goalMovements
users/{uid}/loanInstallmentPayments
users/{uid}/profile/main
```

La configuración web de Firebase es pública por diseño; la protección de datos se aplica con las reglas de Firestore, no ocultando la API key del cliente.
