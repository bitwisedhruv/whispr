import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:whispr/core/theme.dart';
import 'package:whispr/services/supabase_service.dart';
import 'dart:io';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _fullNameController = TextEditingController();
  String _selectedAvatar = 'assets/avatars/avatar_1.svg';
  String? _networkAvatarUrl;
  File? _pickedImage;
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final profile = await SupabaseService.getProfile();
      if (profile != null) {
        setState(() {
          _fullNameController.text = profile['full_name'] ?? '';
          final avatarUrl = profile['avatar_url'] as String?;
          if (avatarUrl != null) {
            if (avatarUrl.startsWith('http')) {
              _networkAvatarUrl = avatarUrl;
              _selectedAvatar = ''; // Deselect SVGs if using network image
            } else {
              _selectedAvatar = avatarUrl;
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  final List<String> _avatars = [
    'assets/avatars/avatar_1.svg',
    'assets/avatars/avatar_2.svg',
    'assets/avatars/avatar_3.svg',
    'assets/avatars/avatar_4.svg',
    'assets/avatars/avatar_5.svg',
    'assets/avatars/avatar_6.svg',
  ];

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _pickedImage = File(pickedFile.path);
        _selectedAvatar = '';
        _networkAvatarUrl = null;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_fullNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your full name')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      String avatarUrl = _selectedAvatar;

      if (_pickedImage != null) {
        avatarUrl = await SupabaseService.uploadAvatar(_pickedImage!);
      } else if (_networkAvatarUrl != null) {
        avatarUrl = _networkAvatarUrl!;
      }

      await SupabaseService.updateProfile(
        fullName: _fullNameController.text,
        avatarUrl: avatarUrl,
      );
      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: WhisprTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 40),
                        Center(
                          child: Stack(
                            children: [
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.1),
                                    width: 4,
                                  ),
                                ),
                                child: Padding(
                                  padding:
                                      (_pickedImage == null &&
                                          _networkAvatarUrl == null)
                                      ? const EdgeInsets.all(20.0)
                                      : EdgeInsets.zero,
                                  child: _buildAvatarWidget(),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: _pickImage,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt_outlined,
                                      size: 20,
                                      color: WhisprTheme.backgroundColor,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ).animate().scale(curve: Curves.easeOutBack),
                        ),
                        const SizedBox(height: 48),
                        Text(
                          'Choose an Avatar',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ).animate().fadeIn(delay: 200.ms),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 80,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _avatars.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(width: 16),
                            itemBuilder: (context, index) {
                              final avatar = _avatars[index];
                              final isSelected = _selectedAvatar == avatar;
                              return GestureDetector(
                                onTap: () => setState(() {
                                  _selectedAvatar = avatar;
                                  _pickedImage = null;
                                  _networkAvatarUrl = null;
                                }),
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withOpacity(0.05),
                                    border: Border.all(
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.white.withOpacity(0.1),
                                      width: 2,
                                    ),
                                  ),
                                  child: SvgPicture.asset(avatar),
                                ),
                              );
                            },
                          ),
                        ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
                        const SizedBox(height: 48),
                        TextField(
                          controller: _fullNameController,
                          decoration: const InputDecoration(
                            labelStyle: TextStyle(color: Colors.white60),
                            hintText: 'Full Name',
                            prefixIcon: Icon(Icons.person_outline, size: 20),
                          ),
                        ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
                        const SizedBox(height: 48),
                        ElevatedButton(
                              onPressed: _isSaving ? null : _saveProfile,
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 56),
                              ),
                              child: _isSaving
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: WhisprTheme.backgroundColor,
                                      ),
                                    )
                                  : const Text('Save Changes'),
                            )
                            .animate()
                            .fadeIn(delay: 500.ms)
                            .scale(begin: const Offset(0.9, 0.9)),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildAvatarWidget() {
    if (_pickedImage != null) {
      return ClipOval(
        child: Image.file(
          _pickedImage!,
          fit: BoxFit.cover,
          width: 120,
          height: 120,
        ),
      );
    } else if (_networkAvatarUrl != null) {
      return ClipOval(
        child: Image.network(
          _networkAvatarUrl!,
          fit: BoxFit.cover,
          width: 120,
          height: 120,
          errorBuilder: (context, error, stackTrace) => SvgPicture.asset(
            'assets/avatars/avatar_1.svg',
            fit: BoxFit.contain,
          ),
        ),
      );
    } else {
      return SvgPicture.asset(
        _selectedAvatar.isEmpty
            ? 'assets/avatars/avatar_1.svg'
            : _selectedAvatar,
        fit: BoxFit.contain,
      );
    }
  }
}
