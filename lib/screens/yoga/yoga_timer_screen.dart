import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/progress_service.dart';
import 'ai_pose_camera_screen.dart';

class YogaTimerScreen extends StatefulWidget {
  final String title;

  const YogaTimerScreen({super.key, required this.title});

  @override
  State<YogaTimerScreen> createState() => _YogaTimerScreenState();
}

class _YogaTimerScreenState extends State<YogaTimerScreen> {
  final ProgressService _progressService = ProgressService();

  int seconds = 60;
  Timer? timer;
  bool isRunning = false;
  bool isCompleting = false;
  bool isStarting = false;
  String? sessionId;

  Future<void> startTimer() async {
    if (isStarting || isRunning) return;
    setState(() => isStarting = true);

    try {
      sessionId ??= await _progressService.startYogaSession(
        title: widget.title,
      );
      timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (seconds > 0) {
          setState(() {
            seconds--;
          });
        } else {
          completeSession();
        }
      });

      setState(() => isRunning = true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not start session: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => isStarting = false);
      }
    }
  }

  void stopTimer() {
    timer?.cancel();
    setState(() => isRunning = false);
  }

  void resetTimer() {
    stopTimer();
    setState(() {
      seconds = 60;
      sessionId = null;
    });
  }

  Future<void> completeSession() async {
    if (isCompleting) return;
    setState(() => isCompleting = true);
    stopTimer();

    final durationSeconds = (60 - seconds).clamp(1, 60).toInt();

    try {
      final activeSessionId =
          sessionId ??
          await _progressService.startYogaSession(title: widget.title);
      await _progressService.completeYogaSession(
        sessionId: activeSessionId,
        title: widget.title,
        durationSeconds: durationSeconds,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Session Completed")));

      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      setState(() => isCompleting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not save session: $error')));
    }
  }

  Future<void> openAiCamera() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AiPoseCameraScreen(poseName: widget.title),
      ),
    );
  }

  String formatTime(int sec) {
    final min = sec ~/ 60;
    final rem = sec % 60;
    return "$min:${rem.toString().padLeft(2, '0')}";
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            tooltip: 'Open AI camera coach',
            onPressed: isCompleting ? null : openAiCamera,
            icon: const Icon(Icons.camera_alt),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Yoga Timer",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.green.shade50,
              ),
              child: Text(
                formatTime(seconds),
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: isRunning || isCompleting || isStarting
                      ? null
                      : startTimer,
                  child: Text(
                    isCompleting
                        ? "Saving..."
                        : isStarting
                        ? "Starting..."
                        : "Start",
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: isCompleting ? null : stopTimer,
                  child: const Text("Pause"),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: isCompleting ? null : resetTimer,
                  child: const Text("Reset"),
                ),
              ],
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: isCompleting ? null : openAiCamera,
              icon: const Icon(Icons.camera_alt),
              label: const Text('AI Camera Coach'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.green,
                side: const BorderSide(color: Colors.green),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
