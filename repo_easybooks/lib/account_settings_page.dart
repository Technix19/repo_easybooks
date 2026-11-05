import 'package:flutter/material.dart';
import 'package:repo_easybooks/theme/easybooks_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AccountSettingsPage extends StatefulWidget {
  const AccountSettingsPage({super.key});

  @override
  State<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _organization = TextEditingController();
  final _client = Supabase.instance.client;

  bool _loading = true;
  bool _saving = false;
  bool _profileExists = false;
  bool _signingOut = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _username.dispose();
    _organization.dispose();
    super.dispose();
  }

  String _message(Object error) {
    if (error is PostgrestException) return error.message;
    if (error is AuthException) return error.message;
    return 'Please try again. If this persists, check your connection.';
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });

    try {
      final user = _client.auth.currentUser;
      if (user == null) throw StateError('You must be signed in.');

      final record = await _client
          .from('profile')
          .select('id, username, org_name')
          .eq('user_id', user.id)
          .maybeSingle();

      if (!mounted) return;
      _username.text = (record?['username'] ?? '').toString();
      _organization.text = (record?['org_name'] ?? '').toString();
      setState(() => _profileExists = record != null);
    } catch (error) {
      if (!mounted) return;
      setState(() => _loadError = _message(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    final user = _client.auth.currentUser;
    if (user == null) return;

    setState(() => _saving = true);
    try {
      final fields = {
        'username': _username.text.trim(),
        'org_name': _organization.text.trim(),
      };

      if (_profileExists) {
        // Explicit user filter protects against accidental cross-account writes.
        final updated = await _client
            .from('profile')
            .update(fields)
            .eq('user_id', user.id)
            .select('id')
            .maybeSingle();
        if (updated == null) {
          throw StateError('Your profile could not be updated.');
        }
      } else {
        // The existing EasyBooks database supplies user_id on insertion.
        await _client.from('profile').insert(fields).select('id').single();
      }

      if (!mounted) return;
      setState(() => _profileExists = true);
      FocusScope.of(context).unfocus();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your account settings were saved.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not save your profile: ${_message(error)}'),
          backgroundColor: EasyBooksTheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _changePassword() async {
    final changed = await showDialog<bool>(
      context: context,
      builder: (_) => const _ChangePasswordDialog(),
    );
    if (changed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your password has been updated.')),
      );
    }
  }

  Future<void> _signOut() async {
    if (_signingOut) return;
    setState(() => _signingOut = true);
    try {
      await _client.auth.signOut();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to sign out: ${_message(error)}'),
          backgroundColor: EasyBooksTheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _signingOut = false);
    }
  }

  Widget _section({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: EasyBooksTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: EasyBooksTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              color: EasyBooksTheme.text,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final email = _client.auth.currentUser?.email ?? 'Not available';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontSize: 17)),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Unable to load your profile.'),
                        const SizedBox(height: 8),
                        Text(
                          _loadError!,
                          style: const TextStyle(color: EasyBooksTheme.muted),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        OutlinedButton(
                          onPressed: _loadProfile,
                          child: const Text('Try again'),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 32, 20, 56),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 760),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Account settings',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.6,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Manage the details displayed in your EasyBooks workspace.',
                            style: TextStyle(color: EasyBooksTheme.muted),
                          ),
                          const SizedBox(height: 28),
                          _section(
                            title: 'Profile and organization',
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  TextFormField(
                                    controller: _username,
                                    maxLength: 60,
                                    textInputAction: TextInputAction.next,
                                    decoration: const InputDecoration(
                                      labelText: 'Username',
                                      helperText: 'Shown in your account menu.',
                                    ),
                                    validator: (value) {
                                      final text = (value ?? '').trim();
                                      if (text.length < 2) {
                                        return 'Use at least 2 characters.';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _organization,
                                    maxLength: 100,
                                    textInputAction: TextInputAction.done,
                                    decoration: const InputDecoration(
                                      labelText: 'Organization name',
                                      helperText: 'Shown at the top of your workspace.',
                                    ),
                                    validator: (value) {
                                      if ((value ?? '').trim().isEmpty) {
                                        return 'Enter your organization name.';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Account email',
                                    style: TextStyle(
                                      color: EasyBooksTheme.muted,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  SelectableText(
                                    email,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: EasyBooksTheme.text,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Your email is managed through Supabase authentication.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: EasyBooksTheme.muted,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: FilledButton(
                                      onPressed: _saving ? null : _saveProfile,
                                      style: FilledButton.styleFrom(
                                        backgroundColor: EasyBooksTheme.accent,
                                        foregroundColor: EasyBooksTheme.background,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 22,
                                          vertical: 16,
                                        ),
                                      ),
                                      child: _saving
                                          ? const SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Text('Save changes'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          _section(
                            title: 'Security and session',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Update your password without requesting a new login link.',
                                  style: TextStyle(color: EasyBooksTheme.muted),
                                ),
                                const SizedBox(height: 16),
                                OutlinedButton.icon(
                                  onPressed: _changePassword,
                                  icon: const Icon(Icons.lock_outline, size: 18),
                                  label: const Text('Change password'),
                                ),
                                const SizedBox(height: 20),
                                const Divider(),
                                const SizedBox(height: 14),
                                const Text(
                                  'Sign out of this device when you are finished.',
                                  style: TextStyle(color: EasyBooksTheme.muted),
                                ),
                                const SizedBox(height: 12),
                                TextButton.icon(
                                  onPressed: _signingOut ? null : _signOut,
                                  icon: const Icon(Icons.logout, size: 18),
                                  label: const Text('Sign out'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }
}

class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog();

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _key = GlobalKey<FormState>();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _saving = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _update() async {
    if (_saving || !_key.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: _newPassword.text),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error is AuthException
            ? error.message
            : 'Your password could not be updated. Please try again.';
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change password'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _key,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _newPassword,
                obscureText: _obscure,
                maxLength: 72,
                decoration: InputDecoration(
                  labelText: 'New password',
                  suffixIcon: IconButton(
                    tooltip: _obscure ? 'Show password' : 'Hide password',
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(_obscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined),
                  ),
                ),
                validator: (value) => (value ?? '').length < 8
                    ? 'Use at least 8 characters.'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirmPassword,
                obscureText: _obscure,
                onFieldSubmitted: (_) => _update(),
                decoration: const InputDecoration(
                  labelText: 'Confirm new password',
                ),
                validator: (value) => value != _newPassword.text
                    ? 'Passwords do not match.'
                    : null,
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: const TextStyle(color: EasyBooksTheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _update,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Update password'),
        ),
      ],
    );
  }
}
