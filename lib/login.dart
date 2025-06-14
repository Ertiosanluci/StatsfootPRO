import 'package:flutter/material.dart';
import 'package:statsfoota/register.dart';
import 'package:statsfoota/features/notifications/join_match_screen.dart'; // Actualizado path
import 'package:statsfoota/password_reset_request_screen.dart'; // Nueva pantalla de solicitud de reset
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';
import 'package:statsfoota/services/onesignal_service.dart'; // Importar el servicio de OneSignal

class LoginScreen extends StatefulWidget {
  // Añadir un parámetro opcional para el ID del partido para redirigir después del login
  final String? redirectMatchId;
  
  const LoginScreen({Key? key, this.redirectMatchId}) : super(key: key);
  
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    
    // Si hay un ID de partido para redireccionar, mostrar un mensaje
    if (widget.redirectMatchId != null && widget.redirectMatchId!.isNotEmpty) {
      // Programar el mensaje para después de que el widget se haya construido
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Inicia sesión para unirte al partido'),
            backgroundColor: Colors.blue.shade700,
            duration: Duration(seconds: 3),
          ),
        );
      });
    }
    
    // Configurar animaciones
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1200),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.0, 0.65, curve: Curves.easeOut),
      ),
    );
    
    _slideAnimation = Tween<Offset>(begin: Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.0, 0.65, curve: Curves.easeOutQuad),
      ),
    );
    
    // Iniciar animación
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  
  // Método para registrar el dispositivo del usuario en la tabla user_devices
  Future<void> _registerUserDevice() async {
    try {
      debugPrint('Registrando dispositivo del usuario en user_devices...');
      
      // Inicializar OneSignal si aún no se ha hecho
      await OneSignalService.initializeOneSignal();
      
      // Obtener el player ID actual
      final playerId = await OneSignalService.getPlayerId();
      
      if (playerId != null) {
        // Guardar el player ID en la tabla user_devices
        await OneSignalService.savePlayerIdToSupabase(playerId);
        
        // Migrar tokens antiguos a la nueva tabla si es necesario
        await OneSignalService.migrateTokensToDevices();
        
        debugPrint('Dispositivo registrado correctamente con player ID: $playerId');
      } else {
        debugPrint('No se pudo obtener el player ID de OneSignal');
      }
    } catch (e) {
      debugPrint('Error al registrar el dispositivo: $e');
      // No interrumpimos el flujo principal por un error en el registro del dispositivo
    }
  }

  Future<void> _signIn() async {
    // Validar el formulario primero
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });
    
    try {
      // Ocultar el teclado
      FocusScope.of(context).unfocus();
      
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      
      if (response.user == null) {
        if (mounted) {
          _showErrorSnackBar('No se pudo iniciar sesión. Verifica tus credenciales.');
        }
      } else {
        if (mounted) {
          _showSuccessSnackBar();
          
          // Registrar el dispositivo del usuario en la tabla user_devices
          _registerUserDevice();
          
          // Esperar a que se muestre el SnackBar antes de navegar
          Future.delayed(Duration(seconds: 1), () {
            // Si hay un ID de partido para redireccionar, navegar a esa pantalla
            if (widget.redirectMatchId != null && widget.redirectMatchId!.isNotEmpty) {
              Navigator.pushReplacement(
                context, 
                MaterialPageRoute(
                  builder: (context) => JoinMatchScreen(matchId: int.parse(widget.redirectMatchId!)),
                ),
              );
            } else {
              // De lo contrario, ir al menú principal
              Navigator.pushReplacementNamed(context, '/user_menu');
            }
          });
        }
      }
    } on AuthException catch (e) {
      _showErrorSnackBar(_getReadableAuthError(e.message));
    } catch (e) {
      _showErrorSnackBar('Error inesperado: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.red.shade700,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: Duration(seconds: 4),
      ),
    );
  }
  
  void _showSuccessSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 10),
            Text("¡Inicio de sesión exitoso!"),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.green.shade600,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: Duration(seconds: 2),
      ),
    );
  }
  
  String _getReadableAuthError(String errorMessage) {
    if (errorMessage.contains('Invalid login credentials')) {
      return 'Credenciales inválidas. Verifica tu email y contraseña.';
    } else if (errorMessage.contains('Email not confirmed')) {
      return 'Tu email no ha sido confirmado. Revisa tu bandeja de entrada.';
    } else if (errorMessage.contains('Too many requests')) {
      return 'Demasiados intentos fallidos. Inténtalo más tarde.';
    } else {
      return 'Error de autenticación: $errorMessage';
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    // Asegurar que la barra de estado sea transparente
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Color(0xFF1565C0), // Color de fondo base para evitar barras blancas
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: Colors.white),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1565C0), // Azul oscuro
              Color(0xFF1976D2), // Azul primario
              Color(0xFF1E88E5), // Azul medio
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.fromLTRB(24.0, 0, 24.0, MediaQuery.of(context).viewInsets.bottom + 24.0),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(height: size.height * 0.03),
                        
                        // Logo con animación personalizada
                        Center(
                          child: TweenAnimationBuilder<double>(
                            tween: Tween<double>(begin: 0.0, end: 1.0),
                            duration: Duration(milliseconds: 800),
                            curve: Curves.elasticOut,
                            builder: (context, value, child) {
                              return Transform.scale(
                                scale: value,
                                child: child,
                              );
                            },
                            child: Hero(
                              tag: 'app_logo',
                              child: Container(
                                height: 120,
                                width: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 15,
                                      offset: Offset(0, 8),
                                    ),
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
                          ),
                        ),
                        
                        SizedBox(height: 28),
                        
                        // Títulos animados
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0.0, end: 1.0),
                          duration: Duration(milliseconds: 1000),
                          curve: Curves.easeOut,
                          builder: (context, value, child) {
                            return Opacity(
                              opacity: value,
                              child: Transform.translate(
                                offset: Offset(0, 20 * (1 - value)),
                                child: child,
                              ),
                            );
                          },
                          child: Column(
                            children: [
                              Text(
                                "¡Bienvenido!",
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 1.0,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black26,
                                      blurRadius: 5,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 8),
                              Text(
                                "Inicia sesión para continuar",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white.withOpacity(0.8),
                                  letterSpacing: 0.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        
                        SizedBox(height: 40),
                        
                        // Campos de formulario con validación
                        TextFormField(
                          controller: _emailController,
                          style: TextStyle(color: Colors.white),
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor, introduce tu correo electrónico';
                            }
                            final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                            if (!emailRegex.hasMatch(value)) {
                              return 'Introduce un correo electrónico válido';
                            }
                            return null;
                          },
                          decoration: _buildInputDecoration(
                            'Email',
                            Icons.email_rounded,
                            false,
                          ),
                        ),
                        
                        SizedBox(height: 20),
                        
                        TextFormField(
                          controller: _passwordController,
                          style: TextStyle(color: Colors.white),
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor, introduce tu contraseña';
                            }
                            if (value.length < 6) {
                              return 'La contraseña debe tener al menos 6 caracteres';
                            }
                            return null;
                          },
                          onFieldSubmitted: (_) => _signIn(),
                          decoration: _buildInputDecoration(
                            'Contraseña',
                            Icons.lock_rounded,
                            true,
                          ),
                        ),
                        
                        SizedBox(height: 10),
                        
                        // Olvidaste tu contraseña
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context, 
                                MaterialPageRoute(builder: (context) => PasswordResetRequestScreen())
                              );
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white70,
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            ),
                            child: Text(
                              '¿Olvidaste tu contraseña?',
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                        ),
                        
                        SizedBox(height: 40),
                        
                        // Botón de inicio de sesión
                        ElevatedButton(
                          onPressed: _isLoading ? null : _signIn,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.shade600,
                            disabledBackgroundColor: Colors.orange.shade300,
                            foregroundColor: Colors.white,
                            elevation: 8,
                            shadowColor: Colors.orange.withOpacity(0.5),
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: _isLoading 
                            ? SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.login_rounded, size: 20),
                                  SizedBox(width: 10),
                                  Text(
                                    "INICIAR SESIÓN",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                        ),
                          SizedBox(height: 24),
                        
                        // Enlace de ¿Olvidaste tu contraseña?
                        Center(
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PasswordResetRequestScreen(),
                                ),
                              );
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white70,
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                            child: Text(
                              "¿Olvidaste tu contraseña?",
                              style: TextStyle(
                                fontSize: 14,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),
                        
                        SizedBox(height: 16),
                        
                        // Registro
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "¿No tienes cuenta?",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 15,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context, 
                                  MaterialPageRoute(builder: (context) => RegisterScreen())
                                );
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              ),
                              child: Text(
                                "REGÍSTRATE",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        SizedBox(height: 20),
                        
                        // Indicador de versión
                        Padding(
                          padding: EdgeInsets.only(bottom: 16),
                          child: Text(
                            "v1.0.0",
                            style: TextStyle(color: Colors.white38, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  InputDecoration _buildInputDecoration(String label, IconData icon, bool isPassword) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.white70),
      prefixIcon: Icon(icon, color: Colors.white70, size: 22),
      suffixIcon: isPassword 
        ? IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility,
              color: Colors.white70,
              size: 20,
            ),
            onPressed: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
          ) 
        : null,
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.white38),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.white, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.orange.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.orange.shade400, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      errorStyle: TextStyle(color: Colors.orange.shade200),
      filled: true,
      fillColor: Colors.white.withOpacity(0.1),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}