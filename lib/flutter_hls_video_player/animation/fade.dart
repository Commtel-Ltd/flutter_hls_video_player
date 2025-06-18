import 'package:flutter/material.dart';

class FadeAnimationWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;
  final bool isVisible; // Flag to control visibility

  const FadeAnimationWidget({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 500),
    this.curve = Curves.easeInOut,
    this.isVisible = true, // Default to visible
  });

  @override
  State<FadeAnimationWidget> createState() => _FadeAnimationWidgetState();
}

class _FadeAnimationWidgetState extends State<FadeAnimationWidget> {
  late bool _isVisible;

  @override
  void initState() {
    super.initState();
    _isVisible = widget.isVisible;
  }

  @override
  void didUpdateWidget(FadeAnimationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isVisible != widget.isVisible) {
      setState(() {
        _isVisible = widget.isVisible;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
        ignoring: !_isVisible,
        child: AnimatedOpacity(
          duration: widget.duration,
          curve: widget.curve,
          opacity: _isVisible ? 1.0 : 0.0,
          child: widget.child,
        ));
  }
}
