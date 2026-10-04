import 'package:flutter/material.dart';
import '../utils/validators.dart';
import '../utils/feedback.dart';

class ChangePasswordForm extends StatefulWidget {
  final Future<void> Function(String current, String next) onSave;
  const ChangePasswordForm({super.key, required this.onSave});
  @override
  State<ChangePasswordForm> createState() => _ChangePasswordFormState();
}

class _ChangePasswordFormState extends State<ChangePasswordForm> {
  final _key = GlobalKey<FormState>();
  final _fields = List.generate(3, (_) => TextEditingController());
  final _hidden = [true, true, true];
  bool _saving = false;
  String? _error;
  @override
  void dispose() {
    for (final field in _fields) {
      field.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_key.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSave(_fields[0].text, _fields[1].text);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _error = AppFeedback.message(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Form(
        key: _key,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Change Password',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            for (var i = 0; i < 3; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextFormField(
                  controller: _fields[i],
                  obscureText: _hidden[i],
                  enabled: !_saving,
                  decoration: InputDecoration(
                    labelText:
                        [
                          'Current Password',
                          'New Password',
                          'Confirm New Password',
                        ][i],
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      tooltip: _hidden[i] ? 'Show password' : 'Hide password',
                      onPressed: () => setState(() => _hidden[i] = !_hidden[i]),
                      icon: Icon(
                        _hidden[i]
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                  validator:
                      (value) =>
                          i == 0
                              ? AppValidators.validateRequired(
                                value,
                                'Current password',
                              )
                              : i == 1
                              ? AppValidators.validatePassword(value)
                              : value != _fields[1].text
                              ? 'Passwords do not match'
                              : null,
                ),
              ),
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            FilledButton(
              onPressed: _saving ? null : _save,
              child:
                  _saving
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Text('Update Password'),
            ),
          ],
        ),
      ),
    ),
  );
}
