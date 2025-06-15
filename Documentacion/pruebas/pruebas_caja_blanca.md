# Pruebas de Caja Blanca - StatsfootPRO

## Introducción

Las pruebas de caja blanca, también conocidas como pruebas estructurales o de caja de cristal, son técnicas de prueba que examinan la estructura interna del código fuente y la lógica de la aplicación. Este documento detalla el enfoque de pruebas de caja blanca para la aplicación StatsfootPRO, centrándose en validar la implementación correcta de la lógica de negocio, la cobertura de código y la calidad del código.

## Objetivos

- Verificar que todas las rutas de ejecución del código se prueban adecuadamente
- Identificar defectos en la lógica de programación y estructuras de control
- Validar la correcta implementación de los patrones de arquitectura (Clean Architecture)
- Asegurar que las dependencias entre componentes funcionan correctamente
- Optimizar el rendimiento del código

## Metodologías de Prueba

### 1. Pruebas Unitarias

| ID | Componente | Método/Función | Aspectos a Probar | Criterio de Éxito |
|----|------------|----------------|-------------------|-------------------|
| UT001 | AuthRepository | signIn() | Autenticación correcta con credenciales válidas | Retorna usuario autenticado |
| UT002 | AuthRepository | signIn() | Manejo de errores con credenciales inválidas | Lanza excepción apropiada |
| UT003 | AuthRepository | signUp() | Registro exitoso con datos válidos | Usuario creado en Supabase |
| UT004 | AuthRepository | resetPassword() | Envío de email de recuperación | Confirmación de envío |
| UT005 | MatchRepository | createMatch() | Creación correcta de partido | Partido persistido en BD |
| UT006 | MatchRepository | getMatchById() | Recuperación de partido existente | Datos correctos del partido |
| UT007 | MatchRepository | getMatchById() | Manejo de ID inexistente | Retorna null o excepción |
| UT008 | InvitationService | sendInvitation() | Envío correcto de invitación | Invitación creada y notificación enviada |
| UT009 | NotificationService | sendPushNotification() | Envío de notificación a OneSignal | Respuesta exitosa de API |
| UT010 | UserController | updateProfile() | Actualización de datos de perfil | Datos actualizados en BD |

### 2. Pruebas de Cobertura de Código

| Componente | Cobertura Mínima | Áreas Críticas |
|------------|------------------|----------------|
| Repositories | 90% | Métodos CRUD y manejo de errores |
| Controllers | 85% | Lógica de negocio y transformación de datos |
| Services | 90% | Integración con servicios externos |
| Models | 75% | Serialización/deserialización |
| Widgets | 70% | Comportamiento y eventos |

### 3. Pruebas de Caminos (Path Testing)

#### Ejemplo: Flujo de Autenticación

```dart
Future<User?> signIn(String email, String password) async {
  try {
    final response = await _supabaseClient.auth.signInWithPassword(
      email: email,
      password: password,
    );
    
    if (response.user != null) {
      return response.user;
    } else {
      return null;
    }
  } catch (e) {
    _logError('Sign in error', e);
    throw AuthException('Failed to sign in: ${e.toString()}');
  }
}
```

**Caminos a probar:**
1. Credenciales correctas → respuesta exitosa → usuario retornado
2. Credenciales correctas → respuesta sin usuario → null retornado
3. Credenciales incorrectas → excepción de Supabase → AuthException lanzada
4. Error de red → excepción de conexión → AuthException lanzada

### 4. Pruebas de Condición/Decisión

| ID | Componente | Método | Condición | Valores a Probar |
|----|------------|--------|-----------|------------------|
| CD001 | MatchController | canJoinMatch() | match.maxPlayers > currentPlayers | true, false |
| CD002 | MatchController | canJoinMatch() | user.isInvited || match.isPublic | true/true, true/false, false/true, false/false |
| CD003 | AuthController | validatePassword() | password.length >= 6 | 5 chars, 6 chars, 10 chars |
| CD004 | ProfileController | canEditProfile() | user.id == profile.id | igual, diferente |

## Pruebas de Integración de Componentes

### 1. Pruebas de Integración entre Capas

| ID | Componentes | Escenario | Resultado Esperado |
|----|-------------|-----------|-------------------|
| IC001 | MatchController ↔ MatchRepository | Creación de partido | Partido creado en BD y estado actualizado |
| IC002 | AuthController ↔ AuthRepository | Inicio de sesión | Usuario autenticado y estado actualizado |
| IC003 | NotificationController ↔ OneSignalService | Envío de notificación | Notificación enviada y registrada |
| IC004 | ProfileController ↔ UserRepository | Actualización de perfil | Perfil actualizado en BD |

### 2. Pruebas de Dependencias

| ID | Dependencia | Método de Prueba | Aspectos a Verificar |
|----|-------------|------------------|---------------------|
| DP001 | Supabase | Mock de respuestas | Manejo correcto de respuestas y errores |
| DP002 | OneSignal | Stub de servicio | Formato correcto de payload y manejo de respuestas |
| DP003 | Riverpod | Pruebas de Provider | Actualización de estado y notificación a widgets |
| DP004 | Freezed | Pruebas de serialización | Conversión correcta entre JSON y objetos |

## Herramientas y Técnicas

### Herramientas de Prueba
- **Flutter Test**: Framework principal para pruebas unitarias y de widgets
- **Mockito**: Para crear mocks de dependencias
- **Fake Supabase**: Para simular respuestas de Supabase sin conexión real
- **Coverage**: Para análisis de cobertura de código
- **Flutter Driver**: Para pruebas de integración

### Técnicas de Análisis Estático
- **Dart Analyzer**: Para verificar cumplimiento con reglas de estilo y potenciales errores
- **Flutter Lints**: Para mantener consistencia de código
- **SonarQube**: Para análisis de calidad de código y deuda técnica

## Implementación de Pruebas

### Estructura de Archivos de Prueba

```
test/
├── unit/
│   ├── repositories/
│   │   ├── auth_repository_test.dart
│   │   ├── match_repository_test.dart
│   │   └── user_repository_test.dart
│   ├── controllers/
│   │   ├── auth_controller_test.dart
│   │   ├── match_controller_test.dart
│   │   └── notification_controller_test.dart
│   └── services/
│       ├── one_signal_service_test.dart
│       └── supabase_service_test.dart
├── integration/
│   ├── auth_flow_test.dart
│   ├── match_creation_flow_test.dart
│   └── notification_flow_test.dart
└── widget/
    ├── auth/
    │   ├── login_screen_test.dart
    │   └── register_screen_test.dart
    └── match/
        ├── match_list_test.dart
        └── match_detail_test.dart
```

### Ejemplo de Prueba Unitaria

```dart
void main() {
  late AuthRepository authRepository;
  late MockSupabaseClient mockSupabaseClient;
  late MockAuthResponse mockAuthResponse;
  
  setUp(() {
    mockSupabaseClient = MockSupabaseClient();
    mockAuthResponse = MockAuthResponse();
    authRepository = AuthRepository(mockSupabaseClient);
  });
  
  group('signIn', () {
    test('should return User when credentials are valid', () async {
      // Arrange
      final testUser = User(id: 'test-id', email: 'test@example.com');
      when(mockSupabaseClient.auth.signInWithPassword(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenAnswer((_) async => mockAuthResponse);
      when(mockAuthResponse.user).thenReturn(testUser);
      
      // Act
      final result = await authRepository.signIn('test@example.com', 'password');
      
      // Assert
      expect(result, equals(testUser));
      verify(mockSupabaseClient.auth.signInWithPassword(
        email: 'test@example.com',
        password: 'password',
      )).called(1);
    });
    
    test('should throw AuthException when signIn fails', () async {
      // Arrange
      when(mockSupabaseClient.auth.signInWithPassword(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenThrow(Exception('Invalid credentials'));
      
      // Act & Assert
      expect(
        () => authRepository.signIn('test@example.com', 'wrong-password'),
        throwsA(isA<AuthException>()),
      );
    });
  });
}
```

## Plan de Ejecución de Pruebas

### Ciclo de Pruebas
1. **Pruebas Unitarias**: Ejecutadas en cada commit
   - Cobertura mínima requerida: 80%
   - Tiempo máximo de ejecución: 2 minutos

2. **Pruebas de Integración**: Ejecutadas en cada PR
   - Cobertura de flujos críticos: 100%
   - Tiempo máximo de ejecución: 5 minutos

3. **Análisis Estático**: Ejecutado en cada commit
   - Zero issues de severidad alta
   - Máximo 5 issues de severidad media

### Integración con CI/CD
- GitHub Actions para ejecución automática de pruebas
- Generación de reportes de cobertura en cada build
- Bloqueo de merge si las pruebas fallan o la cobertura es insuficiente

## Métricas de Calidad

| Métrica | Objetivo | Método de Medición |
|---------|----------|-------------------|
| Cobertura de código | >80% | Flutter Coverage |
| Complejidad ciclomática | <10 por método | Dart Analyzer |
| Duplicación de código | <3% | SonarQube |
| Deuda técnica | <5 días | SonarQube |
| Tiempo de ejecución de pruebas | <10 minutos total | CI/CD metrics |

## Casos de Prueba Específicos

### Pruebas de Manejo de Estado con Riverpod

```dart
test('MatchController notifies listeners when match is created', () async {
  // Arrange
  final mockRepository = MockMatchRepository();
  final controller = MatchController(mockRepository);
  final match = Match(id: '1', title: 'Test Match', date: DateTime.now());
  
  when(mockRepository.createMatch(any)).thenAnswer((_) async => match);
  
  // Act
  final future = controller.createMatch(
    title: 'Test Match',
    date: DateTime.now(),
    location: 'Test Location',
  );
  
  // Assert - Verificar cambios de estado
  expect(controller.debugState, isA<MatchStateLoading>());
  
  await future;
  
  expect(controller.debugState, isA<MatchStateSuccess>());
  expect((controller.debugState as MatchStateSuccess).match, equals(match));
});
```

### Pruebas de Navegación

```dart
testWidgets('Navigate to match detail when match is tapped', (tester) async {
  // Arrange
  final mockNavigator = MockNavigator();
  final match = Match(id: '1', title: 'Test Match', date: DateTime.now());
  
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        matchesProvider.overrideWithValue([match]),
        navigatorProvider.overrideWithValue(mockNavigator),
      ],
      child: MaterialApp(home: MatchListScreen()),
    ),
  );
  
  // Act
  await tester.tap(find.text('Test Match'));
  await tester.pumpAndSettle();
  
  // Assert
  verify(mockNavigator.push(any, arguments: {'matchId': '1'})).called(1);
});
```

## Conclusiones y Recomendaciones

Las pruebas de caja blanca para StatsfootPRO se centrarán en validar la correcta implementación de la arquitectura Clean y asegurar que todos los componentes funcionan según lo esperado. Se recomienda:

1. Mantener una alta cobertura de código, especialmente en componentes críticos
2. Implementar pruebas unitarias para toda nueva funcionalidad antes de integrarla
3. Utilizar mocks y stubs para aislar componentes y probar comportamientos específicos
4. Revisar regularmente las métricas de calidad y abordar deuda técnica de forma proactiva

Este plan de pruebas de caja blanca debe evolucionar junto con el código base, añadiendo nuevos casos de prueba conforme se implementen nuevas funcionalidades.
