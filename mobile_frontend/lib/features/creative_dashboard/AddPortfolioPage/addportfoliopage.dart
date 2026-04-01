import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mime/mime.dart';
import 'package:mobile_frontend/features/creative_dashboard/AddPortfolioPage/video_portfolio_item.dart';
import 'package:mobile_frontend/providers/profile_provider.dart';
import 'package:mobile_frontend/providers/user_provider.dart';
import 'package:mobile_frontend/services/profileservice.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:video_compress/video_compress.dart';

class AddPortfolioPage extends StatefulWidget {
  const AddPortfolioPage({super.key});

  @override
  State<AddPortfolioPage> createState() => _AddPortfolioPageState();
}

class _AddPortfolioPageState extends State<AddPortfolioPage> {
  bool _loading = false;

  // Add this method to _AddPortfolioPageState
  Future<Map<String, dynamic>?> _showMetadataSheet(String filePath) async {
    final mimeType = lookupMimeType(filePath) ?? 'image/jpeg';
    final isVideo = mimeType.startsWith('video/');
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final tagController = TextEditingController();
    List<String> tags = [];

    return await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isVideo ? "Video Details" : "Photo Details",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: "Title",
                    hintText: "e.g., Wedding at Aso Rock",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: "Description",
                    hintText: "Tell the story behind this...",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Tags
                Wrap(
                  spacing: 6,
                  children: tags
                      .map(
                        (tag) => Chip(
                          label: Text(
                            tag,
                            style: const TextStyle(fontSize: 11),
                          ),
                          deleteIcon: const Icon(Icons.close, size: 14),
                          onDeleted: () =>
                              setSheetState(() => tags.remove(tag)),
                          backgroundColor: const Color(
                            0xFFFF7A33,
                          ).withOpacity(0.1),
                          side: const BorderSide(color: Color(0xFFFF7A33)),
                        ),
                      )
                      .toList(),
                ),
                TextField(
                  controller: tagController,
                  decoration: InputDecoration(
                    labelText: "Tags",
                    hintText: "Type a tag and press enter",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        final t = tagController.text.trim();
                        if (t.isNotEmpty && !tags.contains(t)) {
                          setSheetState(() => tags.add(t));
                          tagController.clear();
                        }
                      },
                    ),
                  ),
                  onSubmitted: (t) {
                    final tag = t.trim();
                    if (tag.isNotEmpty && !tags.contains(tag)) {
                      setSheetState(() => tags.add(tag));
                      tagController.clear();
                    }
                  },
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx, null), // skip
                        child: const Text("Skip"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF7A33),
                        ),
                        onPressed: () => Navigator.pop(ctx, {
                          'title': titleController.text.trim(),
                          'description': descController.text.trim(),
                          'tags': tags.join(','),
                        }),
                        child: const Text(
                          "Done",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndUpload() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['jpg', 'png', 'jpeg', 'mp4', 'mov'],
    );
    if (result == null) return;

    final files = result.paths.whereType<String>().toList();

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );
    final token = userProvider.token!;

    setState(() => _loading = true);

    try {
      for (final filePath in files) {
        final mimeType = lookupMimeType(filePath) ?? 'image/jpeg';
        final isVideo = mimeType.startsWith('video/');

        final metadata = await _showMetadataSheet(filePath);

        int? durationSeconds;

        if (isVideo) {
          final info = await VideoCompress.getMediaInfo(filePath);
          durationSeconds = ((info.duration ?? 0) / 1000)
              .round(); // ms → seconds
        }

        final newItem = await ProfilePortfolioService().uploadPortfolioItem(
          token: token,
          filePath: filePath,
          title: metadata?['title']?.isNotEmpty == true
              ? metadata!['title']
              : null,
          description: metadata?['description']?.isNotEmpty == true
              ? metadata!['description']
              : null,
          tags: metadata?['tags']?.isNotEmpty == true
              ? metadata!['tags']
              : null,
          durationSeconds: durationSeconds,
        );
        profileProvider.addPortfolioItem(newItem);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ Uploaded ${files.length} file(s)!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ Upload failed: $e")));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _deletePortfolioItem(String itemId) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );
    final token = userProvider.token!;

    setState(() => _loading = true);

    try {
      await ProfilePortfolioService().deletePortfolioItem(
        token: token,
        itemId: itemId,
      );
      profileProvider.removePortfolioItem(itemId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🗑️ Deleted successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ Delete failed: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context);
    final creative = profileProvider.profile?['creativeDetails'] ?? {};
    final portfolio = List<Map<String, dynamic>>.from(
      creative['portfolio'] ?? [],
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_photo_alternate, color: Colors.black),
            onPressed: _loading ? null : _pickAndUpload,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFFF7A33)),
              )
            : portfolio.isEmpty
            ? Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset('assets/addportfolio_pic.svg'),
                      SizedBox(height: 20),
                      const Text(
                        'Show your best work to your clients',
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 10),
                      const Text(
                        'Upload images and videos to show clients what you can do',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(12.0),
                child: GridView.builder(
                  itemCount: portfolio.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemBuilder: (context, index) {
                    final item = portfolio[index];
                    final url = item['url']?.toString() ?? '';
                    final type = item['type']?.toString() ?? '';
                    final id = item['id'] ?? item['_id'] ?? '';

                    if (url.isEmpty) return const SizedBox.shrink();
                    return Stack(
                      children: [
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: type == 'video'
                                ? VideoThumbnail(key: ValueKey(url), url: url)
                                : Image.network(
                                    url,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.broken_image,
                                      color: Colors.grey,
                                    ),
                                  ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: id.isEmpty
                                ? null
                                : () => _deletePortfolioItem(id),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black54,
                              ),
                              child: const Icon(
                                Icons.delete,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
      ),
    );
  }
}
