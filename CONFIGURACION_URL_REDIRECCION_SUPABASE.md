# Configuración de la URL de Redirección en Supabase

## Problema Actual

La URL de redirección en la plantilla de email de Supabase está configurada incorrectamente, por lo que los enlaces de recuperación de contraseña están enviando a los usuarios directamente a la aplicación web Flutter en lugar de a nuestra página HTML intermediaria.

## Solución: Actualizar la URL de Redirección

### 1. Accede al Dashboard de Supabase

- Ve a [https://app.supabase.com](https://app.supabase.com)
- Selecciona tu proyecto StatsFoot
- Ve a **Authentication** → **Email Templates**

### 2. Edita la Plantilla "Reset Password"

- Haz clic en el botón de editar (ícono de lápiz) junto a "Reset Password"
- Localiza el campo llamado **Redirect URL** (URL de Redirección)

### 3. Actualiza la URL de Redirección

- Cambia la URL actual por esta:
  ```
  https://statsfootpro.netlify.app/reset-password
  ```

- ⚠️ **IMPORTANTE**: Asegúrate de que la URL sea EXACTAMENTE como se muestra arriba.

  **¡NO** debe ser:
  - ❌ `https://statsfootpro.netlify.app/app/`
  - ❌ `https://statsfootpro.netlify.app/app/#/password_reset`
  - ❌ `https://statsfootpro.netlify.app/#/reset-password`

### 4. Guarda los Cambios

- Haz clic en "Save" o "Update"
- Espera 2-3 minutos para que los cambios se propaguen

## Verificación 

Para verificar que el cambio fue exitoso:

1. En tu app, ve a la pantalla de login
2. Haz clic en "¿Olvidaste tu contraseña?"
3. Ingresa tu correo electrónico
4. Recibe el email y verifica que el enlace (al pasar el cursor por encima o hacer clic derecho → Copiar dirección del enlace) comience con:
   ```
   https://statsfootpro.netlify.app/reset-password?token=...
   ```

## Cómo Funciona

Cuando configuras esta URL en Supabase:

1. Supabase genera un enlace de recuperación con la URL base que proporcionaste
2. El usuario hace clic en el enlace en su email
3. El enlace lleva a la página `reset-password.html` en tu sitio
4. La página HTML extrae los tokens y redirige a la aplicación móvil usando el esquema `statsfoot://`

## Si Sigues Teniendo Problemas

Si después de cambiar la URL, los enlaces en los emails siguen apuntando a la URL incorrecta:

1. **Espera unos minutos** - Puede haber un retraso debido a caché
2. **Limpia la caché del navegador** donde estás accediendo a Supabase
3. **Verifica que guardaste los cambios** - Debería aparecer una notificación de "Changes saved" o similar
4. **Revisa otras configuraciones** - Ve a Authentication → Settings → URL Configuration y verifica que el Site URL sea `https://statsfootpro.netlify.app`

![Ejemplo de configuración](https://i.imgur.com/ejemplo_supabase_config.png)
