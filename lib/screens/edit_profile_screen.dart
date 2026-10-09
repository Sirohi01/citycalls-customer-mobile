import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/customer_providers.dart';
import '../providers/auth_providers.dart';
import '../widgets/profile_avatar.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  bool _photoBusy = false;
  String? _error;
  // What was loaded, so "Update profile" only lights up after a real change.
  String _initialName = '';
  String _initialEmail = '';

  bool get _hasChanges =>
      _nameController.text.trim() != _initialName ||
      _emailController.text.trim() != _initialEmail;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(myProfileProvider).value;
    _initialName = profile?.name ?? '';
    _initialEmail = profile?.email ?? '';
    _nameController = TextEditingController(text: _initialName)
      ..addListener(_onEdited);
    _emailController = TextEditingController(text: _initialEmail)
      ..addListener(_onEdited);
  }

  void _onEdited() => setState(() => _error = null);

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // Camera / gallery / remove sheet for the profile photo.
  Future<void> _changePhoto(String customerId) async {
    final hasPhoto = ref.read(profilePhotoUrlProvider).valueOrNull != null;
    final choice = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 8, 20, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Profile photo',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined, color: Color(0xFF16A34A)),
                title: const Text('Take a photo'),
                onTap: () => Navigator.pop(sheet, 'camera'),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: Color(0xFF16A34A)),
                title: const Text('Choose from gallery'),
                onTap: () => Navigator.pop(sheet, 'gallery'),
              ),
              if (hasPhoto)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text('Remove photo', style: TextStyle(color: Colors.red)),
                  onTap: () => Navigator.pop(sheet, 'remove'),
                ),
            ],
          ),
        ),
      ),
    );
    if (choice == null || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final repo = ref.read(customerRepositoryProvider);
    try {
      if (choice == 'remove') {
        setState(() => _photoBusy = true);
        await repo.removeProfilePhoto(customerId);
        messenger.showSnackBar(const SnackBar(content: Text('Profile photo removed')));
      } else {
        // Resized + re-encoded as JPEG so it stays well under the 5 MB limit.
        final image = await ImagePicker().pickImage(
          source: choice == 'camera' ? ImageSource.camera : ImageSource.gallery,
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 85,
        );
        if (image == null || !mounted) return;
        setState(() => _photoBusy = true);
        await repo.uploadProfilePhoto(customerId, image);
        messenger.showSnackBar(const SnackBar(content: Text('Profile photo updated')));
      }
      ref.invalidate(profilePhotoUrlProvider);
    } catch (_) {
      messenger.showSnackBar(const SnackBar(
          content: Text("Couldn't update your photo. Please try again.")));
    } finally {
      if (mounted) setState(() => _photoBusy = false);
    }
  }

  Future<void> _saveChanges() async {
    final profile = ref.read(myProfileProvider).value;
    if (profile == null || _saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    setState(() {
      _saving = true;
      _error = null;
    });
    
    try {
      await ref.read(customerRepositoryProvider).updateProfile(
            profile.id,
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
          );
      ref.invalidate(myProfileProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated')));
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to save changes. Please try again.';
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(myProfileProvider).value;

    if (profile == null) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator(color: _kGreen)));
    }

    final canSave = _hasChanges && !_saving && !_photoBusy;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded, color: _kInk),
        ),
        titleSpacing: 0,
        title: const Text('Edit profile',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w700, color: _kInk)),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              // --- Photo ---
              Center(
                child: GestureDetector(
                  onTap: _photoBusy ? null : () => _changePhoto(profile.id),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const ProfileAvatar(
                          size: 104,
                          borderWidth: 3,
                          borderColor: Color(0xFFF1F5F9)),
                      if (_photoBusy)
                        Container(
                          width: 104,
                          height: 104,
                          decoration: const BoxDecoration(
                              color: Colors.black38, shape: BoxShape.circle),
                          alignment: Alignment.center,
                          child: const SizedBox(
                            width: 26,
                            height: 26,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5, color: Colors.white),
                          ),
                        ),
                      Positioned(
                        right: -2,
                        bottom: 2,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _kInk,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                          child: const Icon(Icons.camera_alt_rounded,
                              size: 15, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: TextButton(
                  onPressed:
                      _photoBusy ? null : () => _changePhoto(profile.id),
                  style: TextButton.styleFrom(foregroundColor: _kGreen),
                  child: const Text('Change photo',
                      style: TextStyle(
                          fontSize: 13.5, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 18),

              // --- Fields ---
              _FieldLabel('Name'),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                style: _fieldText,
                decoration: _fieldDecoration(hint: 'Enter your full name'),
                validator: (v) => (v == null || v.trim().length < 2)
                    ? 'Please enter your name'
                    : null,
              ),
              const SizedBox(height: 18),
              _FieldLabel('Email address'),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => canSave ? _saveChanges() : null,
                style: _fieldText,
                decoration: _fieldDecoration(hint: 'name@example.com'),
                validator: (v) {
                  final email = v?.trim() ?? '';
                  if (email.isEmpty) return null; // optional
                  return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)
                      ? null
                      : 'Please enter a valid email address';
                },
              ),
              const SizedBox(height: 18),
              _FieldLabel('Mobile number'),
              TextFormField(
                initialValue: '+91 ${profile.mobile ?? ''}',
                readOnly: true,
                enableInteractiveSelection: false,
                style: _fieldText.copyWith(color: _kMuted),
                decoration: _fieldDecoration(
                  filled: true,
                  suffix: Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _kGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_rounded, size: 13, color: _kGreen),
                        SizedBox(width: 4),
                        Text('Verified',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: _kGreen)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Your mobile number is used to sign in and can\'t be changed.',
                style: TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          size: 18, color: Color(0xFFDC2626)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_error!,
                            style: const TextStyle(
                                fontSize: 13, color: Color(0xFFB91C1C))),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      // --- Sticky update button ---
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
          ),
          child: SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: canSave ? _saveChanges : null,
              style: FilledButton.styleFrom(
                backgroundColor: _kInk,
                disabledBackgroundColor: const Color(0xFFE2E8F0),
                disabledForegroundColor: const Color(0xFF94A3B8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Update profile',
                      style: TextStyle(
                          fontSize: 15.5, fontWeight: FontWeight.w700)),
            ),
          ),
        ),
      ),
    );
  }
}

const _kInk = Color(0xFF0F172A);
const _kMuted = Color(0xFF64748B);
const _kGreen = Color(0xFF16A34A);

const _fieldText =
    TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: _kInk);

// Clean outlined field: grey border, dark border when focused.
InputDecoration _fieldDecoration(
    {String? hint, Widget? suffix, bool filled = false}) {
  OutlineInputBorder border(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: width),
      );
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14.5),
    filled: filled,
    fillColor: const Color(0xFFF8FAFC),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    suffixIcon: suffix,
    suffixIconConstraints: const BoxConstraints(minHeight: 0, minWidth: 0),
    border: border(const Color(0xFFE2E8F0)),
    enabledBorder: border(const Color(0xFFE2E8F0)),
    focusedBorder: border(_kInk, 1.5),
    errorBorder: border(const Color(0xFFDC2626)),
    focusedErrorBorder: border(const Color(0xFFDC2626), 1.5),
  );
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 2),
        child: Text(text,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: _kMuted)),
      );
}
