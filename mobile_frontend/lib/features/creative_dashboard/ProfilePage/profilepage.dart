import 'package:flutter/material.dart';
import 'package:mobile_frontend/app/profile_provider.dart';
import 'package:mobile_frontend/services/authservice.dart';
import 'package:mobile_frontend/app/user_provider.dart';
import 'package:mobile_frontend/features/auth/login/loginscreen.dart';
import 'package:mobile_frontend/features/creative_dashboard/ProfilePage/profileedit.dart';
import 'package:mobile_frontend/features/creative_dashboard/ProfilePage/reviewmodel.dart';
import 'package:mobile_frontend/features/creative_dashboard/rateCard.dart';
import 'package:mobile_frontend/services/profileservice.dart';
import 'package:provider/provider.dart';

class CreativeProfilePage extends StatefulWidget {
  const CreativeProfilePage({super.key});

  @override
  State<CreativeProfilePage> createState() => _CreativeProfilePageState();
}

class _CreativeProfilePageState extends State<CreativeProfilePage> {
  final _profileService = ProfilePortfolioService();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile({bool initial = false}) async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final profileProvider = Provider.of<ProfileProvider>(
        context,
        listen: false,
      );

      final userId = userProvider.user?['_id'];
      final token = userProvider.token;
      if (userId == null || token == null) return;

      final data = await _profileService.getProfile(userId, token: token);
      print("🔗 Avatar URL from backend: ${data['basic']?['avatarUrl']}");
      profileProvider.setProfile(data);

      print(
        "🧩 Profile loaded for ${data['role']}, isOwner: ${data['isOwner']}",
      );
    } catch (e) {
      print("❌ Error loading profile: $e");
    }
  }

  Future<void> _logout(BuildContext context) async {
    await AuthService().logout();

    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginPage()));
  }

  @override
  Widget build(BuildContext context) {
    final profile = Provider.of<ProfileProvider>(context).profile;
    final userProvider = Provider.of<UserProvider>(context);

    if (profile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final basic = profile['basic'] ?? {};
    final creative = profile['creativeDetails'] ?? {};
    final isOwner = profile['isOwner'] ?? false;
    final role = profile['role'] ?? 'client';
    final businessName = isOwner
        ? (userProvider.user?['basic']?['businessName'] ??
              basic['businessName'] ??
              'No Name')
        : (basic['businessName'] ?? 'No Name');

    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: () => _loadProfile(initial: false),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Consumer<ProfileProvider>(
                  builder: (context, profileProvider, _) {
                    final basic = profileProvider.profile?['basic'] ?? {};
                    return ProfileHeader(
                      businessName: businessName,
                      avatarUrl: basic['avatarUrl'],
                      role: role,
                      isOwner: isOwner,
                      onEditComplete: () {
                        setState(() {});
                      },
                    );
                  },
                ),
                AboutMeSection(about: creative['aboutMe'] ?? ''),
                PortfolioReviewSection(),
                const SizedBox(height: 20),
                //if (isOwner)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _logout(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFAA0A0A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: const Text(
                        'Logout',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ------------------ PROFILE HEADER ------------------ ///
class ProfileHeader extends StatelessWidget {
  final String businessName;
  final String? avatarUrl;
  final String role;
  final bool isOwner;
  final VoidCallback? onEditComplete;

  const ProfileHeader({
    super.key,
    required this.businessName,
    required this.avatarUrl,
    required this.role,
    required this.isOwner,
    this.onEditComplete,
  });

  @override
  Widget build(BuildContext context) {
    final imageWidget = avatarUrl != null
        ? ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Image.network(
              avatarUrl!,
              width: 117,
              height: 103,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Image.asset(
                "assets/profileplaceholder.png",
                width: 117,
                height: 103,
              ),
            ),
          )
        : Image.asset("assets/profileplaceholder.png", width: 117, height: 103);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          isOwner
              ? const Text(
                  "My Profile",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                )
              : Text(
                  "$businessName${businessName.endsWith('s') ? "'" : "'s"} Profile",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
          const SizedBox(height: 5),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: const Color(0xFFF5F9F6),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    imageWidget,
                    IconButton(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const EditProfilePage(),
                          ),
                        );
                        if (result == true && onEditComplete != null) {
                          onEditComplete!();
                        }
                      },
                      icon: Icon(Icons.edit, color: Colors.black),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            businessName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: List.generate(
                              5,
                              (index) => Icon(
                                Icons.star,
                                color: Colors.orange,
                                size: 18,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            role == 'photographer' ? "Photographer" : "Client",
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Hide buttons if user is viewing their own profile
                    if (!isOwner)
                      Column(
                        children: [
                          SizedBox(
                            height: 31,
                            width: 83,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: EdgeInsets.zero,
                                backgroundColor: const Color(0xFFFF7A33),
                              ),
                              onPressed: () {},
                              child: const Text(
                                "Book Now",
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 5),
                          SizedBox(
                            height: 31,
                            width: 83,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Colors.white,
                                side: const BorderSide(color: Colors.black),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: EdgeInsets.zero,
                              ),
                              onPressed: () {},
                              child: const Text(
                                "Message",
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      Column(
                        children: [
                          SizedBox(
                            height: 31,
                            width: 83,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Color(0xFF047418),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: EdgeInsets.zero,
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => RateCardPage(
                                      isOwner: isOwner,
                                      businessName: businessName,
                                      avatarUrl: avatarUrl,
                                    ),
                                  ),
                                );
                              },
                              child: const Text(
                                "Rate Card",
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ------------------ ABOUT ME ------------------ ///
class AboutMeSection extends StatelessWidget {
  final String about;
  const AboutMeSection({super.key, required this.about});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: Color(0xFFF5F9F6),
      ),
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "About Me",
            textAlign: TextAlign.start,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            about.isNotEmpty ? about : "No description added yet.",
            textAlign: TextAlign.start,
            style: const TextStyle(color: Colors.black, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

/// ------------------ PORTFOLIO + REVIEWS ------------------ ///
class PortfolioReviewSection extends StatefulWidget {
  const PortfolioReviewSection({super.key});

  @override
  State<PortfolioReviewSection> createState() => _PortfolioReviewSectionState();
}

class _PortfolioReviewSectionState extends State<PortfolioReviewSection> {
  bool showPortfolio = true;
  int? expandedIndex;

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context);
    final creative = profileProvider.profile?['creativeDetails'] ?? {};
    final portfolio = List<Map<String, dynamic>>.from(
      creative['portfolio'] ?? [],
    );

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: const Color(0xFFF5F9F6),
      ),
      padding: const EdgeInsets.only(right: 16, left: 16, bottom: 16),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Toggle row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () => setState(() {
                  showPortfolio = true;
                  expandedIndex = null;
                }),
                child: Text(
                  "Portfolio",
                  style: TextStyle(
                    fontWeight: showPortfolio
                        ? FontWeight.bold
                        : FontWeight.w700,
                    color: showPortfolio
                        ? const Color(0xFF047418)
                        : Colors.black,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => setState(() {
                  showPortfolio = false;
                  expandedIndex = null;
                }),
                child: Text(
                  "Reviews",
                  style: TextStyle(
                    fontWeight: !showPortfolio
                        ? FontWeight.bold
                        : FontWeight.w700,
                    color: !showPortfolio
                        ? const Color(0xFF047418)
                        : Colors.black,
                  ),
                ),
              ),
            ],
          ),

          // Content
          if (showPortfolio)
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: expandedIndex == null
                  ? _buildPortfolioGrid(portfolio)
                  : _buildExpandedItem(portfolio[expandedIndex!]),
            )
          else
            _buildReviewsSection(),
        ],
      ),
    );
  }

  /// Portfolio Grid (images/videos)
  Widget _buildPortfolioGrid(List<Map<String, dynamic>> portfolio) {
    if (portfolio.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          "No portfolio items yet.",
          style: TextStyle(fontSize: 13, color: Colors.grey),
        ),
      );
    }

    final visibleItems = portfolio.length > 9
        ? portfolio.take(9).toList()
        : portfolio;

    return Column(
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: visibleItems.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
          ),
          itemBuilder: (context, index) {
            final item = visibleItems[index];
            final url = item['url'];
            final type = item['type'];

            return GestureDetector(
              onTap: () => setState(() => expandedIndex = index),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: type == 'video'
                    ? Stack(
                        alignment: Alignment.center,
                        children: [
                          Image.network(
                            url,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.videocam, color: Colors.grey),
                          ),
                          const Icon(
                            Icons.play_circle_fill,
                            color: Colors.white70,
                            size: 28,
                          ),
                        ],
                      )
                    : Image.network(
                        url,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.broken_image, color: Colors.grey),
                      ),
              ),
            );
          },
        ),
        if (portfolio.length > 9)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FullPortfolioPage(portfolio: portfolio),
                  ),
                );
              },
              child: const Text(
                "See more",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Expanded single portfolio item (preview mode)
  Widget _buildExpandedItem(Map<String, dynamic> item) {
    final url = item['url'];
    final type = item['type'];
    final title = item['title'] ?? '';
    final description = item['description'] ?? '';

    return GestureDetector(
      onTap: () => setState(() => expandedIndex = null),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: type == 'video'
                ? Stack(
                    alignment: Alignment.center,
                    children: [
                      Image.network(
                        url,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.videocam,
                          size: 80,
                          color: Colors.grey,
                        ),
                      ),
                      const Icon(
                        Icons.play_circle_outline,
                        color: Colors.white70,
                        size: 48,
                      ),
                    ],
                  )
                : Image.network(
                    url,
                    fit: BoxFit.contain,
                    width: double.infinity,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.broken_image, color: Colors.grey),
                  ),
          ),
          const SizedBox(height: 8),
          if (title.isNotEmpty)
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          if (description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ),
          const SizedBox(height: 8),
          const Icon(Icons.visibility_off, color: Colors.grey, size: 16),
        ],
      ),
    );
  }

  Widget _buildReviewsSection() {
    final List<Review> mockReviews = [
      Review(
        userProfileUrl: "assets/avatar1.png",
        userName: "John Doe",
        title: "Great experience!",
        text: "Loved the work, very professional.",
        rating: 5,
        date: DateTime.now(),
      ),
      Review(
        userName: 'Goodie Martins',
        userProfileUrl: "assets/avatar1.png",
        rating: 5,
        title: 'Best Corporate Photographer Ever',
        text:
            'A close friend referred me to him. I employed his services for one of my organisation’s monthly in- house meetings and he delivered excellently.',
        date: DateTime(2025, 8, 12),
      ),
      Review(
        userName: 'Salem Ochidi',
        userProfileUrl: "assets/avatar1.png",
        rating: 4,
        title: 'He’s quite reliable',
        text:
            'I found him on the app. He was quite reliable and professional as opposed to past experiences with photographers and videographers. I can recommend him.',
        date: DateTime(2025, 8, 12),
      ),
      Review(
        userProfileUrl: "assets/avatar2.png",
        userName: "Jane Smith",
        title: "Okay job",
        text: "It was fine, but could be faster.",
        rating: 3,
        date: DateTime(2025, 8, 12),
      ),
      // add more...
    ];

    final reviews = mockReviews; // Replace with your real backend data

    return Column(
      children: [
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: reviews.length > 3
              ? 3
              : reviews.length, // show 3 initially
          separatorBuilder: (_, __) => const Divider(height: 20),
          itemBuilder: (context, index) {
            return ReviewTile(review: reviews[index]);
          },
        ),
        if (reviews.length > 3)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                // Navigate to full screen reviews
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => FullReviewsPage(reviews: reviews),
                  ),
                );
              },
              child: const Text(
                "See more",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
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
                        child: CircularProgressIndicator(),
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
    setState(() => _isLoading = true);
    await Future.delayed(
      const Duration(milliseconds: 500),
    ); // simulate network delay

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
        child: GridView.builder(
          controller: _controller,
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
          ),
          itemCount: loadedItems.length + (_hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index < loadedItems.length) {
              final item = loadedItems[index];
              final url = item['url'];
              final type = item['type'];

              return ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: type == 'video'
                    ? Stack(
                        alignment: Alignment.center,
                        children: [
                          Image.network(
                            url,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.videocam, color: Colors.grey),
                          ),
                          const Icon(
                            Icons.play_circle_fill,
                            color: Colors.white70,
                            size: 28,
                          ),
                        ],
                      )
                    : Image.network(
                        url,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.broken_image, color: Colors.grey),
                      ),
              );
            } else {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              );
            }
          },
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
