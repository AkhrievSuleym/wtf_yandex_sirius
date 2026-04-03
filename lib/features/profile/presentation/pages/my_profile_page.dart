import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../navigation/route_names.dart';
import '../../../auth/presentation/cubits/auth_cubit.dart';
import '../../../auth/presentation/cubits/auth_state.dart';
import '../cubits/profile_cubit.dart';
import '../cubits/profile_state.dart';
import '../widgets/profile_header.dart';

class MyProfilePage extends StatefulWidget {
  const MyProfilePage({super.key});

  @override
  State<MyProfilePage> createState() => _MyProfilePageState();
}

class _MyProfilePageState extends State<MyProfilePage> {
  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      context.read<ProfileCubit>().loadProfile(authState.user.uid);
    }
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );
    if (file != null && mounted) {
      context.read<ProfileCubit>().updateProfile(avatarPath: file.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мой профиль'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.goNamed(RouteNames.settings),
          ),
        ],
      ),
      body: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, state) {
          return switch (state) {
            ProfileInitial() || ProfileLoading() => const LoadingIndicator(),
            ProfileError(:final message) => AppErrorWidget(
                message: message,
                onRetry: () {
                  final authState = context.read<AuthCubit>().state;
                  if (authState is AuthAuthenticated) {
                    context.read<ProfileCubit>().loadProfile(authState.user.uid);
                  }
                },
              ),
            ProfileLoaded(:final profile) ||
            ProfileUpdating(:final profile) =>
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    ProfileHeader(
                      profile: profile,
                      onAvatarTap: state is ProfileUpdating ? null : _pickAvatar,
                    ),
                    if (state is ProfileUpdating)
                      const Padding(
                        padding: EdgeInsets.all(8),
                        child: LinearProgressIndicator(),
                      ),
                    const Divider(),
                    _EditSection(profile: profile),
                  ],
                ),
              ),
          };
        },
      ),
    );
  }
}

class _EditSection extends StatefulWidget {
  final dynamic profile;

  const _EditSection({required this.profile});

  @override
  State<_EditSection> createState() => _EditSectionState();
}

class _EditSectionState extends State<_EditSection> {
  late final _displayNameController =
      TextEditingController(text: widget.profile.displayName);
  late final _bioController =
      TextEditingController(text: widget.profile.bio);
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Редактировать',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 20),
            TextFormField(
              controller: _displayNameController,
              validator: Validators.displayName,
              maxLength: AppConstants.displayNameMaxLength,
              decoration: const InputDecoration(labelText: 'Отображаемое имя'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _bioController,
              validator: Validators.bio,
              maxLength: AppConstants.bioMaxLength,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'О себе'),
            ),
            const SizedBox(height: 20),
            AppButton(
              label: 'Сохранить изменения',
              onPressed: () {
                if (_formKey.currentState?.validate() ?? false) {
                  context.read<ProfileCubit>().updateProfile(
                        displayName: _displayNameController.text,
                        bio: _bioController.text,
                      );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
