# 🔍 Diagnóstico del Problema de Recuperación de Contraseña

## 🚨 Problema Identificado

El enlace que recibes:
```
https://vlygdxrppzoqlkntfypx.supabase.co/auth/v1/verify?token=pkce_27e6fb2e04e6a6b6f47db7e15f9b525825f328fc5c93d8c6f56a68f3&type=recovery&redirect_to=https://statsfootpro.netlify.app/reset-password
```

**Te lleva a la pantalla inicial** en lugar de procesar la recuperación porque:

1. **Supabase no está pasando los tokens** a la página de redirección
2. **Los tokens se procesan en el servidor** antes de redirigir
3. **La sesión no se está estableciendo** correctamente

## 🔧 Soluciones a Probar

### **Solución 1: Usar página de debug (INMEDIATA)**

1. **Sube la página de debug** a Netlify:
   - Archivo: `netlify-redirect/reset-password-debug.html`
   - URL: `https://statsfootpro.netlify.app/reset-password-debug`

2. **Prueba el nuevo flujo**:
   - Ve a la app → "¿Olvidaste tu contraseña?" 
   - Ingresa email → Revisa email
   - Haz clic en el enlace → Deberías ver información de debug

### **Solución 2: Cambiar redirect URL en Supabase**

En tu Supabase Dashboard:

1. Ve a **Authentication** → **Settings** → **Site URL and Redirect URLs**

2. **Cambia las redirect URLs** por estas:

```
statsfoot://reset-password
https://statsfootpro.netlify.app/reset-password-debug
```

3. **Elimina temporalmente** las otras URLs para evitar confusión

### **Solución 3: Verificar configuración de Auth**

En Supabase Dashboard → **Authentication** → **Settings**:

1. **Verifica que Site URL sea**:
   ```
   https://statsfootpro.netlify.app
   ```

2. **En "Auth Provider Settings"**, verifica que esté habilitado:
   - ✅ Email confirmations
   - ✅ Password recovery

## 📱 Pasos de Diagnóstico

### **Paso 1: Probar con página de debug**

1. **Actualiza el código** (ya hecho):
   ```dart
   redirectTo: 'https://statsfootpro.netlify.app/reset-password-debug'
   ```

2. **Sube `reset-password-debug.html`** a Netlify

3. **Solicita nuevo email** de reset

4. **Haz clic en el enlace** del email

5. **La página de debug te mostrará**:
   - URL completa recibida
   - Parámetros encontrados
   - Si hay tokens o no

### **Paso 2: Verificar información de debug**

La página te dirá exactamente qué está pasando:

- ✅ **Si hay tokens**: El problema está en el manejo de la app
- ❌ **Si NO hay tokens**: El problema está en la configuración de Supabase

### **Paso 3: Ajustar según resultados**

#### **Si hay tokens**:
- El problema está en la aplicación Flutter
- Usar los tokens para establecer sesión

#### **Si NO hay tokens**:
- El problema está en Supabase
- Necesitamos cambiar la configuración

## 🎯 Solución Alternativa Simple

Si el problema persiste, podemos usar un enfoque más directo:

### **Opción A: Manejo en la app sin redirección**

```dart
// En lugar de redirigir, manejar todo en la app
await Supabase.instance.client.auth.resetPasswordForEmail(
  email,
  // Sin redirectTo - Supabase usará configuración por defecto
);
```

### **Opción B: Usar deep link directo**

Configurar en Supabase:
```
Redirect URL: statsfoot://reset-password
```

Sin página intermedia.

## 📝 Información Necesaria

Para diagnosticar mejor, necesito que pruebes con la página de debug y me digas:

1. **¿Qué información muestra** la página de debug?
2. **¿Aparecen tokens** en los parámetros?
3. **¿Cuál es la URL completa** que recibe la página?

## ⚡ Acción Inmediata

**HACER AHORA**:

1. **Subir** `reset-password-debug.html` a Netlify
2. **Probar** el flujo completo
3. **Reportar** qué información muestra la página de debug

Una vez que tengamos esa información, podré darte la solución exacta.

---

**🎯 El objetivo es identificar exactamente dónde se pierden los tokens en el flujo.**
