import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../screens/service_browse_screen.dart';

const _kGreen = Color(0xFF16A34A);

/// Mic button on the home search bar: listens in a bottom sheet, then opens
/// the service search with whatever the customer said already typed in.
Future<void> startVoiceSearch(BuildContext context) async {
  final navigator = Navigator.of(context);
  final words = await showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => const _VoiceSearchSheet(),
  );
  if (words == null || words.trim().isEmpty) return;
  navigator.push(MaterialPageRoute(
    builder: (_) =>
        ServiceBrowseScreen(title: 'Search', initialQuery: words.trim()),
  ));
}

class _VoiceSearchSheet extends StatefulWidget {
  const _VoiceSearchSheet();

  @override
  State<_VoiceSearchSheet> createState() => _VoiceSearchSheetState();
}

enum _Status { starting, listening, unavailable, error }

class _VoiceSearchSheetState extends State<_VoiceSearchSheet>
    with SingleTickerProviderStateMixin {
  final _speech = SpeechToText();
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  _Status _status = _Status.starting;
  String _words = '';
  bool _closed = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    setState(() {
      _status = _Status.starting;
      _words = '';
    });
    // Asks for the microphone permission on first use.
    final available = await _speech.initialize(
      onStatus: (s) {
        // Recogniser stopped on its own (silence) — finish with what we have.
        if ((s == 'done' || s == 'notListening') && _words.isNotEmpty) {
          _finish();
        }
      },
      onError: (_) {
        if (mounted && _words.isEmpty) setState(() => _status = _Status.error);
      },
    );
    if (!mounted) return;
    if (!available) {
      setState(() => _status = _Status.unavailable);
      return;
    }
    setState(() => _status = _Status.listening);
    await _speech.listen(
      onResult: _onResult,
      listenOptions: SpeechListenOptions(
        partialResults: true,
        listenFor: const Duration(seconds: 15),
        pauseFor: const Duration(seconds: 3),
        localeId: 'en_IN',
      ),
    );
  }

  void _onResult(SpeechRecognitionResult result) {
    if (!mounted) return;
    setState(() => _words = result.recognizedWords);
    if (result.finalResult && _words.isNotEmpty) _finish();
  }

  void _finish() {
    if (_closed || !mounted) return;
    _closed = true;
    _speech.stop();
    Navigator.of(context).pop(_words);
  }

  @override
  void dispose() {
    _pulse.dispose();
    _speech.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listening = _status == _Status.listening;
    final failed = _status == _Status.unavailable || _status == _Status.error;

    final String title;
    final String subtitle;
    switch (_status) {
      case _Status.starting:
        title = 'Getting ready...';
        subtitle = 'Allow microphone access if asked';
      case _Status.listening:
        title = _words.isEmpty ? 'Listening...' : _words;
        subtitle = _words.isEmpty
            ? 'Try saying “AC repair” or “home cleaning”'
            : 'Tap the mic when you are done';
      case _Status.unavailable:
        title = 'Voice search unavailable';
        subtitle =
            'Allow microphone permission for CityCalls in your phone settings.';
      case _Status.error:
        title = "Didn't catch that";
        subtitle = 'Tap the mic and try again';
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: listening
                  ? (_words.isNotEmpty ? _finish : null)
                  : (failed ? _start : null),
              child: AnimatedBuilder(
                animation: _pulse,
                builder: (_, child) {
                  final t = listening ? _pulse.value : 0.0;
                  return Container(
                    width: 96 + 16 * t,
                    height: 96 + 16 * t,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: (failed ? Colors.red : _kGreen)
                          .withValues(alpha: 0.10 + 0.08 * t),
                    ),
                    child: child,
                  );
                },
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: failed ? Colors.red.shade400 : _kGreen,
                  ),
                  child: Icon(
                    failed ? Icons.mic_off_rounded : Icons.mic_rounded,
                    color: Colors.white,
                    size: 34,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            if (failed) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Type instead'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
