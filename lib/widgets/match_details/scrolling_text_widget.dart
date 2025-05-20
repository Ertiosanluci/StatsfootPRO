import 'package:flutter/material.dart';

/// Widget que muestra un texto deslizante (marquesina) con efecto de movimiento de derecha a izquierda
class ScrollingTextWidget extends StatefulWidget {
  final String text;
  final TextStyle? textStyle;
  final Duration duration;
  final VoidCallback? onTap;
  
  const ScrollingTextWidget({
    Key? key,
    required this.text,
    this.textStyle,
    this.duration = const Duration(seconds: 10),
    this.onTap,
  }) : super(key: key);
  
  @override
  _ScrollingTextWidgetState createState() => _ScrollingTextWidgetState();
}

class _ScrollingTextWidgetState extends State<ScrollingTextWidget> with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _animationController;
  
  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _animationController = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startScrollingAnimation();
    });
  }
  
  void _startScrollingAnimation() {
    // Si no hay suficiente contenido para deslizar, no hacer nada
    if (!_scrollController.hasClients || 
        _scrollController.position.maxScrollExtent <= 0) {
      return;
    }
    
    _animationController.forward().then((_) {
      _animationController.reset();
      _scrollController.jumpTo(0);
      _startScrollingAnimation();
    });
    
    _animationController.addListener(() {
      if (_scrollController.hasClients) {
        final maxExtent = _scrollController.position.maxScrollExtent;
        final currentValue = _animationController.value;
        _scrollController.jumpTo(maxExtent * currentValue);
      }
    });
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onTap,
      child: Container(
        height: 22,
        decoration: BoxDecoration(
          color: Colors.amber.shade700,
        ),
        width: double.infinity,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          controller: _scrollController,
          physics: NeverScrollableScrollPhysics(),
          child: Row(
            children: [
              // Espacio inicial para que el texto comience fuera de la vista
              SizedBox(width: MediaQuery.of(context).size.width),
              // El texto que se deslizará
              Text(
                widget.text,
                style: widget.textStyle ?? const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              // Espacio para asegurar que el texto desaparezca completamente
              SizedBox(width: MediaQuery.of(context).size.width),
            ],
          ),
        ),
      ),
    );
  }
}
