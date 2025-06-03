# Guía de Despliegue y Verificación de Recuperación de Contraseña

## 📋 Lista de Cambios Implementados

Se han realizado las siguientes mejoras para resolver el problema del enlace de recuperación de contraseña:

1. **Mejorado el manejo del parámetro `code`** en `reset-password.html`
2. **Actualizado el procesamiento de tokens** en `password_reset_screen.dart` 
3. **Mejorada la detección de enlaces** en `main.dart`
4. **Agregado un diagnóstico avanzado** en la nueva página `password-debug.html`
5. **Actualizada la configuración de Netlify** para asegurar todas las rutas

## 🚀 Instrucciones de Despliegue

### 1. Verificar los archivos actualizados

Revisa que estos archivos estén correctamente modificados:
- `netlify-redirect/reset-password.html`
- `netlify-redirect/password-debug.html` (nuevo)
- `lib/password_reset_screen.dart`
- `lib/main.dart`
- `netlify.toml`

### 2. Hacer commit y desplegar

```powershell
# Verificar los cambios
git status

# Hacer commit
git add .
git commit -m "Mejora de recuperación de contraseñas con soporte para formato ?code="

# Subir a repositorio
git push
```

### 3. Esperar a que Netlify termine el despliegue

Una vez que Netlify termine de construir y desplegar el sitio, continúa con las pruebas.

## 🧪 Instrucciones de Verificación

### Prueba 1: Flujo de recuperación completo

1. Abre la aplicación móvil
2. Ve a la pantalla de login
3. Haz clic en "¿Olvidaste tu contraseña?"
4. Ingresa un correo electrónico válido
5. Revisa tu correo y haz clic en el enlace
6. Verifica que:
   - La página de redirección muestra "Enlace válido"
   - Se intenta abrir la app automáticamente
   - Al abrir la app, muestra la pantalla de reset de contraseña
   - Puedes cambiar la contraseña correctamente

### Prueba 2: Diagnóstico directo

Si la Prueba 1 falla, usa la página de diagnóstico:

1. Abre el enlace de recuperación recibido
2. Cambia la URL para usar `/password-debug` en lugar de `/reset-password`
3. Analiza los parámetros mostrados en la página
4. Usa los botones "Abrir en App" para probar la redirección

### Prueba 3: Verificación del código de un solo uso

1. Abre el enlace recibido en la computadora
2. Copia el código de un solo uso (parámetro `code=`)
3. Abre la app móvil manualmente
4. En la consola de depuración, verifica los logs que muestran:
   - Detección del código
   - Intercambio por una sesión
   - Establecimiento exitoso de la sesión

## 📝 Resolución de Problemas Comunes

### Si el enlace no abre la app:

- Verifica que la URL de redirección en Supabase sea correcta
- Asegúrate de que la app tenga registrado el esquema `statsfoot://`
- Prueba manualmente abriendo `statsfoot://reset-password`

### Si aparece "Enlace expirado":

- Usa la página de diagnóstico para ver si el código está presente
- Verifica en los logs si hay errores al intercambiar el código
- Genera un nuevo enlace y prueba inmediatamente

### Si el enlace funciona pero no permite cambiar la contraseña:

- Verifica que la sesión se haya establecido correctamente
- Asegúrate de que el usuario tenga permisos para actualizar su contraseña

## 📱 Flujo Ideal

1. Usuario solicita recuperación → Recibe email
2. Hace clic en enlace → Se abre página de redirección
3. Página detecta el código y abre la app
4. App establece sesión → Muestra pantalla de nueva contraseña
5. Usuario establece contraseña → Sesión restaurada
