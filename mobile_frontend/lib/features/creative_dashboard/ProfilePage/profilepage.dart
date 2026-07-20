import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_frontend/features/client_dashboard/BookScreen/book.dart';
import 'package:mobile_frontend/features/creative_dashboard/AddPortfolioPage/video_portfolio_item.dart';
import 'package:mobile_frontend/features/creative_dashboard/ProfilePage/profile_settings.dart';
import 'package:mobile_frontend/features/creative_dashboard/ProfilePage/profileedit.dart';
import 'package:mobile_frontend/features/creative_dashboard/ProfilePage/reviewmodel.dart';
import 'package:mobile_frontend/features/creative_dashboard/rateCard.dart';
import 'package:mobile_frontend/features/shared/chat_conversation_screen.dart';
import 'package:mobile_frontend/providers/chat_provider.dart';
import 'package:mobile_frontend/providers/profile_provider.dart';
import 'package:mobile_frontend/providers/user_provider.dart';
import 'package:mobile_frontend/features/auth/login/loginscreen.dart';
import 'package:mobile_frontend/services/authservice.dart';
import 'package:mobile_frontend/services/profileservice.dart';
import 'package:provider/provider.dart';
 
class CreativeProfilePage extends StatefulWidget {
  final bool isOwner;
  final String? creativeId;
 
  const CreativeProfilePage({super.key, this.isOwner = true, this.creativeId});
 
  @override
  State<CreativeProfilePage> createState() => _CreativeProfilePageState();
}
 
class _CreativeProfilePageState extends State<CreativeProfilePage> {
  final _profileService = ProfilePortfolioService();
  final AuthService _authService = AuthService();
  bool _loading = true;
 
  @override
  void initState() {
    super.initState();
    _loadProfile();
  }
 
  Future<void> _loadProfile({bool initial = false}) async {
    setState(() => _loading = true);
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
      final token = userProvider.token;
      if (token == null) { _redirectToLogin(); return; }
 
      Map<String, dynamic> raw;
      List<dynamic> portfolioData = [];
 
      if (widget.isOwner) {
        final data = await _profileService.getProfile(token: token);
        raw = data['profile'] as Map<String, dynamic>;
        portfolioData = await _profileService.getMyPortfolio(token: token);
      } else {
        final data = await _profileService.getProfile(token: token, userId: widget.creativeId);
        raw = data['profile'] ?? data;
        final portfolioRes = await http.get(
          Uri.parse('https://api.photobookhq.com/api/search/portfolio?photographerId=${widget.creativeId}'),
          headers: {'Authorization': 'Bearer $token'},
        );
        if (portfolioRes.statusCode == 200) {
          final pData = jsonDecode(portfolioRes.body);
          final items = pData is List ? pData : pData['items'] ?? pData['results'] ?? [];
          portfolioData = List<dynamic>.from(items).map((item) {
            final m = Map<String, dynamic>.from(item);
            return {...m, 'url': m['media_url'] ?? m['url'], 'type': m['media_type'] ?? m['type']};
          }).toList();
        }
      }
 
      profileProvider.setProfile({
        'role': raw['role'] ?? 'photographer',
        'isOwner': widget.isOwner,
        'basic': {
          'businessName': raw['business_name'] ?? raw['businessName'],
          'avatarUrl': raw['photographer_profile_photo_url'] ?? raw['avatarUrl'],
          'displayTitle': raw['display_title'] ?? raw['displayTitle'],
          'tags': List<String>.from(raw['tags'] ?? []),
        },
        'creativeDetails': {
          'aboutMe': raw['about_me'] ?? raw['aboutMe'] ?? '',
          'portfolio': portfolioData,
          'starRating': raw['star_rating'] ?? raw['starRating'],
          'totalReviews': raw['total_reviews'] ?? raw['totalReviews'],
        },
      });
    } catch (e) {
      print("❌ Error loading profile: $e");
      if (e.toString().contains('UNAUTHORIZED')) {
        await AuthService().logout();
        _redirectToLogin();
      }
    } finally {
      setState(() => _loading = false);
    }
  }
 
  void _redirectToLogin() {
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }
 
  @override
  Widget build(BuildContext context) {
    final profile = Provider.of<ProfileProvider>(context).profile;
    final userProvider = Provider.of<UserProvider>(context);
 
    if (_loading || profile == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFFFF7A33))),
      );
    }
 
    final basic = profile['basic'] ?? {};
    final creative = profile['creativeDetails'] ?? {};
    final isOwner = profile['isOwner'] ?? false;
    final businessName = isOwner
        ? (userProvider.user?['basic']?['businessName'] ?? basic['businessName'] ?? 'No Name')
        : (basic['businessName'] ?? 'No Name');
    final starRating = double.tryParse(creative['starRating']?.toString() ?? '0') ?? 0;
    final totalReviews = creative['totalReviews'] ?? 0;
 
    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        color: const Color(0xFFFF7A33),
        onRefresh: () => _loadProfile(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Top bar ──
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (!isOwner)
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.arrow_back, size: 20),
                              ),
                            )
                          else
                            const Text(
                              'Profile',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          if (isOwner)
                            GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const CreativeSettingsPage()),
                              ),
                              child: const Icon(Icons.settings_outlined, size: 24),
                            ),
                        ],
                      ),
                    ),
 
                    // ── Profile card ──
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Consumer<ProfileProvider>(
                        builder: (context, profileProvider, _) {
                          final b = profileProvider.profile?['basic'] ?? {};
                          final c = profileProvider.profile?['creativeDetails'] ?? {};
                          final rating = double.tryParse(c['starRating']?.toString() ?? '0') ?? 0;
                          final reviews = c['totalReviews'] ?? 0;
                          final avatarUrl = b['avatarUrl'];
                          final tags = List<String>.from(b['tags'] ?? []);
 
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Avatar + buttons row
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Circular avatar
                                  CircleAvatar(
                                    radius: 44,
                                    backgroundColor: Colors.grey.shade200,
                                    backgroundImage: avatarUrl != null
                                        ? NetworkImage(avatarUrl)
                                        : null,
                                    child: avatarUrl == null
                                        ? const Icon(Icons.person, size: 44, color: Colors.grey)
                                        : null,
                                  ),
                                  const SizedBox(width: 16),
                                  if (isOwner) ...[
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          const SizedBox(height: 8),
                                          OutlinedButton(
                                            style: OutlinedButton.styleFrom(
                                              side: const BorderSide(color: Color(0xFFFF7A33)),
                                              foregroundColor: const Color(0xFFFF7A33),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                              padding: const EdgeInsets.symmetric(vertical: 8),
                                            ),
                                            onPressed: () => Navigator.push(
                                              context,
                                              MaterialPageRoute(builder: (_) => RateCardPage(
                                                isOwner: true,
                                                businessName: businessName,
                                                avatarUrl: avatarUrl,
                                                creativeId: '',
                                                rating: rating,
                                              )),
                                            ),
                                            child: const Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.credit_card_outlined, size: 14),
                                                SizedBox(width: 4),
                                                Text('Rate Card', style: TextStyle(fontSize: 12)),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFFFF7A33),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                              padding: const EdgeInsets.symmetric(vertical: 8),
                                            ),
                                            onPressed: () async {
                                              final result = await Navigator.push(
                                                context,
                                                MaterialPageRoute(builder: (_) => const EditProfilePage()),
                                              );
                                              if (result == true) setState(() {});
                                            },
                                            child: const Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.edit_outlined, size: 14, color: Colors.white),
                                                SizedBox(width: 4),
                                                Text('Edit Profile', style: TextStyle(fontSize: 12, color: Colors.white)),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ] else ...[
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          const SizedBox(height: 8),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFFFF7A33),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                              padding: const EdgeInsets.symmetric(vertical: 8),
                                            ),
                                            onPressed: () => Navigator.push(
                                              context,
                                              MaterialPageRoute(builder: (_) => BookingPage(
                                                creativeId: widget.creativeId!,
                                                name: businessName,
                                                avatarUrl: avatarUrl ?? '',
                                                rating: rating,
                                              )),
                                            ),
                                            child: const Text('Book Now', style: TextStyle(color: Colors.white, fontSize: 12)),
                                          ),
                                          const SizedBox(height: 8),
                                          OutlinedButton(
                                            style: OutlinedButton.styleFrom(
                                              side: const BorderSide(color: Colors.black),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                              padding: const EdgeInsets.symmetric(vertical: 8),
                                            ),
                                            onPressed: () => _startConversation(context, avatarUrl),
                                            child: const Text('Message', style: TextStyle(color: Colors.black, fontSize: 12)),
                                          ),
                                          const SizedBox(height: 8),
                                          OutlinedButton(
                                            style: OutlinedButton.styleFrom(
                                              backgroundColor: const Color(0xFF047418),
                                              side: BorderSide.none,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                              padding: const EdgeInsets.symmetric(vertical: 8),
                                            ),
                                            onPressed: () => Navigator.push(
                                              context,
                                              MaterialPageRoute(builder: (_) => RateCardPage(
                                                isOwner: false,
                                                businessName: businessName,
                                                avatarUrl: avatarUrl,
                                                creativeId: widget.creativeId ?? '',
                                                rating: rating,
                                              )),
                                            ),
                                            child: const Text('Rate Card', style: TextStyle(color: Colors.white, fontSize: 12)),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 16),
 
                              // Business name + verified badge
                              Row(
                                children: [
                                  Text(
                                    businessName,
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(Icons.verified, color: Color(0xFFFF7A33), size: 18),
                                ],
                              ),
                              const SizedBox(height: 6),
 
                              // Stars + rating
                              Row(
                                children: [
                                  ...List.generate(5, (i) => Icon(
                                    i < rating.round() ? Icons.star : Icons.star_border,
                                    color: Colors.orange, size: 16,
                                  )),
                                  const SizedBox(width: 6),
                                  Text(
                                    rating > 0 ? rating.toStringAsFixed(1) : '0.0',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
 
                              // Categories chips
                              if (tags.isNotEmpty)
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: tags.map((tag) => Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(tag, style: const TextStyle(fontSize: 11, color: Colors.black87)),
                                  )).toList(),
                                ),
                              const SizedBox(height: 10),
 
                              // Stats row
                              Row(
                                children: [
                                  const Icon(Icons.camera_alt_outlined, size: 14, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  const Text('243 shoots completed', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                  const SizedBox(width: 12),
                                  const Text('|', style: TextStyle(color: Colors.grey)),
                                  const SizedBox(width: 12),
                                  const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  const Text('Based in Abuja', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                    ),
 
                    // ── About Me ──
                    if ((creative['aboutMe'] ?? '').isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('About Me', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text(
                              creative['aboutMe'],
                              style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.5),
                            ),
                          ],
                        ),
                      ),
 
                    // ── Portfolio / Reviews tabs ──
                    PortfolioReviewSection(totalReviews: profile['creativeDetails']?['totalReviews'] ?? 0),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
 
  Future<void> _startConversation(BuildContext context, String? avatarUrl) async {
    final token = context.read<UserProvider>().token;
    if (token == null || widget.creativeId == null) return;
    try {
      final result = await context.read<ChatProvider>().createConversation(
        token: token,
        participantId: widget.creativeId!,
      );
      final conversationId = result['id'] ?? result['conversation']?['id'];
      if (conversationId != null && context.mounted) {
        final profile = context.read<ProfileProvider>().profile;
        final businessName = profile?['basic']?['businessName'] ?? 'Unknown'; 
        Navigator.push(context, MaterialPageRoute(builder: (_) => ChatConversationScreen(
          conversationId: conversationId,
          title: businessName,
          avatarUrl: avatarUrl,
          isCreative: false,
        )));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to open chat: $e')));
    }
  }
}
 
// ── Portfolio + Reviews ──────────────────────────────────────────────────────
 
class PortfolioReviewSection extends StatefulWidget {
  final int totalReviews;
  const PortfolioReviewSection({super.key, this.totalReviews = 0});
 
  @override
  State<PortfolioReviewSection> createState() => _PortfolioReviewSectionState();
}
 
class _PortfolioReviewSectionState extends State<PortfolioReviewSection>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int? expandedIndex;
 
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }
 
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
 
  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context);
    final creative = profileProvider.profile?['creativeDetails'] ?? {};
    final portfolio = List<Map<String, dynamic>>.from(creative['portfolio'] ?? []);
 
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tab bar
          Row(
            children: [
              GestureDetector(
                onTap: () => setState(() { _tabController.index = 0; expandedIndex = null; }),
                child: Column(
                  children: [
                    Text(
                      'Portfolio',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: _tabController.index == 0 ? const Color(0xFF047418) : Colors.black54,
                      ),
                    ),
                    if (_tabController.index == 0)
                      Container(height: 2, width: 60, color: const Color(0xFF047418)),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              GestureDetector(
                onTap: () => setState(() { _tabController.index = 1; expandedIndex = null; }),
                child: Column(
                  children: [
                    Text(
                      'Reviews (${widget.totalReviews})',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: _tabController.index == 1 ? const Color(0xFF047418) : Colors.black54,
                      ),
                    ),
                    if (_tabController.index == 1)
                      Container(height: 2, width: 80, color: const Color(0xFF047418)),
                  ],
                ),
              ),
            ],
          ),
          Divider(color: Colors.grey.shade200, height: 1),
          const SizedBox(height: 12),
 
          if (_tabController.index == 0)
            _buildPortfolioGrid(portfolio)
          else
            _buildReviewsSection(),
        ],
      ),
    );
  }
 
  Widget _buildPortfolioGrid(List<Map<String, dynamic>> portfolio) {
    if (portfolio.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('No portfolio items yet.', style: TextStyle(fontSize: 13, color: Colors.grey)),
      );
    }
    final visible = portfolio.length > 9 ? portfolio.take(9).toList() : portfolio;
    return Column(
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: visible.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, crossAxisSpacing: 4, mainAxisSpacing: 4,
          ),
          itemBuilder: (context, index) {
            final item = visible[index];
            final url = item['url']?.toString() ?? '';
            final type = item['type']?.toString() ?? '';
            if (url.isEmpty) return const SizedBox.shrink();
            return ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: type == 'video'
                  ? VideoThumbnail(
                      key: ValueKey(url), url: url,
                      onTap: () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => VideoPlayerPage(key: ValueKey(url), url: url),
                      )),
                    )
                  : GestureDetector(
                      onTap: () => _showExpandedImage(context, url),
                      child: Image.network(url, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.grey)),
                    ),
            );
          },
        ),
        if (portfolio.length > 9)
          TextButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => FullPortfolioPage(portfolio: portfolio),
            )),
            child: const Text('See more', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
      ],
    );
  }
 
  void _showExpandedImage(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(url, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
 
  Widget _buildReviewsSection() {
    final List<Review> mockReviews = [
      Review(userProfileUrl: "assets/avatar1.png", userName: "John Doe",
          title: "Great experience!", text: "Loved the work, very professional.", rating: 5, date: DateTime.now()),
      Review(userName: 'Goodie Martins', userProfileUrl: "assets/avatar1.png",
          rating: 5, title: 'Best Corporate Photographer Ever',
          text: 'A close friend referred me to him. I employed his services and he delivered excellently.',
          date: DateTime(2025, 8, 12)),
      Review(userName: 'Salem Ochidi', userProfileUrl: "assets/avatar1.png",
          rating: 4, title: 'He\'s quite reliable',
          text: 'I found him on the app. He was quite reliable and professional.',
          date: DateTime(2025, 8, 12)),
      Review(userProfileUrl: "assets/avatar2.png", userName: "Jane Smith",
          title: "Okay job", text: "It was fine, but could be faster.", rating: 3, date: DateTime(2025, 8, 12)),
    ];
    return Column(
      children: [
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: mockReviews.length > 3 ? 3 : mockReviews.length,
          separatorBuilder: (_, __) => const Divider(height: 20),
          itemBuilder: (_, i) => ReviewTile(review: mockReviews[i]),
        ),
        if (mockReviews.length > 3)
          TextButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => FullReviewsPage(reviews: mockReviews),
            )),
            child: const Text('See more', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
      ],
    );
  }
}

class FullReviewsPage extends StatefulWidget {
  final List<Review> reviews;

  const FullReviewsPage({super.key, required this.reviews});

  @override
  State<FullReviewsPage> createState() => _FullReviewsPageState();
}

class _FullReviewsPageState extends State<FullReviewsPage> {
  final ScrollController _controller = ScrollController();

  List<Review> loadedReviews = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _page = 1;
  final int _limit = 5;

  @override
  void initState() {
    super.initState();
    // Load initial reviews
    _fetchMoreReviews();

    // Add scroll listener
    _controller.addListener(() {
      if (_controller.position.pixels >= _controller.position.maxScrollExtent &&
          !_isLoading &&
          _hasMore) {
        _fetchMoreReviews();
      }
    });
  }

  Future<void> _fetchMoreReviews() async {
    setState(() => _isLoading = true);

    // In real app: fetch from API using _page & _limit
    // Here: simulate from provided widget.reviews
    await Future.delayed(const Duration(seconds: 1)); // fake network delay
    final start = (_page - 1) * _limit;
    final end = start + _limit;

    final newItems = widget.reviews.sublist(
      start,
      end > widget.reviews.length ? widget.reviews.length : end,
    );

    setState(() {
      loadedReviews.addAll(newItems);
      _isLoading = false;
      _page++;
      if (newItems.length < _limit) _hasMore = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
        title: Text(
          "My Reviews (${widget.reviews.length})",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: Color(0xFFF5F9F6),
        ),
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: ListView.separated(
          controller: _controller,
          itemCount: loadedReviews.length + 1, // +1 for loader at end
          separatorBuilder: (_, __) => const Divider(height: 20),
          itemBuilder: (context, index) {
            if (index < loadedReviews.length) {
              return ReviewTile(review: loadedReviews[index]);
            } else {
              return _isLoading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(
                          color: Color(0xFFFF7A33),
                        ),
                      ),
                    )
                  : const SizedBox.shrink();
            }
          },
        ),
      ),
    );
  }
}

class FullPortfolioPage extends StatefulWidget {
  final List<Map<String, dynamic>> portfolio;

  const FullPortfolioPage({super.key, required this.portfolio});

  @override
  State<FullPortfolioPage> createState() => _FullPortfolioPageState();
}

class _FullPortfolioPageState extends State<FullPortfolioPage> {
  final ScrollController _controller = ScrollController();

  List<Map<String, dynamic>> loadedItems = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _page = 1;
  final int _limit = 9; // load 9 (3x3 grid) at a time

  @override
  void initState() {
    super.initState();
    _fetchMore();
    _controller.addListener(() {
      if (_controller.position.pixels >= _controller.position.maxScrollExtent &&
          !_isLoading &&
          _hasMore) {
        _fetchMore();
      }
    });
  }

  Future<void> _fetchMore() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    final start = (_page - 1) * _limit;
    final end = start + _limit;
    final newItems = widget.portfolio.sublist(
      start,
      end > widget.portfolio.length ? widget.portfolio.length : end,
    );

    setState(() {
      loadedItems.addAll(newItems);
      _isLoading = false;
      _page++;
      if (newItems.length < _limit) _hasMore = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        title: Text(
          "My Portfolio (${widget.portfolio.length})",
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: const Color(0xFFF5F9F6),
        ),
        child: Column(
          children: [
            Expanded(
              child: GridView.builder(
                controller: _controller,
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                ),
                itemCount: loadedItems.length,
                itemBuilder: (context, index) {
                  if (index < loadedItems.length) {
                    final item = loadedItems[index];
                    final url = item['url']?.toString() ?? '';
                    final type = item['type']?.toString() ?? '';

                    if (url.isEmpty) return const SizedBox.shrink();

                    return ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: type == 'video'
                          ? VideoThumbnail(url: url)
                          : Image.network(
                              url,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.broken_image,
                                color: Colors.grey,
                              ),
                            ),
                    );
                  }
                },
              ),
            ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFFFF7A33)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class ReviewTile extends StatelessWidget {
  final Review review;

  const ReviewTile({super.key, required this.review});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          backgroundImage: AssetImage(review.userProfileUrl),
          radius: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Row(
                    children: List.generate(
                      5,
                      (i) => Icon(
                        i < review.rating ? Icons.star : Icons.star_border,
                        color: Colors.orange,
                        size: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                review.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 4),
              Text(
                review.text,
                style: const TextStyle(fontSize: 13, color: Colors.black87),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    review.userName,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.teal,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    "${review.date.day}/${review.date.month}/${review.date.year}",
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
