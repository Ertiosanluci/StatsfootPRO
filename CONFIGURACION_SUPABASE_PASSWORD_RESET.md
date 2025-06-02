# Configuración de Recuperación de Contraseña en Supabase

## URLs de Redirección que debes configurar en Supabase Dashboard

### 1. Acceder a la configuración de Authentication en Supabase

1. Ve a tu proyecto en [https://supabase.com/dashboard](https://supabase.com/dashboard)
2. Navega a **Authentication > Settings**
3. Busca la sección **Site URL and Redirect URLs**

### 2. Configurar Redirect URLs

En la sección **Redirect URLs**, agrega las siguientes URLs:

#### Para aplicaciones móviles (Android/iOS):
```
statsfoot://reset-password
```

#### Para aplicación web:
```
https://statsfootpro.netlify.app/app/#/password_reset
```

#### Para la página de redirección HTML:
```
https://statsfootpro.netlify.app/reset-password
```

### 3. Configuración completa de Redirect URLs

Tu lista de Redirect URLs debería incluir:
- `statsfoot://reset-password` (para móviles)
- `https://statsfootpro.netlify.app/app/#/password_reset` (para web)
- `https://statsfootpro.netlify.app/reset-password` (página de redirección)
- `statsfoot://match` (para partidos - si ya lo tienes configurado)

### 4. Site URL

Asegúrate de que tu **Site URL** esté configurada como:
```
https://statsfootpro.netlify.app
```

## Cómo funciona el flujo de recuperación

1. **Usuario solicita reset**: En la app, el usuario ingresa su email en `PasswordResetRequestScreen`
2. **Supabase envía email**: Se envía un email con un enlace a `https://statsfootpro.netlify.app/reset-password`
3. **Página de redirección**: El usuario hace clic en el enlace y llega a `reset-password.html`
4. **Redirección automática**: La página HTML detecta si es móvil o web y redirige apropiadamente:
   - **Móvil**: `statsfoot://reset-password?access_token=...&refresh_token=...`
   - **Web**: `https://statsfootpro.netlify.app/app/#/password_reset?access_token=...&refresh_token=...`
5. **App procesa tokens**: Flutter detecta el deep link, establece la sesión y navega a `PasswordResetScreen`
6. **Usuario cambia contraseña**: En `PasswordResetScreen`, el usuario ingresa nueva contraseña

## Archivos involucrados

- `lib/password_reset_request_screen.dart` - Pantalla para solicitar reset
- `lib/password_reset_screen.dart` - Pantalla para establecer nueva contraseña
- `lib/main.dart` - Manejo de deep links y rutas
- `lib/login.dart` - Botón "¿Olvidaste tu contraseña?"
- `netlify-redirect/reset-password.html` - Página de redirección
- `android/app/src/main/AndroidManifest.xml` - Configuración Android
- `ios/Runner/Info.plist` - Configuración iOS

## Testing

### Para probar en desarrollo:

1. **Configurar Supabase** con las URLs listadas arriba
2. **Desplegar** `reset-password.html` en Netlify
3. **Probar flujo completo**:
   - Abrir app → Login → "¿Olvidaste tu contraseña?"
   - Ingresar email → Revisar email
   - Hacer clic en enlace del email
   - Verificar que la app se abre en la pantalla de nueva contraseña
   - Cambiar contraseña y verificar que funciona

### URLs de prueba:

- **Página de redirección**: https://statsfootpro.netlify.app/reset-password
- **App web**: https://statsfootpro.netlify.app/app/
- **Deep link móvil**: `statsfoot://reset-password`

## Notas importantes

- Los tokens de acceso tienen un tiempo de vida limitado (típicamente 1 hora)
- La página de redirección maneja fallbacks automáticos entre móvil y web
- Los deep links solo funcionan si la app está instalada
- En desarrollo, puedes probar los deep links usando ADB (Android) o simuladores
