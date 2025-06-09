import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'package:statsfoota/user_menu.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dart:math';
import 'dart:ui' as ui;

class CreateMatchScreen extends StatefulWidget {
  @override
  _CreateMatchScreenState createState() => _CreateMatchScreenState();
}

class _CreateMatchScreenState extends State<CreateMatchScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  String _selectedFormat = '';
  bool _isPublic = false;
  final TextEditingController _matchNameController = TextEditingController();
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  bool _isLoading = false;
  bool _matchCreated = false;
  String? _matchLink;
  int? _matchId;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _selectedTime = TimeOfDay.now();
    
    // Inicializar localización para español
    initializeDateFormatting('es_ES', null).then((_) {
      Intl.defaultLocale = 'es_ES';
    });
  }

  @override
  void dispose() {
    _matchNameController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.orange.shade600,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.orange.shade600,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // Generar un enlace único para el partido
  String _generateMatchLink(int matchId) {
    return "https://statsfootpro.netlify.app/match/$matchId";
  }

  Future<void> _saveMatch() async {
    if (_selectedFormat.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Selecciona un formato para el partido'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_matchNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ingresa un nombre para el partido'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(
            color: Colors.orange.shade600,
          ),
        ),
      );

      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) {
        Navigator.pop(context); // Cerrar diálogo
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Debes iniciar sesión para crear un partido'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Crear el objeto DateTime combinado
      final DateTime matchDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      // Insertar el partido en la base de datos
      final matchResponse = await supabase.from('matches').insert({
        'creador_id': currentUser.id,
        'nombre': _matchNameController.text.trim(),
        'formato': _selectedFormat,
        'fecha': matchDateTime.toIso8601String(),
        'estado': 'pendiente',
        'created_at': DateTime.now().toIso8601String(),
        'publico': _isPublic,
      }).select();

      // Obtener el ID del partido recién creado
      final int matchId = matchResponse[0]['id'];
      _matchId = matchId;

      // Generar y guardar enlace único para compartir
      final String matchLink = _generateMatchLink(matchId);
      _matchLink = matchLink;
      
      await supabase.from('matches').update({
        'enlace': matchLink
      }).eq('id', matchId);
      
      // Registrar al creador como organizador en match_participants
      try {
        print('Intentando registrar organizador: matchId=$matchId, userId=${currentUser.id}');
        
        await supabase.from('match_participants').insert({
          'match_id': matchId,
          'user_id': currentUser.id,
          'equipo': null,
          'es_organizador': true,
          'joined_at': DateTime.now().toIso8601String(),
        });
        
        print('Organizador registrado correctamente');
      } catch (e) {
        print('Error al registrar organizador: $e');
      }

      setState(() {
        _matchCreated = true;
        _isLoading = false;
      });

      // Cerrar el indicador de carga
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Partido creado correctamente'),
          backgroundColor: Colors.green,
        ),
      );
      
    } catch (e) {
      // Cerrar el indicador de carga si hay error
      Navigator.pop(context);
      
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar el partido: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _shareMatchLink() {
    if (_matchLink != null) {
      // Formatear fecha y hora del partido
      final String formattedDate = DateFormat('EEEE d/M/yyyy', 'es_ES').format(_selectedDate);
      final String formattedTime = '${_selectedTime.format(context)}';
      
      // Crear mensaje para compartir
      final String message = """
🏆 ¡Únete a mi partido de fútbol! 🏆

📅 Fecha: $formattedDate
⏰ Hora: $formattedTime
👥 Formato: $_selectedFormat
${_isPublic ? '🌐 Partido Público' : '🔒 Partido Privado'}

Únete usando este enlace: $_matchLink

¡Te esperamos!
      """;

      Share.share(
        message,
        subject: 'Invitación a partido de fútbol',
      );
    }
  }

  void _copyMatchLink() {
    if (_matchLink != null) {
      Clipboard.setData(ClipboardData(text: _matchLink!));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Enlace copiado al portapapeles'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Usar un color de fondo azul para evitar franjas blancas
      backgroundColor: Colors.blue.shade200,
      // El body ahora está dentro de un SafeArea y Container con decoración
      body: SafeArea(
        child: Container(
          // Asegurar que el contenedor ocupe toda la pantalla
          height: double.infinity,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade100, Colors.blue.shade200],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          // Envolver el contenido en un SingleChildScrollView para evitar desbordamientos
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            child: _matchCreated ? _buildMatchCreatedContent() : _buildCreateMatchContent(),
          ),
        ),
      ),
    );
  }
  
  Widget _buildCreateMatchContent() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildInfoCard(),
          SizedBox(height: 16),
          _buildDateTimeCard(),
          SizedBox(height: 24),
          _buildCreateButton(),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: Colors.blue.shade800,
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.sports_soccer, color: Colors.white, size: 24),
                SizedBox(width: 12),
                Text(
                  'Información del Partido',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            Divider(thickness: 1, height: 24, color: Colors.white.withOpacity(0.5)),
            _buildTextField(
              controller: _matchNameController,
              label: 'Nombre del partido',
              hint: 'Ej: Liga Barrial - J3',
              icon: Icons.title,
            ),
            SizedBox(height: 20),
            _buildFormatDropdown(),
            SizedBox(height: 16),
            _buildVisibilitySwitch(),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      style: TextStyle(fontSize: 16, color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.9)),
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
        prefixIcon: Icon(icon, color: Colors.white),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white, width: 2),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
      ),
    );
  }

  Widget _buildFormatDropdown() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedFormat.isEmpty ? null : _selectedFormat,
        hint: Text(
          'Selecciona el formato',
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
        items: ['5v5', '6v6', '7v7', '8v8', '9v9', '10v10', '11v11']
            .map((format) => DropdownMenuItem(
                  value: format,
                  child: Text(
                    format,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ))
            .toList(),
        onChanged: (value) {
          setState(() {
            _selectedFormat = value ?? '';
          });
        },
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.people, color: Colors.white),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          alignLabelWithHint: true,
        ),
        dropdownColor: Colors.blue.shade800,
        icon: Icon(Icons.arrow_drop_down, color: Colors.white),
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
        ),
        isExpanded: true,
      ),
    );
  }

  Widget _buildVisibilitySwitch() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.shade100,
      ),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(
            _isPublic ? Icons.public : Icons.lock,
            color: _isPublic ? Colors.green : Colors.orange,
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Visibilidad del Partido',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _isPublic ? 'Visible para todos' : 'Solo por invitación',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isPublic,
            onChanged: (value) {
              setState(() {
                _isPublic = value;
              });
            },
            activeColor: Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeCard() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: Colors.blue.shade800,
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.event, color: Colors.white, size: 24),
                SizedBox(width: 12),
                Text(
                  'Fecha y Hora',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            Divider(thickness: 1, height: 24, color: Colors.white.withOpacity(0.5)),
            _buildDateTimeTile(
              icon: Icons.calendar_today,
              title: 'Fecha',
              subtitle: DateFormat('EEEE, d MMM yyyy', 'es_ES').format(_selectedDate),
              onTap: () => _selectDate(context),
            ),
            Divider(height: 1, color: Colors.white.withOpacity(0.2)),
            _buildDateTimeTile(
              icon: Icons.access_time,
              title: 'Hora',
              subtitle: _selectedTime.format(context),
              onTap: () => _selectTime(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.white),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
          color: Colors.white,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.white.withOpacity(0.9),
          fontSize: 15,
        ),
      ),
      onTap: onTap,
      trailing: Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.7)),
    );
  }

  Widget _buildCreateButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _saveMatch,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green.shade600,
        padding: EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 4,
      ),
      child: _isLoading
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  'CREANDO PARTIDO...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            )
          : Text(
              'CREAR PARTIDO',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
    );
  }

  Widget _buildMatchCreatedContent() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            color: Colors.blue.shade800,
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: Colors.white,
                  ),
                  SizedBox(height: 16),
                  Text(
                    '¡Partido creado con éxito!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Divider(height: 32, color: Colors.white.withOpacity(0.5)),
                  ListTile(
                    leading: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.sports_soccer, color: Colors.white),
                    ),
                    title: Text('Nombre',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    subtitle: Text(_matchNameController.text,
                      style: TextStyle(color: Colors.white.withOpacity(0.9))),
                  ),
                  ListTile(
                    leading: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.people, color: Colors.white),
                    ),
                    title: Text('Formato',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    subtitle: Text(_selectedFormat,
                      style: TextStyle(color: Colors.white.withOpacity(0.9))),
                  ),
                  ListTile(
                    leading: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.calendar_today, color: Colors.white),
                    ),
                    title: Text('Fecha',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      DateFormat('EEEE, d MMM yyyy', 'es_ES').format(_selectedDate),
                      style: TextStyle(color: Colors.white.withOpacity(0.9)),
                    ),
                  ),
                  ListTile(
                    leading: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.access_time, color: Colors.white),
                    ),
                    title: Text('Hora',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    subtitle: Text(_selectedTime.format(context),
                      style: TextStyle(color: Colors.white.withOpacity(0.9))),
                  ),
                  ListTile(
                    leading: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(_isPublic ? Icons.public : Icons.lock,
                        color: Colors.white),
                    ),
                    title: Text('Visibilidad',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    subtitle: Text(_isPublic ? 'Público' : 'Privado',
                      style: TextStyle(color: Colors.white.withOpacity(0.9))),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
          Card(
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            color: Colors.blue.shade800,
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Compartir Partido',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Divider(color: Colors.white.withOpacity(0.5)),
                  if (_matchLink != null) ...[
                    Container(
                      margin: EdgeInsets.symmetric(vertical: 12),
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _matchLink!,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.copy, color: Colors.white),
                            onPressed: _copyMatchLink,
                            tooltip: 'Copiar enlace',
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _shareMatchLink,
                      icon: Icon(Icons.share),
                      label: Text('Compartir Partido'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.blue.shade800,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                        minimumSize: Size(double.infinity, 48),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),          SizedBox(height: 16),
          Card(
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            color: Colors.blue.shade800,
            child: InkWell(
              onTap: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UserMenuScreen(initialTabIndex: 1),
                  ),
                  (route) => false,
                );
              },
              borderRadius: BorderRadius.circular(15),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.list, color: Colors.white),
                    SizedBox(width: 12),
                    Text(
                      'Ver Mis Partidos',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Painter para el efecto de reflejo del campo
class GlassPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, 0),
        Offset(size.width, size.height / 3),
        [
          Colors.white.withOpacity(0.05),
          Colors.white.withOpacity(0.01),
        ],
      );
    
    // Crear un suave reflejo en la parte superior
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height / 3),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}