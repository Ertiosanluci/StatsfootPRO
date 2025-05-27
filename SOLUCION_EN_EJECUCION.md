## 🚨 SOLUCIÓN PASO A PASO - URGENTE

### 📅 **ESTADO:** 27 Mayo 2025 - EN EJECUCIÓN

---

## ✅ **PASO 1: HERRAMIENTAS CREADAS**
- ✅ Creado `diagnostico-urgente.html` para análisis en tiempo real
- ✅ Actualizada página de reset con enlace a diagnóstico
- ✅ Herramientas de verificación listas

---

## 🎯 **PASO 2: CONFIGURACIÓN SUPABASE (ACCIÓN REQUERIDA)**

### 📍 **IR A SUPABASE DASHBOARD AHORA:**
1. **Abrir:** https://supabase.com/dashboard
2. **Seleccionar:** Proyecto StatsFoot PRO  
3. **Ir a:** Authentication → Settings

### 📍 **VERIFICAR SITE URL:**
```
Site URL: https://statsfootpro.netlify.app
```
⚠️ **SIN barra final, SIN protocolo adicional**

### 📍 **VERIFICAR REDIRECT URLS (CRÍTICO):**
```
https://statsfootpro.netlify.app/reset-password
https://statsfootpro.netlify.app/**
statsfoot://reset-password
statsfoot://**
```
⚠️ **Cada URL en una línea separada**

### 📍 **VERIFICAR EMAIL TEMPLATE:**
1. **Ir a:** Authentication → Email Templates
2. **Seleccionar:** Reset Password  
3. **Verificar que contiene:**

```html
<a href="{{ .SiteURL }}/reset-password?access_token={{ .Token }}&type=recovery&redirect_to={{ .RedirectTo }}">
  Restablecer contraseña
</a>
```

⚠️ **IMPORTANTE:** Debe contener `{{ .Token }}` exactamente

---

## 🔄 **PASO 3: PROBAR CONFIGURACIÓN**

### A. **Después de configurar Supabase:**
1. **GUARDAR** todos los cambios en Supabase
2. **Esperar** 1-2 minutos
3. **Solicitar** nuevo reset password desde la app
4. **Revisar** el email recibido

### B. **El enlace DEBE verse así:**
```
https://statsfootpro.netlify.app/reset-password?access_token=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...&refresh_token=abc123...&type=recovery
```

### C. **Si el enlace se ve así (SIN tokens):**
```
https://statsfootpro.netlify.app/reset-password
```
**→ La configuración de Supabase está INCORRECTA**

---

## 🛠️ **PASO 4: VERIFICACIÓN CON HERRAMIENTAS**

### **Abrir página de diagnóstico:**
```
https://statsfootpro.netlify.app/diagnostico-urgente.html
```

### **O desde la app:**
1. Ir a reset-password con el enlace del email
2. Hacer clic en "🚨 DIAGNÓSTICO URGENTE"
3. Ver análisis completo

---

## ⏰ **TIEMPO ESTIMADO:**
- **Configuración Supabase:** 3-5 minutos
- **Prueba completa:** 2-3 minutos
- **Total:** 5-8 minutos

---

## 🎯 **SIGUIENTE ACCIÓN:**
**AHORA MISMO:** Configurar Supabase Dashboard según los pasos arriba

**Una vez configurado:** Notificar para continuar con la verificación
