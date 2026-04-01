import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_compress/video_compress.dart';
import 'package:video_player/video_player.dart';

// ── Thumbnail widget for grid ──
class VideoThumbnail extends StatefulWidget {
  final String url;
  final VoidCallback? onTap;
  const VideoThumbnail({super.key, required this.url, this.onTap});

  @override
  State<VideoThumbnail> createState() => _VideoThumbnailState();
}

class _VideoThumbnailState extends State<VideoThumbnail> {
  dynamic _thumbnail; // Uint8List

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  Future<void> _loadThumbnail() async {
    try {
      final thumb = await VideoCompress.getByteThumbnail(
        widget.url,
        quality: 50,
      );
      if (mounted) setState(() => _thumbnail = thumb);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _thumbnail != null
              ? Image.memory(_thumbnail!, fit: BoxFit.cover)
              : Container(color: Colors.grey.shade300),
          const Center(
            child: Icon(Icons.play_circle_fill, color: Colors.white70, size: 32),
          ),
        ],
      ),
    );
  }
}

// ── Full screen video player ──
class VideoPlayerPage extends StatefulWidget {
  final String url;
  const VideoPlayerPage({super.key, required this.url});

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late VideoPlayerController _videoController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    print("🎬 Video URL: ${widget.url}");
    _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize()
          .then((_) {
            print("🎬 Video URL: ${widget.url}");
            _chewieController = ChewieController(
              videoPlayerController: _videoController,
              autoPlay: true,
              allowFullScreen: true,
              aspectRatio: _videoController.value.aspectRatio,
            );
            setState(() {});
          })
          .catchError((e) {
            print("❌ Video init error: $e"); // ✅ catches silent failures
          });

    _videoController.addListener(() {
      if (_videoController.value.hasError) {
        print(
          "❌ Video player error: ${_videoController.value.errorDescription}",
        );
      }
    });
  } 

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: _chewieController != null
            ? Chewie(controller: _chewieController!)
            : const CircularProgressIndicator(color: Color(0xFFFF7A33)),
      ),
    );
  }
}
