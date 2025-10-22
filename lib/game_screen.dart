import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:confetti/confetti.dart';
import 'dart:async';
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
// Removed unused imports

import 'ranking_service.dart';
import 'style_guide.dart';
import 'package:provider/provider.dart';
import 'settings_controller.dart';
import 'settings_page.dart';
// Removed unused import

class GameScreen extends StatefulWidget {
  final String title;
  final String puzzlePath;
  final int rows;
  final int cols;
  final ConfettiController confettiController;
  final Locale locale;
  final bool isAuthenticated;
  final bool isDarkMode;
  // Removido: final bool soundEnabled;
  final VoidCallback? onExit;

  const GameScreen({
    super.key,
    required this.title,
    required this.puzzlePath,
    required this.rows,
    required this.cols,
    required this.confettiController,
    required this.locale,
    required this.isAuthenticated,
    required this.isDarkMode,
  // Removido: required this.soundEnabled,
    this.onExit,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  // Controla animação de borda para cada peça
  List<bool> _highlightedPieces = [];
  late List<String?> _sections;
  late List<String?> _images;
  late String _currentPuzzlePath;
  late int _rows;
  late int _cols;
  late int _gridSize;
  bool _isPlaying = false;
  Timer? _timer;
  Timer? _shuffleTimer;
  int _elapsedSeconds = 0;
  final Map<String, int> _bestTimes = {};
  final AudioPlayer _audioPlayer = AudioPlayer();
  // Removido: bool _soundEnabled = true;
  // Removed unused variable _isResumed

  @override
  void initState() {
    super.initState();
    _currentPuzzlePath = widget.puzzlePath;
    _rows = widget.rows;
    _cols = widget.cols;
    _gridSize = widget.cols;
    _images = List.generate(_rows * _cols, (index) => '$_currentPuzzlePath/${index + 1}.png');
    _sections = List.generate(_rows * _cols, (index) {
      final row = index ~/ _cols;
      final col = index % _cols;
      return String.fromCharCode(97 + row) + (col + 1).toString();
    });
  _highlightedPieces = List.generate(_rows * _cols, (index) => false);
    _loadBestTimes();
    _startShuffleAnimation();
  }

  Future<void> _loadBestTimes() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('bestTimes');
    if (stored != null) {
      final decoded = Map<String, dynamic>.from(jsonDecode(stored));
      decoded.forEach((key, value) {
        _bestTimes[key] = value as int;
      });
    }
  }

  // Removed unused _saveBestTimes

  void _shuffleSections() {
    setState(() {
      _images.shuffle();
      _isPlaying = true;
      _stopShuffleAnimation();
      _startTimer();
    });
  }

  void _resetSections() {
    setState(() {
      _images = List.generate(_rows * _cols, (index) => '$_currentPuzzlePath/${index + 1}.png');
      _sections = List.generate(_rows * _cols, (index) {
        final row = index ~/ _cols;
        final col = index % _cols;
        return String.fromCharCode(97 + row) + (col + 1).toString();
      });
      _isPlaying = false;
      _stopTimer();
      _stopShuffleAnimation();
      _elapsedSeconds = 0;
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedSeconds++;
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
  }

  void _pauseGame() {
    setState(() {
      _isPlaying = false;
      _stopTimer();
      _stopShuffleAnimation();
    });
  }

  void _resumeGame() {
    setState(() {
      _isPlaying = true;
      _stopShuffleAnimation();
      _startTimer();
    });
  }

  void _stopGame() {
    setState(() {
      _isPlaying = false;
      _stopTimer();
      _stopShuffleAnimation();
      _images = List.generate(_rows * _cols, (index) => '$_currentPuzzlePath/${index + 1}.png');
      _elapsedSeconds = 0;
    });
    if (widget.onExit != null) widget.onExit!();
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    if (minutes > 0) {
      return '$minutes:${remainingSeconds.toString().padLeft(2, '0')} ${widget.locale.languageCode == 'pt' ? 'min.' : 'min.'}';
    } else {
      return '$seconds ${widget.locale.languageCode == 'pt' ? 'seg.' : 'sec.'}';
    }
  }

  bool _isPuzzleComplete() {
    for (int i = 0; i < _sections.length; i++) {
      if (_images[i] != '$_currentPuzzlePath/${i + 1}.png') {
        return false;
      }
    }
    return true;
  }

  void _checkPuzzleCompletion() async {
    if (_isPuzzleComplete()) {
      setState(() {
        _isPlaying = false;
        _stopTimer();
      });
      final soundEnabled = Provider.of<SettingsController>(context, listen: false).soundEnabled;
      if (soundEnabled) {
        _audioPlayer.play(AssetSource('audio/bell2.mp3'));
      }
      if (widget.isAuthenticated) {
        // puzzleId e puzzleName são iguais e únicos para cada puzzle
        String puzzleId = widget.title;
        String puzzleName = widget.title;
        final rankingService = RankingService();
        // Salva o melhor tempo do usuário logado
        await rankingService.updateUserBestTime(puzzleId, _elapsedSeconds);
        final isTopTime = await rankingService.updateRanking(puzzleId, puzzleName, _elapsedSeconds);
        if (isTopTime) {
          widget.confettiController.play();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(widget.locale.languageCode == 'pt' ? 'Parabéns! Você bateu o recorde do ranking global' : 'Congratulations! You set the global ranking record!')),
          );
          return;
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Puzzle completed in ${_formatTime(_elapsedSeconds)}')),
      );
    }
  }

  void _playSound(int correctPositions) async {
    final soundEnabled = Provider.of<SettingsController>(context, listen: false).soundEnabled;
    if (soundEnabled) {
      if (correctPositions == 1) {
        await _audioPlayer.play(AssetSource('audio/bamboo.mp3'));
      } else if (correctPositions > 1) {
        await _audioPlayer.play(AssetSource('audio/bamboox2.mp3'));
      }
    }
  }

  Future<void> _startShuffleAnimation() async {
    await Future.delayed(const Duration(milliseconds: 2000));
    if (!_isPlaying) {
      _shuffleTimer = Timer.periodic(const Duration(milliseconds: 800), (timer) {
        if (mounted) {
          setState(() {
            _images.shuffle();
          });
        }
      });
    }
  }

  void _stopShuffleAnimation() {
    _shuffleTimer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.isDarkMode ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: widget.isDarkMode ? AppColors.darkAppBar : AppColors.lightAppBar,
        iconTheme: IconThemeData(
          color: widget.isDarkMode ? AppColors.darkAppBarIcon : AppColors.lightAppBarIcon,
        ),
        leading: IconButton(
          iconSize: 30.0,
          icon: Icon(
            Icons.arrow_back,
            color: widget.isDarkMode ? AppColors.darkAppBarIcon : AppColors.lightAppBarIcon,
          ),
          onPressed: () {
            _stopGame();
            Navigator.pop(context);
          },
        ),
        title: Padding(
          padding: const EdgeInsets.only(top: 8.0, left: 8.0, bottom: 16.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${widget.locale.languageCode == 'pt' ? 'Tempo' : 'Time'}: ${_formatTime(_elapsedSeconds)}',
              style: TextStyle(
                fontSize: 18,
                color: widget.isDarkMode ? AppColors.darkAppBarText : AppColors.lightAppBarText,
              ),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.menu,
              color: widget.isDarkMode ? AppColors.darkAppBarIcon : AppColors.lightAppBarIcon,
              size: 30.0,
            ),
            tooltip: 'Configurações',
            onPressed: () {
              final settings = Provider.of<SettingsController>(context, listen: false);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => SettingsPage(
                    isDarkMode: settings.isDarkMode,
                    soundEnabled: settings.soundEnabled,
                    locale: settings.locale,
                    toggleTheme: settings.toggleTheme,
                    setLanguage: settings.setLanguage,
                    toggleSound: settings.toggleSound,
                    onLogout: () {}, // ajuste conforme necessário
                    onDeleteAccount: null,
                    isAuthenticated: widget.isAuthenticated,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Expanded(
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: _cols / _rows,
                      child: GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: _gridSize,
                        ),
                        itemCount: _sections.length,
                        itemBuilder: (BuildContext context, int index) {
                          final label = _sections[index];
                          return DragTarget<String>(
                            onWillAccept: (data) => _isPlaying,
                            onAccept: (data) {
                              if (_isPlaying) {
                                setState(() {
                                  final fromIndex = _sections.indexOf(data);
                                  final toIndex = index;
                                  final temp = _sections[fromIndex];
                                  _sections[fromIndex] = _sections[toIndex];
                                  _sections[toIndex] = temp;
                                  final tempImage = _images[fromIndex];
                                  _images[fromIndex] = _images[toIndex];
                                  _images[toIndex] = tempImage;
                                  int correctPositions = 0;
                                  // Animação de borda para peça correta
                                  if (_images[toIndex] == '$_currentPuzzlePath/${toIndex + 1}.png') {
                                    correctPositions++;
                                    _highlightedPieces[toIndex] = true;
                                    Future.delayed(const Duration(milliseconds: 400), () {
                                      if (mounted) setState(() => _highlightedPieces[toIndex] = false);
                                    });
                                  }
                                  if (_images[fromIndex] == '$_currentPuzzlePath/${fromIndex + 1}.png') {
                                    correctPositions++;
                                    _highlightedPieces[fromIndex] = true;
                                    Future.delayed(const Duration(milliseconds: 400), () {
                                      if (mounted) setState(() => _highlightedPieces[fromIndex] = false);
                                    });
                                  }
                                  _playSound(correctPositions);
                                  _checkPuzzleCompletion();
                                });
                              }
                            },
                            builder: (context, candidateData, rejectedData) {
                              return Draggable<String>(
                                data: label ?? '',
                                feedback: Material(
                                  child: Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.black),
                                      color: Colors.white,
                                    ),
                                    child: Center(
                                      child: label != null && _images[index] != null
                                          ? Image.asset(
                                              _images[index]!,
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                              height: double.infinity,
                                            )
                                          : null,
                                    ),
                                  ),
                                ),
                                childWhenDragging: Container(),
                                child: GridTile(
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 400),
                                    curve: Curves.easeOut,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: _highlightedPieces[index]
                                            ? Colors.greenAccent
                                            : const Color.fromARGB(0, 0, 0, 0),
                                        width: _highlightedPieces[index] ? 4.0 : 0.2,
                                      ),
                                    ),
                                    child: Center(
                                      child: label != null && _images[index] != null
                                          ? Image.asset(
                                              _images[index]!,
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                              height: double.infinity,
                                            )
                                          : null,
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  child: Container(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        IconButton(
                          iconSize: 46.0,
                          icon: Icon(
                            Icons.stop,
                            color: widget.isDarkMode ? AppColors.darkAppBarIcon : AppColors.lightAppBarIcon,
                          ),
                          onPressed: () {
                            _stopShuffleAnimation();
                            _stopGame();
                          },
                        ),
                        IconButton(
                          iconSize: 46.0,
                          icon: Icon(
                            _isPlaying ? Icons.pause : Icons.play_arrow,
                            color: widget.isDarkMode ? AppColors.darkAppBarIcon : AppColors.lightAppBarIcon,
                          ),
                          onPressed: () {
                            _stopShuffleAnimation();
                            if (_isPlaying) {
                              _pauseGame();
                            } else {
                              if (_elapsedSeconds == 0) {
                                _resetSections();
                                _shuffleSections();
                              } else if (_isPuzzleComplete()) {
                                _resetSections();
                                _shuffleSections();
                              } else {
                                _resumeGame();
                              }
                            }
                          },
                        ),
                        IconButton(
                          iconSize: 46.0,
                          icon: Icon(
                            Icons.refresh,
                            color: widget.isDarkMode ? AppColors.darkAppBarIcon : AppColors.lightAppBarIcon,
                          ),
                          onPressed: () {
                            _stopShuffleAnimation();
                            _resetSections();
                            _shuffleSections();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: widget.confettiController,
              numberOfParticles: 20,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [Colors.red, Colors.blue, Colors.green, Colors.yellow],
            ),
          ),
        ],
      ),
    );
  }
}
