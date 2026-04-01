import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_frontend/features/client_dashboard/BookScreen/book.dart';
import 'package:mobile_frontend/features/creative_dashboard/AddPortfolioPage/video_portfolio_item.dart';
import 'package:mobile_frontend/providers/profile_provider.dart';
import 'package:mobile_frontend/services/authservice.dart';
import 'package:mobile_frontend/providers/user_provider.dart';
import 'package:mobile_frontend/features/auth/login/loginscreen.dart';
import 'package:mobile_frontend/features/creative_dashboard/ProfilePage/profileedit.dart';
import 'package:mobile_frontend/features/creative_dashboard/ProfilePage/reviewmodel.dart';
import 'package:mobile_frontend/features/creative_dashboard/rateCard.dart';
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
      final profileProvider = Provider.of<ProfileProvider>(
        context,
        listen: false,
      );

      final token = userProvider.token;
      if (token == null) {
        _redirectToLogin();
        return;
      }

      Map<String, dynamic> raw;
      List<dynamic> portfolioData = [];

      if (widget.isOwner) {
        final data = await _profileService.getProfile(token: token);
        raw = data['profile'] as Map<String, dynamic>;
        portfolioData = await _profileService.getMyPortfolio(token: token);
      } else {
        final data = await _profileService.getProfile(
          token: token,
          userId: widget
              .creativeId, // ✅ optional userId — if provided, fetches that user's profile
        );
        raw = data['profile'] ?? data;

        final portfolioRes = await http.get(
          Uri.parse(
            'https://api.photobookhq.com/api/search/portfolio?photographerId=${widget.creativeId}',
          ),
          headers: {'Authorization': 'Bearer $token'},
        );
        print(
          "📸 Public portfolio: ${portfolioRes.statusCode} ${portfolioRes.body}",
        );
        if (portfolioRes.statusCode == 200) {
          final pData = jsonDecode(portfolioRes.body);
          final items = pData is List
              ? pData
              : pData['items'] ?? pData['results'] ?? [];

          portfolioData = List<dynamic>.from(items).map((item) {
            final m = Map<String, dynamic>.from(item);
            return {
              ...m,
              'url': m['media_url'] ?? m['url'],
              'type': m['media_type'] ?? m['type'],
            };
          }).toList();
        }
      }

      final remapped = {
        'role': raw['role'] ?? 'photographer',
        'isOwner': widget.isOwner,
        'basic': {
          'businessName': raw['business_name'] ?? raw['businessName'],
          'avatarUrl':
              raw['photographer_profile_photo_url'] ?? raw['avatarUrl'],
          'displayTitle': raw['display_title'] ?? raw['displayTitle'],
          'tags': List<String>.from(raw['tags'] ?? []),
        },
        'creativeDetails': {
          'aboutMe': raw['about_me'] ?? raw['aboutMe'] ?? '',
          'portfolio': portfolioData,
          'starRating': raw['star_rating'] ?? raw['starRating'],
          'totalReviews': raw['total_reviews'] ?? raw['totalReviews'],
        },
      };

      profileProvider.setProfile(remapped);
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

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Account"),
        content: const Text(
          "Are you sure? This action is permanent and cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx); // close dialog
              final success = await _authService.deleteAccount();
              if (success && context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false, // clears the entire nav stack
                );
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Failed to delete account. Try again."),
                  ),
                );
              }
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  void _redirectToLogin() {
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
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
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFFF7A33)),
        ),
      );
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
        color: Color(0xFFFF7A33),
        backgroundColor: Colors.white,
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
                    final creative =
                        profileProvider.profile?['creativeDetails'] ?? {};
                    return ProfileHeader(
                      businessName: businessName,
                      avatarUrl: basic['avatarUrl'],
                      role: role,
                      isOwner: isOwner,
                      displayTitle: basic['displayTitle'],
                      tags: List<String>.from(basic['tags'] ?? []),
                      creativeId: widget.isOwner ? null : widget.creativeId,
                      starRating:
                          double.tryParse(
                            creative['starRating']?.toString() ?? '0',
                          ) ??
                          0,
                      totalReviews: creative['totalReviews'] ?? 0,
                      onEditComplete: () {
                        setState(() {});
                      },
                      onLogout: () => _logout(context),
                      onDeleteAccount: () => _confirmDelete(context),
                    );
                  },
                ),
                AboutMeSection(about: creative['aboutMe'] ?? ''),
                PortfolioReviewSection(),
                const SizedBox(height: 20),
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
  final String? displayTitle;
  final List<String> tags;
  final String? creativeId;
  final double starRating;
  final int totalReviews;
  final VoidCallback? onEditComplete;
  final VoidCallback? onLogout;
  final VoidCallback? onDeleteAccount;

  const ProfileHeader({
    super.key,
    required this.businessName,
    required this.avatarUrl,
    required this.role,
    required this.isOwner,
    this.tags = const [],
    this.creativeId,
    this.displayTitle,
    this.starRating = 0,
    this.totalReviews = 0,
    this.onEditComplete,
    this.onLogout,
    this.onDeleteAccount,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (!isOwner)
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.arrow_back, color: Colors.black),
                    ),
                  if (!isOwner) const SizedBox(width: 8),
                  Text(
                    isOwner
                        ? "My Profile"
                        : "$businessName${businessName.endsWith('s') ? "'" : "'s"} Profile",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (isOwner)
                PopupMenuButton<String>(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  icon: const Icon(Icons.more_vert, color: Colors.black),
                  onSelected: (value) {
                    if (value == 'logout' && onLogout != null) {
                      onLogout!();
                    } else if (value == 'delete' && onDeleteAccount != null) {
                      onDeleteAccount!();
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'logout',
                      child: Text(
                        'Logout',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text(
                        'Delete Account',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
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
                    if (isOwner)
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
                        icon: const Icon(Icons.edit, color: Colors.black),
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
                            children: [
                              ...List.generate(
                                5,
                                (i) => Icon(
                                  i < starRating.round()
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: Colors.orange,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                totalReviews > 0
                                    ? "${starRating.toStringAsFixed(1)} ($totalReviews)"
                                    : "No reviews yet",
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            displayTitle?.isNotEmpty == true
                                ? displayTitle!
                                : role == 'photographer'
                                ? 'Photographer'
                                : 'Client',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                          if (tags.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: tags
                                  .map(
                                    (tag) => Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFFFF7A33,
                                        ).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: const Color(0xFFFF7A33),
                                          width: 0.8,
                                        ),
                                      ),
                                      child: Text(
                                        tag,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Color(0xFFFF7A33),
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
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
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => BookingPage(
                                      creativeId:
                                          creativeId!, // ✅ need to pass this in
                                      name: businessName,
                                      avatarUrl: avatarUrl ?? '',
                                      rating: starRating,
                                    ),
                                  ),
                                );
                              },
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
                          const SizedBox(height: 5),
                          SizedBox(
                            height: 31,
                            width: 83,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                backgroundColor: const Color(0xFF047418),
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
                                      creativeId: creativeId ?? '',
                                      rating: starRating,
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
                      )
                    else
                      SizedBox(
                        height: 31,
                        width: 83,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: const Color(0xFF047418),
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
                                  creativeId: creativeId ?? '',
                                  rating: starRating,
                                ),
                              ),
                            );
                          },
                          child: const Text(
                            "Rate Card",
                            style: TextStyle(fontSize: 10, color: Colors.white),
                          ),
                        ),
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
            final url = item['url']?.toString() ?? '';
            final type = item['type']?.toString() ?? '';

            if (url.isEmpty) return const SizedBox.shrink();

            return ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: type == 'video'
                  ? VideoThumbnail(
                      key: ValueKey(url),
                      url: url,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              VideoPlayerPage(key: ValueKey(url), url: url),
                        ),
                      ),
                    )
                  : GestureDetector(
                      onTap: () => setState(() => expandedIndex = index),
                      child: Image.network(
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
    final url = item['url']?.toString() ?? '';
    final type = item['type']?.toString() ?? '';
    final title = item['title']?.toString() ?? '';
    final description = item['description']?.toString() ?? '';

    if (url.isEmpty) return const SizedBox.shrink();

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
