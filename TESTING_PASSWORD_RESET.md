# Guía de Pruebas - Recuperación de Contraseña

## 🔧 Pasos de Configuración Inicial

### 1. **Configurar Supabase Dashboard**
- Ve a tu proyecto en Supabase Dashboard → Authentication → Settings
- En **Redirect URLs**, agregar:
  ```
  statsfoot://reset-password
  https://statsfootpro.netlify.app/app/#/password_reset
  https://statsfootpro.netlify.app/reset-password
  ```

### 2. **Desplegar Página de Redirección**
- Subir el archivo `netlify-redirect/reset-password.html` a tu sitio de Netlify
- Verificar que esté accesible en: `https://statsfootpro.netlify.app/reset-password`

## 📱 Pruebas a Realizar

### **Prueba 1: Solicitud de Reset (Mobile/Web)**
1. **Abrir la app** → Pantalla de Login
2. **Tocar** "¿Olvidaste tu contraseña?"
3. **Ingresar email** válido de usuario existente
4. **Tocar** "Enviar Enlace de Recuperación"
5. **Verificar**: 
   - ✅ Mensaje de confirmación aparece
   - ✅ Email llega a la bandeja de entrada

### **Prueba 2: Flujo Completo - Mobile**
1. **Abrir email** recibido
2. **Tocar enlace** en el email
3. **Verificar redirección**:
   - ✅ Se abre página `reset-password.html`
   - ✅ Automáticamente intenta abrir la app
   - ✅ App se abre en pantalla "Nueva Contraseña"
4. **Cambiar contraseña**:
   - ✅ Ingresar nueva contraseña válida
   - ✅ Confirmar contraseña
   - ✅ Tocar "Actualizar Contraseña"
   - ✅ Mensaje de éxito aparece
   - ✅ Redirige a pantalla de login

### **Prueba 3: Flujo Completo - Web**
1. **Abrir enlace** en navegador web
2. **Verificar**: Si la app no está instalada, debería redirigir a la versión web
3. **Completar cambio** de contraseña en web

### **Prueba 4: Verificar Nueva Contraseña**
1. **Ir a pantalla de login**
2. **Intentar login** con contraseña antigua → Debería fallar
3. **Intentar login** con nueva contraseña → Debería funcionar

## 🧪 Pruebas de Casos Edge

### **Caso 1: Email Inválido**
- Ingresar email que no existe → Debería mostrar mensaje genérico de éxito (por seguridad)

### **Caso 2: Enlace Expirado**
- Usar enlace después de 1 hora → Debería mostrar error de token expirado

### **Caso 3: Enlace Usado Múltiples Veces**
- Usar mismo enlace dos veces → Segunda vez debería fallar

### **Caso 4: Deep Link sin App Instalada**
- Abrir enlace en dispositivo sin app → Debería fallback a versión web

## 🔍 Deep Link Testing

### **Android (ADB)**
```bash
adb shell am start \
  -W -a android.intent.action.VIEW \
  -d "statsfoot://reset-password?access_token=TEST_TOKEN&refresh_token=TEST_REFRESH&type=recovery" \
  com.statsfootpro.app
```

### **iOS (Simulator)**
```bash
xcrun simctl openurl booted "statsfoot://reset-password?access_token=TEST_TOKEN&refresh_token=TEST_REFRESH&type=recovery"
```

## 📋 Checklist de Verificación

### **Frontend ✅**
- [x] `PasswordResetRequestScreen` creada y funcional
- [x] `PasswordResetScreen` creada y funcional
- [x] Botón "¿Olvidaste tu contraseña?" en login
- [x] Rutas agregadas en `main.dart`
- [x] Deep link handling implementado
- [x] Manejo de errores implementado

### **Backend ✅**
- [x] `resetPasswordForEmail` implementado
- [x] `updateUser` para cambio de contraseña
- [x] Manejo de sesión con tokens

### **Redirección ✅**
- [x] Página HTML `reset-password.html` creada
- [x] Detección de plataforma (móvil/web)
- [x] Fallback automático entre plataformas
- [x] Manejo de tokens en URL

### **Configuración ✅**
- [x] Android `AndroidManifest.xml` actualizado
- [x] iOS `Info.plist` configurado
- [x] Esquema `statsfoot://reset-password` añadido

## 🚨 Problemas Comunes y Soluciones

### **Problema**: Deep link no abre la app
**Solución**: 
- Verificar que el esquema `statsfoot` esté registrado
- Revisar `AndroidManifest.xml` e `Info.plist`
- Probar con ADB/simulador

### **Problema**: "Token inválido" error
**Solución**:
- Verificar que los redirect URLs estén configurados correctamente en Supabase
- Verificar que los tokens se estén pasando correctamente en la URL

### **Problema**: Email no llega
**Solución**:
- Verificar configuración SMTP en Supabase
- Revisar carpeta de spam
- Verificar que el email existe en la base de datos

### **Problema**: Página de redirección no carga
**Solución**:
- Verificar que `reset-password.html` esté desplegado en Netlify
- Verificar la URL de redirección en el código

## 📊 Métricas de Éxito

- ✅ **Solicitud**: Email enviado exitosamente
- ✅ **Redirección**: App se abre desde email link
- ✅ **Autenticación**: Sesión establecida con tokens
- ✅ **Cambio**: Contraseña actualizada exitosamente
- ✅ **Login**: Login funciona con nueva contraseña

---

**Estado**: ✅ **IMPLEMENTACIÓN COMPLETA**

La funcionalidad de recuperación de contraseña está completamente implementada y lista para pruebas. Solo falta configurar las redirect URLs en Supabase Dashboard para que funcione en producción.
