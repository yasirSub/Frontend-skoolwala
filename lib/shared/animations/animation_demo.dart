import 'package:flutter/material.dart';
import 'package:skoolwala/shared/animations/animations.dart';

/// Demo screen showing all available animations
class AnimationDemoScreen extends StatefulWidget {
  const AnimationDemoScreen({super.key});

  @override
  State<AnimationDemoScreen> createState() => _AnimationDemoScreenState();
}

class _AnimationDemoScreenState extends State<AnimationDemoScreen> {
  int _counter = 0;
  double _progress = 0.0;
  DateTime _currentMonth = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Animation Demo'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Animated Counter Demo
            _buildSection(
              title: 'Animated Counter',
              child: Column(
                children: [
                  AnimatedCounter(
                    targetValue: _counter,
                    textStyle: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () => setState(() => _counter += 10),
                        child: const Text('+10'),
                      ),
                      ElevatedButton(
                        onPressed: () => setState(() => _counter -= 5),
                        child: const Text('-5'),
                      ),
                      ElevatedButton(
                        onPressed: () => setState(() => _counter = 0),
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Animated Percentage Demo
            _buildSection(
              title: 'Animated Percentage',
              child: Column(
                children: [
                  AnimatedPercentage(
                    targetPercentage: _progress * 100,
                    textStyle: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Slider(
                    value: _progress,
                    onChanged: (value) => setState(() => _progress = value),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Animated Progress Bar Demo
            _buildSection(
              title: 'Animated Progress Bar',
              child: Column(
                children: [
                  AnimatedProgressBar(
                    progress: _progress,
                    height: 20,
                    backgroundColor: Colors.grey[300],
                    progressColor: Colors.blue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  const SizedBox(height: 16),
                  Text('Progress: ${(_progress * 100).toStringAsFixed(1)}%'),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Animated Circular Progress Demo
            _buildSection(
              title: 'Animated Circular Progress',
              child: Center(
                child: AnimatedCircularProgress(
                  progress: _progress,
                  size: 120,
                  strokeWidth: 12,
                  backgroundColor: Colors.grey[300],
                  progressColor: Colors.purple,
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Animated Calendar Demo
            _buildSection(
              title: 'Animated Calendar',
              child: AnimatedCalendar(
                currentMonth: _currentMonth,
                attendanceData: {
                  1: true,
                  3: true,
                  5: true,
                  7: true,
                  9: true,
                  11: true,
                  13: true,
                  15: true,
                  17: true,
                  19: true,
                  21: true,
                  23: true,
                  25: true,
                  27: true,
                  29: true,
                },
                onDateSelected: (date) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Selected: ${date.day}/${date.month}/${date.year}',
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 32),

            // Animated Button Demo
            _buildSection(
              title: 'Animated Buttons',
              child: Column(
                children: [
                  AnimatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Animated Button Pressed!'),
                        ),
                      );
                    },
                    child: const Text('Animated Button'),
                  ),
                  const SizedBox(height: 16),
                  AnimatedIconButton(
                    icon: Icons.favorite,
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Heart pressed!')),
                      );
                    },
                    color: Colors.red,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Loading Animations Demo
            _buildSection(
              title: 'Loading Animations',
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      LoadingAnimations.pulse(
                        child: const Icon(Icons.favorite, color: Colors.red),
                      ),
                      LoadingAnimations.bounce(
                        child: const Icon(Icons.star, color: Colors.orange),
                      ),
                      LoadingAnimations.rotate(
                        child: const Icon(Icons.refresh, color: Colors.blue),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  LoadingAnimations.wave(child: const SizedBox(height: 20)),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Animated Cards Demo
            _buildSection(
              title: 'Animated Cards',
              child: Column(
                children: [
                  AnimatedCard(
                    animationType: AnimationType.slideInUp,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('Slide In Up Animation'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  AnimatedCard(
                    animationType: AnimationType.scaleIn,
                    delay: const Duration(milliseconds: 200),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('Scale In Animation'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        child,
      ],
    );
  }
}
