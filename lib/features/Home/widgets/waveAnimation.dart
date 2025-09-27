import 'package:flutter/material.dart';
import 'package:mindmate/constants.dart';

class WaveAnimation extends StatefulWidget {
  const WaveAnimation({super.key});

  @override
  State<WaveAnimation> createState() => _WaveAnimationState();
}

class _WaveAnimationState extends State<WaveAnimation>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late List<AnimationController> _barControllers;
  late List<Animation<double>> _barAnimations;

  final int numberOfBars = 20;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _barControllers = List.generate(
      numberOfBars,
      (index) => AnimationController(
        duration: Duration(milliseconds: 300 + (index * 50)),
        vsync: this,
      ),
    );

    _barAnimations = _barControllers.map((controller) {
      return Tween<double>(
        begin: 0.1,
        end: 1.0,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));
    }).toList();

    _startAnimation();
  }

  void _startAnimation() {
    for (int i = 0; i < _barControllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 100), () {
        if (mounted) {
          _barControllers[i].repeat(reverse: true);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: Globals.screenHeight * 0.06,
      padding: EdgeInsets.symmetric(horizontal: Globals.screenWidth * 0.05),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.grey[300]!, width: 1),
        color: Colors.grey[50],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.mic, color: Colors.red, size: Globals.screenWidth * 0.05),
          SizedBox(width: Globals.screenWidth * 0.03),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: List.generate(numberOfBars, (index) {
                return AnimatedBuilder(
                  animation: _barAnimations[index],
                  builder: (context, child) {
                    return Container(
                      width: 3,
                      height: (20 + (30 * _barAnimations[index].value)),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(
                          0.7 + (0.3 * _barAnimations[index].value),
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  },
                );
              }),
            ),
          ),
          SizedBox(width: Globals.screenWidth * 0.03),
          Text(
            "Recording...",
            style: TextStyle(
              color: Colors.red,
              fontSize: Globals.screenWidth * 0.035,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    for (var controller in _barControllers) {
      controller.dispose();
    }
    super.dispose();
  }
}
