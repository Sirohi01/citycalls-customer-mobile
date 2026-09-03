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
    final canProceed = _selectedSymptoms.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: Stack(
        children: [
          // Background Gradient matching the UI
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 350,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFF6EAF6),
                    Color(0xFFECF1FD),
                    Color(0xFFFAFAFA),
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Custom Header (Back Button & Title) ---
                Padding(
                  padding: const EdgeInsets.only(top: 16, left: 20, right: 20, bottom: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          InkWell(
                            onTap: () => Navigator.pop(context),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.02),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.arrow_back, color: Colors.black87, size: 20),
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Text('Describe the issue', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                        ],
                      ),
                      RichText(
                        text: const TextSpan(
                          children: [
                            TextSpan(text: 'Step 3 ', style: TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.bold, fontSize: 13)),
                            TextSpan(text: 'of 5', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w500, fontSize: 13)),
                          ]
                        )
                      ),
                    ],
                  ),
                ),

                // --- Progress ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      // Progress Bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: 3 / 5,
                          minHeight: 5,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: const AlwaysStoppedAnimation(Color(0xFF16A34A)),
                        ),
                      ),
                    ],
                  ),
                ),

                // --- Scrollable Content ---
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- Section 1: Symptoms ---
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0FDF4),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.assignment_outlined, color: Color(0xFF16A34A), size: 20),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(text: 'What symptoms are you seeing?', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
                                      ]
                                    )
                                  ),
                                  SizedBox(height: 4),
                                  Text('You can select multiple options', style: TextStyle(color: Colors.black54, fontSize: 13)),
                                ],
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 16),
                        symptoms.when(
                          data: (items) => Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: items.map((s) {
                              final isSelected = _selectedSymptoms.contains(s.label);
                              return InkWell(
                                onTap: () => setState(() {
                                  isSelected ? _selectedSymptoms.remove(s.label) : _selectedSymptoms.add(s.label);
                                }),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: isSelected ? const Color(0xFF16A34A) : Colors.grey.shade300, width: isSelected ? 1.5 : 1),
                                    boxShadow: [
                                      if (!isSelected)
                                        BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 3)),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.build_circle_outlined, color: const Color(0xFF16A34A).withValues(alpha: 0.7), size: 18),
                                      const SizedBox(width: 8),
                                      Text(s.label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87)),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          loading: () => const LinearProgressIndicator(),
                          error: (_, __) => const Text('Failed to load symptoms', style: TextStyle(color: Colors.black54)),
                        ),
                        
                        const SizedBox(height: 24),

                        // --- Section 2: Notes ---
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0FDF4),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.chat_bubble_outline, color: Color(0xFF16A34A), size: 20),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(text: 'Additional notes ', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
                                        TextSpan(text: '(optional)', style: TextStyle(fontSize: 13, color: Colors.black54)),
                                      ]
                                    )
                                  ),
                                  SizedBox(height: 4),
                                  Text('Provide more details to help our technician', style: TextStyle(color: Colors.black54, fontSize: 13)),
                                ],
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 3)),
                            ],
                          ),
                          child: Stack(
                            children: [
                              TextField(
                                controller: _notesController,
                                maxLines: 4,
                                maxLength: 500,
                                decoration: const InputDecoration(
                                  hintText: 'Describe what\'s wrong in your own words...',
                                  hintStyle: TextStyle(color: Colors.black38, fontSize: 14),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.all(16),
                                  counterText: '',
                                ),
                              ),
                              Positioned(
                                bottom: 12,
                                right: 16,
                                child: ValueListenableBuilder<TextEditingValue>(
                                  valueListenable: _notesController,
                                  builder: (context, value, child) {
                                    return Text(
                                      '${value.text.length}/500',
                                      style: const TextStyle(color: Colors.black45, fontSize: 12),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // --- Section 3: Add Photos ---
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0FDF4),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.image_outlined, color: Color(0xFF16A34A), size: 20),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(text: 'Add photos ', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
                                        TextSpan(text: '(optional)', style: TextStyle(fontSize: 13, color: Colors.black54)),
                                      ]
                                    )
                                  ),
                                  SizedBox(height: 4),
                                  Text('Add photos of the issue for better assistance', style: TextStyle(color: Colors.black54, fontSize: 13)),
                                ],
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            InkWell(
                              onTap: _pickImage,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: 90,
                                height: 90,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  // In real app use custom painter for dashes, here we use solid light border
                                  border: Border.all(color: Colors.grey.shade300, width: 1.5),
                                  boxShadow: [
                                    BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 3)),
                                  ],
                                ),
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_a_photo_outlined, color: Color(0xFF16A34A), size: 28),
                                    SizedBox(height: 6),
                                    Text('Add Photo', style: TextStyle(color: Colors.black54, fontSize: 11, fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              ),
                            ),
                            ..._pickedImages.map((f) => Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.file(f, width: 90, height: 90, fit: BoxFit.cover),
                                    ),
                                    Positioned(
                                      top: -6,
                                      right: -6,
                                      child: GestureDetector(
                                        onTap: () => setState(() => _pickedImages.remove(f)),
                                        child: const CircleAvatar(radius: 12, backgroundColor: Colors.red, child: Icon(Icons.close, size: 14, color: Colors.white)),
                                      ),
                                    ),
                                  ],
                                )),
                          ],
                        ),
                        
                        if (_error != null) Padding(padding: const EdgeInsets.only(top: 24), child: Text(_error!, style: const TextStyle(color: Colors.red))),
                        
                        const SizedBox(height: 60),
                      ],
                    ),
                  ),
                ),

                // --- Sticky Bottom Action ---
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: InkWell(
                    onTap: (canProceed && !_uploading) ? _proceed : null,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: canProceed ? const Color(0xFF16A34A) : Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: _uploading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Continue',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                              ],
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
