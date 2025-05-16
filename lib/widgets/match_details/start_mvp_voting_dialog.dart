import 'package:flutter/material.dart';

/// Widget de diálogo para iniciar la votación de MVPs
class StartMVPVotingDialog extends StatefulWidget {
  final Function(int hours) onConfirm;
  final Function() onCancel;
  
  const StartMVPVotingDialog({
    Key? key,
    required this.onConfirm,
    required this.onCancel,
  }) : super(key: key);
  
  @override
  _StartMVPVotingDialogState createState() => _StartMVPVotingDialogState();
}

class _StartMVPVotingDialogState extends State<StartMVPVotingDialog> {
  int _votingDuration = 24; // Duración predeterminada: 24 horas
    @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.blue.shade800,
      insetPadding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [            // Encabezado
            Row(
              children: [
                Icon(Icons.how_to_vote, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: const Text(
                    'Iniciar Votación para MVPs',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
              // Explicación
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              width: double.infinity,
              child: const Text(
                'Al iniciar la votación, todos los participantes podrán votar por los MVP de cada equipo. '
                'La votación finalizará automáticamente al terminar el tiempo establecido.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                ),
                softWrap: true,
              ),
            ),
            
            const SizedBox(height: 24),
              // Selector de duración
            Row(
              children: [
                const Icon(Icons.timer_outlined, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Flexible(
                  child: const Text(
                    'Duración:',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _buildDurationSelector(),
                const SizedBox(width: 8),
                const Text(
                  'horas',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 30),
              // Botones de acción
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: widget.onCancel,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white70,
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('Iniciar', style: TextStyle(fontSize: 14)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: () => widget.onConfirm(_votingDuration),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
    Widget _buildDurationSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      width: 60,
      height: 36,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          dropdownColor: Colors.blue.shade900,
          value: _votingDuration,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white, size: 20),
          iconSize: 20,
          isDense: true,
          items: [
            DropdownMenuItem(value: 1, child: Text('1')),
            DropdownMenuItem(value: 6, child: Text('6')),
            DropdownMenuItem(value: 12, child: Text('12')),
            DropdownMenuItem(value: 24, child: Text('24')),
            DropdownMenuItem(value: 48, child: Text('48')),
            DropdownMenuItem(value: 72, child: Text('72')),
          ],
          onChanged: (value) {
            setState(() {
              if (value != null) _votingDuration = value;
            });
          },
          alignment: AlignmentDirectional.center,
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
      ),
    );
  }
}
