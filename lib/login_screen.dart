import 'package:flutter/material.dart';
import 'auth.dart';
import 'expense.dart';
import 'home_shell.dart';

// One screen for both "Log in" and "Sign up"
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  bool isSignUp = false;
  bool hidePassword = true;
  bool loading = false;
  String? errorMessage;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  void switchMode() {
    setState(() {
      isSignUp = !isSignUp;
      errorMessage = null;
    });
    formKey.currentState?.reset();
  }

  void submit() async {
    FocusScope.of(context).unfocus();
    if (!formKey.currentState!.validate()) return;

    setState(() {
      loading = true;
      errorMessage = null;
    });

    String? error = isSignUp
        ? await signUp(
            nameController.text, emailController.text, passwordController.text)
        : await logIn(emailController.text, passwordController.text);

    if (error == null) {
      await loadExpenses();
    }
    if (!mounted) return;

    if (error != null) {
      setState(() {
        loading = false;
        errorMessage = error;
      });
      return;
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Colored header with the logo
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 72, 24, 40),
              decoration: const BoxDecoration(
                gradient: brandGradient,
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(32)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Icon(Icons.account_balance_wallet_rounded,
                        size: 44, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  const Text('Spendly',
                      style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  const SizedBox(height: 6),
                  const Text('Track every rupee, reach every goal',
                      style: TextStyle(color: Colors.white70, fontSize: 15)),
                ],
              ),
            ),

            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(isSignUp ? 'Create account' : 'Welcome back',
                            style: const TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(
                          isSignUp
                              ? 'Sign up to start tracking your expenses'
                              : 'Log in to continue to your account',
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 24),

                        if (isSignUp) ...[
                          TextFormField(
                            controller: nameController,
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Full name',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().length < 2) {
                                return 'Please enter your name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                        ],

                        TextFormField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.mail_outline),
                          ),
                          validator: validateEmail,
                        ),
                        const SizedBox(height: 14),

                        TextFormField(
                          controller: passwordController,
                          obscureText: hidePassword,
                          textInputAction: isSignUp
                              ? TextInputAction.next
                              : TextInputAction.done,
                          onFieldSubmitted: (_) {
                            if (!isSignUp) submit();
                          },
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              tooltip: hidePassword
                                  ? 'Show password'
                                  : 'Hide password',
                              icon: Icon(hidePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined),
                              onPressed: () {
                                setState(() {
                                  hidePassword = !hidePassword;
                                });
                              },
                            ),
                          ),
                          validator: validatePassword,
                        ),

                        if (isSignUp) ...[
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: confirmController,
                            obscureText: hidePassword,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => submit(),
                            decoration: const InputDecoration(
                              labelText: 'Confirm password',
                              prefixIcon: Icon(Icons.lock_outline),
                            ),
                            validator: (value) {
                              if (value != passwordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                        ],

                        if (errorMessage != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline,
                                    color: Colors.red),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(errorMessage!,
                                      style:
                                          const TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: loading ? null : submit,
                          child: loading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.5, color: Colors.white),
                                )
                              : Text(isSignUp ? 'Create Account' : 'Log In'),
                        ),
                        const SizedBox(height: 16),
                        // Wrap instead of Row so it never overflows
                        // on small screens or with large text
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(isSignUp
                                ? 'Already have an account?'
                                : "Don't have an account?"),
                            TextButton(
                              onPressed: loading ? null : switchMode,
                              child: Text(isSignUp ? 'Log in' : 'Sign up'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.phone_android,
                                size: 14, color: Colors.grey),
                            SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Your account and data are saved on this device.',
                                style:
                                    TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
