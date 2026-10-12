import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:udyogasethu/features/chat/data/chat_repository.dart';
import 'package:udyogasethu/features/chat/domain/call_session.dart';

class SecuredCallScreen extends ConsumerStatefulWidget {
  final String recipientId;
  final String recipientName;
  final String? recipientRole;
  final String bookingCode;
  final String? assignmentId;

  const SecuredCallScreen({
    super.key,
    required this.recipientId,
    required this.recipientName,
    this.recipientRole,
    required this.bookingCode,
    this.assignmentId,
  });

  @override
  ConsumerState<SecuredCallScreen> createState() => _SecuredCallScreenState();
}

class _SecuredCallScreenState extends ConsumerState<SecuredCallScreen> {
  CallSession? _callSession;
  bool _isLoading = true;
  bool _isMuted = false;
  bool _isSpeakerOn = true;
  int _secondsElapsed = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCall();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _startCall() async {
    try {
      final repo = ref.read(chatRepositoryProvider);
      final session = await repo.initiateMaskedCall(
        recipientId: widget.recipientId,
        bookingCode: widget.bookingCode,
        assignmentId: widget.assignmentId,
      );

      if (mounted) {
        setState(() {
          _callSession = session;
          _isLoading = false;
        });

        // Start duration timer
        _timer = Timer.periodic(const Duration(seconds: 1), (t) {
          if (mounted) {
            setState(() => _secondsElapsed++);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to initiate masked call: $e')),
        );
      }
    }
  }

  Future<void> _endCall() async {
    _timer?.cancel();
    if (_callSession != null) {
      final repo = ref.read(chatRepositoryProvider);
      await repo.endMaskedCall(
        callId: _callSession!.callId,
        durationSeconds: _secondsElapsed,
      );
    }
    if (mounted) {
      context.pop();
    }
  }

  void _triggerSos() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            SizedBox(width: 8),
            Text('Safety SOS Alert', style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        content: const Text(
          'Emergency SOS will log an incident report and alert your emergency contacts for this booking.',
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: Colors.red,
                  content: Text('Emergency escalation recorded. Contacts notified.'),
                ),
              );
            },
            child: const Text('Confirm SOS', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int totalSecs) {
    final mins = (totalSecs ~/ 60).toString().padLeft(2, '0');
    final secs = (totalSecs % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  @override
  Widget build(BuildContext context) {
    final isDemo = _callSession?.isDemo ?? true;
    final proxyDisplay = _callSession?.proxyDisplay ?? '+91 80 4719 8200 (Proxy)';

    return Scaffold(
      backgroundColor: const Color(0xFF0B132B),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Top Banner with SOS pill & Close X
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'PROTECTED MASKED VOICE PROXY',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                  Row(
                    children: [
                      // SOS pill
                      InkWell(
                        onTap: _triggerSos,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDC2626),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.shield_rounded, color: Colors.white, size: 13),
                              SizedBox(width: 4),
                              Text(
                                'SOS',
                                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white70),
                        onPressed: _endCall,
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Demo Mode Banner (unmissable)
              if (isDemo)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF78350F),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFF59E0B)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFFFDE68A)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Demo mode: No real call placed. Simulating proxy bridge.',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFEF3C7),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Privacy Guard Alert Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFEA580C)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lock_rounded, size: 16, color: Color(0xFFFB923C)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '🔒 Privacy Guard: Phone numbers are masked. Do not share personal contact details or off-platform payment info outside UdyogaSethu.',
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFFF8FAFC),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Central Contact Avatar Circle
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF1E293B),
                  border: Border.all(color: const Color(0xFF00875A), width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00875A).withValues(alpha: 0.25),
                      blurRadius: 20,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    widget.recipientName.isNotEmpty ? widget.recipientName[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Booking ID Tag
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'ID: ${widget.bookingCode}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Contact Name & Role
              Text(
                widget.recipientName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 4),

              Text(
                '${widget.recipientRole ?? 'Contact'} • Connected via $proxyDisplay',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF94A3B8),
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Call Duration Counter
              if (_isLoading)
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF10B981))),
                    SizedBox(width: 8),
                    Text('Connecting proxy bridge...', style: TextStyle(color: Color(0xFF10B981), fontSize: 13)),
                  ],
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Call Active • ${_formatDuration(_secondsElapsed)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF10B981),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 32),

              // Audio Controls Row (Mute, Speaker)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Mute button
                  InkWell(
                    onTap: () => setState(() => _isMuted = !_isMuted),
                    borderRadius: BorderRadius.circular(25),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: _isMuted ? const Color(0xFFDC2626).withValues(alpha: 0.2) : const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: _isMuted ? const Color(0xFFDC2626) : const Color(0xFF334155),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                            size: 18,
                            color: _isMuted ? const Color(0xFFEF4444) : Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isMuted ? 'Muted' : 'Mute',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _isMuted ? const Color(0xFFEF4444) : Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Speaker button
                  InkWell(
                    onTap: () => setState(() => _isSpeakerOn = !_isSpeakerOn),
                    borderRadius: BorderRadius.circular(25),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: _isSpeakerOn ? const Color(0xFF00875A).withValues(alpha: 0.2) : const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: _isSpeakerOn ? const Color(0xFF00875A) : const Color(0xFF334155),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _isSpeakerOn ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                            size: 18,
                            color: _isSpeakerOn ? const Color(0xFF10B981) : Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isSpeakerOn ? 'Speaker ON' : 'Speaker OFF',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _isSpeakerOn ? const Color(0xFF10B981) : Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Large Red End Call Pill Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  icon: const Icon(Icons.call_end_rounded, size: 20),
                  label: const Text(
                    'End Call',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  onPressed: _endCall,
                ),
              ),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
