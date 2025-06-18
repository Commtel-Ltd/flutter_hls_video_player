import 'package:flutter/material.dart';

class SeekArrowAnimation extends StatefulWidget {
  final bool isLeft;
  const SeekArrowAnimation({
    super.key,
    required this.isLeft,
  });

  @override
  State<SeekArrowAnimation> createState() => _SeekArrowAnimationState();
}

class _SeekArrowAnimationState extends State<SeekArrowAnimation> {
  final ValueNotifier<List<bool>?> _visibleArrows =
      ValueNotifier([false, false, false]);

  @override
  void initState() {
    _startAnimation(isLeft: widget.isLeft);
    super.initState();
  }

  Future<void> _startAnimation({bool isLeft = false}) async {
    _visibleArrows.value = [false, false, false]; // Reset before starting

    for (int i = 0; i < (_visibleArrows.value ?? []).length; i++) {
      await Future.delayed(const Duration(milliseconds: 300));

      if (isLeft == false) {
        if (i == 0) {
          _visibleArrows.value = [true, false, false];
        }
        if (i == 1) {
          _visibleArrows.value = [false, true, false];
        }
        if (i == 2) {
          _visibleArrows.value = [false, false, true];
        }
      } else {
        if (i == 0) {
          _visibleArrows.value = [false, false, true];
        }
        if (i == 1) {
          _visibleArrows.value = [false, true, false];
        }
        if (i == 2) {
          _visibleArrows.value = [true, false, false];
        }
      }
    }

    await Future.delayed(const Duration(milliseconds: 200));
    _visibleArrows.value = [false, false, false]; // Hide after animation
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<bool>?>(
      valueListenable: _visibleArrows,
      builder: (context, visibleArrows, _) {
        return Row(
          children: [
            for (int index = 0; index < 3; index++)
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: (visibleArrows![index] == true) ? 1.0 : 0.0,
                child: Icon(
                  widget.isLeft == true
                      ? Icons.keyboard_double_arrow_left
                      : Icons.keyboard_double_arrow_right,
                  size: 28.0,
                  color: Colors.white,
                ),
              )
          ],
        );
      },
    );
  }
}
