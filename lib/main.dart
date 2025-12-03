import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'auth_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'home_screen.dart';
import 'settings_controller.dart';
import 'welcome_screen.dart';

// 1. Inicializa o Firebase e executa o aplicativo.
void main() async {
	WidgetsFlutterBinding.ensureInitialized();
	await WelcomeScreen.resetSessionFlag(); // <-- Para efeitos de debug para ver o Walkthrough. Remover antes de deploy
	await SystemChrome.setPreferredOrientations([
		DeviceOrientation.portraitUp,
		DeviceOrientation.portraitDown,
	]);
	await Firebase.initializeApp(
		options: DefaultFirebaseOptions.currentPlatform,
	);
	final showWelcome = await WelcomeScreen.shouldShow();
	runApp(
		ChangeNotifierProvider(
			create: (_) => SettingsController(),
			child: MyApp(showWelcome: showWelcome),
		),
	);
}

class MyApp extends StatelessWidget {
	final bool showWelcome;
	const MyApp({super.key, required this.showWelcome});

	@override
	Widget build(BuildContext context) {
		final settings = Provider.of<SettingsController>(context);
		return MaterialApp(
			title: 'Mosaico',
			theme: ThemeData(
				primaryColor: const Color.fromRGBO(209, 217, 239, 1.0),
				brightness: settings.isDarkMode ? Brightness.dark : Brightness.light,
			),
			locale: settings.locale,
			supportedLocales: const [
				Locale('en', 'US'),
				Locale('pt', 'BR'),
			],
			localizationsDelegates: const [
				GlobalMaterialLocalizations.delegate,
				GlobalWidgetsLocalizations.delegate,
				GlobalCupertinoLocalizations.delegate,
			],
			initialRoute: '/',
			routes: {
				'/': (context) => showWelcome
						? const WelcomeScreen()
						: HomeScreen(
								userName: 'Jogador',
								currentLevel: 1,
								maxLevel: 10,
								totalPoints: 0,
							),
				'/auth': (context) => AuthPage(),
				'/home': (context) => HomeScreen(
					userName: 'Jogador',
					currentLevel: 1,
					maxLevel: 10,
					totalPoints: 0,
				),
				'/welcome': (context) => const WelcomeScreen(),
			},
		);
	}
}

// 3. Widget que determina qual tela inicial mostrar
class InitialRouteHandler extends StatefulWidget {
	const InitialRouteHandler({super.key});

	@override
	State<InitialRouteHandler> createState() => _InitialRouteHandlerState();
}

class _InitialRouteHandlerState extends State<InitialRouteHandler> {
	@override
	void initState() {
		super.initState();
		_checkAndNavigate();
	}

	Future<void> _checkAndNavigate() async {
		// Verifica se deve mostrar a tela de boas-vindas
		final shouldShowWelcome = await WelcomeScreen.shouldShow();
    
		if (!mounted) return;
    
		if (shouldShowWelcome) {
			Navigator.of(context).pushReplacementNamed('/welcome');
		} else {
			Navigator.of(context).pushReplacementNamed('/home');
		}
	}

	@override
	Widget build(BuildContext context) {
		// Mostra um loading enquanto verifica
		return const Scaffold(
			body: Center(
				child: CircularProgressIndicator(),
			),
		);
	}
}

	// Todo o código de rotas/widgets abaixo foi comentado temporariamente para evitar erros de sintaxe
	/*
	class MyHomePage extends StatefulWidget {
		// ...
	}
	class _MyHomePageState extends State<MyHomePage> {
		// ...
	}
	*/

