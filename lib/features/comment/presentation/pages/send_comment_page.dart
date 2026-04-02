import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../cubits/comment_cubit.dart';
import '../cubits/comment_state.dart';

class SendCommentPage extends StatefulWidget {
  final String uid;
  final String? username;

  const SendCommentPage({
    super.key,
    required this.uid,
    this.username,
  });

  @override
  State<SendCommentPage> createState() => _SendCommentPageState();
}

class _SendCommentPageState extends State<SendCommentPage> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();
  int _charCount = 0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() => _charCount = _controller.text.length);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = widget.username != null
        ? 'Написать @${widget.username}'
        : 'Написать анонимно';

    return BlocListener<CommentCubit, CommentState>(
      listener: (context, state) {
        if (state is CommentSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Сообщение отправлено анонимно'),
              backgroundColor: AppColors.success,
            ),
          );
          context.pop();
        } else if (state is CommentError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text(label)),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Disclaimer
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.shield_outlined,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Ваше сообщение будет анонимным. Получатель не узнает, кто его отправил.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Text field
                  TextFormField(
                    controller: _controller,
                    validator: Validators.comment,
                    maxLength: AppConstants.commentMaxLength,
                    maxLines: 6,
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: 'Напишите что-нибудь...',
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '$_charCount / ${AppConstants.commentMaxLength}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: _charCount > AppConstants.commentMaxLength
                            ? AppColors.error
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ),
                  const Spacer(),
                  BlocBuilder<CommentCubit, CommentState>(
                    builder: (context, state) {
                      return AppButton(
                        label: 'Отправить анонимно',
                        isLoading: state is CommentSending,
                        onPressed: () {
                          if (_formKey.currentState?.validate() ?? false) {
                            context.read<CommentCubit>().sendComment(
                                  boardOwnerId: widget.uid,
                                  text: _controller.text,
                                );
                          }
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
