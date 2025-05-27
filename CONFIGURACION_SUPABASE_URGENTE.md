# 🚨 CONFIGURACIÓN URGENTE DE SUPABASE - PASO A PASO

## ❗ PROBLEMA ACTUAL
Los enlaces de password reset NO contienen tokens porque **Supabase Dashboard no está configurado correctamente**.

## 🎯 SOLUCIÓN GARANTIZADA

### PASO 1: ACCEDER A SUPABASE DASHBOARD
1. Abre navegador
2. Ve a: `https://supabase.com/dashboard`
3. Inicia sesión
4. Selecciona tu proyecto **StatsFoot PRO**

### PASO 2: IR A AUTHENTICATION SETTINGS
1. En menú lateral: **Authentication**
2. Clic en: **Settings**
3. Buscar sección: **URL Configuration**

### PASO 3: CONFIGURAR SITE URL (OBLIGATORIO)
```
Site URL: https://statsfootpro.netlify.app
```
⚠️ **SIN barra al final**

### PASO 4: CONFIGURAR REDIRECT URLS (CRÍTICO)
**En el campo "Redirect URLs", agregar EXACTAMENTE estas líneas:**

```
https://statsfootpro.netlify.app/reset-password
https://statsfootpro.netlify.app/**
statsfoot://reset-password
statsfoot://**
http://localhost:3000/reset-password
```

**🔥 IMPORTANTE:**
- Una URL por línea
- NO agregar espacios extra
- NO agregar comas
- Presionar ENTER después de cada URL

### PASO 5: VERIFICAR EMAIL TEMPLATE
1. En **Authentication** → **Email Templates**
2. Seleccionar: **Reset Password**
3. El subject debe ser: `Reset Your Password`
4. El contenido debe incluir:
```html
<a href="{{ .SiteURL }}/reset-password?access_token={{ .Token }}&type=recovery&redirect_to={{ .RedirectTo }}">
  Reset Password
</a>
```

### PASO 6: GUARDAR CONFIGURACIÓN
1. Hacer clic en **Save** o **Update**
2. Verificar que aparezca mensaje de confirmación
3. **Esperar 1-2 minutos** para que los cambios se propaguen

### PASO 7: PROBAR LA CONFIGURACIÓN
1. Ve a la app StatsFoot PRO
2. Pantalla de login
3. "¿Olvidaste tu contraseña?"
4. Ingresa tu email
5. Enviar
6. **Revisar el email recibido**

### ✅ VERIFICACIÓN DE ÉXITO
El enlace en el email debe verse así:
```
https://statsfootpro.netlify.app/reset-password?access_token=XXXXXXX&type=recovery&refresh_token=XXXXXXX
```

### 🔍 HERRAMIENTA DE VERIFICACIÓN
Después de configurar Supabase, usa:
```
https://statsfootpro.netlify.app/verificar-tokens
```

Pega el enlace completo del email para verificar que contiene todos los tokens.

## ⚠️ SI AÚN NO FUNCIONA
1. Verifica que guardaste los cambios en Supabase
2. Espera 5 minutos para propagación
3. Envía nuevo email de reset password
4. NO uses enlaces antiguos

## 📞 CONTACTO DE EMERGENCIA
Si sigues teniendo problemas después de seguir estos pasos:
1. Captura pantalla de tu configuración en Supabase
2. Copia el enlace completo del email
3. Reporta el problema con evidencia

---
**Última actualización:** ${new Date().toISOString()}
**Estado:** Pendiente configuración Supabase Dashboard
