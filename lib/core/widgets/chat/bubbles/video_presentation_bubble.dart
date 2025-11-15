import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class VideoPlayerBubble extends StatefulWidget {
  final String title;
  final String videoUrl;
  // --- ADDED: Accept the callback from the parent ---
  final VoidCallback? onVideoEnd;
    


  const VideoPlayerBubble({super.key, 
    required this.title,
    required this.videoUrl,
    // --- ADDED: Add to constructor ---
    this.onVideoEnd,
  });

  @override
  State<VideoPlayerBubble> createState() => _VideoPlayerBubbleState();
}

class _VideoPlayerBubbleState extends State<VideoPlayerBubble> {
  late YoutubePlayerController _controller;
  bool _isValidVideo = false;

  @override
  void initState() {
    super.initState();
    // The player package provides a helper to extract the ID
    final videoId = YoutubePlayer.convertUrlToId(widget.videoUrl);

    if (videoId != null) {
      _isValidVideo = true;
      _controller = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(
          autoPlay: false, // Don't autoplay in a chat list
          mute: false,
          enableCaption: false,
          forceHD: false,
        ),
      )..addListener(_onPlayerStateChanged); // --- ADDED: Listen for state changes ---
    } else {
      _isValidVideo = false;
    }
  }

  // --- ADDED: The listener function ---
  void _onPlayerStateChanged() {
    // Check if the video has ended
    if (_controller.value.playerState == PlayerState.ended) {
      // If it has, call the callback function provided by the parent
      widget.onVideoEnd?.call();
    }
  }


  @override
  void dispose() {
    // Only dispose if the controller was successfully created
    if (_isValidVideo) {
      // --- ADDED: Remove listener before disposing ---
      _controller.removeListener(_onPlayerStateChanged);
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show an error card if the URL from the Cubit was bad
    if (!_isValidVideo) {
      return Card(
        elevation: 1,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            "Error: Invalid video link provided. ${widget.videoUrl}",
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      );
    }

    // Render the full video card
    return Card(
      elevation: 1,
      clipBehavior: Clip.antiAlias, // Ensures the player respects card's rounded corners
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. The Video Player
          YoutubePlayer(
            controller: _controller,
            showVideoProgressIndicator: true,
            progressIndicatorColor: Theme.of(context).colorScheme.primary,
            progressColors: ProgressBarColors(
              playedColor: Theme.of(context).colorScheme.primary,
              handleColor: Theme.of(context).colorScheme.primary,
            ),
            // A simpler control set for a small bubble
            bottomActions: [
               CurrentPosition(),
               ProgressBar(isExpanded: true),
               RemainingDuration(),
            ],
          ),
          
          // 2. The Title/Content
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              widget.title,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }
}