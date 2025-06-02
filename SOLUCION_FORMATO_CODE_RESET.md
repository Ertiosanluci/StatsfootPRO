# Solución: Problema con URL de Recuperación de Contraseña

## Problema Identificado

El enlace de recuperación de contraseña ahora tiene el formato:
```
https://statsfootpro.netlify.app/reset-password?code=67f32cdd-5a28-4da3-a232-e5f41e2b80e2
```

Pero nuestro código esperaba el formato tradicional con `access_token` y `type=recovery`.

## Cambios Implementados

He realizado los siguientes cambios para solucionar el problema:

### 1. Actualizado el archivo HTML de redirección

La página `reset-password.html` ahora:
- Detecta el parámetro `?code=` y lo trata como un token de recuperación
- Crea URLs para app y web adaptadas a ambos formatos (code o access_token)
- Incluye logs detallados para facilitar la depuración

### 2. Actualizado el manejo en la aplicación Flutter

En `main.dart`:
- Detecta el parámetro `code` en los deep links
- Usa el código como token de acceso para la recuperación
- Navega a `PasswordResetScreen` con el token adecuado

En `password_reset_screen.dart`:
- Verifica el formato del token para detectar si es un código UUID
- Usa `verifyOTP` con el código para obtener una sesión válida
- Maneja mejor los errores y proporciona mensajes más claros

## Cómo funciona el nuevo flujo

1. Usuario recibe email con enlace (formato `?code=`)
2. Al hacer clic, se carga la página HTML de redirección
3. La página detecta el formato `code` y redirige a la app móvil con este parámetro
4. La app recibe el código y lo usa para verificar la OTP y establecer una sesión
5. El usuario puede establecer una nueva contraseña

## Próximos pasos

1. **Despliega los cambios**:
   ```powershell
   git add .
   git commit -m "Soporte para nuevo formato de recuperación de contraseña con code"
   git push
   ```

2. **Prueba el flujo completo**:
   - Solicita un reset de contraseña
   - Usa el enlace del email (debe tener formato `?code=`)
   - Verifica que te dirija a la app y puedas cambiar la contraseña

3. **Verifica los logs**:
   - En la página HTML: activa el modo debug para ver los tokens extraídos
   - En la app: revisa los logs con prefijo 🔐 para seguir el proceso

Si después de estos cambios sigues experimentando problemas, podemos implementar una solución alternativa directa usando la API de Supabase para el cambio de contraseña.
