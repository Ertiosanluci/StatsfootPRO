# 🚨 SOLUCIÓN URGENTE: NO SE ENCONTRARON TOKENS DE AUTENTICACIÓN

## ❌ PROBLEMA CONFIRMADO
El error "enlace inválido porque no se encontraron tokens de autenticación" significa que **Supabase NO está enviando los tokens** en el enlace del email.

## 🔧 CAUSA RAÍZ
**Configuración incorrecta en Supabase Dashboard**

## ⚡ SOLUCIÓN PASO A PASO

### PASO 1: IR A SUPABASE DASHBOARD
1. Abre tu navegador
2. Ve a: https://supabase.com/dashboard
3. Selecciona tu proyecto StatsFoot PRO

### PASO 2: CONFIGURAR AUTHENTICATION SETTINGS
1. En el menú lateral: **Authentication**
2. Luego: **Settings**
3. Buscar: **URL Configuration**

### PASO 3: CONFIGURAR SITE URL
```
Site URL: https://statsfootpro.netlify.app
```

### PASO 4: CONFIGURAR REDIRECT URLS (MUY IMPORTANTE)
**Agregar TODAS estas URLs en "Redirect URLs":**

```
https://statsfootpro.netlify.app/reset-password
https://statsfootpro.netlify.app/**
statsfoot://reset-password
statsfoot://**
http://localhost:3000/reset-password
```

**⚠️ IMPORTANTE:** Agregar cada URL en una línea separada

### PASO 5: VERIFICAR EMAIL TEMPLATES
1. Ve a: **Authentication** → **Email Templates**
2. Selecciona: **Reset Password**
3. Verificar que el contenido tenga:
```html
<a href="{{ .SiteURL }}/reset-password?access_token={{ .Token }}&type=recovery&redirect_to={{ .RedirectTo }}">
  Restablecer contraseña
</a>
```

### PASO 6: GUARDAR CONFIGURACIÓN
1. Hacer clic en **Save** o **Update**
2. Esperar confirmación de guardado

## 🧪 TESTING INMEDIATO

### Después de configurar Supabase:

1. **Solicitar nuevo reset** desde la app
2. **Revisar email** recibido
3. **Verificar URL** del enlace:
   - Debe contener: `access_token=...`
   - Debe contener: `refresh_token=...`
   - Debe contener: `type=recovery`

### URL Correcta debe verse así:
```
https://statsfootpro.netlify.app/reset-password?access_token=eyJ...&refresh_token=abc...&type=recovery&expires_in=3600
```

### URL Incorrecta (actual):
```
https://statsfootpro.netlify.app/reset-password
```

## ⏰ TIEMPO ESTIMADO
- **5 minutos** para configurar Supabase
- **2 minutos** para hacer nueva prueba
- **TOTAL: 7 minutos**

## 🎯 RESULTADO ESPERADO
✅ Enlaces con tokens válidos
✅ Página web mostrando opciones (no error)
✅ Deep links funcionando
✅ Flujo completo operativo

## 🚨 SI SIGUE SIN FUNCIONAR
1. Verificar que hayas guardado la configuración
2. Esperar 1-2 minutos para propagación
3. Probar con email diferente
4. Revisar logs en consola del navegador

## 📞 PRÓXIMO PASO
**CONFIGURAR SUPABASE AHORA** → Luego probar reset inmediatamente
