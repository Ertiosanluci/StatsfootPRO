# ¡SOLUCIÓN AL ERROR NOT FOUND!

## Problema Detectado

El enlace de recuperación de contraseña (`https://statsfootpro.netlify.app/reset-password?code=...`) está devolviendo "Not Found" porque los archivos HTML de redirección no están en la ubicación correcta durante el despliegue en Netlify.

## Cambios Realizados

He realizado dos cambios para solucionar este problema:

### 1. Actualizado el script de build de Netlify

He modificado `netlify-build.sh` para copiar los archivos HTML de redirección a la carpeta de publicación (`build/web`).

```bash
# Copiar archivos de redirección a la carpeta de publicación
echo "Copying redirect files to build/web directory..."
cp -r netlify-redirect/* build/web/
```

### 2. Actualizado las reglas de redirección en netlify.toml

He corregido las rutas en las reglas de redirección para que apunten directamente a los archivos HTML (sin el prefijo `/netlify-redirect/`).

```toml
# Redirección para recuperación de contraseña
[[redirects]]
  from = "/reset-password"
  to = "/reset-password.html"
  status = 200
```

## Pasos para Aplicar los Cambios

1. Confirma los cambios en Git
   ```bash
   git add netlify-build.sh netlify.toml
   git commit -m "Corregir rutas de redirección para reset de contraseña"
   git push
   ```

2. Verifica que el despliegue en Netlify se complete correctamente

3. Prueba el flujo de recuperación de contraseña nuevamente

## Verificación

Después de que los cambios se implementen, prueba la URL de recuperación de contraseña:
1. Solicita un restablecimiento de contraseña desde la aplicación
2. Recibe el correo electrónico y haz clic en el enlace
3. Ahora debería cargar correctamente la página de redirección y luego intentar abrir la aplicación móvil

Si aun así hay problemas, puedes probar directamente:
```
https://statsfootpro.netlify.app/reset-password-debug
```

Esta URL debería cargar la página de redirección de depuración.

## Nota sobre Supabase

La configuración de Supabase está correcta según la imagen que has compartido. La URL de redirección `https://statsfootpro.netlify.app/reset-password` está configurada correctamente.
