# Configuración de Recuperación de Contraseña en Supabase

## ⚠️ PROBLEMA IDENTIFICADO

Si recibes un email con código HTML sin procesar y variables como `{{ .ConfirmationURL }}`, necesitas configurar los templates de email en Supabase.

## 🔧 Solución: Configurar Templates de Email

### 1. Acceder a la configuración de Authentication en Supabase

1. Ve a tu proyecto en [https://supabase.com/dashboard](https://supabase.com/dashboard)
2. Navega a **Authentication > Settings**
3. Ve a la pestaña **Email Templates**

### 2. Configurar el Template de "Reset Password"

En **Email Templates**, busca **"Reset Password"** y reemplaza el contenido con:

```html
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Restablecer Contraseña - StatsFoot PRO</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body style="font-family: 'Segoe UI', Arial, sans-serif; margin: 0; padding: 0; background-color: #f5f5f5;">
    <div style="max-width: 600px; margin: 0 auto; background-color: white; border-radius: 10px; overflow: hidden; box-shadow: 0 4px 6px rgba(0,0,0,0.1);">
        
        <!-- Header -->
        <div style="background: linear-gradient(135deg, #1565C0, #1976D2); padding: 30px; text-align: center;">
            <h1 style="color: white; margin: 0; font-size: 28px; font-weight: bold;">🔐 StatsFoot PRO</h1>
            <p style="color: rgba(255,255,255,0.9); margin: 10px 0 0 0; font-size: 16px;">Restablecer Contraseña</p>
        </div>
        
        <!-- Content -->
        <div style="padding: 40px 30px;">
            <h2 style="color: #333; margin: 0 0 20px 0; font-size: 24px;">¡Hola!</h2>
            
            <p style="color: #666; line-height: 1.6; font-size: 16px; margin: 0 0 25px 0;">
                Recibimos una solicitud para restablecer tu contraseña en <strong>StatsFoot PRO</strong>.
            </p>
            
            <p style="color: #666; line-height: 1.6; font-size: 16px; margin: 0 0 30px 0;">
                Haz clic en el siguiente botón para establecer una nueva contraseña:
            </p>
            
            <!-- Button -->
            <div style="text-align: center; margin: 40px 0;">
                <a href="{{ .ConfirmationURL }}" 
                   style="background: linear-gradient(135deg, #1565C0, #1976D2); 
                          color: white; 
                          padding: 16px 32px; 
                          text-decoration: none; 
                          border-radius: 8px; 
                          display: inline-block; 
                          font-weight: bold; 
                          font-size: 16px;
                          box-shadow: 0 4px 12px rgba(21, 101, 192, 0.3);">
                    🔓 Restablecer Contraseña
                </a>
            </div>
            
            <!-- Alternative link -->
            <div style="margin: 30px 0; padding: 20px; background-color: #f8f9fa; border-radius: 8px; border-left: 4px solid #1565C0;">
                <p style="margin: 0 0 10px 0; font-weight: bold; color: #333; font-size: 14px;">O copia este enlace en tu navegador:</p>
                <p style="word-break: break-all; color: #666; font-size: 14px; margin: 0; font-family: 'Courier New', monospace;">{{ .ConfirmationURL }}</p>
            </div>
            
            <!-- Security notice -->
            <div style="margin: 30px 0 0 0; padding: 20px; background-color: #fff3cd; border-radius: 8px; border: 1px solid #ffeaa7;">
                <h3 style="margin: 0 0 15px 0; color: #856404; font-size: 16px;">⚠️ Información de Seguridad</h3>
                <ul style="margin: 0; padding-left: 20px; color: #856404; font-size: 14px; line-height: 1.5;">
                    <li>Este enlace es válido por <strong>1 hora</strong></li>
                    <li>Solo se puede usar <strong>una vez</strong></li>
                    <li>Si no solicitaste este cambio, <strong>ignora este correo</strong></li>
                    <li>Tu contraseña actual seguirá siendo válida hasta que la cambies</li>
                </ul>
            </div>
        </div>
        
        <!-- Footer -->
        <div style="background-color: #f8f9fa; padding: 20px 30px; text-align: center; border-top: 1px solid #dee2e6;">
            <p style="margin: 0; color: #6c757d; font-size: 14px;">
                © 2025 StatsFoot PRO. Todos los derechos reservados.
            </p>
            <p style="margin: 10px 0 0 0; color: #6c757d; font-size: 12px;">
                Este es un email automatizado, por favor no respondas a este mensaje.
            </p>
        </div>
    </div>
</body>
</html>
```

### 3. Configurar Redirect URLs

En **Authentication > Settings > Site URL and Redirect URLs**, agrega:

#### Redirect URLs:
```
statsfoot://reset-password
https://statsfootpro.netlify.app/app/#/password_reset
https://statsfootpro.netlify.app/reset-password
```

#### Site URL:
```
https://statsfootpro.netlify.app
```

## 🔍 Verificación del Template

### Cómo verificar que funciona:

1. **Guarda** el template en Supabase
2. **Prueba** enviando un email de reset desde la app
3. **Revisa** tu bandeja de entrada
4. **Verifica** que el email se vea como un email real (no código HTML)
5. **Confirma** que el enlace funciona

### Si aún ves código HTML:

1. **Verifica** que guardaste el template correctamente
2. **Espera** unos minutos para que los cambios se apliquen
3. **Prueba** desde una cuenta de email diferente
4. **Revisa** la carpeta de spam

## 🎨 Personalización Adicional

Puedes personalizar más el template cambiando:

- **Colores**: Modifica los valores hexadecimales (#1565C0, etc.)
- **Logo**: Reemplaza el emoji 🔐 con `<img src="URL_DE_TU_LOGO">`
- **Texto**: Ajusta los mensajes según tu preferencia
- **Estilo**: Modifica padding, margins, fuentes, etc.

## 📱 Alternativa: Email Template Minimalista

Si prefieres algo más simple:

```html
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Restablecer Contraseña</title>
</head>
<body style="font-family: Arial, sans-serif; padding: 20px; max-width: 600px; margin: 0 auto;">
    <h1 style="color: #1565C0;">🔐 Restablecer Contraseña</h1>
    
    <p>Hola,</p>
    
    <p>Recibimos una solicitud para restablecer tu contraseña en <strong>StatsFoot PRO</strong>.</p>
    
    <div style="margin: 30px 0; text-align: center;">
        <a href="{{ .ConfirmationURL }}" 
           style="background-color: #1565C0; color: white; padding: 15px 30px; text-decoration: none; border-radius: 5px; display: inline-block; font-weight: bold;">
            Restablecer Contraseña
        </a>
    </div>
    
    <p><strong>O copia este enlace:</strong></p>
    <p style="word-break: break-all; background-color: #f0f0f0; padding: 10px; border-radius: 5px;">
        {{ .ConfirmationURL }}
    </p>
    
    <hr style="margin: 30px 0;">
    
    <p style="color: #666; font-size: 14px;">
        <strong>⚠️ Información importante:</strong><br>
        • Este enlace es válido por 1 hora<br>
        • Si no solicitaste este cambio, ignora este correo
    </p>
</body>
</html>
```

## 🚨 Troubleshooting

### Problema: Sigo viendo código HTML
**Solución**: 
- Verifica que estés editando el template correcto ("Reset Password")
- Asegúrate de hacer clic en "Save" después de editar
- Espera 5-10 minutos antes de probar

### Problema: El enlace no funciona
**Solución**:
- Verifica las Redirect URLs en Supabase
- Asegúrate de que `reset-password.html` esté desplegado en Netlify

### Problema: No llega el email
**Solución**:
- Revisa carpeta de spam
- Verifica configuración SMTP en Supabase
- Prueba con diferentes proveedores de email

---

**🎯 Una vez configurado correctamente, deberías recibir emails profesionales con enlaces funcionales.**

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
