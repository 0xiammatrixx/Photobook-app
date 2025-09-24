import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mobile_frontend/features/creative_dashboard/ProfilePage/reviewmodel.dart';

class CreativeProfilePage extends StatelessWidget {
  const CreativeProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProfileHeader(),
            AboutMeSection(),
            PortfolioReviewSection(),
          ],
        ),
      ),
    );
  }
}

/// ------------------ PROFILE HEADER ------------------ ///
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "My Profile",
            textAlign: TextAlign.start,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: Color(0xFFF5F9F6),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: SvgPicture.asset(
                    "assets/timmonprofile.svg", // replace with network if needed
                    width: 117,
                    height: 103,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 40),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Timmon Photography",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: const [
                              Icon(
                                Icons.star,
                                color: Color(0xFFFF9F05),
                                size: 12,
                              ),
                              Icon(
                                Icons.star,
                                color: Color(0xFFFF9F05),
                                size: 12,
                              ),
                              Icon(
                                Icons.star,
                                color: Color(0xFFFF9F05),
                                size: 12,
                              ),
                              Icon(
                                Icons.star,
                                color: Color(0xFFFF9F05),
                                size: 12,
                              ),
                              Icon(
                                Icons.star_border,
                                color: Color(0xFFFF9F05),
                                size: 12,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Corporate Photographer",
                            style: TextStyle(color: Colors.grey, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
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
                              backgroundColor: Color(0xFFFF7A33),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
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
                        SizedBox(height: 5),
                        SizedBox(
                          height: 31,
                          width: 83,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.zero,
                              backgroundColor: Colors.white,
                              side: BorderSide(color: Colors.black),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
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
  const AboutMeSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: Color(0xFFF5F9F6),
      ),
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "About Me",
            textAlign: TextAlign.start,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            "Passionate about capturing stories through the lens, I specialize in portrait, lifestyle, and CORPORATE event photography. My work blends natural light with bold composition to create timeless, emotive images. I believe every moment holds beauty, and my goal is to freeze it with authenticity and style. With years of hands-on experience and a love for visual storytelling,",
            textAlign: TextAlign.start,
            style: TextStyle(color: Colors.black, fontSize: 12),
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
  int? expandedIndex; // which image is expanded

  final List<String> portfolioImages = [
    "assets/portfolio6.svg",
    "assets/portfolio5.svg",
    "assets/portfolio4.svg",
    "assets/portfolio3.svg",
    "assets/portfolio2.svg",
    "assets/portfolio1.svg",
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: Color(0xFFF5F9F6),
      ),
      padding: const EdgeInsets.all(16),
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
                  expandedIndex = null; // reset any expanded state
                }),
                child: Text(
                  "Portfolio",
                  style: TextStyle(
                    fontWeight: showPortfolio
                        ? FontWeight.bold
                        : FontWeight.w700,
                    color: showPortfolio ? Color(0xFF047418) : Colors.black,
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
                    color: !showPortfolio ? Color(0xFF047418) : Colors.black,
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
                  ? _buildGrid() // grid view
                  : _buildExpandedImage(
                      expandedIndex!,
                    ), // single expanded image
            )
          else
            _buildReviewsSection(),
        ],
      ),
    );
  }

  /// Grid view
  Widget _buildGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: portfolioImages.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, // 3 per row
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () => setState(() => expandedIndex = index),
          child: Stack(
            children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: SvgPicture.asset(
                    portfolioImages[index],
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const Positioned(
                bottom: 12,
                right: 12,
                child: Icon(Icons.visibility, color: Colors.white, size: 16),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Expanded single image
  Widget _buildExpandedImage(int index) {
    return GestureDetector(
      onTap: () => setState(() => expandedIndex = null), // collapse
      child: Stack(
        children: [
          AspectRatio(
            aspectRatio: 16 / 9, // keeps it nice, you can adjust
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: SvgPicture.asset(
                portfolioImages[index],
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
          ),
          const Positioned(
            top: 12,
            right: 12,
            child: Icon(Icons.visibility_off, color: Colors.white, size: 16),
          ),
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
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
        title: Text("My Reviews (${widget.reviews.length})", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),),
      ),
      body: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: Color(0xFFF5F9F6),
        ),
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.symmetric(horizontal: 16),
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
