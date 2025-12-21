import 'package:beon_widget_sdk/src/utils/app_functions/app_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../providers/widget_state.dart';
import '../models/visitor.dart';
import '../utils/validators.dart';
import 'components/chat_header.dart';
import 'components/powered_by_footer.dart';

/// Pre-chat form for collecting visitor information
class PreChatForm extends ConsumerStatefulWidget {
  const PreChatForm({super.key});

  @override
  ConsumerState<PreChatForm> createState() => _PreChatFormState();
}

class _PreChatFormState extends ConsumerState<PreChatForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseConfig = ref.watch(configProvider);
    final effectiveConfigAsync = ref.watch(effectiveConfigProvider);
    final config = effectiveConfigAsync.valueOrNull ?? baseConfig;
    final theme = ref.watch(themeProvider);

    // Fullscreen mode - simple form without card decoration
    if (config.fullScreen) {
      return _buildFullScreenForm(config, theme);
    }

    // Normal mode - card style form
    return Container(
      width: theme.windowWidth,
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        borderRadius: theme.windowBorderRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          ChatHeader(
            title: config.headerTitle ?? 'Welcome!',
            subtitle: config.headerSubtitle ?? 'Fill in the details below to get started',
            primaryColor: theme.primaryColor,
            onClose: () => ref.read(widgetStateProvider.notifier).close(),
            showWave: true,
          ),

          // Form
          Padding(
            padding: const EdgeInsets.all(20),
            child: _buildFormFields(config, theme),
          ),

          const PoweredByFooter(),
        ],
      ),
    );
  }

  /// Fullscreen form layout
  Widget _buildFullScreenForm(dynamic config, dynamic theme) {
    return Column(
      children: [
        // Form content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: _buildFormFields(config, theme),
          ),
        ),

        const PoweredByFooter(),
      ],
    );
  }

  /// Form fields (shared between normal and fullscreen modes)
  Widget _buildFormFields(dynamic config, dynamic theme) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Name field
          if (config.preChatNameEnabled) ...[
            _buildTextField(
              controller: _nameController,
              label: 'Name',
              icon: Icons.person_outline,
              validator: Validators.validateName,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
          ],

          // Email field
          if (config.preChatEmailEnabled) ...[
            _buildTextField(
              controller: _emailController,
              label: 'Email',
              icon: Icons.email_outlined,
              validator: Validators.validateEmail,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
          ],

          // Phone field
          if (config.preChatPhoneEnabled) ...[
            _buildTextField(
              controller: _phoneController,
              label: 'Phone',
              icon: Icons.phone_outlined,
              validator: Validators.validatePhone,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
          ],

          // Message field
          if (config.preChatMessageEnabled) ...[
            _buildTextField(
              controller: _messageController,
              label: 'Message',
              icon: Icons.message_outlined,
              maxLines: 3,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 24),
          ],

          // Spacing if no message field
          if (!config.preChatMessageEnabled)
            const SizedBox(height: 8),

          // Submit button
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: theme.primaryColor.withOpacity(0.6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Start Chat',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    int maxLines = 1,
    void Function(String)? onFieldSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      maxLines: maxLines,
      onFieldSubmitted: onFieldSubmitted,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: ref.watch(themeProvider).primaryColor,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final authService = ref.read(authServiceProvider);
      final chatService = ref.read(chatServiceProvider);

      // Update visitor with form data
      await authService.updateVisitor(PreChatData(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        initialMessage: _messageController.text.trim().isNotEmpty
            ? _messageController.text.trim()
            : null,
      ));

      // Send initial message if provided
      if (_messageController.text.trim().isNotEmpty) {
        await chatService.sendMessage(_messageController.text.trim());
      }

      // Navigate to chat
      ref.read(widgetStateProvider.notifier).goToChat();
    } catch (e) {
      AppFunctions.logPrint(message: "Errroorororooror : ${e.toString()}");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
