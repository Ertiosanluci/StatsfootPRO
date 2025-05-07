import 'dart:io';
import 'dart:typed_data'; // Añadido para usar Uint8List
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

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
  
  File? _imageFile;
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
  
  // Seleccionar imagen desde la galería
  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedImage = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      
      if (pickedImage != null) {
        setState(() {
          _imageFile = File(pickedImage.path);
        });
      }
    } catch (e) {
      print('Error al seleccionar imagen: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al seleccionar imagen')),
      );
    }
  }
  
  // Tomar foto con la cámara
  Future<void> _takePhoto() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      
      if (photo != null) {
        setState(() {
          _imageFile = File(photo.path);
        });
      }
    } catch (e) {
      print('Error al tomar foto: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al tomar foto')),
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
                    Navigator.of(context).pop();
                    setState(() {
                      _imageFile = null;
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
  
  // Subir imagen a Supabase Storage
  Future<String?> _uploadImageToStorage() async {
    if (_imageFile == null) return _currentImageUrl;
    
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return null;
      
      final fileExt = path.extension(_imageFile!.path);
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
      }
      
      // Subir la imagen
      print('Subiendo imagen a: $filePath en bucket "images"');
      await Supabase.instance.client.storage
          .from('images') // Usando el bucket "images"
          .upload(filePath, _imageFile!);
      
      // Obtener URL pública de la imagen
      final imageUrlResponse = Supabase.instance.client.storage
          .from('images') // Usando el bucket "images"
          .getPublicUrl(filePath);
      
      print('URL de imagen generada: $imageUrlResponse');
      return imageUrlResponse;
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
  
  // Guardar perfil actualizado
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
      
      // Subir imagen si hay una nueva
      String? avatarUrl = _currentImageUrl;
      if (_imageFile != null) {
        avatarUrl = await _uploadImageToStorage();
        print('Nueva URL de imagen: $avatarUrl');
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
        await Supabase.instance.client
            .from('profiles')
            .update(updatedData)
            .eq('id', user.id);
      } else {
        // Crear nuevo perfil si no existe
        updatedData['id'] = user.id;  // Asegurarse de incluir el ID de usuario
        await Supabase.instance.client
            .from('profiles')
            .insert(updatedData);
      }
      
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
      print('Error al guardar perfil: $e');
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
              child: _imageFile != null
                ? Image.file(
                    _imageFile!,
                    fit: BoxFit.cover,
                  )
                : (_currentImageUrl != null && _currentImageUrl!.isNotEmpty)
                  ? Image.network(
                      _currentImageUrl!,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: Colors.blue.shade400,
                          child: Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 70,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        print("Error cargando imagen: $error");
                        return Container(
                          color: Colors.blue.shade400,
                          child: Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 70,
                          ),
                        );
                      },
                    )
                  : Container(
                      color: Colors.blue.shade400,
                      child: Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 70,
                      ),
                    ),
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
}