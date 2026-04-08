import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../cubits/auth_cubit.dart';

class CreateProfilePage extends StatefulWidget {
  const CreateProfilePage({super.key});

  @override
  State<CreateProfilePage> createState() => _CreateProfilePageState();
}

class _CreateProfilePageState extends State<CreateProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _bioController = TextEditingController();

  bool _isCheckingUsername = false;
  bool? _isUsernameAvailable;
  String? _usernameValidationError;
  Timer? _debounce;

  @override
  void dispose() {
    _usernameController.dispose();
    _displayNameController.dispose();
    _bioController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onUsernameChanged(String value) {
    _debounce?.cancel();
    if (value.length < AppConstants.usernameMinLength) {
      setState(() => _isUsernameAvailable = null);
      return;
    }
    setState(() {
      _isCheckingUsername = true;
      _isUsernameAvailable = null;
    });
    _debounce = Timer(
      const Duration(milliseconds: AppConstants.searchDebounceMs),
      () => _checkUsername(value),
    );
  }

  Future<void> _checkUsername(String username) async {
    final validationError = Validators.username(username);
    if (validationError != null) {
      setState(() {
        _isCheckingUsername = false;
        _isUsernameAvailable = null;
        _usernameValidationError = validationError;
      });
      return;
    }

    // Clear validation error if username is valid
    setState(() => _usernameValidationError = null);

    try {
      final available = await context
          .read<AuthCubit>()
          .isUsernameAvailable(username.toLowerCase().trim());
      if (mounted) {
        setState(() {
          _isCheckingUsername = false;
          _isUsernameAvailable = available;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isCheckingUsername = false);
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_isUsernameAvailable != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите доступный никнейм')),
      );
      return;
    }

    context.read<AuthCubit>().createProfile(
          username: _usernameController.text.trim().toLowerCase(),
          displayName: _displayNameController.text.trim(),
          bio: _bioController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Создать профиль')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Расскажите о себе', style: theme.textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text('Ник нельзя будет изменить позже',
                    style: theme.textTheme.bodySmall),
                const SizedBox(height: 32),
                // Username
                AppTextField(
                  label: 'Никнейм',
                  hint: 'только a-z, 0-9, _',
                  controller: _usernameController,
                  onChanged: _onUsernameChanged,
                  validator: Validators.username,
                  maxLength: AppConstants.usernameMaxLength,
                  suffix: _buildUsernameSuffix(),
                ),
                if (_usernameValidationError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 4),
                    child: Text(
                      _usernameValidationError!,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: AppColors.error),
                    ),
                  ),
                if (_isUsernameAvailable == false &&
                    _usernameValidationError == null &&
                    !_isCheckingUsername)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 4),
                    child: Text('Никнейм занят',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: AppColors.error)),
                  ),
                if (_isUsernameAvailable == true)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 4),
                    child: Text('Никнейм свободен',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: AppColors.success)),
                  ),
                const SizedBox(height: 16),
                // Display name
                AppTextField(
                  label: 'Отображаемое имя',
                  hint: 'Как вас называть?',
                  controller: _displayNameController,
                  validator: Validators.displayName,
                  maxLength: AppConstants.displayNameMaxLength,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                // Bio
                AppTextField(
                  label: 'О себе',
                  hint: 'Расскажите немного о себе...',
                  controller: _bioController,
                  validator: Validators.bio,
                  maxLength: AppConstants.bioMaxLength,
                  maxLines: 3,
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 32),
                AppButton(
                  label: 'Создать профиль',
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget? _buildUsernameSuffix() {
    if (_isCheckingUsername) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    if (_isUsernameAvailable == true) {
      return const Icon(Icons.check_circle, color: AppColors.success);
    }
    if (_isUsernameAvailable == false) {
      return const Icon(Icons.cancel, color: AppColors.error);
    }
    return null;
  }
}
