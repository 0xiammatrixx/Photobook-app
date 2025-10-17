import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mobile_frontend/app/profile_provider.dart';
import 'package:mobile_frontend/app/user_provider.dart';
import 'package:mobile_frontend/services/profileservice.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';

class AddPortfolioPage extends StatefulWidget {
  const AddPortfolioPage({super.key});

  @override
  State<AddPortfolioPage> createState() => _AddPortfolioPageState();
}

class _AddPortfolioPageState extends State<AddPortfolioPage> {
  bool _loading = false;

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
        final newItem = await ProfilePortfolioService().uploadPortfolioItem(
          token: token,
          filePath: filePath,
          title: "New Upload",
          description: "Uploaded via app",
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
            icon: const Icon(Icons.add_photo_alternate, color: Colors.black,),
            onPressed: _loading ? null : _pickAndUpload,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: _loading
            ? const Center(child: CircularProgressIndicator(
              color: Color(0xFFFF7A33),
            ))
            : portfolio.isEmpty
            ? Center(child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset('assets/addportfolio_pic.svg'),
                  SizedBox(height: 20,),
                  const Text('Show your best work to your clients', textAlign: TextAlign.center,),
                  SizedBox(height: 10,),
                  const Text('Upload images and videos to show clients what you can do', textAlign: TextAlign.center,)
                ],
              ),
            ))
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
                    final url = item['url'];
                    final type = item['type'];
                    final id = item['_id'];
        
                    return Stack(
                      children: [
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: type == 'video'
                                ? Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Image.network(
                                        url,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => const Icon(
                                          Icons.videocam,
                                          size: 40,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const Icon(
                                        Icons.play_circle_fill,
                                        color: Colors.white70,
                                        size: 32,
                                      ),
                                    ],
                                  )
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
                            onTap: () => _deletePortfolioItem(id),
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
