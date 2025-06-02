# Configuración de Supabase para Password Reset

## Problema Identificado

El enlace del correo va directamente a la aplicación Flutter web (`https://statsfootpro.netlify.app/app/`) en lugar de ir a nuestra página HTML de redirect (`https://statsfootpro.netlify.app/reset-password`).

## Solución: Configurar Redirect URLs en Supabase

### 1. Acceder al Dashboard de Supabase

1. Ve a https://app.supabase.com
2. Selecciona tu proyecto StatsFoot
3. Ve a **Authentication** → **Settings**

### 2. Configurar Site URL

En la sección **Site URL**, debe estar configurado como:
```
https://statsfootpro.netlify.app
```

### 3. Configurar Redirect URLs

En la sección **Redirect URLs**, añade las siguientes URLs:

```
https://statsfootpro.netlify.app/reset-password
https://statsfootpro.netlify.app/reset-password.html
http://localhost:3000/reset-password
statsfoot://reset-password
```

### 4. Configurar Email Templates

Ve a **Authentication** → **Email Templates** → **Reset Password**

#### Template HTML que debe estar configurado:

```html
<h2>Restablecer contraseña</h2>
<p>Hola,</p>
<p>Haz clic en el siguiente enlace para restablecer tu contraseña:</p>
<p><a href="{{ .ConfirmationURL }}">Restablecer contraseña</a></p>
<p>Si no solicitaste este cambio, puedes ignorar este correo.</p>
<p>Saludos,<br>El equipo de StatsFoot</p>
```

#### Configuración importante:

- **Subject**: `Restablecer contraseña - StatsFoot`
- **Redirect URL**: `https://statsfootpro.netlify.app/reset-password`

⚠️ **CRÍTICO**: Asegúrate de que el **Redirect URL** en el template de email sea exactamente:
```
https://statsfootpro.netlify.app/reset-password
```

NO debe ser:
- `https://statsfootpro.netlify.app/app/`
- `https://statsfootpro.netlify.app/app/#/password_reset`

### 5. Flujo Correcto Esperado

1. Usuario solicita reset desde la app
2. Supabase envía email con enlace a: `https://statsfootpro.netlify.app/reset-password?access_token=...`
3. Netlify redirect procesa la URL y la envía a `reset-password.html`
4. La página HTML extrae los tokens y redirige a: `statsfoot://reset-password?access_token=...`
5. La app móvil recibe el deep link y abre `PasswordResetScreen`

### 6. Verificar Configuración

Para verificar que la configuración es correcta:

1. Solicita un reset de contraseña desde la app
2. Revisa el email recibido
3. El enlace debe ser: `https://statsfootpro.netlify.app/reset-password?access_token=...`
4. NO debe ser: `https://statsfootpro.netlify.app/app/...`

### 7. Si el problema persiste

Si aún no funciona, verifica:

1. **Configuración en código**: Que estés usando la URL correcta en `resetPasswordForEmail`
2. **Cache de Supabase**: Espera unos minutos después de cambiar la configuración
3. **Logs de Supabase**: Revisa los logs de autenticación para ver qué URL se está generando

### 8. URL de desarrollo vs producción

Para desarrollo local, puedes configurar:
- Site URL: `http://localhost:3000`
- Redirect URL: `http://localhost:3000/reset-password`

Para producción:
- Site URL: `https://statsfootpro.netlify.app`
- Redirect URL: `https://statsfootpro.netlify.app/reset-password`
