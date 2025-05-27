# 🔧 VERIFICACIÓN CONFIGURACIÓN SUPABASE - PASO A PASO

## 📋 CHECKLIST URGENTE

### ✅ PASO 1: ACCEDER A SUPABASE DASHBOARD
1. Ir a: https://supabase.com/dashboard
2. Seleccionar proyecto StatsFoot PRO
3. Ir a **Authentication** → **Settings**

### ✅ PASO 2: VERIFICAR SITE URL
**Debe estar configurado EXACTAMENTE así:**
```
Site URL: https://statsfootpro.netlify.app
```

### ✅ PASO 3: VERIFICAR REDIRECT URLS
**Debe contener TODAS estas URLs (una por línea):**
```
https://statsfootpro.netlify.app/reset-password
https://statsfootpro.netlify.app/**
statsfoot://reset-password
statsfoot://**
```

### ✅ PASO 4: VERIFICAR EMAIL TEMPLATES
1. Ir a **Authentication** → **Email Templates**
2. Seleccionar **Reset Password**
3. Verificar que contiene:

```html
<a href="{{ .SiteURL }}/reset-password?access_token={{ .Token }}&type=recovery&redirect_to={{ .RedirectTo }}">
  Restablecer contraseña
</a>
```

### ✅ PASO 5: GUARDAR Y PROBAR
1. **GUARDAR** toda la configuración
2. Esperar 1-2 minutos
3. Solicitar nuevo reset password
4. Verificar que el email contenga tokens

## 🔍 DIAGNÓSTICO RÁPIDO

### ¿Cómo saber si está funcionando?
El enlace en el email DEBE verse así:
```
https://statsfootpro.netlify.app/reset-password?access_token=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...&refresh_token=abc123...&type=recovery&expires_in=3600
```

### ¿Cómo saber si NO está funcionando?
El enlace se ve así (SIN parámetros):
```
https://statsfootpro.netlify.app/reset-password
```

## 🚨 PROBLEMA MÁS COMÚN
**Configuración incorrecta en Email Templates**

Si el template no tiene las variables `{{ .Token }}` correctas, Supabase NO incluirá los tokens en el enlace.

## ⏰ TIEMPO TOTAL: 5 MINUTOS
