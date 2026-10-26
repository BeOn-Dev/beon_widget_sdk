import 'package:flutter/material.dart';
import '../config/beon_config.dart';
import '../utils/validators.dart';
import 'components/powered_by_footer.dart';

/// Internal responsive presentation. Not exported by the SDK public library.
class PreChatTabletLayout extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final BeonConfig config;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController messageController;
  final bool isSubmitting;
  final VoidCallback onSubmit;
  const PreChatTabletLayout({
    super.key,
    required this.formKey,
    required this.config,
    required this.nameController,
    required this.emailController,
    required this.phoneController,
    required this.messageController,
    required this.isSubmitting,
    required this.onSubmit,
  });

  static const _textStyle = TextStyle(
    fontSize: 20,
    height: 1.2,
    fontWeight: FontWeight.w400,
    color: Color(0xFF595959),
  );
  static const _borderColor = Color(0xFFE6E8EB);
  bool get _arabic => config.locale.toLowerCase().startsWith('ar');

  String _label(String english) {
    if (!_arabic) return english;
    return const {
          'Name': 'الاسم',
          'Email': 'البريد الإلكتروني',
          'Phone': 'الهاتف',
          'Message': 'الرسالة',
          'Start Chat': 'بدء المحادثة',
        }[english] ??
        english;
  }

  String? _validation(String? error) {
    if (!_arabic || error == null) return error;
    return const {
          'Name is required': 'الاسم مطلوب',
          'Name must be at least 2 characters': 'يجب ألا يقل الاسم عن حرفين',
          'Phone number is required': 'رقم الهاتف مطلوب',
          'Please enter a valid phone number': 'يرجى إدخال رقم هاتف صالح',
          'Please enter a valid email address': 'يرجى إدخال بريد إلكتروني صالح',
        }[error] ??
        error;
  }

  String? _nameValidator(String? value) =>
      _validation(Validators.validateName(value));
  String? _emailValidator(String? value) =>
      _validation(Validators.validateEmail(value));
  String? _phoneValidator(String? value) =>
      _validation(Validators.validatePhone(value));
  void _onMessageSubmitted(String value) => onSubmit();

  Widget _field({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    FormFieldValidator<String>? validator,
    TextInputType keyboard = TextInputType.text,
    int? maxLines = 1,
    int minLines = 1,
    double height = 48,
    TextInputAction action = TextInputAction.next,
    ValueChanged<String>? onSubmitted,
  }) => TextFormField(
    controller: controller,
    validator: validator,
    keyboardType: keyboard,
    maxLines: maxLines,
    minLines: minLines,
    textInputAction: action,
    onFieldSubmitted: onSubmitted,
    style: _textStyle,
    textAlignVertical: TextAlignVertical.top,
    decoration: InputDecoration(
      hintText: _label(label),
      hintStyle: _textStyle,
      errorStyle: const TextStyle(fontSize: 16),
      isDense: true,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      prefixIconConstraints: BoxConstraints.tightFor(width: 44, height: height),
      prefixIcon: Padding(
        padding: const EdgeInsetsDirectional.only(start: 12, end: 8, top: 12),
        child: Align(
          alignment: AlignmentDirectional.topStart,
          child: Icon(icon, size: 24, color: const Color(0xFF595959)),
        ),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: config.primaryColor),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.red),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(40, 8, 40, 24),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (config.preChatNameEnabled) ...[
                  _field(
                    label: 'Name',
                    icon: Icons.person_outline,
                    controller: nameController,
                    validator: _nameValidator,
                  ),
                  const SizedBox(height: 16),
                ],
                if (config.preChatEmailEnabled) ...[
                  _field(
                    label: 'Email',
                    icon: Icons.email_outlined,
                    controller: emailController,
                    validator: _emailValidator,
                    keyboard: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                ],
                if (config.preChatPhoneEnabled) ...[
                  _field(
                    label: 'Phone',
                    icon: Icons.phone_outlined,
                    controller: phoneController,
                    validator: _phoneValidator,
                    keyboard: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                ],
                if (config.preChatMessageEnabled)
                  _field(
                    label: 'Message',
                    icon: Icons.message_outlined,
                    controller: messageController,
                    maxLines: null,
                    minLines: 6,
                    height: 190,
                    keyboard: TextInputType.multiline,
                    action: TextInputAction.done,
                    onSubmitted: _onMessageSubmitted,
                  ),
                SizedBox(height: config.preChatMessageEnabled ? 40 : 8),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isSubmitting ? null : onSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: config.primaryColor,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: config.primaryColor.withValues(
                        alpha: 0.6,
                      ),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator.adaptive(),
                          )
                        : Text(
                            _label('Start Chat'),
                            style: const TextStyle(
                              fontSize: 20,
                              height: 1.2,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      const PoweredByFooter(),
    ],
  );
}
