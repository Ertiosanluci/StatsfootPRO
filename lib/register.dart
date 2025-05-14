import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;

// Conditionally import dart:html for web platform only
// Using a conditional import approach
import 'html_stub.dart' if (dart.library.html) 'dart:html' as html;

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _posicionController = TextEditingController();
  final _descripcionController = TextEditingController();
  
  late AnimationController _animationController;
    bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _acceptTerms = false;
  
  // Variables para manejo multiplataforma de imágenes
  File? _profileImageFile;           // Para plataformas nativas
  Uint8List? _profileImageWeb;       // Para la web
  String? _profileImagePath;         // Ruta para todas las plataformas

  @override
  void initState() {
    super.initState();
    
    // Configurar animaciones más simples para evitar problemas de rendimiento
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    // Iniciar animación
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _usernameController.dispose();
    _posicionController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }  // Método para seleccionar imagen de perfil
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    
    // Mostrar un diálogo para elegir entre cámara o galería
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: const Color(0xFF1976D2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Seleccionar imagen',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                InkWell(
                  onTap: () async {
                    Navigator.of(context).pop();
                    try {                      final XFile? photo = await picker.pickImage(
                        source: ImageSource.camera,
                        imageQuality: 70,  // Reducir calidad para mejorar rendimiento
                        maxWidth: 800,     // Limitar tamaño para compatibilidad
                      );
                      if (photo != null) {
                        setState(() {
                          if (kIsWeb) {
                            // Lectura de bytes para la web
                            photo.readAsBytes().then((value) {
                              _profileImageWeb = value;
                              _profileImagePath = photo.path;
                            });
                          } else {
                            // Uso de File para plataformas nativas
                            _profileImageFile = File(photo.path);
                            _profileImagePath = photo.path;
                          }
                        });
                      }
                    } catch (e) {
                      _showErrorSnackBar('No se pudo acceder a la cámara: ${e.toString()}');
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade600,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.photo_camera,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Text(
                          'Tomar una foto',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    Navigator.of(context).pop();
                    try {                      // Usar configuraciones optimizadas para compatibilidad con Chrome
                      final XFile? image = await picker.pickImage(
                        source: ImageSource.gallery,
                        imageQuality: 70,  // Reducir calidad para mejorar rendimiento
                        maxWidth: 800,     // Limitar tamaño para compatibilidad
                      );
                      if (image != null) {
                        setState(() {
                          if (kIsWeb) {
                            // Lectura de bytes para la web
                            image.readAsBytes().then((value) {
                              _profileImageWeb = value;
                              _profileImagePath = image.path;
                            });
                          } else {
                            // Uso de File para plataformas nativas
                            _profileImageFile = File(image.path);
                            _profileImagePath = image.path;
                          }
                        });
                      }
                    } catch (e) {
                      // Manejo específico para errores en la web
                      _showErrorSnackBar('Error al seleccionar la imagen: ${e.toString()}');
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade600,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.photo_library,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Text(
                          'Seleccionar de galería',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'Cancelar',
                    style: TextStyle(
                      color: Colors.orange.shade300,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );  }
    // Método para subir imagen de perfil a Supabase Storage
  Future<String?> _uploadProfileImage(String userId) async {
    if (_profileImagePath == null) return null;
    
    try {
      final String username = _usernameController.text.trim();
      // Extraer extensión del archivo de forma segura para compatibilidad multiplataforma
      String fileExtension = '';
      try {
        fileExtension = path.extension(_profileImagePath!).toLowerCase();
        // Si la extensión está vacía o no es válida, asignar una por defecto
        if (fileExtension.isEmpty || !fileExtension.startsWith('.')) {
          fileExtension = '.jpg'; // Extensión predeterminada
        }
      } catch (e) {
        // En caso de error al extraer la extensión, usar jpg por defecto
        fileExtension = '.jpg';
      }
      
      final String folderName = '$userId-$username';
      final String fileName = '$folderName/${DateTime.now().millisecondsSinceEpoch}$fileExtension';
      
      // Intentar eliminar archivo anterior si existe
      try {
        await Supabase.instance.client.storage
            .from('images')
            .remove([fileName]);
      } catch (e) {
        // Ignorar error si no existe
      }
      
      // Preparar los bytes de la imagen para subirla
      Uint8List? imageBytes;
      
      if (kIsWeb) {
        // En web, ya tenemos los bytes
        imageBytes = _profileImageWeb;
      } else if (_profileImageFile != null) {
        // En plataformas nativas, leer del archivo
        List<int> tempBytes = await _profileImageFile!.readAsBytes();
        imageBytes = Uint8List.fromList(tempBytes);
      }
      
      if (imageBytes == null) {
        print('No se pudieron obtener los bytes de la imagen');
        return null;
      }
      
      if (imageBytes == null || imageBytes.isEmpty) {
        print('No se pudieron obtener los bytes de la imagen');
        return null;
      }
      
      // Convertir List<int> a Uint8List para compatibilidad con uploadBinary
      final Uint8List uint8Bytes = Uint8List.fromList(imageBytes);
      
      // Subir archivo usando bytes para mayor compatibilidad entre plataformas
      await Supabase.instance.client.storage
          .from('images')
          .uploadBinary(
            fileName, 
            uint8Bytes,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: true,
              contentType: 'image/jpeg', // Definir tipo de contenido explícitamente
            )
          );
      
      // Obtener URL pública
      final String imageUrl = Supabase.instance.client.storage
          .from('images')
          .getPublicUrl(fileName);
      
      return imageUrl;
    } catch (e) {
      print('Error al subir imagen: $e');
      return null;
    }
  }

  // Método para verificar si el email ya existe
  Future<bool> _checkIfEmailExists(String email) async {
    try {
      // Intentamos encontrar cualquier usuario con este correo electrónico
      final response = await Supabase.instance.client
          .from('usuarios')
          .select('email')
          .eq('email', email.trim())
          .limit(1)
          .maybeSingle();
      
      // Si se encuentra algún registro, el correo ya está en uso
      return response != null;
    } catch (e) {
      print('Error al verificar email: $e');
      // En caso de error, asumimos que no existe para continuar con la validación normal
      return false;
    }
  }

  // Método para el proceso de registro
  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    if (!_acceptTerms) {
      _showErrorSnackBar('Debes aceptar los términos y condiciones');
      return;
    }

    setState(() {
      _isLoading = true;
    });
    
    try {
      // Ocultar teclado
      FocusScope.of(context).unfocus();
      
      // Mostrar diálogo de comprobación
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ),
      );
      
      // Verificar si el email ya existe antes de intentar el registro
      final emailExists = await _checkIfEmailExists(_emailController.text.trim());
      
      // Cerrar el diálogo de comprobación
      Navigator.pop(context);
      
      if (emailExists) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Este correo electrónico ya está registrado. Por favor, usa otro.');
        return;
      }
      
      // Mostrar progreso del registro
      _showProgressDialog();
      
      // Registro en Supabase
      final response = await Supabase.instance.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        data: {
          'username': _usernameController.text.trim(),
        },
      );
      
      if (response.user == null) {
        Navigator.of(context, rootNavigator: true).pop();
        _showErrorSnackBar('No se pudo crear la cuenta. Intente de nuevo más tarde.');
        return;
      }
      
      // Guardar perfil
      try {
        await Supabase.instance.client.from('profiles').insert({
          'id': response.user!.id,
          'username': _usernameController.text.trim(),
          'created_at': DateTime.now().toIso8601String(),
          'avatar_url': null,
        });
      } catch (e) {
        // Continuar aunque falle
      }
      
      // Guardar usuario (compatibilidad)
      try {
        await Supabase.instance.client.from('usuarios').insert({
          'id': response.user!.id,
          'username': _usernameController.text.trim(),
          'email': _emailController.text.trim(),
          'created_at': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        // Continuar aunque falle
      }
        // Subir imagen si hay
      if (_profileImagePath != null) {
        try {
          final avatarUrl = await _uploadProfileImage(response.user!.id);
          
          if (avatarUrl != null) {
            await Supabase.instance.client.from('profiles')
                .update({'avatar_url': avatarUrl})
                .eq('id', response.user!.id);
          }
        } catch (e) {
          // Continuar aunque falle
        }
      }// Cerrar progreso
      Navigator.of(context, rootNavigator: true).pop();
      
      // Iniciar sesión automáticamente
      try {
        await Supabase.instance.client.auth.signInWithPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        
        // Mostrar éxito y navegar a la pantalla principal
        _showSuccessDialog(autoLogin: true);
      } catch (loginError) {
        // Si falla el inicio de sesión automático, mostrar el diálogo normal
        _showSuccessDialog(autoLogin: false);
      }
      
    } on AuthException catch (e) {
      Navigator.of(context, rootNavigator: true).pop();
      _showErrorSnackBar(_getReadableAuthError(e.message));
    } catch (e) {
      Navigator.of(context, rootNavigator: true).pop();
      _showErrorSnackBar('Error: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // Diálogo de progreso
  void _showProgressDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 50,
                width: 50,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Creando cuenta...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Esto puede tardar unos segundos',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
    // Diálogo de éxito
  void _showSuccessDialog({bool autoLogin = false}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 80,
                width: 80,
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_rounded,
                  size: 50,
                  color: Colors.green.shade700,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                '¡Registro exitoso!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                autoLogin 
                    ? 'Tu cuenta ha sido creada y has iniciado sesión automáticamente.'
                    : 'Hemos enviado un correo de verificación a ${_emailController.text}. Por favor, revisa tu bandeja de entrada.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade800,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Cerrar diálogo
                  if (autoLogin) {
                    // En lugar de volver a la pantalla de inicio, navegar a la pantalla principal (user_menu)
                    Navigator.pushNamedAndRemoveUntil(context, '/user_menu', (route) => false);
                  } else {
                    Navigator.of(context).pop(); // Volver a la pantalla de inicio si no es inicio automático
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                ),
                child: Text(
                  autoLogin ? 'Ir al menú principal' : 'Continuar',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Mensaje de error
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.red.shade700,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
  
  // Mensajes de error amigables
  String _getReadableAuthError(String errorMessage) {
    if (errorMessage.contains('email already in use')) {
      return 'Este correo ya está registrado';
    } else if (errorMessage.contains('password should be at least 6 characters')) {
      return 'La contraseña debe tener al menos 6 caracteres';
    } else if (errorMessage.contains('invalid email')) {
      return 'El formato del correo electrónico es inválido';
    } else if (errorMessage.contains('network request failed')) {
      return 'Error de conexión. Verifica tu internet e intenta nuevamente.';
    } else {
      return 'Error de registro: $errorMessage';
    }
  }
  
  // Alternador de visibilidad de contraseña
  void _togglePasswordVisibility(bool isConfirmPassword) {
    setState(() {
      if (isConfirmPassword) {
        _obscureConfirmPassword = !_obscureConfirmPassword;
      } else {
        _obscurePassword = !_obscurePassword;
      }
    });
  }
  
  // Constructor de campos de texto optimizados
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
    TextInputAction textInputAction = TextInputAction.next,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: _buildInputDecoration(label, icon),
      validator: validator,
      textInputAction: textInputAction,
      enableInteractiveSelection: true,
      autocorrect: false,
    );
  }
  
  // Decoración para campos de texto
  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      prefixIcon: Icon(icon, color: Colors.white70),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.white38),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.white, width: 2),
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
    );
  }

  // Método para mostrar la imagen de perfil según la plataforma
  Widget _buildProfileImage() {
    if (kIsWeb) {
      // Para web, usar los bytes de la imagen
      if (_profileImageWeb != null) {
        return Image.memory(
          _profileImageWeb!,
          fit: BoxFit.cover,
        );
      }
    } else {
      // Para plataformas nativas, usar el archivo
      if (_profileImageFile != null) {
        return Image.file(
          _profileImageFile!,
          fit: BoxFit.cover,
        );
      }
    }
    
    // En caso de error o estado intermedio, mostrar un icono
    return Icon(
      Icons.person,
      size: 80,
      color: Colors.white.withOpacity(0.9),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Configurar la barra de estado
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1565C0), // Azul oscuro
              Color(0xFF1976D2), // Azul primario
              Color(0xFF42A5F5), // Azul claro
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  
                  // Título de la pantalla
                  const Text(
                    "Crear Cuenta",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Avatar y selector de imagen
                  Center(
                    child: Stack(
                      children: [
                        GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            height: 120,
                            width: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.2),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 15,
                                  offset: Offset(0, 8),
                                ),
                              ],
                            ),                            child: ClipOval(
                              child: _profileImagePath != null
                                  ? _buildProfileImage()
                                  : Icon(
                                      Icons.person,
                                      size: 80,
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                            ),
                          ),
                        ),
                        
                        // Botón de cambio de imagen
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade600,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 5,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Únete a nuestra comunidad y comienza a registrar tus estadísticas",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.8),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Campo de nombre de usuario
                  _buildTextField(
                    controller: _usernameController,
                    label: 'Nombre de usuario',
                    icon: Icons.person_rounded,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, ingresa un nombre de usuario';
                      }
                      if (value.length < 3) {
                        return 'El nombre debe tener al menos 3 caracteres';
                      }
                      return null;
                    },
                  ),                  
                  const SizedBox(height: 20),
                  
                  // Campo de email
                  _buildTextField(
                    controller: _emailController,
                    label: 'Correo Electrónico',
                    icon: Icons.email_rounded,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, ingresa tu correo electrónico';
                      }
                      // Validación básica de formato de email
                      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                      if (!emailRegex.hasMatch(value)) {
                        return 'Ingresa un correo electrónico válido';
                      }
                      
                      // Validación específica para Gmail
                      if (value.toLowerCase().endsWith('@gmail.com')) {
                        // Obtener la parte local del email (antes de @)
                        final localPart = value.split('@')[0].toLowerCase();
                        
                        // Verificar reglas específicas de Gmail
                        // 1. Longitud mínima de 6 caracteres para la parte local
                        if (localPart.length < 6) {
                          return 'Las direcciones de Gmail deben tener al menos 6 caracteres antes de @gmail.com';
                        }
                        
                        // 2. No permitir caracteres consecutivos como puntos
                        if (localPart.contains('..')) {
                          return 'Dirección de Gmail inválida: no puede contener puntos consecutivos';
                        }
                        
                        // 3. Verificar que no comience ni termine con punto
                        if (localPart.startsWith('.') || localPart.endsWith('.')) {
                          return 'Dirección de Gmail inválida: no puede comenzar ni terminar con punto';
                        }
                        
                        // 4. Verificar caracteres permitidos en Gmail
                        final gmailAllowedChars = RegExp(r'^[a-z0-9.]+$');
                        if (!gmailAllowedChars.hasMatch(localPart)) {
                          return 'Dirección de Gmail inválida: solo puede contener letras, números y puntos';
                        }
                      }
                      
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Campo de contraseña
                  TextFormField(
                    controller: _passwordController,
                    style: const TextStyle(color: Colors.white),
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      labelStyle: const TextStyle(color: Colors.white70),
                      prefixIcon: const Icon(Icons.lock_rounded, color: Colors.white70),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: Colors.white70,
                          size: 20,
                        ),
                        onPressed: () => _togglePasswordVisibility(false),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.white38),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.white, width: 2),
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
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, ingresa una contraseña';
                      }
                      if (value.length < 6) {
                        return 'La contraseña debe tener al menos 6 caracteres';
                      }
                      return null;
                    },
                    textInputAction: TextInputAction.next,
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Campo de confirmar contraseña
                  TextFormField(
                    controller: _confirmPasswordController,
                    style: const TextStyle(color: Colors.white),
                    obscureText: _obscureConfirmPassword,
                    decoration: InputDecoration(
                      labelText: 'Confirmar Contraseña',
                      labelStyle: const TextStyle(color: Colors.white70),
                      prefixIcon: const Icon(Icons.lock_rounded, color: Colors.white70),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                          color: Colors.white70,
                          size: 20,
                        ),
                        onPressed: () => _togglePasswordVisibility(true),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.white38),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.white, width: 2),
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
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, confirma tu contraseña';
                      }
                      if (value != _passwordController.text) {
                        return 'Las contraseñas no coinciden';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Términos y condiciones
                  Theme(
                    data: Theme.of(context).copyWith(
                      unselectedWidgetColor: Colors.white70,
                    ),
                    child: CheckboxListTile(
                      title: const Text(
                        "Acepto los términos y condiciones",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      value: _acceptTerms,
                      onChanged: (value) {
                        setState(() {
                          _acceptTerms = value ?? false;
                        });
                      },
                      activeColor: Colors.orange.shade600,
                      checkColor: Colors.white,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      dense: true,
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Botón de registro
                  ElevatedButton(
                    onPressed: _isLoading ? null : _signUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade600,
                      disabledBackgroundColor: Colors.orange.shade300,
                      foregroundColor: Colors.white,
                      elevation: 8,
                      shadowColor: Colors.orange.withOpacity(0.5),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.how_to_reg_rounded, size: 20),
                        const SizedBox(width: 10),
                        const Text(
                          "CREAR CUENTA",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Enlace para iniciar sesión
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.arrow_back, size: 16),
                          const SizedBox(width: 8),
                          const Text(
                            "¿Ya tienes cuenta? Iniciar sesión",
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}