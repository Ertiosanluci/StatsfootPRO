import 'dart:io';
import 'dart:typed_data'; // Añadido para usar Uint8List
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ProfileEditScreen extends StatefulWidget {
  @override
  _ProfileEditScreenState createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isSubmitting = false;
  
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _emailController = TextEditingController(); // Solo lectura
  final TextEditingController _birthdateController = TextEditingController();
  
  String? _selectedPosition;
  String? _selectedFrequency;
  String? _selectedGender;
  String? _selectedLevel;
    DateTime? _birthdate;
  
  // Variables para manejo multiplataforma de imágenes
  File? _imageFile;              // Para plataformas nativas
  Uint8List? _imageWebBytes;     // Para la web
  String? _imagePath;            // Ruta para todas las plataformas
  String? _currentImageUrl;
  String _username = "Usuario";
  
  // Lista de posiciones de fútbol
  final List<String> _positions = [
    'Portero', 
    'Defensa central', 
    'Lateral derecho', 
    'Lateral izquierdo', 
    'Mediocentro defensivo',
    'Mediocentro', 
    'Mediocentro ofensivo', 
    'Extremo derecho', 
    'Extremo izquierdo',
    'Segundo delantero', 
    'Delantero centro'
  ];
  
  // Frecuencia con la que juega
  final List<String> _frequencies = [
    'Rara vez',
    '1 vez a la semana',
    '2-3 veces a la semana',
    'Más de 3 veces a la semana',
    'Todos los días'
  ];
  
  // Opciones de género
  final List<String> _genders = [
    'Masculino',
    'Femenino',
    'Otro',
    'Prefiero no decir'
  ];
  
  // Niveles de juego
  final List<String> _levels = [
    'Principiante',
    'Aficionado',
    'Intermedio',
    'Avanzado',
    'Semi-profesional',
    'Profesional'
  ];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }
  
  @override
  void dispose() {
    _usernameController.dispose();
    _descriptionController.dispose();
    _emailController.dispose();
    _birthdateController.dispose();
    super.dispose();
  }

  // Cargar datos del perfil del usuario
  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final user = Supabase.instance.client.auth.currentUser;
      
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se encontró sesión de usuario')),
        );
        Navigator.pop(context);
        return;
      }
      
      // Obtener datos del perfil
      final profileData = await Supabase.instance.client
          .from('profiles')
          .select('username, avatar_url, position, description, birthdate, frequency, gender, level')
          .eq('id', user.id)
          .single();
      
      if (mounted) {
        setState(() {
          // Cargar el email del usuario (que viene de auth)
          _emailController.text = user.email ?? 'No disponible';
          
          // Cargar datos básicos
          _username = profileData['username'] ?? "Usuario";
          _usernameController.text = profileData['username'] ?? '';
          _currentImageUrl = profileData['avatar_url'];
          _descriptionController.text = profileData['description'] ?? '';
          
          // Cargar posición
          _selectedPosition = profileData['position'];
          
          // Cargar fecha de nacimiento
          if (profileData['birthdate'] != null) {
            _birthdate = DateTime.parse(profileData['birthdate']);
            _birthdateController.text = _formatDate(_birthdate!);
          }
          
          // Cargar otros campos nuevos
          _selectedFrequency = profileData['frequency'];
          _selectedGender = profileData['gender'];
          _selectedLevel = profileData['level'];
          
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error al cargar perfil: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar perfil: $e')),
        );
      }
    }
  }
  
  // Formatear fecha para mostrar
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
  // Seleccionar imagen desde la galería (mejorado)
  Future<void> _pickImage() async {
    try {
      print('Iniciando selección de imagen desde galería');
      print('Plataforma actual: ${kIsWeb ? "Web" : "Nativa"}');
      
      final ImagePicker picker = ImagePicker();
      final XFile? pickedImage = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      
      if (pickedImage != null) {
        print('Imagen seleccionada: ${pickedImage.path}');
        
        // Primero establecer la ruta
        setState(() {
          _imagePath = pickedImage.path;
        });
        
        if (kIsWeb) {
          // Para web, leer como bytes de manera asíncrona
          print('En plataforma web: leyendo bytes de la imagen');
          try {
            final bytes = await pickedImage.readAsBytes();
            print('Bytes leídos en web: ${bytes.length}');
            
            // Guardar los bytes de forma segura
            setState(() {
              _imageWebBytes = bytes;
              _imageFile = null; // Asegurar que no haya conflicto con la versión nativa
            });
          } catch (bytesError) {
            print('Error al leer bytes en web: $bytesError');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error al procesar la imagen. Intente con otro formato.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } else {
          // Para plataformas nativas, usar File
          print('En plataforma nativa: creando objeto File');
          setState(() {
            _imageFile = File(pickedImage.path);
            _imageWebBytes = null; // Asegurar que no haya conflicto con la versión web
          });
        }
        
        // Limpiar URL anterior para asegurar la actualización
        setState(() {
          // Mantener la URL actual, se reemplazará al guardar
        });
      } else {
        print('No se seleccionó ninguna imagen');
      }
    } catch (e) {
      print('Error al seleccionar imagen: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al seleccionar imagen: ${kIsWeb 
            ? "Intente con otro formato de imagen o un archivo más pequeño" 
            : e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  // Tomar foto con la cámara (simplificado)
  Future<void> _takePhoto() async {
    try {
      print('Iniciando captura de foto desde cámara');
      print('Plataforma actual: ${kIsWeb ? "Web" : "Nativa"}');
      
      // Mostrar advertencia general en web
      if (kIsWeb) {
        print('Advertencia: Acceso a cámara en web puede tener limitaciones');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Para mejor experiencia con la cámara, use Google Chrome'),
            duration: Duration(seconds: 3),
          ),
        );
      }
      
      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      
      if (photo != null) {
        print('Foto tomada: ${photo.path}');
        
        // Primero establecer la ruta
        setState(() {
          _imagePath = photo.path;
        });
        
        if (kIsWeb) {
          // Para web, leer bytes de forma asíncrona
          print('En web: leyendo bytes de la foto');
          try {
            final bytes = await photo.readAsBytes();
            print('Bytes leídos en web: ${bytes.length}');
            
            setState(() {
              _imageWebBytes = bytes;
              _imageFile = null; // Limpiar versión nativa
            });
          } catch (bytesError) {
            print('Error al leer bytes de la foto en web: $bytesError');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error al procesar la foto. Intente usar la galería.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } else {
          // Para plataformas nativas
          print('En plataforma nativa: creando objeto File para la foto');
          setState(() {
            _imageFile = File(photo.path);
            _imageWebBytes = null; // Limpiar versión web
          });
        }
      } else {
        print('No se capturó ninguna foto');
      }
    } catch (e) {
      print('Error al tomar foto: $e');
      String errorMsg;
      
      if (kIsWeb) {
        errorMsg = "La cámara puede no estar disponible en este navegador o requiere permisos. Intente usar la galería.";
      } else {
        errorMsg = e.toString();
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al tomar foto: $errorMsg'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  // Mostrar opciones para seleccionar imagen
  Future<void> _showImageSourceActionSheet() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.blue.shade800,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.photo_library, color: Colors.white),
                title: Text('Galería', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage();
                },
              ),
              ListTile(
                leading: Icon(Icons.camera_alt, color: Colors.white),
                title: Text('Cámara', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.of(context).pop();
                  _takePhoto();
                },
              ),
              if (_currentImageUrl != null)
                ListTile(
                  leading: Icon(Icons.delete, color: Colors.red.shade300),
                  title: Text('Eliminar foto', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.of(context).pop();                    setState(() {
                      _imageFile = null;
                      _imageWebBytes = null;
                      _imagePath = null;
                      _currentImageUrl = null;
                    });
                  },
                ),
            ],
          ),
        );
      },
    );
  }
  // Subir imagen a Supabase Storage (mejorado)
  Future<String?> _uploadImageToStorage() async {
    print('>>> Inicio de subida de imagen <<<');
    // Si no hay nueva imagen o ruta, devolver la URL actual
    if (_imagePath == null && _imageWebBytes == null && _imageFile == null) {
      print('No hay nueva imagen para subir, manteniendo la URL actual: $_currentImageUrl');
      return _currentImageUrl;
    }
    
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        print('Error: No hay usuario autenticado');
        return null;
      }
      
      print('Subiendo imagen para el usuario: ${user.id}');
      
      // Determinar la extensión del archivo según la plataforma
      String fileExt = '.jpg'; // Extensión por defecto
      try {
        if (_imagePath != null) {
          fileExt = path.extension(_imagePath!).toLowerCase();
          print('Extensión detectada del archivo: $fileExt');
          if (fileExt.isEmpty || !fileExt.startsWith('.')) {
            fileExt = '.jpg';
            print('Extensión inválida, usando .jpg por defecto');
          }
        } else {
          print('No hay ruta de archivo, usando extensión .jpg por defecto');
        }
      } catch (e) {
        // En caso de error, usar extensión predeterminada
        print('Error al obtener extensión: $e, usando .jpg por defecto');
      }
      
      final fileName = '${const Uuid().v4()}$fileExt';
      final filePath = 'avatars/${user.id}/$fileName'; // La carpeta dentro del bucket será "avatars"
      
      // Intentar crear la estructura de carpetas primero (esto no hará nada si ya existe)
      try {
        // No podemos crear carpetas directamente, pero intentaremos subir un archivo vacío
        // como marcador temporal si la carpeta no existe y luego lo borraremos
        final folderPath = 'avatars/${user.id}/.folder_exists';
        final emptyBytes = Uint8List(0);
        
        try {
          // Verificar si ya existe algún archivo en la carpeta del usuario
          final existing = await Supabase.instance.client.storage
              .from('images') // Usando el bucket "images"
              .list(path: 'avatars/${user.id}');
          
          // Si llegamos aquí, la carpeta ya existe
          print('Carpeta de usuario ya existe con ${existing.length} archivos.');
        } catch (folderCheckError) {
          // Si da error, la carpeta no existe, intentamos crearla
          print('Creando carpeta para usuario en bucket "images"...');
          await Supabase.instance.client.storage
              .from('images') // Usando el bucket "images"
              .uploadBinary(folderPath, emptyBytes);

          // Eliminar el archivo marcador
          await Supabase.instance.client.storage
              .from('images') // Usando el bucket "images"
              .remove([folderPath]);
        }
      } catch (folderError) {
        // Si falla la creación de carpeta, intentamos subir directamente
        print('Error creando carpeta: $folderError. Intentando subir directamente.');
      }        // Preparar los bytes para subir según la plataforma
      Uint8List? imageBytes;
      
      if (kIsWeb && _imageWebBytes != null) {
        // En web, usar los bytes ya obtenidos
        print('Usando bytes de imagen web: ${_imageWebBytes!.length} bytes');
        imageBytes = _imageWebBytes;
      } else if (!kIsWeb && _imageFile != null) {
        // En plataformas nativas, leer el archivo
        print('Leyendo bytes de archivo nativo: ${_imageFile!.path}');
        try {
          List<int> tempBytes = await _imageFile!.readAsBytes();
          imageBytes = Uint8List.fromList(tempBytes);
          print('Bytes leídos correctamente: ${imageBytes.length} bytes');
        } catch (e) {
          print('Error al leer bytes del archivo: $e');
        }
      } else if (_imagePath != null && kIsWeb) {
        // Intentar recuperar bytes si solo tenemos la ruta en web
        // Este caso no debería ocurrir normalmente, pero es un respaldo
        print('Advertencia: Solo tenemos ruta de imagen en web, intentando recuperar bytes');
        return _currentImageUrl;
      }
      
      if (imageBytes == null || imageBytes.isEmpty) {
        print('ERROR: No se pudieron obtener los bytes de la imagen');
        return _currentImageUrl;
      }
      
      print('Bytes de imagen obtenidos correctamente: ${imageBytes.length} bytes');      // Subir la imagen usando bytes para compatibilidad multiplataforma
      try {
        print('Subiendo imagen a: $filePath en bucket "images" con ${imageBytes.length} bytes');
        await Supabase.instance.client.storage
            .from('images') // Usando el bucket "images"
            .uploadBinary(
              filePath, 
              imageBytes,
              fileOptions: const FileOptions(
                cacheControl: '3600',
                upsert: true,
                contentType: 'image/jpeg', // Definir tipo de contenido explícitamente
              )
            );
        
        print('Subida completada exitosamente');
        
        // Obtener URL pública de la imagen
        final imageUrlResponse = Supabase.instance.client.storage
            .from('images') // Usando el bucket "images"
            .getPublicUrl(filePath);
        
        print('URL de imagen generada: $imageUrlResponse');
        return imageUrlResponse;
      } catch (uploadError) {
        print('ERROR durante la subida de la imagen: $uploadError');
        
        // Mostrar mensaje de error específico para web
        if (kIsWeb) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al subir imagen en la web: $uploadError'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
        }
        
        return _currentImageUrl;
      }
    } catch (e) {
      print('Error al subir imagen: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al subir imagen: $e'),
          backgroundColor: Colors.red,
        ),
      );
      return null;
    }
  }
  
  // Seleccionar fecha de nacimiento
  Future<void> _selectBirthdate() async {
    final DateTime now = DateTime.now();
    final DateTime initialDate = _birthdate ?? DateTime(now.year - 18, now.month, now.day);
    final DateTime firstDate = DateTime(1940);
    final DateTime lastDate = DateTime(now.year - 10, now.month, now.day);
    
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Colors.blue.shade800,
            colorScheme: ColorScheme.light(
              primary: Colors.blue.shade800,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            buttonTheme: ButtonThemeData(
              textTheme: ButtonTextTheme.primary,
              colorScheme: ColorScheme.light(
                primary: Colors.blue.shade800,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _birthdate) {
      setState(() {
        _birthdate = picked;
        _birthdateController.text = _formatDate(_birthdate!);
      });
    }
  }
  
  // Guardar perfil actualizado con depuración mejorada
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isSubmitting = true;
    });
    
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('No se encontró sesión de usuario');
      }
      
      // DEBUG: Estado de variables de imagen
      print('=== DEBUG: Estado de las variables de imagen ===');
      print('Plataforma: ${kIsWeb ? "Web" : "Nativa"}');
      print('_imageFile: ${_imageFile != null ? "Presente" : "Null"}');
      print('_imageWebBytes: ${_imageWebBytes != null ? "${_imageWebBytes!.length} bytes" : "Null"}');
      print('_imagePath: $_imagePath');
      print('_currentImageUrl: $_currentImageUrl');
      
      // Subir imagen si hay una nueva
      String? avatarUrl = _currentImageUrl;
      bool hasNewImage = (_imageFile != null && !kIsWeb) || 
                         (_imageWebBytes != null && kIsWeb) || 
                         (_imagePath != null && _currentImageUrl == null);
      
      print('¿Hay nueva imagen para subir? ${hasNewImage ? "SÍ" : "NO"}');
      
      if (hasNewImage) {
        print('Intentando subir nueva imagen al storage...');
        avatarUrl = await _uploadImageToStorage();
        print('Nueva URL de imagen obtenida: $avatarUrl');
      }
        // Verificación adicional para problemas con la URL de la imagen
      if (avatarUrl == null && _currentImageUrl != null) {
        print('ADVERTENCIA: Se perdió la URL de la imagen durante la subida, restaurando original');
        avatarUrl = _currentImageUrl;
      }
      
      // Preparar datos para actualizar
      final updatedData = {
        'username': _usernameController.text.trim(),
        'position': _selectedPosition,
        'description': _descriptionController.text.trim(),
        'updated_at': DateTime.now().toIso8601String(),
        'frequency': _selectedFrequency,
        'gender': _selectedGender,
        'level': _selectedLevel,
      };
      
      // Incluir fecha de nacimiento si se ha seleccionado
      if (_birthdate != null) {
        updatedData['birthdate'] = _birthdate!.toIso8601String();
      }
      
      // Solo incluir avatar_url si no es nulo
      if (avatarUrl != null) {
        updatedData['avatar_url'] = avatarUrl;
        print('Incluyendo avatar_url en los datos a actualizar: $avatarUrl');
      } else {
        print('No se incluirá avatar_url (es null)');
      }
      
      print('Actualizando perfil con datos: $updatedData');
      
      // Verificar si el perfil existe
      final profileExists = await Supabase.instance.client
          .from('profiles')
          .select('id')
          .eq('id', user.id)
          .maybeSingle();
      
      if (profileExists != null) {
        // Actualizar perfil existente
        print('Actualizando perfil existente para usuario: ${user.id}');
        await Supabase.instance.client
            .from('profiles')
            .update(updatedData)
            .eq('id', user.id);
      } else {
        // Crear nuevo perfil si no existe
        updatedData['id'] = user.id;  // Asegurarse de incluir el ID de usuario
        print('Creando nuevo perfil para usuario: ${user.id}');
        await Supabase.instance.client
            .from('profiles')
            .insert(updatedData);
      }
      
      print('Operación de guardado completada con éxito');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Perfil actualizado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print('ERROR al guardar perfil: $e');
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar el perfil: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Widget para los campos de selección (género, frecuencia, nivel)
  Widget _buildDropdown({
    required String label,
    required String hint,
    required IconData icon,
    required List<String> items,
    String? value,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white24),
          ),
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: DropdownButtonFormField<String>(
            value: value,
            hint: Text(
              hint,
              style: TextStyle(color: Colors.white.withOpacity(0.5)),
            ),
            style: TextStyle(color: Colors.white),
            dropdownColor: Colors.blue.shade800,
            icon: Icon(Icons.arrow_drop_down, color: Colors.white),
            decoration: InputDecoration(
              border: InputBorder.none,
              prefixIcon: Icon(icon, color: Colors.white70),
              prefixIconConstraints: BoxConstraints(minWidth: 45),
              contentPadding: EdgeInsets.zero,
            ),
            items: items.map((String item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(
                  item,
                  style: TextStyle(color: Colors.white),
                ),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
  
  // Widget para el selector de fecha
  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fecha de nacimiento',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        SizedBox(height: 10),
        GestureDetector(
          onTap: _selectBirthdate,
          child: AbsorbPointer(
            child: TextFormField(
              controller: _birthdateController,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Selecciona tu fecha de nacimiento',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                prefixIcon: Icon(Icons.calendar_today, color: Colors.white70),
                suffixIcon: Icon(Icons.arrow_drop_down, color: Colors.white),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: Colors.white24),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: Colors.white),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  // Widget para campo de solo lectura como el email
  Widget _buildReadonlyField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        SizedBox(height: 10),
        TextFormField(
          controller: controller,
          style: TextStyle(color: Colors.white),
          readOnly: true,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.white70),
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(color: Colors.white24),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
  
  // Widget para cambiar contraseña
  Widget _buildChangePasswordButton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cambiar contraseña',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        SizedBox(height: 10),
        Container(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () async {
              // Obtener el correo del usuario autenticado
              final user = Supabase.instance.client.auth.currentUser;
              if (user != null && user.email != null) {
                try {
                  // Enviar email de recuperación de contraseña
                  await Supabase.instance.client.auth.resetPasswordForEmail(
                    user.email!,
                    redirectTo: 'io.supabase.flutterquickstart://login-callback/',
                  );
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Se ha enviado un enlace para cambiar la contraseña a tu correo'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  print('Error al enviar email de recuperación: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al enviar email de recuperación: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            icon: Icon(Icons.lock),
            label: Text('Cambiar contraseña'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrange.shade800,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Editar Perfil",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: Colors.white),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      ),
      body: Container(
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0D47A1),  // Azul más oscuro (coincide con el splash)
              Color(0xFF1565C0),  // Azul oscuro
              Color(0xFF1976D2),  // Azul medio
              Color(0xFF1E88E5),  // Azul claro
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              )
            : SafeArea(
                child: SingleChildScrollView(
                  physics: BouncingScrollPhysics(),
                  padding: EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Imagen y nombre de perfil
                        Center(
                          child: Column(
                            children: [
                              _buildProfileImage(),
                              SizedBox(height: 15),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _username,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    shadows: [
                                      Shadow(
                                        blurRadius: 4,
                                        color: Colors.black26,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 40),
                        
                        // Campo oculto para nombre de usuario
                        SizedBox(
                          height: 0,
                          child: Opacity(
                            opacity: 0,
                            child: TextFormField(
                              controller: _usernameController,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Por favor ingresa un nombre de usuario';
                                }
                                return null;
                              },
                            ),
                          ),
                        ),
                        
                        // Email (campo de solo lectura)
                        _buildReadonlyField(
                          controller: _emailController,
                          label: 'Correo electrónico',
                          icon: Icons.email,
                        ),
                        SizedBox(height: 20),
                        
                        // Fecha de nacimiento
                        _buildDateField(),
                        SizedBox(height: 20),
                        
                        // Género
                        _buildDropdown(
                          label: 'Género',
                          hint: 'Selecciona tu género',
                          icon: Icons.person,
                          items: _genders,
                          value: _selectedGender,
                          onChanged: (value) {
                            setState(() {
                              _selectedGender = value;
                            });
                          },
                        ),
                        SizedBox(height: 20),
                        
                        // Posición en el campo
                        _buildPositionDropdown(),
                        SizedBox(height: 20),
                        
                        // Frecuencia de juego
                        _buildDropdown(
                          label: 'Frecuencia de juego entre semana',
                          hint: 'Selecciona con qué frecuencia juegas',
                          icon: Icons.sports_soccer,
                          items: _frequencies,
                          value: _selectedFrequency,
                          onChanged: (value) {
                            setState(() {
                              _selectedFrequency = value;
                            });
                          },
                        ),
                        SizedBox(height: 20),
                        
                        // Nivel de juego
                        _buildDropdown(
                          label: 'Nivel de juego',
                          hint: 'Selecciona tu nivel',
                          icon: Icons.trending_up,
                          items: _levels,
                          value: _selectedLevel,
                          onChanged: (value) {
                            setState(() {
                              _selectedLevel = value;
                            });
                          },
                        ),
                        SizedBox(height: 20),
                        
                        // Descripción
                        _buildTextField(
                          controller: _descriptionController,
                          label: 'Descripción',
                          hint: 'Cuéntanos algo sobre ti...',
                          icon: Icons.description,
                          maxLines: 4,
                        ),
                        SizedBox(height: 30),
                        
                        // Cambiar contraseña
                        _buildChangePasswordButton(),
                        SizedBox(height: 30),
                        
                        // Botón guardar
                        _buildSaveButton(),
                        SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
    Widget _buildProfileImage() {
    return GestureDetector(
      onTap: _showImageSourceActionSheet,
      child: Stack(
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 15,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: ClipOval(
              child: _getProfileImageWidget(),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.orange.shade600,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Icon(
                Icons.camera_alt,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        SizedBox(height: 10),
        TextFormField(
          controller: controller,
          style: TextStyle(color: Colors.white),
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
            prefixIcon: maxLines == 1 ? Icon(icon, color: Colors.white70) : null,
            prefixIconConstraints: maxLines == 1
                ? BoxConstraints(minWidth: 45)
                : BoxConstraints(minWidth: 0, minHeight: 0),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 20,
              vertical: maxLines == 1 ? 0 : 15,
            ),
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(color: Colors.white24),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(color: Colors.white),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(color: Colors.red.shade300),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(color: Colors.red.shade300),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }
  
  Widget _buildPositionDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Posición',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white24),
          ),
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: DropdownButtonFormField<String>(
            value: _selectedPosition,
            hint: Text(
              'Selecciona tu posición',
              style: TextStyle(color: Colors.white.withOpacity(0.5)),
            ),
            style: TextStyle(color: Colors.white),
            dropdownColor: Colors.blue.shade800,
            icon: Icon(Icons.arrow_drop_down, color: Colors.white),
            decoration: InputDecoration(
              border: InputBorder.none,
              prefixIcon: Icon(Icons.sports_soccer, color: Colors.white70),
              prefixIconConstraints: BoxConstraints(minWidth: 45),
              contentPadding: EdgeInsets.zero,
            ),
            items: _positions.map((String position) {
              return DropdownMenuItem<String>(
                value: position,
                child: Text(
                  position,
                  style: TextStyle(color: Colors.white),
                ),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedPosition = newValue;
                });
              }
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange.shade600,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 5,
        ),
        child: _isSubmitting
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.save),
                  SizedBox(width: 10),
                  Text(
                    'Guardar Cambios',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
  // Método mejorado para obtener el widget de imagen según la plataforma
  Widget _getProfileImageWidget() {
    // Registrar el estado actual para depuración
    print('Estado actual de imagen:');
    print('- _imageFile: ${_imageFile != null ? "Presente" : "Null"}');
    print('- _imageWebBytes: ${_imageWebBytes != null ? "${_imageWebBytes!.length} bytes" : "Null"}');
    print('- _currentImageUrl: ${_currentImageUrl != null ? _currentImageUrl : "Null"}');
    print('- Plataforma: ${kIsWeb ? "Web" : "Nativa"}');
    
    // Para plataformas nativas, verificar archivo
    if (!kIsWeb && _imageFile != null) {
      print('Mostrando imagen desde archivo: ${_imageFile!.path}');
      return Image.file(
        _imageFile!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('Error al cargar archivo de imagen: $error');
          return _buildDefaultProfileIcon();
        },
      );
    } 
    // Para web, verificar bytes
    else if (kIsWeb && _imageWebBytes != null) {
      print('Mostrando imagen desde bytes en web: ${_imageWebBytes!.length} bytes');
      return Image.memory(
        _imageWebBytes!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('Error al cargar bytes de imagen en web: $error');
          return _buildDefaultProfileIcon();
        },
      );
    } 
    // Si hay URL, mostrarla
    else if (_currentImageUrl != null && _currentImageUrl!.isNotEmpty) {
      print('Mostrando imagen desde URL: $_currentImageUrl');
      return Image.network(
        _currentImageUrl!,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Colors.blue.shade400,
            child: Center(
              child: CircularProgressIndicator(
                color: Colors.white,
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / 
                      loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          print('Error al cargar imagen desde URL: $error');
          return _buildDefaultProfileIcon();
        },
      );
    }
    
    // Fallback a icono por defecto
    print('Mostrando icono por defecto (no hay imagen disponible)');
    return _buildDefaultProfileIcon();
  }
  
  // Widget para mostrar un icono por defecto
  Widget _buildDefaultProfileIcon() {
    return Container(
      color: Colors.blue.shade400,
      child: Icon(
        Icons.person,
        color: Colors.white,
        size: 70,
      ),
    );
  }
}