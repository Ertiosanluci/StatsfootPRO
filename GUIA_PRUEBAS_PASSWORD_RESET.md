# 🔐 GUÍA DE PRUEBAS COMPLETAS - Password Reset

## ✅ CAMBIOS REALIZADOS

### 1. **Mejoras en main.dart**
- ✅ Logging detallado con emojis 🔗🔐
- ✅ Mejor manejo de deep links `statsfoot://reset-password`
- ✅ Procesamiento mejorado de URIs con parámetros

### 2. **Mejoras en PasswordResetScreen**
- ✅ Logging detallado del proceso de sesión
- ✅ Mejor manejo de tokens recibidos
- ✅ Mensajes informativos para el usuario
- ✅ Manejo mejorado de errores

### 3. **Corrección en PasswordResetRequestScreen**
- ✅ Corregido error de compilación (`void` no se puede imprimir)
- ✅ Mejorados los mensajes de debug

### 4. **Página de redirect mejorada (reset-password.html)**
- ✅ Sistema de logging integrado con debug toggle
- ✅ Mejor extracción de tokens desde múltiples fuentes
- ✅ Redirección automática mejorada
- ✅ Manejo de fallbacks

---

## 🧪 PROCESO DE PRUEBAS

### **PASO 1: Verificar compilación**
```bash
cd "c:\Users\edusa\Documents\GitHub\StatsfootPRO"
flutter clean && flutter pub get
flutter run --debug
```

### **PASO 2: Probar solicitud de reset**
1. Abrir la app
2. En la pantalla de login, presionar "¿Olvidaste tu contraseña?"
3. Ingresar tu email
4. Presionar "ENVIAR CORREO"
5. ✅ Debería mostrar mensaje de éxito y regresar al login

### **PASO 3: Verificar el email recibido**
1. Revisar tu bandeja de entrada
2. Buscar email de Supabase
3. El enlace debería ser algo como:
   ```
   https://vlygdxrppzoqlkntfypx.supabase.co/auth/v1/verify?token=...&type=recovery&redirect_to=https://statsfootpro.netlify.app/reset-password
   ```

### **PASO 4: Hacer clic en el enlace del email**
1. Hacer clic en el enlace del email
2. Debería abrir `https://statsfootpro.netlify.app/reset-password`
3. La página debería:
   - ✅ Mostrar "Procesando tu solicitud..."
   - ✅ Extraer tokens automáticamente
   - ✅ Intentar abrir la app con `statsfoot://reset-password?access_token=...`

### **PASO 5: Verificar logs en la app**
Con la app en modo debug, busca estos logs:
```
🔗 Procesando URI: statsfoot://reset-password?access_token=...
🔗 Es un deep link de statsfoot
🔗 Es un enlace de reset de contraseña
🔐 Procesando enlace de recuperación de contraseña: ...
🔐 Tokens extraídos - Access: SÍ, Refresh: NO, Type: recovery
🔐 ✅ Tokens válidos encontrados, navegando a PasswordResetScreen con tokens
```

### **PASO 6: Verificar pantalla de reset**
1. La app debería navegar automáticamente a `PasswordResetScreen`
2. Buscar estos logs:
```
🔐 Inicializando sesión para reset de contraseña...
🔐 Access Token recibido: SÍ
🔐 Estableciendo sesión con token recibido...
🔐 ✅ Sesión establecida exitosamente con token
```
3. ✅ Debería mostrar SnackBar verde: "Enlace de recuperación verificado"
4. ✅ Debería mostrar el formulario para nueva contraseña

### **PASO 7: Cambiar contraseña**
1. Ingresar nueva contraseña (mínimo 6 caracteres)
2. Confirmar la contraseña
3. Presionar "ACTUALIZAR CONTRASEÑA"
4. ✅ Debería mostrar SnackBar verde: "¡Contraseña actualizada exitosamente!"
5. ✅ Debería redirigir al login después de 2 segundos

### **PASO 8: Probar nueva contraseña**
1. En el login, usar la nueva contraseña
2. ✅ Debería poder iniciar sesión correctamente

---

## 🐛 TROUBLESHOOTING

### **Si no llegan tokens a la app:**
1. Abrir el navegador developer tools en `https://statsfootpro.netlify.app/reset-password`
2. Presionar el botón "Mostrar Info Debug"
3. Verificar que se muestren los tokens extraídos
4. Si no hay tokens, verificar la configuración de Supabase:
   - Redirect URL: `https://statsfootpro.netlify.app/reset-password`
   - Email template correcto

### **Si la app no se abre automáticamente:**
1. En la página de redirect, usar el botón "📱 Abrir en App"
2. O usar el botón "🌐 Abrir en Web" como fallback

### **Si hay errores de sesión:**
1. Verificar logs en la app:
```
🔐 ❌ Error estableciendo sesión con token: [error]
🔐 ❌ No hay sesión activa
```
2. Solicitar un nuevo enlace de recuperación

### **URLs de debug:**
- Página principal: `https://statsfootpro.netlify.app/reset-password`
- Página debug: `https://statsfootpro.netlify.app/reset-password-debug`

---

## 📋 CHECKLIST DE VERIFICACIÓN

- [ ] La app compila sin errores
- [ ] Se puede solicitar reset desde la app
- [ ] Llega el email de Supabase
- [ ] El enlace del email redirige correctamente
- [ ] La página web extrae los tokens
- [ ] La app recibe el deep link con tokens
- [ ] Se establece la sesión en la app
- [ ] Se muestra la pantalla de nueva contraseña
- [ ] Se puede cambiar la contraseña exitosamente
- [ ] La nueva contraseña funciona en el login

---

## 🔧 CONFIGURACIÓN REQUERIDA EN SUPABASE

1. **Authentication > URL Configuration:**
   - Site URL: `https://statsfootpro.netlify.app`
   - Redirect URLs:
     - `statsfoot://reset-password`
     - `https://statsfootpro.netlify.app/app/#/password_reset`
     - `https://statsfootpro.netlify.app/reset-password`

2. **Authentication > Email Templates > Reset Password:**
   ```html
   <h2>Restablecer tu contraseña</h2>
   <p>Haz clic en el enlace de abajo para restablecer tu contraseña:</p>
   <p><a href="{{ .ConfirmationURL }}">Restablecer contraseña</a></p>
   <p>Si no solicitaste este cambio, puedes ignorar este email.</p>
   ```

---

## 📞 SIGUIENTES PASOS

1. **Ejecutar las pruebas** paso a paso
2. **Reportar resultados** con logs específicos
3. **Si hay errores**, proporcionar los logs exactos para debug
4. **Una vez funcionando**, documentar el flujo final

¡El sistema está listo para pruebas! 🚀
