import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../../../../data/enums/message_sender.dart';
import 'bubble_layout.dart';

class VideoPlayerBubble extends StatefulWidget {
  final String title;
  final String videoUrl;
  final VoidCallback? onVideoEnd;

  const VideoPlayerBubble({
    super.key,
    required this.title,
    required this.videoUrl,
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
    final videoId = YoutubePlayer.convertUrlToId(widget.videoUrl);

    if (videoId != null) {
      _isValidVideo = true;
      _controller = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(
          autoPlay: false,
          mute: false,
          enableCaption: false,
          forceHD: false,
        ),
      )..addListener(_onPlayerStateChanged);
    } else {
      _isValidVideo = false;
    }
  }

  void _onPlayerStateChanged() {
    if (_controller.value.playerState == PlayerState.ended) {
      widget.onVideoEnd?.call();
    }
  }

  @override
  void dispose() {
    if (_isValidVideo) {
      _controller.removeListener(_onPlayerStateChanged);
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bubbleTextColor = theme.colorScheme.onSecondaryContainer;

    // Build the content to go inside the bubble
    Widget content;
    if (!_isValidVideo) {
      // Show an error message if the URL was bad
      content = Text(
        "Error: Invalid video link provided. ${widget.videoUrl}",
        style: TextStyle(color: theme.colorScheme.error),
      );
    } else {
      // Render the full video card content
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. The Video Player
          ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: YoutubePlayer(
              controller: _controller,
              showVideoProgressIndicator: true,
              progressIndicatorColor: theme.colorScheme.primary,
              progressColors: ProgressBarColors(
                playedColor: theme.colorScheme.primary,
                handleColor: theme.colorScheme.primary,
              ),
              bottomActions: [
                CurrentPosition(),
                ProgressBar(isExpanded: true),
                RemainingDuration(),
              ],
            ),
          ),

          // 2. The Title/Content
          if (widget.title.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Text(
                widget.title,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: bubbleTextColor,
                ),
              ),
            ),
        ],
      );
    }

    // Return the content wrapped in the layout
    return BubbleLayout(
      sender: MessageSender.gemini,
      child: content,
    );
  }
}