import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:math';
import 'dart:io' show Platform;
import 'style_guide.dart';
import 'ranking_service.dart';
import 'best_times_service.dart';
// import 'welcome_screen.dart';


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
  bool _googleSignInInitialized = false;
  
  /// Navega para home após autenticação
  Future<void> _navigateAfterAuth() async {
    if (!mounted) return;
    
    // Vai direto para home - welcome screen já foi mostrada no início da app
    Navigator.pushReplacementNamed(context, '/home');
  }
  
  @override
  void initState() {
    super.initState();
    _initializeGoogleSignIn();
  }
  
  // Initialize Google Sign-In once at startup
  Future<void> _initializeGoogleSignIn() async {
    if (_googleSignInInitialized) return;
    try {
      await GoogleSignIn.instance.initialize(
        serverClientId: '517915885966-q6e89m2rqiaqjoq49uaqn0no6aov537j.apps.googleusercontent.com',
      );
      _googleSignInInitialized = true;
      debugPrint('Google Sign-In initialized successfully');
    } catch (e) {
      debugPrint('Error initializing Google Sign-In: $e');
    }
  }
  
  // Method to aggressively clear all Google Sign-In sessions
  Future<void> _clearAllGoogleSessions() async {
    // Try with the instance
    try {
      await GoogleSignIn.instance.signOut();
      await GoogleSignIn.instance.disconnect();
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

        await _navigateAfterAuth();
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

      await _navigateAfterAuth();
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
              onPressed: () async {
                Navigator.of(context).pop();
                await _navigateAfterAuth();
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

  // Password reset method
  Future<void> _resetPassword() async {
    final TextEditingController emailController = TextEditingController();
    
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(_isPortuguese() ? 'Recuperar Senha' : 'Reset Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _isPortuguese() 
                    ? 'Digite seu email para receber o link de recuperação de senha.'
                    : 'Enter your email to receive the password reset link.',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: const OutlineInputBorder(),
                  hintText: _isPortuguese() ? 'seu@email.com' : 'your@email.com',
                ),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(_isPortuguese() ? 'Cancelar' : 'Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final email = emailController.text.trim();
                if (email.isEmpty) {
                  _showErrorDialog(_isPortuguese() 
                      ? 'Por favor, digite um email.' 
                      : 'Please enter an email.');
                  return;
                }
                
                try {
                  await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                  Navigator.of(context).pop();
                  _showErrorDialog(_isPortuguese()
                      ? 'Email de recuperação enviado! Verifique sua caixa de entrada.'
                      : 'Password reset email sent! Check your inbox.');
                } catch (e) {
                  Navigator.of(context).pop();
                  String errorMessage = _isPortuguese()
                      ? 'Erro ao enviar email. Verifique se o email está correto.'
                      : 'Error sending email. Please check if the email is correct.';
                  
                  if (e.toString().contains('user-not-found')) {
                    errorMessage = _isPortuguese()
                        ? 'Email não encontrado. Verifique o endereço digitado.'
                        : 'Email not found. Please check the address.';
                  }
                  
                  _showErrorDialog(errorMessage);
                }
              },
              child: Text(_isPortuguese() ? 'Enviar' : 'Send'),
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
      // Make sure Google Sign-In is initialized
      if (!_googleSignInInitialized) {
        await _initializeGoogleSignIn();
      }
      
      // Use the singleton GoogleSignIn instance
      final GoogleSignIn googleSignIn = GoogleSignIn.instance;
      
      // Begin interactive sign in process
      final GoogleSignInAccount gUser;
      try {
        debugPrint('Starting Google authentication...');
        // Use authenticate() with scope hint
        gUser = await googleSignIn.authenticate(
          scopeHint: ['email'],
        );
        debugPrint('Google authentication succeeded!');
      } catch (e) {
        debugPrint('Google authentication failed: $e');
        // User cancelled or authentication failed  
        if (e.toString().contains('SIGN_IN_CANCELLED') || e.toString().contains('cancelled') || e.toString().contains('canceled')) {
          return; // User cancelled - silently return
        }
        rethrow; // Re-throw other errors
      }
      
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
    } catch (e, stackTrace) {
      debugPrint('Error signing in with Google: $e');
      debugPrint('Stack trace: $stackTrace');
      
      String errorMessage = _isPortuguese() 
          ? 'Erro ao fazer login com o Google. Verifique sua conexão e tente novamente.'
          : 'Error signing in with Google. Please check your connection and try again.';
      
      // Provide more specific error message for common issues
      if (e.toString().contains('network_error') || e.toString().contains('NetworkError')) {
        errorMessage = _isPortuguese()
            ? 'Erro de rede. Verifique sua conexão com a internet.'
            : 'Network error. Please check your internet connection.';
      } else if (e.toString().contains('10:') || e.toString().contains('PlatformException')) {
        errorMessage = _isPortuguese()
            ? 'Erro de configuração do Google Sign-In. Detalhes: ${e.toString()}'
            : 'Google Sign-In configuration error. Details: ${e.toString()}';
      }
      
      _showErrorDialog(errorMessage);
    }
  }

  // Helper method to complete Google sign-in process
  Future<void> _completeGoogleSignIn(GoogleSignIn googleSignIn, GoogleSignInAccount gUser, String? username) async {
    try {
      // Obtain auth details using the GoogleSignIn v7.2.0 API
      debugPrint('Getting authentication tokens...');
      
      // Get idToken from authentication property
      final GoogleSignInAuthentication authentication = gUser.authentication;
      debugPrint('Got authentication. idToken: ${authentication.idToken != null ? "exists" : "null"}');
      
      // Get accessToken from authorizationClient
      final GoogleSignInClientAuthorization? authorization = await gUser.authorizationClient.authorizationForScopes(['email']);
      debugPrint('Got authorization. accessToken: ${authorization?.accessToken != null ? "exists" : "null"}');
      
      // Create a new credential for the user
      final credential = GoogleAuthProvider.credential(
        accessToken: authorization?.accessToken,
        idToken: authentication.idToken,
      );
      
      debugPrint('Created Firebase credential, signing in...');
      
      // Sign in with Firebase
      final UserCredential userCredential = 
          await FirebaseAuth.instance.signInWithCredential(credential);
      
      debugPrint('Successfully signed in to Firebase. User: ${userCredential.user?.email}');
      
      // If this is a new account (signup), save user info to Firestore
      if (username != null) {
        debugPrint('Creating new user document in Firestore with username: $username');
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
      
      debugPrint('Navigating to home page...');
      // Navigate to Collections page or welcome screen
      await _navigateAfterAuth();
    } catch (e, stackTrace) {
      debugPrint('Error in _completeGoogleSignIn: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Add Sign in with Apple method
  Future<void> _signInWithApple() async {
    try {
      // Generate nonce for security
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      // Request Apple ID credential
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
        // Required for Android - web authentication
        webAuthenticationOptions: WebAuthenticationOptions(
          clientId: 'com.mosaico.signin.firebase', // Service ID from Apple Developer
          redirectUri: Uri.parse('https://muzaico-bb279.firebaseapp.com/__/auth/handler'),
        ),
      );

      // Create OAuth credential for Firebase
      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
        accessToken: appleCredential.authorizationCode,
      );

      // Sign in to Firebase
      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(oauthCredential);

      debugPrint('Successfully signed in with Apple. User: ${userCredential.user?.email}');

      // Check if this is a new user
      final user = userCredential.user;
      
      if (user == null) return;

      // Check if user document exists in Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        // New user - need to collect username
        String? displayName;
        
        // Try to get name from Apple credential
        if (appleCredential.givenName != null && appleCredential.familyName != null) {
          displayName = '${appleCredential.givenName} ${appleCredential.familyName}';
        } else if (appleCredential.givenName != null) {
          displayName = appleCredential.givenName;
        }
        
        final String? username = await _showUsernameDialog(
          displayName ?? user.email ?? 'User',
        );
        
        if (username == null) {
          // User cancelled - sign out and delete account
          await user.delete();
          await FirebaseAuth.instance.signOut();
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
          await user.delete();
          await FirebaseAuth.instance.signOut();
          return;
        }

        // Create user document
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({
          'username': username,
          'email': user.email ?? '',
          'unlockedPuzzles': [1],
        });
      }

      // Sync offline data
      final rankingService = RankingService();
      await rankingService.syncOfflineTimesToFirestore();

      debugPrint('Navigating to home page...');
      await _navigateAfterAuth();
      
    } catch (e, stackTrace) {
      debugPrint('Error signing in with Apple: $e');
      debugPrint('Stack trace: $stackTrace');

      // Handle user cancellation
      if (e.toString().contains('AuthorizationErrorCode.canceled') ||
          e.toString().contains('1001')) {
        // User cancelled - silently return
        return;
      }

      String errorMessage = _isPortuguese()
          ? 'Erro ao fazer login com Apple. Verifique sua conexão e tente novamente.'
          : 'Error signing in with Apple. Please check your connection and try again.';

      _showErrorDialog(errorMessage);
    }
  }

  // Generate nonce for Apple Sign In
  String _generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  // SHA256 hash for nonce
  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
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
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(), // Fecha o teclado ao tocar fora
      child: Scaffold(
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
                const SizedBox(height: 40), // Distância de 40px do topo
                Center(
                  child: Column(
                    children: [
                      SizedBox(
                        width: 120,
                        height: 120,
                        child: Image.asset(
                          'assets/images/icon.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'MOSAICO',
                        style: AppStyles.title(context).copyWith(
                          fontSize: 32,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : const Color.fromARGB(255, 3, 104, 197),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40), // Distância de 48px do elemento seguinte
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
                
                // Forgot password button (only show on login screen)
                if (_isLogin)
                  TextButton(
                    onPressed: _resetPassword,
                    child: Text(
                      _isPortuguese() ? 'Esqueceu a senha?' : 'Forgot password?',
                      style: AppStyles.subtitle(context).copyWith(
                        decoration: TextDecoration.underline,
                      ),
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
                
                // Add Google Sign-In button
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
                
                const SizedBox(height: 12),
                
                // Add Sign in with Apple button (iOS only)
                if (Platform.isIOS) ...[
                  ElevatedButton.icon(
                    icon: const Icon(Icons.apple, size: 24, color: Colors.white),
                    label: Text(
                      _isPortuguese() ? 'Continuar com Apple' : 'Continue with Apple',
                      overflow: TextOverflow.ellipsis,
                      style: AppStyles.buttonText(context, fontSize: 16).copyWith(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    onPressed: _signInWithApple,
                  ),
                  const SizedBox(height: 12),
                ],
                
                const SizedBox(height: 4),
                
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
      ),
    );
  }
}
