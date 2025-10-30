import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart'; // Add this import
import 'style_guide.dart';
import 'ranking_service.dart';
import 'best_times_service.dart';


class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  AuthPageState createState() => AuthPageState();
}

class AuthPageState extends State<AuthPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isLogin = true;
  bool _obscurePassword = true;
  final _formKey = GlobalKey<FormState>();
  
  // Method to create a fresh GoogleSignIn instance
  GoogleSignIn _createFreshGoogleSignIn() {
    return GoogleSignIn(
      scopes: ['email'],
      // Force account selection on every sign-in
      forceCodeForRefreshToken: true,
    );
  }

  // Method to aggressively clear all Google Sign-In sessions
  Future<void> _clearAllGoogleSessions() async {
    // Try with the default instance
    try {
      final GoogleSignIn defaultGoogleSignIn = GoogleSignIn();
      await defaultGoogleSignIn.signOut();
      await defaultGoogleSignIn.disconnect();
    } catch (e) {
      // Ignore errors: session may not exist or already signed out
    }

    // Try with a fresh instance
    try {
      final GoogleSignIn freshGoogleSignIn = _createFreshGoogleSignIn();
      await freshGoogleSignIn.signOut();
      await freshGoogleSignIn.disconnect();
    } catch (e) {
      // Ignore errors: session may not exist or already signed out
    }
  }

  // Check if a Google account already exists in our Firestore database
  Future<bool> _checkIfGoogleAccountExists(String email) async {
    try {
      final QuerySnapshot result = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .get();
      return result.docs.isNotEmpty;
    } catch (e) {
      return false; // If error, assume account doesn't exist
    }
  }

  // Show dialog to collect username for Google account registration
  Future<String?> _showUsernameDialog(String accountName) async {
    final TextEditingController usernameController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    
    return await showDialog<String>(
      context: context,
      barrierDismissible: false, // User must choose
      builder: (BuildContext context) {
        return AlertDialog(
          contentPadding: const EdgeInsets.all(16),
          title: Text(
            _isPortuguese() ? 'Nome de Usuário' : 'Username',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          content: SizedBox(
            width: 280,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: usernameController,
                    decoration: InputDecoration(
                      labelText: _isPortuguese() ? 'Nome de Usuário' : 'Username',
                      hintText: _isPortuguese() ? '5-9 caracteres' : '5-9 characters',
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      isDense: true,
                    ),
                    maxLength: 9,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return _isPortuguese() ? 'Obrigatório' : 'Required';
                      } else if (value.length < 5 || value.length > 9) {
                        return _isPortuguese()
                            ? '5-9 caracteres'
                            : '5-9 characters';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: Text(_isPortuguese() ? 'Cancelar' : 'Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.of(context).pop(usernameController.text);
                }
              },
              child: Text(_isPortuguese() ? 'OK' : 'OK'),
            ),
          ],
        );
      },
    );
  }

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
        if (!mounted) return;
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
        if (!mounted) return;
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
          'unlockedPuzzles': [1], // Novos utilizadores começam apenas com Puzzle 1
        });

        // REMOVIDO: Não sincronizar tempos para novos usuários
        // Novos usuários começam limpos, sem tempos offline de outros usuários

        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/');
      } catch (e) {
        debugPrint('Error: $e');
        if (!mounted) return;
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

      // Migra dados offline para usuário autenticado
      final bestTimesService = BestTimesService();
      await bestTimesService.migrateOfflineData();
      
      // TEMPORARIAMENTE REMOVIDO - estava desbloqueando todos os puzzles
      // final progressService = ProgressService();
      // await progressService.migrateExistingUser();

      Navigator.pushReplacementNamed(context, '/');
    } catch (e) {
      debugPrint('Error: $e');
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
      // Aggressively clear all existing Google sessions first
      await _clearAllGoogleSessions();
      
      // Create a fresh GoogleSignIn instance to avoid cached sessions
      final GoogleSignIn googleSignIn = _createFreshGoogleSignIn();
      
      // Begin interactive sign in process
      final GoogleSignInAccount? gUser = await googleSignIn.signIn();
      
      // If the user cancels the sign-in flow, return
      if (gUser == null) return;
      
      // Check if this Google account is already registered in our app
      final bool accountExists = await _checkIfGoogleAccountExists(gUser.email);
      
      if (_isLogin) {
        // LOGIN FLOW: User wants to log in with existing account
        if (accountExists) {
          // Account exists - proceed with login directly
          await _completeGoogleSignIn(googleSignIn, gUser, null);
        } else {
          // Account doesn't exist - show error message and offer to create account
          await googleSignIn.signOut();
          _showAccountNotFoundDialog(gUser.email);
          return;
        }
      } else {
        // SIGNUP FLOW: User wants to create new account
        if (accountExists) {
          // Account already exists - show error message
          await googleSignIn.signOut();
          _showAccountAlreadyExistsDialog(gUser.email);
          return;
        } else {
          // Account doesn't exist - collect username and create account
          final String? username = await _showUsernameDialog(gUser.displayName ?? gUser.email);
          if (username == null) {
            // User cancelled username input, sign out from Google and return
            await googleSignIn.signOut();
            return;
          }
          
          // Check if username is already taken
          final QuerySnapshot usernameResult = await FirebaseFirestore.instance
              .collection('users')
              .where('username', isEqualTo: username)
              .get();
          
          if (usernameResult.docs.isNotEmpty) {
            _showErrorDialog(_isPortuguese() 
                ? 'Nome de usuário já em uso. Tente novamente com outro nome.'
                : 'Username already in use. Please try again with another name.');
            await googleSignIn.signOut();
            return;
          }
          
          // Complete signup with username
          await _completeGoogleSignIn(googleSignIn, gUser, username);
        }
      }
    } catch (e) {
      debugPrint('Error signing in with Google: $e');
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

  // Helper method to complete Google sign-in process
  Future<void> _completeGoogleSignIn(GoogleSignIn googleSignIn, GoogleSignInAccount gUser, String? username) async {
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
    
    // If this is a new account (signup), save user info to Firestore
    if (username != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
            'username': username,
            'email': userCredential.user?.email ?? '',
            'unlockedPuzzles': [1], // Novos utilizadores começam apenas com Puzzle 1
          });
    }
    
    // Limpa dados compartilhados problemáticos (não sincroniza mais automaticamente)
    final rankingService = RankingService();
    await rankingService.syncOfflineTimesToFirestore();
    
    // Navigate to Collections page
    Navigator.pushReplacementNamed(context, '/');
  }

  // Show dialog when account doesn't exist during login
  void _showAccountNotFoundDialog(String email) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            _isPortuguese() ? 'Conta Não Encontrada' : 'Account Not Found',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.orange,
                  size: 40,
                ),
                const SizedBox(height: 12),
                Text(
                  _isPortuguese()
                      ? 'A conta Google não está vinculada ao Mosaico.'
                      : 'The Google account is not linked to Mosaico.',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  _isPortuguese()
                      ? 'Deseja criar uma nova conta?'
                      : 'Do you want to create a new account?',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                _isPortuguese() ? 'Cancelar' : 'Cancel',
                style: const TextStyle(fontSize: 14),
              ),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.person_add, size: 18),
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _isLogin = false; // Switch to signup mode
                });
              },
              label: Text(
                _isPortuguese() ? 'Criar Conta' : 'Create Account',
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        );
      },
    );
  }

  // Show dialog when account already exists during signup
  void _showAccountAlreadyExistsDialog(String email) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            _isPortuguese() ? 'Conta Já Existe' : 'Account Already Exists',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.account_circle,
                  color: Colors.blue,
                  size: 40,
                ),
                const SizedBox(height: 12),
                Text(
                  _isPortuguese()
                      ? 'A conta Google já está registrada no Mosaico.'
                      : 'The Google account is already registered in Mosaico.',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  _isPortuguese()
                      ? 'Deseja fazer login?'
                      : 'Do you want to log in?',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                _isPortuguese() ? 'Cancelar' : 'Cancel',
                style: const TextStyle(fontSize: 14),
              ),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.login, size: 18),
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _isLogin = true; // Switch to login mode
                });
              },
              label: Text(
                _isPortuguese() ? 'Fazer Login' : 'Log In',
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        );
      },
    );
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