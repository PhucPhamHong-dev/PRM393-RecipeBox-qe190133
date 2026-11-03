import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../validators.dart';
import '../widgets/common.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    super.key,
    required this.register,
    required this.onRegistered,
  });
  final bool register;
  final VoidCallback onRegistered;
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _submitted = false;
  bool _busy = false;
  String? _serverError;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _changed(String _) {
    if (_serverError != null) setState(() => _serverError = null);
    if (_submitted) _form.currentState?.validate();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _submitted = true;
      _serverError = null;
    });
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final auth = FirebaseAuth.instance;
      if (widget.register) {
        await auth.createUserWithEmailAndPassword(
          email: _email.text.trim(),
          password: _password.text,
        );
        widget.onRegistered();
      } else {
        await auth.signInWithEmailAndPassword(
          email: _email.text.trim(),
          password: _password.text,
        );
      }
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on FirebaseAuthException catch (error) {
      if (mounted) setState(() => _serverError = error.message ?? error.code);
    } catch (error) {
      if (mounted) {
        setState(
          () => _serverError = 'Could not connect. Please try again. $error',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.register ? 'Register' : 'Login';
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 18),
                  const Icon(
                    Icons.restaurant_menu_rounded,
                    size: 46,
                    color: recipeAccent,
                  ),
                  const SizedBox(height: 22),
                  Text(
                    widget.register
                        ? 'Make room for good food.'
                        : 'Welcome back.',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.register
                        ? 'Create an account for your own private recipe collection.'
                        : 'Your recipes and your next delicious idea are waiting.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 28),
                  ShelfCard(
                    child: Form(
                      key: _form,
                      autovalidateMode: _submitted
                          ? AutovalidateMode.onUserInteraction
                          : AutovalidateMode.disabled,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            key: const ValueKey('auth_email'),
                            controller: _email,
                            enabled: !_busy,
                            keyboardType: TextInputType.emailAddress,
                            autocorrect: false,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.alternate_email),
                            ),
                            validator: Validators.email,
                            onChanged: _changed,
                          ),
                          const SizedBox(height: 18),
                          TextFormField(
                            key: const ValueKey('auth_password'),
                            controller: _password,
                            enabled: !_busy,
                            obscureText: true,
                            autocorrect: false,
                            enableSuggestions: false,
                            textInputAction: widget.register
                                ? TextInputAction.next
                                : TextInputAction.done,
                            decoration: const InputDecoration(
                              labelText: 'Password',
                              prefixIcon: Icon(Icons.lock_outline),
                            ),
                            validator: (value) => Validators.password(
                              value,
                              register: widget.register,
                            ),
                            onChanged: _changed,
                            onFieldSubmitted: (_) {
                              if (!widget.register && !_busy) _submit();
                            },
                          ),
                          if (widget.register) ...[
                            const SizedBox(height: 18),
                            TextFormField(
                              key: const ValueKey('auth_confirm'),
                              controller: _confirm,
                              enabled: !_busy,
                              obscureText: true,
                              autocorrect: false,
                              enableSuggestions: false,
                              textInputAction: TextInputAction.done,
                              decoration: const InputDecoration(
                                labelText: 'Confirm password',
                                prefixIcon: Icon(Icons.lock_outline),
                              ),
                              validator: (value) => Validators.confirmPassword(
                                value,
                                _password.text,
                              ),
                              onChanged: _changed,
                              onFieldSubmitted: (_) {
                                if (!_busy) _submit();
                              },
                            ),
                          ],
                          const SizedBox(height: 24),
                          FilledButton(
                            key: const ValueKey('auth_submit'),
                            onPressed: _busy ? null : _submit,
                            child: _busy
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(title),
                          ),
                          if (_serverError != null) ...[
                            const SizedBox(height: 14),
                            Text(
                              _serverError!,
                              key: const ValueKey('auth_server_error'),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    widget.register
                        ? 'Already have an account? Go back and choose Login.'
                        : 'New here? Go back and choose Register.',
                    textAlign: TextAlign.center,
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
