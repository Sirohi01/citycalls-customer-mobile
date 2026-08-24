import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/booking_models.dart';
import '../../providers/booking_providers.dart';
import '../../providers/customer_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/booking_step_header.dart';
import 'slot_selection_screen.dart';

// Per docs/rohit/05-customer-app-screen-list.md "Booking" — Issue Description
// + Image Upload.
class IssueDescriptionScreen extends ConsumerStatefulWidget {
  final BookingDraft draft;
  const IssueDescriptionScreen({super.key, required this.draft});

  @override
  ConsumerState<IssueDescriptionScreen> createState() => _IssueDescriptionScreenState();
}

class _IssueDescriptionScreenState extends ConsumerState<IssueDescriptionScreen> {
  final _notesController = TextEditingController();
  final Set<String> _selectedSymptoms = {};
  final List<File> _pickedImages = [];
  bool _uploading = false;
  String? _error;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) setState(() => _pickedImages.add(File(picked.path)));
  }

  Future<void> _proceed() async {
    setState(() {
      _uploading = true;
      _error = null;
    });
    try {
      final customerId = (await ref.read(myProfileProvider.future)).id;
      final repo = ref.read(bookingRepositoryProvider);
      final urls = <String>[];
      for (final file in _pickedImages) {
        urls.add(await repo.uploadIssueImage(customerId, file));
      }
      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => SlotSelectionScreen(
          draft: widget.draft.copyWith(
            symptoms: _selectedSymptoms.toList(),
            notes: _notesController.text.trim(),
            imageUrls: urls,
          ),
        ),
      ));
    } catch (e) {
      setState(() => _error = 'Failed to upload photos: $e');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final symptoms = ref.watch(serviceSymptomsProvider(widget.draft.serviceId));

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(title: const Text('Describe the Issue'), centerTitle: false),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const BookingStepHeader(step: 3, totalSteps: 5, title: 'Describe the issue'),
            const Text('What symptoms are you seeing? (optional)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: 12),
            symptoms.when(
              data: (items) => Wrap(
                spacing: 8,
                runSpacing: 8,
                children: items
                    .map((s) => FilterChip(
                          label: Text(s.label),
                          selected: _selectedSymptoms.contains(s.label),
                          onSelected: (v) => setState(() => v ? _selectedSymptoms.add(s.label) : _selectedSymptoms.remove(s.label)),
                          selectedColor: Theme.of(context).colorScheme.primary,
                          labelStyle: TextStyle(color: _selectedSymptoms.contains(s.label) ? Colors.white : AppColors.black),
                          backgroundColor: AppColors.neutral100,
                          side: BorderSide.none,
                          showCheckmark: false,
                        ))
                    .toList(),
              ),
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const Text('Failed to load symptoms', style: TextStyle(color: AppColors.neutral500)),
            ),
            const SizedBox(height: 20),
            const Text('Additional notes (optional)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(hintText: 'Describe what\'s wrong in your own words...'),
            ),
            const SizedBox(height: 20),
            const Text('Add photos (optional)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: 8),
            SizedBox(
              height: 84,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  ..._pickedImages.map((f) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.file(f, width: 84, height: 84, fit: BoxFit.cover),
                            ),
                            Positioned(
                              top: 2,
                              right: 2,
                              child: GestureDetector(
                                onTap: () => setState(() => _pickedImages.remove(f)),
                                child: const CircleAvatar(radius: 10, backgroundColor: Colors.black54, child: Icon(Icons.close, size: 12, color: Colors.white)),
                              ),
                            ),
                          ],
                        ),
                      )),
                  InkWell(
                    onTap: _pickImage,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.25), style: BorderStyle.solid),
                      ),
                      child: Icon(Icons.add_a_photo_outlined, color: Theme.of(context).colorScheme.primary),
                    ),
                  ),
                ],
              ),
            ),
            if (_error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_error!, style: const TextStyle(color: Colors.red))),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _uploading ? null : _proceed,
              child: _uploading
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }
}
