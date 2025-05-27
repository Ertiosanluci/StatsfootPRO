# 🔧 SOLUCIÓN COMPLETA: ENLACE DE RECUPERACIÓN EXPIRADO

## 🎯 ACCIÓN INMEDIATA REQUERIDA

### 1. CONFIGURAR SUPABASE DASHBOARD (MUY IMPORTANTE)

**📋 PASOS OBLIGATORIOS:**

1. **Ir a tu Dashboard de Supabase:**
   ```
   https://supabase.com/dashboard/project/[TU-PROJECT-ID]
   ```

2. **Navegar a Authentication:**
   ```
   Authentication → Settings → URL Configuration
   ```

3. **Configurar Site URL:**
   ```
   Site URL: https://statsfootpro.netlify.app
   ```

4. **Agregar Redirect URLs (CRÍTICO):**
   ```
   Redirect URLs:
   https://statsfootpro.netlify.app/reset-password
   https://statsfootpro.netlify.app/**
   statsfoot://reset-password
   statsfoot://**
   http://localhost:3000/reset-password (para desarrollo)
   ```

5. **Guardar configuración**

### 2. VERIFICAR EMAIL TEMPLATES

1. **Ir a Authentication → Templates**
2. **Seleccionar "Reset Password"**
3. **Verificar que el link contenga:**
   ```
   {{ .SiteURL }}/reset-password?access_token={{ .Token }}&type=recovery
   ```

### 3. DESPLEGAR CAMBIOS EN NETLIFY

```bash
# Hacer commit de los cambios hechos
git add .
git commit -m "Fix password reset link expiration issues"
git push origin main
```

## 🧪 TESTING COMPLETO

### Test 1: Solicitar Reset
1. Abrir la app
2. Ir a login → "¿Olvidaste tu contraseña?"
3. Ingresar email registrado
4. Verificar que llegue el email

### Test 2: Verificar Enlace
1. Abrir email recibido
2. Hacer clic en el enlace
3. Verificar que se abra la página web correctamente
4. Verificar que no aparezca mensaje de "expirado"

### Test 3: Deep Link
1. En móvil: hacer clic en "Abrir en la aplicación"
2. Verificar que abra la app
3. Verificar que aparezca la pantalla de nueva contraseña

### Test 4: Completar Flujo
1. Ingresar nueva contraseña
2. Confirmar contraseña
3. Verificar que se actualice exitosamente
4. Probar login con nueva contraseña

## 🔍 DEBUGGING SI SIGUE FALLANDO

### Logs en la App
```dart
// Buscar estos logs en la consola:
🔄 Enviando reset password para: email@example.com
🔗 URL de redirección: https://statsfootpro.netlify.app/reset-password
✅ Email de reset enviado exitosamente

🔍 Validando tokens...
Access Token: Presente/Ausente
Refresh Token: Presente/Ausente
Type: recovery
```

### Logs en la Web
```javascript
// Abrir Developer Tools → Console
// Buscar estos logs:
🔍 Validando tokens...
Access Token: Presente
Refresh Token: Presente
Type: recovery
```

### Si los Tokens están Ausentes:
1. **Problema:** URL de Supabase mal configurada
2. **Solución:** Verificar redirect URLs en dashboard

### Si los Tokens están Presentes pero Expirados:
1. **Problema:** Enlace usado después de 60 minutos
2. **Solución:** Solicitar nuevo enlace

### Si Type ≠ 'recovery':
1. **Problema:** Email template incorrecto
2. **Solución:** Verificar templates en Supabase

## ⚡ CAMBIOS REALIZADOS EN EL CÓDIGO

### `resetpasswordscreen.dart`
- ✅ Logging mejorado para debugging
- ✅ Manejo de errores específicos
- ✅ Información más clara sobre expiración

### `new_password_screen.dart`
- ✅ Validación mejorada de sesión
- ✅ Errores específicos para tokens expirados
- ✅ UI mejorada para errores

### `reset-password.html`
- ✅ Validación detallada de tokens
- ✅ Mensajes de error específicos
- ✅ Botón para solicitar nuevo enlace

## 🎯 RESULTADO ESPERADO

Después de aplicar estas correcciones:

1. ✅ Enlaces válidos por 60 minutos completos
2. ✅ Mensajes de error claros y útiles
3. ✅ Deep links funcionando correctamente
4. ✅ Flujo completo sin interrupciones
5. ✅ Debugging fácil con logs detallados

## ⏰ TIEMPO ESTIMADO

- **Configuración Supabase:** 10 minutos
- **Deploy y verificación:** 10 minutos
- **Testing completo:** 15 minutos
- **TOTAL:** 35 minutos

## 🚨 SI SIGUE SIN FUNCIONAR

1. **Verificar configuración Supabase** (causa #1)
2. **Probar con email diferente** (verificar que esté registrado)
3. **Usar modo incógnito** (evitar cache)
4. **Verificar logs en consola** (tanto app como web)
5. **Contactar soporte si todo lo anterior falla**
