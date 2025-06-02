# 🚨 SOLUCIÓN RÁPIDA - Email Template Problema

## El Problema
Estás recibiendo código HTML crudo en lugar de un email formateado porque Supabase necesita que configures el template de email.

## ✅ Solución Inmediata (5 minutos)

### 1. Ve a Supabase Dashboard
- Abre [https://supabase.com/dashboard](https://supabase.com/dashboard)
- Selecciona tu proyecto
- Ve a **Authentication** → **Settings** → **Email Templates**

### 2. Encuentra "Reset Password" Template
- Busca la sección "Reset Password" 
- Haz clic en **Edit**

### 3. Reemplaza TODO el contenido con esto:

```html
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Restablecer Contraseña - StatsFoot PRO</title>
</head>
<body style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; background-color: #f5f5f5;">
    <div style="background-color: white; border-radius: 10px; padding: 30px; box-shadow: 0 2px 10px rgba(0,0,0,0.1);">
        
        <!-- Header -->
        <div style="text-align: center; margin-bottom: 30px;">
            <h1 style="color: #1565C0; margin: 0; font-size: 28px;">🔐 StatsFoot PRO</h1>
            <p style="color: #666; margin: 10px 0 0 0;">Restablecer Contraseña</p>
        </div>
        
        <!-- Content -->
        <h2 style="color: #333; margin: 0 0 20px 0;">¡Hola!</h2>
        
        <p style="color: #666; line-height: 1.6; margin: 0 0 20px 0;">
            Recibimos una solicitud para restablecer tu contraseña en <strong>StatsFoot PRO</strong>.
        </p>
        
        <p style="color: #666; line-height: 1.6; margin: 0 0 30px 0;">
            Haz clic en el siguiente botón para establecer una nueva contraseña:
        </p>
        
        <!-- Button -->
        <div style="text-align: center; margin: 30px 0;">
            <a href="{{ .ConfirmationURL }}" 
               style="background-color: #1565C0; 
                      color: white; 
                      padding: 15px 30px; 
                      text-decoration: none; 
                      border-radius: 8px; 
                      display: inline-block; 
                      font-weight: bold; 
                      font-size: 16px;">
                🔓 Restablecer Contraseña
            </a>
        </div>
        
        <!-- Alternative link -->
        <div style="margin: 30px 0; padding: 15px; background-color: #f8f9fa; border-radius: 5px;">
            <p style="margin: 0 0 10px 0; font-weight: bold; color: #333; font-size: 14px;">
                O copia este enlace:
            </p>
            <p style="word-break: break-all; color: #1565C0; font-size: 14px; margin: 0;">
                {{ .ConfirmationURL }}
            </p>
        </div>
        
        <!-- Security notice -->
        <div style="margin: 30px 0 0 0; padding: 15px; background-color: #fff3cd; border-radius: 5px; border-left: 4px solid #ffc107;">
            <p style="margin: 0; color: #856404; font-size: 14px;">
                <strong>⚠️ Importante:</strong> Este enlace es válido por 1 hora. Si no solicitaste este cambio, ignora este correo.
            </p>
        </div>
    </div>
</body>
</html>
```

### 4. Guarda los Cambios
- Haz clic en **Save** o **Update**
- Espera 2-3 minutos para que se apliquen los cambios

### 5. Prueba Inmediatamente
- Ve a tu app → Login → "¿Olvidaste tu contraseña?"
- Ingresa tu email
- Revisa tu bandeja de entrada

## ✅ Resultado Esperado

Ahora deberías recibir un email que se ve así:

```
🔐 StatsFoot PRO
Restablecer Contraseña

¡Hola!

Recibimos una solicitud para restablecer tu contraseña en StatsFoot PRO.

Haz clic en el siguiente botón para establecer una nueva contraseña:

[🔓 Restablecer Contraseña]  ← BOTÓN AZUL CLICKEABLE

O copia este enlace:
https://statsfootpro.netlify.app/reset-password?access_token=...

⚠️ Importante: Este enlace es válido por 1 hora...
```

## 🔧 Si Aún No Funciona

1. **Verifica** que estés editando el template correcto ("Reset Password")
2. **Asegúrate** de hacer clic en "Save"
3. **Espera** 5 minutos antes de probar
4. **Prueba** con un email diferente
5. **Revisa** la carpeta de spam

## 💡 Próximo Paso

Una vez que el email se vea bien, el siguiente paso es hacer clic en el enlace del email y verificar que:
1. Te lleve a la página de redirección
2. Abra tu app
3. Te permita cambiar la contraseña

---

**⏱️ Tiempo estimado: 5 minutos para arreglar completamente el problema**
