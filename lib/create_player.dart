import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

class PlayerCreatorScreen extends StatefulWidget {
  @override
  _PlayerCreatorScreenState createState() => _PlayerCreatorScreenState();
}

class _PlayerCreatorScreenState extends State<PlayerCreatorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  int _rating = 5;
  int _media = 50;
  final Map<String, double> _stats = {
    'Tiro': 50,
    'Regate': 50,
    'Técnica': 50,
    'Defensa': 50,
    'Velocidad': 50,
    'Aguante': 50,
    'Control': 50,
  };
  String _position = 'Delantero';
  File? _profilePhoto;
  bool _isSaving = false;
  PlatformFile? _webFile;
  // Método para seleccionar una foto de perfil
  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null) {
        setState(() {
          _webFile = result.files.first;
          if (!kIsWeb) {
            _profilePhoto = File(result.files.first.path!);
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al seleccionar imagen: $e')),
      );
    }
  }

  // Método para subir la foto a Supabase Storage
  Future<String?> _uploadPhoto(String playerName) async {
    final String? user = Supabase.instance.client.auth.currentUser?.id;
    try {
      final fileName = '$user/${DateTime.now().millisecondsSinceEpoch}_$playerName.jpg';

      if (kIsWeb && _webFile != null) {
        // For web
        await Supabase.instance.client.storage
            .from('images')
            .uploadBinary(fileName, _webFile!.bytes!);
      } else if (_profilePhoto != null) {
        // For mobile
        await Supabase.instance.client.storage
            .from('images')
            .upload(fileName, _profilePhoto!);
      } else {
        return null;
      }

      final publicUrl = Supabase.instance.client.storage
          .from('images/')
          .getPublicUrl(fileName);
      return publicUrl;
    } catch (e) {
      print('Error al subir la foto: $e');
      return null;
    }
  }

  void _calcularMedia() {
    double calcularMedia = 0;
    _stats.forEach((key, value) {
      calcularMedia += value;
    });
    setState(() {
      _media = (calcularMedia / _stats.length).round();
    });
  }

  // Método para guardar el jugador en Supabase
  Future<void> _savePlayer() async {
    if (_isSaving) return; // Evitar múltiples envíos

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSaving = true;
      });

      // Mostrar indicador de carga
      _showLoadingDialog();

      try {
        final String? user = Supabase.instance.client.auth.currentUser?.id;

        String? photoUrl;
        if (_profilePhoto != null || _webFile != null) {
          photoUrl = await _uploadPhoto(_nameController.text);
        }

        final playerData = {
          'nombre': _nameController.text,
          'calificacion': _rating,
          'tiro': _stats['Tiro']!.round(),
          'regate': _stats['Regate']!.round(),
          'tecnica': _stats['Técnica']!.round(),
          'defensa': _stats['Defensa']!.round(),
          'velocidad': _stats['Velocidad']!.round(),
          'aguante': _stats['Aguante']!.round(),
          'control': _stats['Control']!.round(),
          'media': _media,
          'posicion': _position,
          'foto_perfil': photoUrl,
          'user_id': user
        };

        await Supabase.instance.client.from('jugadores').insert([playerData]);

        // Cerrar diálogo de carga
        Navigator.pop(context);

        // Mostrar mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 10),
                Text('¡Jugador creado exitosamente!'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Redirigir a la pantalla anterior después de un breve retraso
        Future.delayed(Duration(seconds: 1), () {
          Navigator.pop(context);
        });
      } catch (e) {
        // Cerrar diálogo de carga
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 10),
                Expanded(child: Text('Error: ${e.toString()}')),
              ],
            ),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Colors.orange.shade600),
              SizedBox(height: 16),
              Text(
                'Creando jugador...',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Método para obtener el color para la media del jugador
  Color _getMediaColor(int value) {
    if (value >= 85) return Colors.green.shade700;
    if (value >= 70) return Colors.green;
    if (value >= 60) return Colors.lime;
    if (value >= 50) return Colors.amber;
    if (value >= 40) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Creador de Jugadores",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.blue.shade800,
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade300, Colors.blue.shade800],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Foto de perfil
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          height: 120,
                          width: 120,
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: _webFile != null
                              ? ClipRRect(
                            borderRadius: BorderRadius.circular(60),
                            child: kIsWeb
                                ? Image.memory(
                              _webFile!.bytes!,
                              fit: BoxFit.cover,
                            )
                                : Image.file(
                              _profilePhoto!,
                              fit: BoxFit.cover,
                            ),
                          )
                              : Icon(
                            Icons.person,
                            size: 60,
                            color: Colors.white70,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            height: 40,
                            width: 40,
                            decoration: BoxDecoration(
                              color: Colors.orange.shade600,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                              onPressed: _pickImage,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),

                  // Nombre del jugador
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    color: Colors.white.withOpacity(0.15),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Información Básica',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 12),
                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: 'Nombre del Jugador',
                              labelStyle: TextStyle(color: Colors.white70),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.white70),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.white),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              prefixIcon: Icon(Icons.person, color: Colors.white70),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.1),
                            ),
                            style: TextStyle(color: Colors.white),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor, ingresa un nombre';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(Icons.place, color: Colors.white70),
                              SizedBox(width: 8),
                              Text(
                                'Posición:',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.white70),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _position,
                                      dropdownColor: Colors.blue.shade700,
                                      style: TextStyle(color: Colors.white),
                                      isExpanded: true,
                                      icon: Icon(Icons.arrow_drop_down, color: Colors.white70),
                                      onChanged: (value) {
                                        setState(() {
                                          _position = value!;
                                        });
                                      },
                                      items: [
                                        'Delantero',
                                        'Mediocampista',
                                        'Defensa',
                                        'Portero',
                                      ].map((position) {
                                        return DropdownMenuItem(
                                          value: position,
                                          child: Text(position),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(Icons.star, color: Colors.white70),
                              SizedBox(width: 8),
                              Text(
                                'Calificación: $_rating',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          Slider(
                            value: _rating.toDouble(),
                            min: 1,
                            max: 10,
                            divisions: 9,
                            label: _rating.toString(),
                            onChanged: (value) {
                              setState(() {
                                _rating = value.round();
                              });
                            },
                            activeColor: Colors.orange.shade600,
                            inactiveColor: Colors.white38,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),

                  // Media del jugador
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    color: Colors.white.withOpacity(0.15),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _getMediaColor(_media),
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: Center(
                                  child: Text(
                                    '$_media',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'MEDIA',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  Text(
                                    _getMediaDescription(_media),
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: _media / 100,
                              minHeight: 10,
                              backgroundColor: Colors.white24,
                              valueColor: AlwaysStoppedAnimation<Color>(_getMediaColor(_media)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),

                  // Estadísticas del jugador
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    color: Colors.white.withOpacity(0.15),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.assessment, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                'Estadísticas',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          ..._stats.keys.map((stat) {
                            Color statColor = _getStatColor(_stats[stat]!.round());
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      stat,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Container(
                                      width: 40,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: statColor,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${_stats[stat]!.round()}',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SliderTheme(
                                  data: SliderThemeData(
                                    trackHeight: 4,
                                    thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
                                    overlayShape: RoundSliderOverlayShape(overlayRadius: 14),
                                  ),
                                  child: Slider(
                                    value: _stats[stat]!,
                                    min: 0,
                                    max: 100,
                                    onChanged: (value) {
                                      setState(() {
                                        _stats[stat] = value;
                                        _calcularMedia();
                                      });
                                    },
                                    activeColor: statColor,
                                    inactiveColor: Colors.white24,
                                  ),
                                ),
                                SizedBox(height: 4),
                              ],
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 24),

                  // Botón para guardar
                  ElevatedButton(
                    onPressed: _isSaving ? null : _savePlayer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 2,
                      disabledBackgroundColor: Colors.grey,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.save),
                        SizedBox(width: 8),
                        Text(
                          'GUARDAR JUGADOR',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getMediaDescription(int value) {
    if (value >= 85) return "Excepcional";
    if (value >= 75) return "Excelente";
    if (value >= 65) return "Muy bueno";
    if (value >= 55) return "Bueno";
    if (value >= 45) return "Promedio";
    if (value >= 35) return "Regular";
    return "Principiante";
  }

  Color _getStatColor(int value) {
    if (value >= 90) return Colors.green.shade800;
    if (value >= 80) return Colors.green.shade600;
    if (value >= 70) return Colors.green;
    if (value >= 60) return Colors.lime;
    if (value >= 50) return Colors.amber;
    if (value >= 40) return Colors.orange;
    if (value >= 30) return Colors.deepOrange;
    return Colors.red;
  }
}