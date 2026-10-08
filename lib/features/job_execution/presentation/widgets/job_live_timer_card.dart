import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';

/// Server-authoritative timer card displaying real-time elapsed job duration
/// on both worker and provider devices.
class JobLiveTimerCard extends StatefulWidget {
  final DateTime? startedAt;
  final DateTime? endedAt;
  final int? serverElapsedSeconds;
  final bool isCompleted;

  const JobLiveTimerCard({
    super.key,
    required this.startedAt,
    this.endedAt,
    this.serverElapsedSeconds,
    this.isCompleted = false,
  });

  @override
  State<JobLiveTimerCard> createState() => _JobLiveTimerCardState();
}

class _JobLiveTimerCardState extends State<JobLiveTimerCard> with SingleTickerProviderStateMixin {
  Timer? _ticker;
  late int _currentSeconds;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initSeconds();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (!widget.isCompleted && widget.startedAt != null) {
      _pulseController.repeat(reverse: true);
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) {
          setState(() {
            _initSeconds();
          });
        }
      });
    }
  }

  void _initSeconds() {
    if (widget.isCompleted) {
      if (widget.serverElapsedSeconds != null && widget.serverElapsedSeconds! > 0) {
        _currentSeconds = widget.serverElapsedSeconds!;
      } else if (widget.startedAt != null && widget.endedAt != null) {
        _currentSeconds = widget.endedAt!.difference(widget.startedAt!).inSeconds;
      } else {
        _currentSeconds = 0;
      }
    } else if (widget.startedAt != null) {
      final now = DateTime.now();
      final diff = now.difference(widget.startedAt!).inSeconds;
      _currentSeconds = diff > 0 ? diff : 0;
    } else {
      _currentSeconds = widget.serverElapsedSeconds ?? 0;
    }
  }

  @override
  void didUpdateWidget(JobLiveTimerCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCompleted != oldWidget.isCompleted ||
        widget.startedAt != oldWidget.startedAt ||
        widget.serverElapsedSeconds != oldWidget.serverElapsedSeconds) {
      _initSeconds();
      if (widget.isCompleted) {
        _ticker?.cancel();
        _ticker = null;
        _pulseController.stop();
      } else if (widget.startedAt != null) {
        if (!_pulseController.isAnimating) {
          _pulseController.repeat(reverse: true);
        }
        _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) {
          if (mounted) {
            setState(() {
              _initSeconds();
            });
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  String _formatDuration(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    final hoursStr = hours.toString().padLeft(2, '0');
    final minutesStr = minutes.toString().padLeft(2, '0');
    final secondsStr = seconds.toString().padLeft(2, '0');

    return '$hoursStr:$minutesStr:$secondsStr';
  }

  @override
  Widget build(BuildContext context) {
    final isRunning = !widget.isCompleted && widget.startedAt != null;
    final timeStr = _formatDuration(_currentSeconds);

    final startDisplay = widget.startedAt != null
        ? DateFormat('hh:mm a').format(widget.startedAt!.toLocal())
        : '--:--';
    final endDisplay = widget.endedAt != null
        ? DateFormat('hh:mm a').format(widget.endedAt!.toLocal())
        : null;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isRunning ? const Color(0xFF0F172A) : const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isRunning ? const Color(0xFF10B981).withValues(alpha: 0.6) : const Color(0xFF334155),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isRunning
                ? const Color(0xFF10B981).withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Status badge & Server authoritative indicator
          Row(
            children: [
              if (isRunning) ...[
                FadeTransition(
                  opacity: _pulseAnimation,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'LIVE WORK TIMER',
                  style: TextStyle(
                    color: Color(0xFF10B981),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1.1,
                  ),
                ),
              ] else ...[
                const Icon(Icons.check_circle_rounded, color: Color(0xFF34D399), size: 16),
                const SizedBox(width: 6),
                const Text(
                  'COMPLETED DURATION',
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Server-authoritative',
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Digital Timer Display
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (isRunning ? const Color(0xFF10B981) : AppColors.headerGreenDark)
                      .withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.timer_rounded,
                  color: isRunning ? const Color(0xFF34D399) : const Color(0xFF94A3B8),
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      timeStr,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                        color: isRunning ? Colors.white : const Color(0xFFE2E8F0),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isRunning ? 'Elapsed time since verified start' : 'Final total logged time',
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: Color(0xFF334155), height: 1),
          const SizedBox(height: 12),

          // Footer timestamps
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.play_circle_outline_rounded, color: Color(0xFF94A3B8), size: 14),
                  const SizedBox(width: 4),
                  Text(
                    'Started: $startDisplay',
                    style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12),
                  ),
                ],
              ),
              if (endDisplay != null)
                Row(
                  children: [
                    const Icon(Icons.stop_circle_outlined, color: Color(0xFF94A3B8), size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Ended: $endDisplay',
                      style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
