import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:whispr/core/theme.dart';
import 'package:whispr/services/supabase_service.dart';
import 'package:whispr/features/home/home_page.dart';
import 'package:whispr/features/auth/auth_page.dart';
import 'dart:io';

class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final _fullNameController = TextEditingController();
  String _selectedAvatar = 'assets/avatars/avatar_1.svg';
  File? _pickedImage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Guard: Redirect back if no user is logged in
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (SupabaseService.currentUser == null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AuthPage()),
        );
      }
    });
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

    setState(() => _isLoading = true);
    try {
      String avatarUrl = _selectedAvatar;

      if (_pickedImage != null) {
        avatarUrl = await SupabaseService.uploadAvatar(_pickedImage!);
      }

      await SupabaseService.updateProfile(_fullNameController.text, avatarUrl);
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomePage()),
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: WhisprTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 60),
                  Text(
                    'Complete Your Profile',
                    style: Theme.of(context).textTheme.displayMedium,
                  ).animate().fadeIn().slideX(begin: -0.1),
                  const SizedBox(height: 8),
                  Text(
                    'How should the world see you?',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ).animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: 48),
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1),
                              width: 4,
                            ),
                          ),
                          child: Padding(
                            padding: _pickedImage == null
                                ? const EdgeInsets.all(20.0)
                                : EdgeInsets.zero,
                            child: _pickedImage != null
                                ? ClipOval(
                                    child: Image.file(
                                      _pickedImage!,
                                      fit: BoxFit.cover,
                                      width: 120,
                                      height: 120,
                                    ),
                                  )
                                : SvgPicture.asset(
                                    _selectedAvatar,
                                    fit: BoxFit.contain,
                                  ),
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
                                Icons.edit_outlined,
                                size: 20,
                                color: WhisprTheme.backgroundColor,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ).animate().scale(delay: 400.ms, curve: Curves.easeOutBack),
                  ),
                  const SizedBox(height: 48),
                  Text(
                    'Choose an Avatar',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ).animate().fadeIn(delay: 600.ms),
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
                          }),
                          child: Container(
                            width: 80,
                            height: 80,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.05),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.1),
                                width: 2,
                              ),
                            ),
                            child: SvgPicture.asset(avatar),
                          ),
                        );
                      },
                    ),
                  ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.1),
                  const SizedBox(height: 48),
                  TextField(
                    controller: _fullNameController,
                    decoration: const InputDecoration(
                      hintText: 'Full Name',
                      prefixIcon: Icon(Icons.person_outline, size: 20),
                    ),
                  ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.1),
                  const SizedBox(height: 48),
                  ElevatedButton(
                        onPressed: _isLoading ? null : _saveProfile,
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: WhisprTheme.backgroundColor,
                                ),
                              )
                            : const Text('Complete Setup'),
                      )
                      .animate()
                      .fadeIn(delay: 900.ms)
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
}
