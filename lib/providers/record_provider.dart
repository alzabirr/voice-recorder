import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';

import '../models/recording_model.dart';

class RecordProvider extends ChangeNotifier {
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final Uuid _uuid = const Uuid();

  // Sampling rate for waveform updates
  static const int _samplingRateMs = 50; 
  // Smoothing factor: Lower = smoother/slower transitions
  static const double _smoothingFactor = 0.1;
  
  double _lastAmplitude = -60.0;
  static const int _maxSamples = 1000;

  final List<RecordingModel> _recordings = [];
  List<RecordingModel> get recordings => _recordings;

  bool _isRecording = false;
  bool get isRecording => _isRecording;

  bool _isPaused = false;
  bool get isPaused => _isPaused;

  int _recordDurationMs = 0;
  int get recordDurationMs => _recordDurationMs;
  Timer? _timer;

  // Playback state
  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;
  
  String? _currentPlayingPath;
  String? get currentPlayingPath => _currentPlayingPath;

  Duration _currentPosition = Duration.zero;
  Duration get currentPosition => _currentPosition;

  Duration _totalDuration = Duration.zero;
  Duration get totalDuration => _totalDuration;

  // Stream for amplitude (waveform)
  Stream<Amplitude>? _amplitudeStream;
  StreamSubscription<Amplitude>? _amplitudeSubscription;
  Stream<Amplitude>? get amplitudeStream => _amplitudeStream;

  final List<double> _amplitudeHistory = [];
  List<double> get amplitudeHistory => _amplitudeHistory;

  RecordProvider() {
    _init();
  }

  Future<void> _init() async {
    await _loadRecordings();
    
    _audioPlayer.onPlayerStateChanged.listen((state) {
      _isPlaying = state == PlayerState.playing;
      if (state == PlayerState.completed) {
        _currentPlayingPath = null;
        _currentPosition = Duration.zero;
      }
      notifyListeners();
    });

    _audioPlayer.onPositionChanged.listen((position) {
      _currentPosition = position;
      notifyListeners();
    });

    _audioPlayer.onDurationChanged.listen((duration) {
      _totalDuration = duration;
      notifyListeners();
    });
  }

  bool _isVoiceIsolationEnabled = false;
  bool get isVoiceIsolationEnabled => _isVoiceIsolationEnabled;

  void toggleVoiceIsolation(bool value) {
    _isVoiceIsolationEnabled = value;
    notifyListeners();
  }

  bool _isPodcastModeEnabled = false;
  bool get isPodcastModeEnabled => _isPodcastModeEnabled;

  void togglePodcastMode(bool value) {
    _isPodcastModeEnabled = value;
    notifyListeners();
  }

  Future<void> startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final directory = await getApplicationDocumentsDirectory();
        final path = '${directory.path}/${DateTime.now().millisecondsSinceEpoch}.wav';

        // Configuration Logic
        // Architecture Rec 1.2: 48kHz Sample Rate
        // Architecture Rec 6.1: WAV (16-bit PCM) for lossless quality
        
        final int sampleRate = 48000; 
        
        // Processing Logic
        // Architecture Rec 2.1: Hybrid DSP + AI. We start with hardware DSP.
        // Isolation: Enable Noise Suppress & Echo Cancel (Voice Comm tuning)
        // Podcast: Pure signal
        
        final bool enableNoiseSuppress = _isVoiceIsolationEnabled;
        final bool enableEchoCancel = _isVoiceIsolationEnabled;
        final bool enableAutoGain = _isVoiceIsolationEnabled 
            ? false // Isolation: OFF to prevent noise floor boosting during silence
            : _isPodcastModeEnabled; // Podcast: ON for leveling 

        await _audioRecorder.start(
          RecordConfig(
            encoder: AudioEncoder.wav, // Lossless PCM 16-bit
            // bitRate: not used for WAV/PCM usually, determined by sample rate/depth
            sampleRate: sampleRate,
            numChannels: 1, 
            
            noiseSuppress: enableNoiseSuppress,
            echoCancel: enableEchoCancel,    
            autoGain: enableAutoGain,
          ), 
          path: path
        );
        
        _isRecording = true;
        _isPaused = false;
        _recordDurationMs = 0;
        _amplitudeHistory.clear();
        _lastAmplitude = -60.0;
        
        _startTimer();
        
        await _amplitudeSubscription?.cancel();
        _amplitudeStream = _audioRecorder.onAmplitudeChanged(const Duration(milliseconds: _samplingRateMs));
        _amplitudeSubscription = _amplitudeStream?.listen((amplitude) {
           if (!_isRecording) return;

           double current = amplitude.current;
           
           // Floor for noise
           if (current < -60) current = -60;
           // Cap for clipping
           if (current > 0) current = 0;

           // React very fast to peaks, but smooth the decay
           if (current > _lastAmplitude) {
              _lastAmplitude = current; // Instant peak pick
           } else {
              _lastAmplitude = _lastAmplitude + (current - _lastAmplitude) * _smoothingFactor;
           }
           
           _amplitudeHistory.add(_lastAmplitude);
           if (_amplitudeHistory.length > _maxSamples) {
             _amplitudeHistory.removeAt(0);
           }
           notifyListeners();
        });

        notifyListeners();
      } else {
        // Handle permission denied
        debugPrint("Permission denied");
      }
    } catch (e) {
      debugPrint("Error starting recording: $e");
    }
  }

  Future<void> pauseRecording() async {
    try {
      await _audioRecorder.pause();
      _isPaused = true;
      _timer?.cancel();
      notifyListeners();
    } catch (e) {
      debugPrint("Error pausing recording: $e");
    }
  }

  Future<void> resumeRecording() async {
    try {
      await _audioRecorder.resume();
      _isPaused = false;
      _startTimer();
      notifyListeners();
    } catch (e) {
      debugPrint("Error resuming recording: $e");
    }
  }

  Future<String?> stopRecording() async {
    try {
      _isRecording = false;
      _isPaused = false;
      _timer?.cancel();
      
      await _amplitudeSubscription?.cancel();
      _amplitudeSubscription = null;
      _amplitudeStream = null;
      _amplitudeHistory.clear(); // Clear immediately for UI responsiveness
      
      notifyListeners();

      final path = await _audioRecorder.stop();
      return path;
    } catch (e) {
      debugPrint("Error stopping recording: $e");
      return null;
    }
  }

  Future<void> discardRecording() async {
    try {
      final path = await _audioRecorder.stop();
      _isRecording = false;
      _isPaused = false;
      _timer?.cancel();
      _amplitudeSubscription?.cancel();
      _amplitudeHistory.clear();
      _recordDurationMs = 0;
      
      if (path != null) {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint("Error discarding recording: $e");
    }
  }

  void saveRecording(String path, String name) {
    final recording = RecordingModel(
      id: _uuid.v4(),
      path: path,
      name: name,
      duration: Duration(milliseconds: _recordDurationMs),
      date: DateTime.now(),
    );
    _recordings.add(recording);
    // In a real app, save metadata to local storage (e.g. SharedPreferences or SQLite)
    notifyListeners();
  }

  void deleteRecording(String id) {
    final recording = _recordings.firstWhere((r) => r.id == id);
    try {
      final file = File(recording.path);
      if (file.existsSync()) {
        file.deleteSync();
      }
    } catch (e) {
      debugPrint("Error deleting file: $e");
    }
    _recordings.removeWhere((r) => r.id == id);
    notifyListeners();
  }
  
  void renameRecording(String id, String newName) {
    final index = _recordings.indexWhere((r) => r.id == id);
    if (index != -1) {
      final old = _recordings[index];
      _recordings[index] = RecordingModel(
        id: old.id,
        path: old.path,
        name: newName,
        duration: old.duration,
        date: old.date,
      );
      notifyListeners();
    }
  }

  Future<void> playRecording(String path) async {
    if (_currentPlayingPath == path && _isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play(DeviceFileSource(path));
      _currentPlayingPath = path;
    }
  }

  Future<void> pausePlayback() async {
    await _audioPlayer.pause();
  }

  Future<void> seekTo(Duration position) async {
    await _audioPlayer.seek(position);
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(milliseconds: 50), (Timer t) {
      _recordDurationMs += 50;
      notifyListeners();
    });
  }

  Future<void> _loadRecordings() async {
    // Load from local storage if implemented
  }

  @override
  void dispose() {
    _timer?.cancel();
    _amplitudeSubscription?.cancel();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }
}
