import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class SoundManager {
  late final AudioPlayer _audioPlayer;

  SoundManager() {
    _audioPlayer = AudioPlayer();
    _audioPlayer.setVolume(1.0);
  }

  Future<void> play() async {
    await _audioPlayer.setSource(AssetSource('sounds/emergency.mp3'));
    await _audioPlayer.resume();
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
  }
}