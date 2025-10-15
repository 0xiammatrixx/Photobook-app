import 'dart:async';
import 'package:flutter/material.dart';

class CountUpText extends StatefulWidget {
  final int endValue;
  final Duration duration;
  final TextStyle style;

  const CountUpText({
    Key? key,
    required this.endValue,
    this.duration = const Duration(seconds: 1),
    required this.style,
  }) : super(key: key);

  @override
  _CountUpTextState createState() => _CountUpTextState();
}

class _CountUpTextState extends State<CountUpText> {
  late Timer _timer;
  int _currentValue = 0;
  late DateTime _startTime;
  late int _totalSteps;
  late int _stepDuration; // milliseconds between updates

  @override
  void initState() {
    super.initState();
    
    print('🚀 CountUpText initState - Duration: ${widget.duration}, End: ${widget.endValue}');
    
    // Calculate how many steps we need and timing
    _totalSteps = widget.endValue;
    _stepDuration = widget.duration.inMilliseconds ~/ _totalSteps;
    
    // Ensure minimum step duration for smooth animation
    if (_stepDuration < 16) { // 60fps = 16ms per frame
      _stepDuration = 16;
      _totalSteps = widget.duration.inMilliseconds ~/ _stepDuration;
    }
    
    print('📊 Steps: $_totalSteps, Step duration: ${_stepDuration}ms');
    
    _startTime = DateTime.now();
    _startAnimation();
  }

  void _startAnimation() {
    _timer = Timer.periodic(Duration(milliseconds: _stepDuration), (timer) {
      final elapsed = DateTime.now().difference(_startTime);
      final progress = elapsed.inMilliseconds / widget.duration.inMilliseconds;
      
      if (progress >= 1.0) {
        // Animation complete
        setState(() {
          _currentValue = widget.endValue;
        });
        _timer.cancel();
        print('✅ Animation completed in ${elapsed.inMilliseconds}ms');
      } else {
        // Update current value based on progress
        final newValue = (widget.endValue * progress).round();
        if (newValue != _currentValue) {
          setState(() {
            _currentValue = newValue;
          });
          
          // Log every 1 second of progress
          if ((progress * 100).round() % 10 == 0) {
            print('📈 Progress: ${(progress * 100).round()}% - Value: $newValue at ${elapsed.inMilliseconds}ms');
          }
        }
      }
    });
  }

  void restartAnimation() {
    print('🔄 Restarting timer-based animation');
    _timer.cancel();
    setState(() {
      _currentValue = 0;
    });
    _startTime = DateTime.now();
    _startAnimation();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _currentValue.toString(),
      style: widget.style,
    );
  }

  @override
  void dispose() {
    print('💀 CountUpText disposed');
    _timer.cancel();
    super.dispose();
  }
}

class CountUpFormattedText extends StatefulWidget {
  final int endValue;
  final Duration duration;
  final TextStyle style;

  const CountUpFormattedText({
    Key? key,
    required this.endValue,
    this.duration = const Duration(seconds: 1),
    required this.style,
  }) : super(key: key);

  @override
  _CountUpFormattedTextState createState() => _CountUpFormattedTextState();
}

class _CountUpFormattedTextState extends State<CountUpFormattedText> {
  late Timer _timer;
  int _currentValue = 0;
  late DateTime _startTime;
  late int _stepDuration;

  @override
  void initState() {
    super.initState();
    
    print('🚀 CountUpFormattedText initState - Duration: ${widget.duration}, End: ${widget.endValue}');
    
    // Update every 50ms for smooth animation
    _stepDuration = 50;
    _startTime = DateTime.now();
    _startAnimation();
  }

  void _startAnimation() {
    _timer = Timer.periodic(Duration(milliseconds: _stepDuration), (timer) {
      final elapsed = DateTime.now().difference(_startTime);
      final progress = elapsed.inMilliseconds / widget.duration.inMilliseconds;
      
      if (progress >= 1.0) {
        setState(() {
          _currentValue = widget.endValue;
        });
        _timer.cancel();
        print('✅ Formatted animation completed in ${elapsed.inMilliseconds}ms');
      } else {
        final newValue = (widget.endValue * progress).round();
        if (newValue != _currentValue) {
          setState(() {
            _currentValue = newValue;
          });
        }
      }
    });
  }

  void restartAnimation() {
    print('🔄 Restarting formatted timer-based animation');
    _timer.cancel();
    setState(() {
      _currentValue = 0;
    });
    _startTime = DateTime.now();
    _startAnimation();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      formatWithSuffix(_currentValue),
      style: widget.style,
    );
  }

  @override
  void dispose() {
    print('💀 CountUpFormattedText disposed');
    _timer.cancel();
    super.dispose();
  }

  String formatWithSuffix(int value) {
    if (value >= 1000000) {
      return "${(value / 1000000).toStringAsFixed(1)}M";
    } else if (value >= 1000) {
      return "${(value / 1000).toStringAsFixed(1)}K";
    } else {
      return value.toString();
    }
  }
}