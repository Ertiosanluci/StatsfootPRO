import 'package:flutter/material.dart';
import 'dart:async';

/// Widget para mostrar el estado de la votación de MVP en curso
class VotingStatusWidget extends StatefulWidget {
  final Map<String, dynamic> votingData;
  final VoidCallback onVoteButtonPressed;
  
  const VotingStatusWidget({
    Key? key,
    required this.votingData,
    required this.onVoteButtonPressed,
  }) : super(key: key);
  
  @override
  _VotingStatusWidgetState createState() => _VotingStatusWidgetState();
}

class _VotingStatusWidgetState extends State<VotingStatusWidget> {
  late DateTime _endTime;
  Duration _timeRemaining = Duration.zero;
  late Timer _timer;
  
  @override
  void initState() {
    super.initState();
    _endTime = DateTime.parse(widget.votingData['voting_ends_at']);
    _updateTimeRemaining();
    _timer = Timer.periodic(Duration(seconds: 1), (_) => _updateTimeRemaining());
  }
  
  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }
  
  void _updateTimeRemaining() {
    final now = DateTime.now();
    if (_endTime.isAfter(now)) {
      setState(() {
        _timeRemaining = _endTime.difference(now);
      });
    } else {
      setState(() {
        _timeRemaining = Duration.zero;
      });
      _timer.cancel();
    }
  }
  
  String _formatTimeRemaining() {
    if (_timeRemaining.inSeconds <= 0) {
      return "¡Votación finalizada!";
    }
    
    final hours = _timeRemaining.inHours;
    final minutes = _timeRemaining.inMinutes % 60;
    final seconds = _timeRemaining.inSeconds % 60;
    
    return "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade800, Colors.indigo.shade900],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.how_to_vote,
            color: Colors.amber,
            size: 18,
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Votación de MVPs en curso",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              Text(
                _formatTimeRemaining(),
                style: TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: _timeRemaining.inSeconds > 0 ? widget.onVoteButtonPressed : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
              minimumSize: const Size(40, 28),
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: const Text(
              "Votar",
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
