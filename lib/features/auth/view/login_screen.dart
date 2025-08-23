import 'package:flutter/material.dart';
import 'package:key_budget/features/auth/view/register_screen.dart';
import 'package:provider/provider.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryBiometricAuth();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _tryBiometricAuth() async {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);

    if (authViewModel.currentUser == null) {
      final success = await authViewModel.authenticateWithBiometrics();
      if (success && mounted) {

      }
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);

    final success = await authViewModel.loginUser(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (mounted && !success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authViewModel.errorMessage ?? 'Erro desconhecido'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) => (value == null || !value.contains('@'))
                      ? 'Insira um email válido'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Senha'),
                  obscureText: true,
                  validator: (value) => (value == null || value.isEmpty)
                      ? 'Insira sua senha'
                      : null,
                ),
                const SizedBox(height: 24),
                Consumer<AuthViewModel>(
                  builder: (context, viewModel, child) {
                    return viewModel.isLoading
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                      onPressed: _submit,
                      child: const Text('Entrar'),
                    );
                  },
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const RegisterScreen()),
                    );
                  },
                  child: const Text('Não tem uma conta? Cadastre-se'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}