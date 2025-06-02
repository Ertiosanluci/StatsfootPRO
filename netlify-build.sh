#!/bin/bash
set -e

# Configurar variables de entorno
export FLUTTER_CHANNEL="stable"
export FLUTTER_VERSION="3.19.3"
export FLUTTER_HOME=$HOME/flutter

# Instalar Flutter
echo "Downloading Flutter $FLUTTER_VERSION on $FLUTTER_CHANNEL channel..."
git clone -b $FLUTTER_CHANNEL https://github.com/flutter/flutter.git $FLUTTER_HOME

# Agregar Flutter al PATH
export PATH="$FLUTTER_HOME/bin:$PATH"

# Verificar la instalación de Flutter
flutter --version

# Configurar Flutter para web
flutter config --enable-web

# Crear directorio para archivos de redirección si no existe
mkdir -p build/web

# Copiar archivos de redirección a la carpeta de publicación
echo "Copying redirect files to build/web directory..."
cp -r netlify-redirect/* build/web/

# Construir el proyecto Flutter para web
echo "Building Flutter web app..."
flutter build web --release

# Mostrar archivos generados
echo "Build complete. Generated files:"
ls -la build/web
