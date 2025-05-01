import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'dart:ui' as ui;

class CreateMatchScreen extends StatefulWidget {
  @override
  _CreateMatchScreenState createState() => _CreateMatchScreenState();
}

class _CreateMatchScreenState extends State<CreateMatchScreen> with SingleTickerProviderStateMixin {
  final SupabaseClient supabase = Supabase.instance.client;
  String _selectedFormat = '';
  final TextEditingController _matchNameController = TextEditingController();
  late TabController _tabController;
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Mostrar instrucciones como toast al iniciar la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showInstructionsToast();
    });
  }
  
  @override
  void dispose() {
    _matchNameController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // Función para mostrar el toast con instrucciones
  void _showInstructionsToast() {
    Fluttertoast.showToast(
      msg: "Crea un partido y comparte el enlace para que otros jugadores se unan.",
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 4,
      backgroundColor: Colors.black.withOpacity(0.7),
      textColor: Colors.white,
      fontSize: 16.0
    );
  }

  // Método para continuar a la siguiente pantalla con los datos del partido
  void _continueToNextScreen() {
    final String matchName = _matchNameController.text.trim().isNotEmpty 
      ? _matchNameController.text.trim() 
      : 'Partido ${_selectedFormat}';
      
    if (_selectedFormat.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Selecciona un formato para el partido'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    // Crear mapa con la información del partido para pasar a la siguiente pantalla
    final Map<String, dynamic> matchData = {
      'nombre': matchName,
      'formato': _selectedFormat,
    };
    
    // Navegar a la siguiente pantalla para configurar fecha y hora
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MatchDetailsScreen(matchData: matchData),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Crear Partido'),
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
        backgroundColor: const Color(0xFF1A237E), // Azul más oscuro y profesional
        elevation: 0, // Eliminar la sombra para un estilo más moderno
        leading: BackButton(color: Colors.white), // Flecha de navegación blanca
        actions: [
          Container(
            margin: EdgeInsets.only(right: 12),
            child: IconButton(
              icon: Icon(Icons.arrow_forward),
              onPressed: _continueToNextScreen,
              tooltip: 'Continuar',
              style: IconButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          // Gradiente sutil y profesional
          gradient: LinearGradient(
            colors: [
              const Color(0xFF1A237E),
              const Color(0xFF283593),
              const Color(0xFF3949AB),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            // Panel de configuración del partido
            _buildConfigurationPanel(),

            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildInfoCard(),
                        SizedBox(height: 30),
                        Image.asset(
                          'assets/habilidades.png',
                          width: 150,
                          height: 150,
                          fit: BoxFit.contain,
                        ),
                        SizedBox(height: 30),
                        Text(
                          'Crea tu partido y comparte el enlace',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 15),
                        Container(
                          width: 300,
                          child: Text(
                            'Los jugadores podrán unirse al partido a través del enlace que compartirás después de crear el partido.',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoCard() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.info_outline,
              size: 40,
              color: Colors.blue.shade700,
            ),
            SizedBox(height: 12),
            Text(
              'Nuevo Sistema de Partidos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'Ahora puedes organizar partidos y los jugadores se unirán mediante un enlace que compartirás.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 16),
                SizedBox(width: 8),
                Text(
                  'Gestión más sencilla',
                  style: TextStyle(color: Colors.grey.shade800),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 16),
                SizedBox(width: 8),
                Text(
                  'Enlaces compartibles',
                  style: TextStyle(color: Colors.grey.shade800),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 16),
                SizedBox(width: 8),
                Text(
                  'Mejor organización de equipos',
                  style: TextStyle(color: Colors.grey.shade800),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  // Panel de configuración rediseñado con estilo más profesional
  Widget _buildConfigurationPanel() {
    return Container(
      margin: EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Dropdown para seleccionar formato
            Expanded(
              flex: 2,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedFormat.isEmpty ? null : _selectedFormat,
                    hint: Text(
                      'Formato',
                      style: TextStyle(
                        color: const Color(0xFF1A237E).withOpacity(0.8),
                      ),
                    ),
                    icon: Icon(Icons.keyboard_arrow_down, color: const Color(0xFF1A237E)),
                    isExpanded: true,
                    items: ['5v5', '6v6', '7v7', '8v8', '9v9', '10v10', '11v11'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          value, 
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1A237E),
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _selectedFormat = newValue!;
                      });
                    },
                  ),
                ),
              ),
            ),
            
            SizedBox(width: 16),
            
            // TextField para nombre del partido a la derecha
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _matchNameController,
                  style: TextStyle(
                    color: const Color(0xFF1A237E),
                  ),
                  decoration: InputDecoration(
                    labelText: 'Nombre del partido',
                    labelStyle: TextStyle(
                      color: const Color(0xFF1A237E).withOpacity(0.8),
                    ),
                    hintText: 'Ej: Liga Barrial - J3',
                    border: InputBorder.none,
                    prefixIcon: Icon(Icons.sports_soccer, color: const Color(0xFF283593)),
                    contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Clase para la pantalla de detalles del partido (fecha y hora)
class MatchDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> matchData;
  
  const MatchDetailsScreen({Key? key, required this.matchData}) : super(key: key);
  
  @override
  _MatchDetailsScreenState createState() => _MatchDetailsScreenState();
}

class _MatchDetailsScreenState extends State<MatchDetailsScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  // Variables for date and time
  late TimeOfDay _selectedTime;
  late DateTime _selectedDate;
  String? _matchLink;
  bool _isLoading = false;
  bool _matchCreated = false;
  int? _matchId;
  
  @override
  void initState() {
    super.initState();
    _selectedTime = TimeOfDay.now();
    _selectedDate = DateTime.now();
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

  // Genera un enlace único para compartir
  String _generateMatchLink(int matchId) {
    // Usar el mismo formato de enlace web compatible que en match_list.dart
    final String shareableLink = "https://statsfoot.netlify.app/match/$matchId";
    return shareableLink;
  }
  
  Future<void> _saveMatch() async {
    if (_isLoading) return;
    
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

      final DateTime matchDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      // Get current user
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('Usuario no autenticado');
      }

      // Crear partido pendiente en Supabase con campos según la estructura de la tabla
      final matchResponse = await supabase.from('matches').insert({
        'creador_id': currentUser.id,
        'nombre': widget.matchData['nombre'],
        'formato': widget.matchData['formato'],
        'fecha': matchDateTime.toIso8601String(),
        'estado': 'pendiente',
        'created_at': DateTime.now().toIso8601String(),
      }).select();

      // Obtener el ID del partido recién creado
      final int matchId = matchResponse[0]['id'];
      _matchId = matchId;

      // Generar y guardar enlace único para compartir
      final String matchLink = _generateMatchLink(matchId);
      
      await supabase.from('matches').update({
        'enlace': matchLink
      }).eq('id', matchId);
      
      // Registrar al creador como organizador en match_participants
      try {
        if (matchId != null && currentUser.id != null) {
          print('Intentando registrar organizador: matchId=$matchId, userId=${currentUser.id}');
          
          // Corrección: usar el nombre exacto de la tabla: match_participants (plural)
          final participantData = {
            'match_id': matchId,
            'user_id': currentUser.id,
            'equipo': null,
            'es_organizador': true,
            'joined_at': DateTime.now().toIso8601String(),
          };
          
          // Inserción directa en la tabla match_participants (nombre correcto)
          final result = await supabase.from('match_participants').insert(participantData);
          
          print('Resultado de registrar organizador: $result');
        }
      } catch (participantError) {
        print('Error al registrar organizador: $participantError');
        print('Detalles del error: ${participantError.toString()}');
        
        // El partido se creó correctamente, por lo que continuamos
        print('Continuando a pesar del error en match_participants');
      }
      
      setState(() {
        _matchLink = matchLink;
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
      // Formatear fecha y hora del partido para el mensaje
      final String formattedDate = '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}';
      final String formattedTime = '${_selectedTime.format(context)}';
      
      // Crear un mensaje más atractivo para compartir
      final String message = """
🏆 ¡Únete a mi partido de fútbol! 🏆

Partido: ${widget.matchData['nombre']}
Formato: ${widget.matchData['formato']}
Fecha: $formattedDate
Hora: $formattedTime

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
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_matchCreated ? 'Partido Creado' : 'Detalles del Partido'),
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        backgroundColor: Colors.blue.shade800,
        actions: [
          if (!_matchCreated)
            IconButton(
              icon: Icon(Icons.save, color: Colors.white),
              onPressed: _saveMatch,
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade300, Colors.blue.shade800],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _matchCreated 
            ? _buildMatchCreatedContent() 
            : _buildMatchDetailsContent(),
      ),
    );
  }
  
  Widget _buildMatchCreatedContent() {
    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              // Icono de éxito
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.check_circle_outline,
                  size: 80,
                  color: Colors.green.shade700,
                ),
              ),
              
              SizedBox(height: 30),
              
              // Información del partido
              Text(
                '¡Partido creado con éxito!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              
              SizedBox(height: 20),
              
              // Información del partido
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.sports_soccer,
                            color: Colors.blue.shade800,
                            size: 28,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Información del Partido',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade800,
                            ),
                          ),
                        ],
                      ),
                      Divider(),
                      ListTile(
                        leading: Icon(Icons.sports_soccer, color: Colors.orange.shade600),
                        title: Text('Nombre'),
                        subtitle: Text(
                          widget.matchData['nombre'],
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      ListTile(
                        leading: Icon(Icons.people, color: Colors.orange.shade600),
                        title: Text('Formato'),
                        subtitle: Text(
                          widget.matchData['formato'],
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      ListTile(
                        leading: Icon(Icons.calendar_today, color: Colors.blue),
                        title: Text('Fecha'),
                        subtitle: Text(
                          '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      ListTile(
                        leading: Icon(Icons.access_time, color: Colors.red),
                        title: Text('Hora'),
                        subtitle: Text(
                          _selectedTime.format(context),
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 30),
              
              // Enlace del partido
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.link,
                            color: Colors.blue.shade800,
                            size: 28,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Enlace del Partido',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade800,
                            ),
                          ),
                        ],
                      ),
                      Divider(),
                      Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _matchLink ?? 'No disponible',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.copy, color: Colors.blue.shade700),
                              onPressed: _copyMatchLink,
                              tooltip: 'Copiar enlace',
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _shareMatchLink,
                        icon: Icon(Icons.share),
                        label: Text('Compartir Enlace'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 30),
              
              // Botones finales
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/match_list');
                    },
                    icon: Icon(Icons.list),
                    label: Text('Ver Mis Partidos'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.popUntil(context, (route) => route.isFirst);
                    },
                    icon: Icon(Icons.home),
                    label: Text('Inicio'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade900,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildMatchDetailsContent() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Información del partido
          Padding(
            padding: EdgeInsets.all(16),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Información del Partido',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                    Divider(),
                    ListTile(
                      leading: Icon(Icons.sports_soccer, color: Colors.orange.shade600),
                      title: Text('Nombre'),
                      subtitle: Text(
                        widget.matchData['nombre'],
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    ListTile(
                      leading: Icon(Icons.people, color: Colors.orange.shade600),
                      title: Text('Formato'),
                      subtitle: Text(
                        widget.matchData['formato'],
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Selección de fecha y hora
          Padding(
            padding: EdgeInsets.all(16),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fecha y Hora del Partido',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                    Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: Icon(Icons.calendar_today),
                            label: Text(
                              '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                              style: TextStyle(color: Colors.white),
                            ),
                            onPressed: () => _selectDate(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade700,
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: Icon(Icons.access_time),
                            label: Text(
                              _selectedTime.format(context),
                              style: TextStyle(color: Colors.white),
                            ),
                            onPressed: () => _selectTime(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange.shade600,
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Información del partido
          Padding(
            padding: EdgeInsets.all(16),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700),
                        SizedBox(width: 8),
                        Text(
                          'Información Adicional',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                          ),
                        ),
                      ],
                    ),
                    Divider(),
                    Text(
                      'Al crear el partido:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Se generará un enlace para compartir',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Los jugadores podrán unirse usando el enlace',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Podrás gestionar los equipos una vez que los jugadores se hayan unido',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Las estadísticas se registrarán automáticamente',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Botón para guardar
          Padding(
            padding: EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveMatch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
                child: _isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.save),
                        SizedBox(width: 10),
                        Text(
                          'CREAR PARTIDO',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
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