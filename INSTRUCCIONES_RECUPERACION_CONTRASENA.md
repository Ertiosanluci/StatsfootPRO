# Instrucciones para Recuperar Contraseña

## Revisión de Configuración

Para solucionar el problema del enlace de recuperación de contraseña que te lleva a la versión web en lugar de la app móvil, hemos realizado las siguientes mejoras:

1. Actualizado el archivo `netlify.toml` para manejar correctamente las redirecciones
2. Mejorado la página `reset-password.html` con técnicas más avanzadas para abrir la app
3. Mejorado las pantallas de error para dar mejor feedback al usuario

## Pasos a Seguir

### 1. Despliegue en Netlify

Primero, debes desplegar estos cambios en Netlify:

```
git add .
git commit -m "Mejorado sistema de recuperación de contraseña"
git push
```

Netlify debería detectar automáticamente los cambios y desplegar la nueva versión.

### 2. Configuración de Supabase

Luego, debes configurar Supabase siguiendo los pasos en `CONFIGURACION_SUPABASE_REDIRECT.md`. Asegúrate de:

1. Configurar el Site URL como `https://statsfootpro.netlify.app`
2. Añadir las Redirect URLs, especialmente `https://statsfootpro.netlify.app/reset-password`
3. Actualizar la plantilla de email para usar `https://statsfootpro.netlify.app/reset-password` como URL de redirección

### 3. Prueba el flujo completo

1. Solicita un reset de contraseña desde la app
2. Revisa el email recibido y copia el enlace
3. Abre el enlace en el navegador de tu teléfono
4. Debería cargar la página de redirección y luego intentar abrir la app automáticamente

### 4. Solución de Problemas

Si aún tienes problemas:

#### Si el enlace sigue abriendo la app web:
- Revisa el enlace del email. Debe comenzar con `https://statsfootpro.netlify.app/reset-password?` 
- Si comienza con `https://statsfootpro.netlify.app/app/`, entonces la configuración de Supabase no se ha actualizado correctamente.

#### Si el enlace carga la página de redirección pero no abre la app:
- Prueba hacer clic manualmente en el botón "Abrir en App"
- En algunos dispositivos Android, puede ser necesario confirmar que deseas abrir la aplicación

#### Si recibes el error "Se requiere una sesión válida":
- El enlace puede haber expirado (son válidos por poco tiempo)
- Solicita un nuevo enlace de recuperación

## Comando Manual de Prueba

Para probar manualmente si el deep link funciona en tu dispositivo Android, puedes usar este comando desde tu computadora (con el dispositivo conectado por USB y depuración activada):

```
adb shell am start -a android.intent.action.VIEW -d "statsfoot://reset-password?access_token=test_token&type=recovery"
```

Esto debería abrir la app directamente en la pantalla de reset de contraseña.
