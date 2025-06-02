import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:statsfoota/create_match.dart';
import 'package:statsfoota/create_player.dart';
import 'package:statsfoota/login.dart';
import 'package:statsfoota/register.dart';
import 'package:statsfoota/user_menu.dart';
import 'package:statsfoota/match_list.dart';
import 'package:statsfoota/ver_Jugadores.dart';
import 'package:statsfoota/match_join_screen.dart'; // Añadido para manejar los deep links
import 'package:statsfoota/profile_edit_screen.dart'; // Importamos la pantalla de edición de perfil
import 'package:statsfoota/password_reset_request_screen.dart'; // Nueva pantalla para solicitar reset
import 'package:statsfoota/password_reset_screen.dart'; // Nueva pantalla para establecer nueva contraseña
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';
import 'package:app_links/app_links.dart'; // Cambiado de uni_links a app_links
import 'dart:async';

// Importaciones del sistema de amigos
import 'package:statsfoota/features/friends/friends_module.dart';
import 'package:statsfoota/features/friends/presentation/screens/friends_main_screen.dart';
import 'package:statsfoota/features/friends/presentation/screens/friend_requests_screen.dart';
import 'package:statsfoota/features/friends/presentation/screens/people_screen.dart';

import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// Clase para personalizar las localizaciones de Material
class _MyMaterialLocalizationsDelegate extends LocalizationsDelegate<MaterialLocalizations> {
  @override
  bool isSupported(Locale locale) => locale.languageCode == 'es';

  @override
  Future<MaterialLocalizations> load(Locale locale) async {
    return _SpanishMaterialLocalizations();
  }

  @override
  bool shouldReload(_MyMaterialLocalizationsDelegate old) => false;
}

// Clase para implementar localizaciones en español con semana que comienza en lunes
class _SpanishMaterialLocalizations extends DefaultMaterialLocalizations {
  _SpanishMaterialLocalizations() : super();

  @override
  String get firstDayOfWeek => 'lunes';

  @override
  String get selectedDateLabel => 'Fecha seleccionada';

  @override
  List<String> get narrowWeekdays => ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

  @override
  List<String> get weekdaysShort => ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

  @override
  List<String> get weekdays => ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];

  @override
  int get firstDayOfWeekIndex => 1; // 0 is Sunday, 1 is Monday
}

bool _initialUriIsHandled = false;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar localización para español
  await initializeDateFormatting('es_ES', null);
  Intl.defaultLocale = 'es_ES';
  
  // Forzar orientación vertical
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Configurar estilo de barra de estado
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  await Supabase.initialize(
    url: 'https://vlygdxrppzoqlkntfypx.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZseWdkeHJwcHpvcWxrbnRmeXB4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDAwMzk0MDEsImV4cCI6MjA1NTYxNTQwMX0.gch5BXjGqXbNI2f0zkA3wPg2b357ZfxF97AMEk5CPdE',
  );
  runApp(
    ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  final _navigatorKey = GlobalKey<NavigatorState>();
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    initAppLinks();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // La app vuelve a primer plano
      _appLinks.getLatestAppLink().then(_processIncomingUri);
    }
  }

  // Inicializar app_links y configurar listeners
  Future<void> initAppLinks() async {
    _appLinks = AppLinks();

    // Maneja los enlaces que llegan cuando la app está en segundo plano/cerrada
    final appLink = await _appLinks.getInitialAppLink();
    if (appLink != null) {
      debugPrint('Enlace inicial: $appLink');
      // Esperar brevemente para asegurar que el navegador esté listo
      Future.delayed(Duration(milliseconds: 500), () {
        _processIncomingUri(appLink);
      });
    }

    // Escucha nuevos enlaces mientras la app está en ejecución
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      debugPrint('Recibido URI: $uri');
      _processIncomingUri(uri);
    }, onError: (e) {
      debugPrint('Error en el manejo de enlaces: $e');
    });
  }
  void _processIncomingUri(Uri? uri) {
    if (uri == null) return;

    // Extraer datos del URI
    try {
      if (uri.scheme == 'statsfoot') {
        if (uri.host == 'match') {
          // Es un Deep Link interno para partido (statsfoot://match/ID)
          _handleMatchLink(uri.pathSegments.last);
        } else if (uri.host == 'reset-password') {
          // Es un Deep Link para reset de contraseña (statsfoot://reset-password)
          _handlePasswordResetLink(uri);
        }
      } else if ((uri.scheme == 'http' || uri.scheme == 'https') && 
                 uri.host == 'statsfootpro.netlify.app' &&
                 uri.pathSegments.isNotEmpty) {
        if (uri.pathSegments.first == 'match') {
          // Es un enlace web para partido (https://statsfootpro.netlify.app/match/ID)
          if (uri.pathSegments.length > 1) {
            _handleMatchLink(uri.pathSegments[1]);
          }
        } else if (uri.fragment.contains('password_reset')) {
          // Es un enlace web para reset de contraseña 
          _handlePasswordResetWebLink(uri);
        }
      }
    } catch (e) {
      debugPrint('Error procesando el URI: $e');
    }
  }
  // Navegar a la pantalla adecuada según el enlace
  void _handleMatchLink(String matchId) {
    debugPrint('Navegando al partido ID: $matchId');
    
    // Obtener el contexto del navegador actual
    final NavigatorState? navigator = _navigatorKey.currentState;
    
    if (navigator != null) {
      // Verificar si el usuario tiene sesión activa
      final Session? session = Supabase.instance.client.auth.currentSession;
      
      if (session != null) {
        // Si tiene sesión, navegar directamente a la pantalla de unirse al partido
        navigator.pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => MatchJoinScreen(matchId: matchId),
          ),
          (route) => false, // Eliminar todas las rutas del stack
        );
      } else {
        // Si no tiene sesión, mostrar la pantalla de login primero,
        // pero guardar el ID para redirigir después del login
        navigator.pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => LoginScreenWithMatchRedirect(matchId: matchId),
          ),
          (route) => false, // Eliminar todas las rutas del stack
        );
      }
    }
  }
  // Manejar enlaces de recuperación de contraseña desde deep link móvil
  void _handlePasswordResetLink(Uri uri) {
    debugPrint('Procesando enlace de recuperación de contraseña: $uri');
    
    final NavigatorState? navigator = _navigatorKey.currentState;
    if (navigator == null) return;

    // Extraer tokens de los parámetros de la URL
    final accessToken = uri.queryParameters['access_token'];
    final refreshToken = uri.queryParameters['refresh_token'];
    final type = uri.queryParameters['type'];

    debugPrint('Tokens extraídos - Access: ${accessToken != null}, Refresh: ${refreshToken != null}, Type: $type');

    // Si tenemos tokens de recovery, usar el flujo normal
    if (type == 'recovery' && accessToken != null) {
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => PasswordResetScreen(
            accessToken: accessToken,
            refreshToken: refreshToken,
          ),
        ),
        (route) => false,
      );
    } else {
      // Si no hay tokens pero el enlace es de recovery, intentar con la sesión existente
      debugPrint('No hay tokens, verificando sesión existente...');
      final session = Supabase.instance.client.auth.currentSession;
      
      if (session != null) {
        debugPrint('Sesión existente encontrada, procediendo con reset');
        navigator.pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => PasswordResetScreen(),
          ),
          (route) => false,
        );
      } else {
        debugPrint('No hay sesión, mostrando error');
        _showPasswordResetError(navigator);
      }
    }
  }

  // Manejar enlaces de recuperación de contraseña desde web
  void _handlePasswordResetWebLink(Uri uri) {
    debugPrint('Procesando enlace web de recuperación de contraseña: $uri');
    
    final NavigatorState? navigator = _navigatorKey.currentState;
    if (navigator == null) return;

    // Extraer tokens del fragment de la URL web
    final fragment = uri.fragment;
    final fragmentParams = Uri.splitQueryString(fragment.contains('?') ? fragment.split('?')[1] : '');
    
    final accessToken = fragmentParams['access_token'];
    final refreshToken = fragmentParams['refresh_token'];
    final type = fragmentParams['type'];

    if (type == 'recovery' && accessToken != null) {
      // Navegar a la pantalla de recuperación de contraseña con los tokens
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => PasswordResetScreen(
            accessToken: accessToken,
            refreshToken: refreshToken,
          ),
        ),
        (route) => false,
      );
    } else {
      // Tokens inválidos, mostrar error
      _showPasswordResetError(navigator);
    }
  }

  // Mostrar error cuando los tokens de recuperación son inválidos
  void _showPasswordResetError(NavigatorState navigator) {
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text('Error de Recuperación'),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          body: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 80, color: Colors.red),
                SizedBox(height: 20),
                Text(
                  'Enlace de recuperación inválido',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 10),
                Text(
                  'El enlace de recuperación de contraseña es inválido o ha expirado. Por favor, solicita un nuevo enlace desde la pantalla de login.',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () {
                    navigator.pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => LoginScreen()),
                      (route) => false,
                    );
                  },
                  child: Text('Ir a Login'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey, // Añadido para manejar la navegación desde fuera de un BuildContext
      // Configuración de localización
      locale: const Locale('es', 'ES'),
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        _MyMaterialLocalizationsDelegate(), // Nuestra delegación personalizada
      ],
      supportedLocales: [
        const Locale('es', 'ES'), // Español
      ],
      routes: {
        '/': (context) => SplashScreen(),
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/user_menu': (context) => UserMenuScreen(initialTabIndex: 0),
        '/create_player': (context) => PlayerCreatorScreen(),
        '/ver_Jugadores':(context) => PlayerListScreen(),
        '/create_match': (context) => CreateMatchScreen(),
        '/match_list': (context) => MatchListScreen(),
        '/match_join': (context) => MatchJoinScreen(matchId: ''),
        '/profile_edit': (context) => ProfileEditScreen(), // Añadido para manejar la edición de perfil
        '/password_reset_request': (context) => PasswordResetRequestScreen(), // Ruta para solicitar reset
        '/password_reset': (context) => PasswordResetScreen(), // Ruta para establecer nueva contraseña
        // Rutas del sistema de amigos
        '/friends': (context) => const FriendsMainScreen(),
        '/people': (context) => const PeopleScreen(),
        '/friend_requests': (context) => const FriendRequestsScreen(),
      },
      debugShowCheckedModeBanner: false,
      title: 'StatsFut',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue.shade800,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Poppins',
        textTheme: TextTheme(
          headlineLarge: TextStyle(fontWeight: FontWeight.bold),
          headlineMedium: TextStyle(fontWeight: FontWeight.w600),
          titleLarge: TextStyle(fontWeight: FontWeight.w600),
        ),
        buttonTheme: ButtonThemeData(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          buttonColor: Colors.orange.shade600,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          ),
        ),
      ),
      // Removed the redundant home property
    );
  }
}

// Nueva versión del LoginScreen que recibe un ID de partido para redirigir después del login
class LoginScreenWithMatchRedirect extends StatelessWidget {
  final String matchId;
  
  const LoginScreenWithMatchRedirect({Key? key, required this.matchId}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return LoginScreen(redirectMatchId: matchId);
  }
}

// Nueva clase SplashScreen para verificar la sesión al iniciar la app
class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    // Añadimos un pequeño retraso para mostrar la pantalla de splash
    // y dar tiempo a que se cargue la sesión
    await Future.delayed(Duration(milliseconds: 1500));
    
    // Verificar si hay una sesión activa
    final Session? session = Supabase.instance.client.auth.currentSession;
    
    if (!mounted) return;
    
    if (session != null) {
      // Si hay sesión activa, ir al menú de usuario
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => UserMenuScreen(initialTabIndex: 0))
      );
    } else {
      // Si no hay sesión, ir a la pantalla principal
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => MainScreen())
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0D47A1), // Azul oscuro
              Color(0xFF1976D2), // Azul medio
              Color(0xFF2196F3), // Azul claro
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo animado
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.8, end: 1.0),
                duration: Duration(seconds: 1),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Hero(
                      tag: 'app_logo',
                      child: Container(
                        height: 150,
                        width: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 15,
                              offset: Offset(0, 5),
                            )
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/habilidades.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 30),
              // Indicador de carga
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              SizedBox(height: 20),
              // Texto de carga
              Text(
                "Cargando...",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MainScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white), // Cambiando el color de la flecha a blanco
      ),
      body: Stack(
        children: [
          // Fondo con patrón de fútbol
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/soccer_pattern.png'),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.15),
                  BlendMode.dstATop,
                ),
              ),
            ),
          ),
          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF0D47A1), // Azul oscuro
                  Color(0xFF1976D2), // Azul medio
                  Color(0xFF2196F3), // Azul claro
                ],
              ),
            ),
          ),
          // Contenido principal
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    SizedBox(height: screenSize.height * 0.05),
                    // Logo con animación sutil
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.8, end: 1.0),
                      duration: Duration(seconds: 1),
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Hero(
                            tag: 'app_logo',
                            child: Container(
                              height: 150,
                              width: 150,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 15,
                                    offset: Offset(0, 5),
                                  )
                                ],
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  'assets/habilidades.png',
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 40),
                    // Título de la app con animación
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: 1),
                      duration: Duration(milliseconds: 800),
                      curve: Curves.easeOutQuad,
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, 20 * (1 - value)),
                            child: child,
                          ),
                        );
                      },
                      child: Text(
                        "¡Bienvenido a StatsFut!",
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                          shadows: [
                            Shadow(
                              blurRadius: 4,
                              color: Colors.black26,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: 16),
                    // Descripción con animación
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: 1),
                      duration: Duration(milliseconds: 800),

                      curve: Curves.easeOutQuad,
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, 20 * (1 - value)),
                            child: child,
                          ),
                        );
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          "La aplicación profesional para gestionar tus partidos y estadísticas de fútbol de manera eficiente.",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.9),
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    SizedBox(height: 50),
                    // Tarjetas de características
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: 1),
                      duration: Duration(milliseconds: 800),

                      curve: Curves.easeOutQuad,
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, 20 * (1 - value)),
                            child: child,
                          ),
                        );
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildFeatureCard(
                            icon: Icons.sports_soccer,
                            title: "Partidos",
                            color: Colors.orange.shade600,
                          ),
                          _buildFeatureCard(
                            icon: Icons.people_alt,
                            title: "Jugadores",
                            color: Colors.green.shade600,
                          ),
                          _buildFeatureCard(
                            icon: Icons.bar_chart,
                            title: "Estadísticas",
                            color: Colors.red.shade600,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 50),
                    // Botones de acción
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: 1),
                      duration: Duration(milliseconds: 800),
                      curve: Curves.easeOutQuad,
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, 20 * (1 - value)),
                            child: child,
                          ),
                        );
                      },
                      child: _buildElevatedButton(
                        text: "Iniciar Sesión",
                        icon: Icons.login,
                        isPrimary: true,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => LoginScreen()),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: 16),
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: 1),
                      duration: Duration(milliseconds: 800),
                      curve: Curves.easeOutQuad,
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, 20 * (1 - value)),
                            child: child,
                          ),
                        );
                      },
                      child: _buildElevatedButton(
                        text: "Registrarse",
                        icon: Icons.person_add,
                        isPrimary: false,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => RegisterScreen()),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: 30),
                    // Footer con versión
                    Opacity(
                      opacity: 0.7,
                      child: Text(
                        "v1.0.0",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Container(
      width: 80,
      height: 90,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
          SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildElevatedButton({
    required String text,
    required IconData icon,
    required bool isPrimary,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: (isPrimary ? Colors.orange.shade600 : Colors.white).withOpacity(0.3),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? Colors.orange.shade600 : Colors.white,
          foregroundColor: isPrimary ? Colors.white : Colors.blue.shade800,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20),
            SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}