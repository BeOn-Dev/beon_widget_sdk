import 'package:flutter/material.dart';
import 'support_style.dart';
import 'support_input_style.dart';

class SupportTicketForm extends StatefulWidget {
  final List<Map<String, dynamic>> categories;
  final SupportStrings strings;
  final Color primaryColor;
  final bool submitting;
  final VoidCallback onBack;
  final Future<bool> Function(
    String categoryId,
    String subject,
    String description,
  )
  onSubmit;
  const SupportTicketForm({
    super.key,
    required this.categories,
    required this.strings,
    required this.primaryColor,
    required this.submitting,
    required this.onBack,
    required this.onSubmit,
  });
  @override
  State<SupportTicketForm> createState() => _SupportTicketFormState();
}

class _SupportTicketFormState extends State<SupportTicketForm> {
  final _form = GlobalKey<FormState>();
  final _subject = TextEditingController();
  final _description = TextEditingController();
  String? _category;
  @override
  void dispose() {
    _subject.dispose();
    _description.dispose();
    super.dispose();
  }

  String? _required(String? value) => value == null || value.trim().isEmpty
      ? widget.strings.text('This field is required', 'هذا الحقل مطلوب')
      : null;
  Future<void> _submit() async {
    if (widget.submitting || !_form.currentState!.validate()) return;
    await widget.onSubmit(
      _category ?? '',
      _subject.text.trim(),
      _description.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    InputDecoration decoration(String label) => SupportInputStyle.decoration(
      primaryColor: widget.primaryColor,
      labelText: label,
    );
    return Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              IconButton(
                onPressed: widget.submitting ? null : widget.onBack,
                icon: const BackButtonIcon(),
              ),
              Expanded(
                child: Text(
                  s.newTicket,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (widget.categories.isNotEmpty) ...[
            DropdownButtonFormField<String>(
              initialValue: _category,
              isExpanded: true,
              style: SupportInputStyle.text,
              decoration: decoration(s.text('Category', 'القسم')),
              dropdownColor: Colors.white,
              items: widget.categories
                  .map(
                    (e) => DropdownMenuItem(
                      value: '${e['id'] ?? e['uuid']}',
                      child: Text('${e['name'] ?? ''}'),
                    ),
                  )
                  .toList(),
              onChanged: widget.submitting
                  ? null
                  : (value) => setState(() => _category = value),
              validator: _required,
            ),
            const SizedBox(height: 16),
          ],
          TextFormField(
            controller: _subject,
            style: SupportInputStyle.text,
            enabled: !widget.submitting,
            validator: _required,
            decoration: decoration(s.text('Subject', 'الموضوع')),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _description,
            style: SupportInputStyle.text,
            enabled: !widget.submitting,
            validator: _required,
            minLines: 4,
            maxLines: 6,
            decoration: decoration(s.text('Description', 'وصف المشكلة')),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 44,
            child: ElevatedButton(
              onPressed: widget.submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: widget.submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator.adaptive(strokeWidth: 2),
                    )
                  : Text(s.newTicket),
            ),
          ),
        ],
      ),
    );
  }
}
