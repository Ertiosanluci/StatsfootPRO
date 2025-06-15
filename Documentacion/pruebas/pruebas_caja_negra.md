# Pruebas de Caja Negra - StatsfootPRO

## Introducción

Las pruebas de caja negra son un método de prueba de software que examina la funcionalidad de una aplicación sin conocer su estructura interna, código o lógica. Este documento detalla el enfoque de pruebas de caja negra para la aplicación StatsfootPRO, centrándose en validar que el sistema cumple con los requisitos funcionales desde la perspectiva del usuario final.

## Objetivos

- Verificar que todas las funcionalidades de la aplicación StatsfootPRO funcionan según lo especificado
- Identificar errores en la interfaz de usuario y en el flujo de trabajo
- Validar la experiencia del usuario en diferentes escenarios de uso
- Comprobar la integración correcta con servicios externos (Supabase, OneSignal)

## Metodologías de Prueba

### 1. Pruebas Funcionales

| ID | Caso de Prueba | Datos de Entrada | Resultado Esperado | Condición de Éxito |
|----|----------------|------------------|-------------------|-------------------|
| FN001 | Registro de usuario | Email: test@example.com<br>Contraseña: Test123! | Usuario registrado correctamente | Usuario puede acceder con credenciales |
| FN002 | Inicio de sesión | Email: test@example.com<br>Contraseña: Test123! | Acceso a la aplicación | Usuario navega a la pantalla principal |
| FN003 | Recuperación de contraseña | Email: test@example.com | Email de recuperación enviado | Usuario recibe email y puede restablecer contraseña |
| FN004 | Creación de partido | Fecha: 20/06/2025<br>Hora: 18:00<br>Ubicación: "Campo Municipal" | Partido creado en el sistema | Partido aparece en la lista de partidos |
| FN005 | Invitación a jugadores | ID de partido: [ID]<br>Email de jugador: player@example.com | Invitación enviada | Jugador recibe notificación |
| FN006 | Aceptar invitación | ID de invitación: [ID] | Jugador añadido a la lista de participantes | Jugador aparece en la lista del partido |
| FN007 | Rechazar invitación | ID de invitación: [ID] | Invitación marcada como rechazada | Jugador no aparece en la lista del partido |
| FN008 | Visualización de estadísticas | ID de usuario: [ID] | Estadísticas mostradas correctamente | Datos estadísticos visibles y precisos |

### 2. Pruebas de Interfaz de Usuario

| ID | Caso de Prueba | Acción | Resultado Esperado | Condición de Éxito |
|----|----------------|--------|-------------------|-------------------|
| UI001 | Responsividad en diferentes tamaños de pantalla | Abrir app en dispositivos de diferentes tamaños | UI adaptada correctamente | Todos los elementos visibles y utilizables |
| UI002 | Navegación entre pantallas | Navegar por el menú principal | Transición fluida entre pantallas | No hay retrasos ni errores visuales |
| UI003 | Validación de formularios | Introducir datos inválidos en formularios | Mensajes de error apropiados | Feedback visual claro para el usuario |
| UI004 | Modo oscuro/claro | Cambiar entre modos de visualización | Cambio correcto de tema | Todos los elementos respetan el tema seleccionado |
| UI005 | Multilenguaje | Cambiar idioma de la aplicación | Textos traducidos correctamente | Todos los textos aparecen en el idioma seleccionado |

### 3. Pruebas de Integración con Servicios Externos

| ID | Caso de Prueba | Escenario | Resultado Esperado | Condición de Éxito |
|----|----------------|-----------|-------------------|-------------------|
| INT001 | Autenticación con Supabase | Registro e inicio de sesión | Tokens de autenticación generados | Usuario autenticado correctamente |
| INT002 | Almacenamiento en Supabase | Crear y recuperar datos | Datos persistidos correctamente | Datos recuperados coinciden con los guardados |
| INT003 | Notificaciones con OneSignal | Envío de notificación push | Notificación entregada al dispositivo | Usuario recibe la notificación |
| INT004 | Geolocalización | Seleccionar ubicación para partido | Coordenadas guardadas correctamente | Ubicación mostrada correctamente en mapa |

## Escenarios de Prueba End-to-End

### Escenario 1: Flujo completo de organización de partido

1. Usuario se registra en la aplicación
2. Usuario crea un nuevo partido
3. Usuario invita a 5 amigos al partido
4. 3 amigos aceptan la invitación, 1 la rechaza, 1 no responde
5. Usuario recibe notificaciones de las respuestas
6. El día del partido, todos los participantes reciben recordatorio
7. Después del partido, se registran estadísticas básicas

**Criterio de éxito**: Todo el flujo se completa sin errores y los datos se mantienen consistentes.

### Escenario 2: Recuperación de cuenta y gestión de perfil

1. Usuario olvida su contraseña
2. Usuario solicita recuperación de contraseña
3. Usuario recibe email y restablece contraseña
4. Usuario inicia sesión con nueva contraseña
5. Usuario actualiza su perfil con nueva información
6. Usuario cierra sesión y vuelve a iniciar con credenciales actualizadas

**Criterio de éxito**: Usuario puede recuperar acceso y gestionar su perfil sin problemas.

## Herramientas y Entorno de Prueba

### Dispositivos para Prueba
- iPhone 13 Pro (iOS 15.0+)
- Samsung Galaxy S21 (Android 12)
- Google Pixel 6 (Android 12)
- iPad Pro 11" (iOS 15.0+)
- Tablet Samsung Galaxy Tab S7 (Android 11)

### Herramientas
- Firebase Test Lab para pruebas automatizadas en múltiples dispositivos
- Appium para automatización de pruebas de UI
- Postman para pruebas de API con Supabase
- Charles Proxy para monitoreo de tráfico de red

## Plan de Ejecución de Pruebas

### Fases de Prueba
1. **Pruebas Alpha**: Ejecutadas por el equipo de desarrollo
   - Fecha estimada: 1-15 de julio 2025
   - Enfoque: Funcionalidades core y estabilidad básica

2. **Pruebas Beta Cerradas**: Con usuarios seleccionados
   - Fecha estimada: 16-31 de julio 2025
   - Enfoque: Experiencia de usuario y casos de uso reales

3. **Pruebas Beta Abiertas**: Disponible para público limitado
   - Fecha estimada: 1-15 de agosto 2025
   - Enfoque: Escalabilidad y rendimiento

### Criterios de Aceptación
- 100% de los casos de prueba críticos (autenticación, creación de partidos) deben pasar
- 90% de los casos de prueba de alta prioridad deben pasar
- 80% de los casos de prueba de media y baja prioridad deben pasar
- No debe haber errores bloqueantes o críticos sin resolver
- Tiempo de respuesta promedio debe ser menor a 2 segundos

## Gestión de Defectos

### Proceso de Reporte
1. Identificación del defecto
2. Documentación (pasos para reproducir, severidad, capturas de pantalla)
3. Asignación al equipo de desarrollo
4. Verificación de la corrección
5. Cierre del defecto

### Clasificación de Severidad
- **Crítico**: Bloquea funcionalidad principal o causa pérdida de datos
- **Alto**: Afecta significativamente la funcionalidad pero existe un workaround
- **Medio**: Afecta la experiencia del usuario pero no la funcionalidad principal
- **Bajo**: Problemas menores de UI o mejoras sugeridas

## Conclusiones y Recomendaciones

Las pruebas de caja negra para StatsfootPRO se centrarán en validar la experiencia del usuario final y asegurar que todas las funcionalidades cumplen con los requisitos especificados. Se recomienda:

1. Priorizar pruebas en los flujos críticos (autenticación, gestión de partidos)
2. Realizar pruebas en diferentes dispositivos y tamaños de pantalla
3. Involucrar a usuarios reales en fases tempranas para obtener feedback valioso
4. Automatizar casos de prueba repetitivos para agilizar ciclos de prueba

Este plan de pruebas de caja negra debe ser revisado y actualizado regularmente conforme avance el desarrollo de la aplicación.
