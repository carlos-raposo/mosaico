import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart'; // Add this import
import 'style_guide.dart';
import 'package:google_fonts/google_fonts.dart';

class AuthPage extends StatefulWidget {
  @override
  _AuthPageState createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isLogin = true;
  bool _obscurePassword = true;
  final _formKey = GlobalKey<FormState>();

  void _toggleFormType() {
    setState(() {
      _isLogin = !_isLogin;
    });
  }

  Future<void> _createAccount() async {
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text.length < 6) {
        _showErrorDialog(_isPortuguese() ? 'A senha deve ter no mínimo 6 caracteres' : 'Password must be at least 6 characters long');
        return;
      }
      if (_passwordController.text != _confirmPasswordController.text) {
        _showErrorDialog(_isPortuguese() ? 'As senhas não coincidem' : 'Passwords do not match');
        return;
      }

      // Verificar se o nome de usuário já está em uso
      final QuerySnapshot usernameResult = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: _usernameController.text)
          .get();
      final List<DocumentSnapshot> usernameDocuments = usernameResult.docs;
      if (usernameDocuments.isNotEmpty) {
        _showErrorDialog(_isPortuguese() ? 'Nome de usuário já em uso. Escolha outro.' : 'Username already in use. Choose another.');
        return;
      }

      // Verificar se o email já está em uso
      final QuerySnapshot emailResult = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: _emailController.text)
          .get();
      final List<DocumentSnapshot> emailDocuments = emailResult.docs;
      if (emailDocuments.isNotEmpty) {
        _showErrorDialog(_isPortuguese() ? 'Email já em uso. Escolha outro.' : 'Email already in use. Choose another.');
        return;
      }

      try {
        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );

        await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
          'username': _usernameController.text,
          'email': _emailController.text,
        });

        Navigator.pushReplacementNamed(context, '/');
      } catch (e) {
        print('Error: $e');
        _showErrorDialog(e.toString());
      }
    }
  }

  Future<void> _login() async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      Navigator.pushReplacementNamed(context, '/');
    } catch (e) {
      print('Error: $e');
      _showErrorDialog(e.toString());
    }
  }

  void _startWithoutAuth() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(_isPortuguese() ? 'Aviso' : 'Warning'),
          content: Text(_isPortuguese()
              ? 'Se entrar sem autentificação não poderá registar nem ver os melhores tempos no ranking global.'
              : 'If you enter without authentication, you will not be able to register or see the best times in the global ranking.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(_isPortuguese() ? 'Autentificar' : 'Authenticate'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacementNamed(context, '/');
              },
              child: Text(_isPortuguese() ? 'Continuar' : 'Continue'),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(_isPortuguese() ? 'Aviso' : 'Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  bool _isPortuguese() {
    return Localizations.localeOf(context).languageCode == 'pt';
  }

  // Add Google Sign In method
  Future<void> _signInWithGoogle() async {
    try {
      // Begin interactive sign in process
      final GoogleSignInAccount? gUser = await GoogleSignIn().signIn();
      
      // If the user cancels the sign-in flow, return
      if (gUser == null) return;
      
      // Obtain auth details from request
      final GoogleSignInAuthentication gAuth = await gUser.authentication;
      
      // Create a new credential for the user
      final credential = GoogleAuthProvider.credential(
        accessToken: gAuth.accessToken,
        idToken: gAuth.idToken,
      );
      
      // Sign in with Firebase
      final UserCredential userCredential = 
          await FirebaseAuth.instance.signInWithCredential(credential);
      
      // Check if this is a new user (first time sign in)
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        // Save user info to Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
              'username': userCredential.user?.displayName?.substring(0, 
                  userCredential.user!.displayName!.length > 9 ? 9 : userCredential.user!.displayName!.length) 
                  ?? 'User${userCredential.user!.uid.substring(0, 5)}',
              'email': userCredential.user?.email ?? '',
            });
      }
      
      // Navigate to Collections page
      Navigator.pushReplacementNamed(context, '/');
    } catch (e) {
      print('Error signing in with Google: $e');
      String errorMessage = _isPortuguese() 
          ? 'Erro ao fazer login com o Google. Verifique sua conexão e tente novamente.'
          : 'Error signing in with Google. Please check your connection and try again.';
      
      // Provide more specific error message for common issues
      if (e.toString().contains('network_error')) {
        errorMessage = _isPortuguese()
            ? 'Erro de rede. Verifique sua conexão com a internet.'
            : 'Network error. Please check your internet connection.';
      } else if (e.toString().contains('10:')) {
        errorMessage = _isPortuguese()
            ? 'Erro de configuração. Por favor, contate o suporte.'
            : 'Configuration error. Please contact support.';
      }
      
      _showErrorDialog(errorMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isLogin ? 'Login' : 'Create Account',
          style: AppStyles.title(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40), // Distância de 50px do topo
                Text(
                  'MOSAICO',
                  style: AppStyles.title(context).copyWith(
                    fontSize: 32,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : const Color.fromARGB(255, 3, 104, 197),
                  ),
                ),
                const SizedBox(height: 48), // Distância de 40px do elemento seguinte
                if (!_isLogin)
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(labelText: 'Username'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return _isPortuguese() ? 'Nome de usuário é obrigatório' : 'Username is required';
                      } else if (value.length < 5 || value.length > 9) {
                        return _isPortuguese()
                            ? 'Nome de usuário deve ter entre 5 e 9 letras'
                            : 'Username must be between 5 and 9 characters';
                      }
                      return null;
                    },
                  ),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return _isPortuguese() ? 'Email é obrigatório' : 'Email is required';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  obscureText: _obscurePassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return _isPortuguese() ? 'Senha é obrigatória' : 'Password is required';
                    } else if (value.length < 6) {
                      return _isPortuguese() ? 'A senha deve ter no mínimo 6 caracteres' : 'Password must be at least 6 characters long';
                    }
                    return null;
                  },
                ),
                if (!_isLogin)
                  TextFormField(
                    controller: _confirmPasswordController,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    obscureText: _obscurePassword,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return _isPortuguese() ? 'Confirmação de senha é obrigatória' : 'Confirm Password is required';
                      } else if (value != _passwordController.text) {
                        return _isPortuguese() ? 'As senhas não coincidem' : 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isLogin ? _login : _createAccount,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.buttonBgWhite
                        : AppColors.buttonBgWhite,
                  ),
                  child: Text(
                    _isLogin ? 'Login' : 'Create Account',
                    style: AppStyles.buttonText(context, fontSize: 16),
                  ),
                ),
                TextButton(
                  onPressed: _toggleFormType,
                  child: Text(
                    _isLogin ? 'Create an account' : 'Have an account? Login',
                    style: AppStyles.subtitle(context),
                  ),
                ),
                
                // Add a divider to separate standard login from Google login
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(_isPortuguese() ? 'ou' : 'or'),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                ),
                
                // Add Google Sign-In button with local icon instead of network image
                ElevatedButton.icon(
                  icon: const Icon(Icons.g_mobiledata, size: 24, color: Colors.blue),
                  label: Text(
                    _isPortuguese() ? 'Continuar com Google' : 'Continue with Google',
                    overflow: TextOverflow.ellipsis,
                    style: AppStyles.buttonText(context, fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  onPressed: _signInWithGoogle,
                ),
                
                const SizedBox(height: 16),
                
                TextButton(
                  onPressed: _startWithoutAuth,
                  child: Text(
                    _isPortuguese() 
                      ? 'Iniciar sem autenticação' 
                      : 'Start without authentication',
                    style: AppStyles.subtitle(context),
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