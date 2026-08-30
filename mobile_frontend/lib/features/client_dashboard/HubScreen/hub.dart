import 'package:flutter/material.dart';
import 'package:mobile_frontend/app/skeleton.dart';
import 'package:mobile_frontend/features/creative_dashboard/ProfilePage/profilepage.dart';
import 'package:mobile_frontend/providers/location_provider.dart';
import 'package:mobile_frontend/providers/search_provider.dart';
import 'package:provider/provider.dart';

class HubScreen extends StatefulWidget {
  const HubScreen({super.key});

  @override
  State<HubScreen> createState() => _HubScreenState();
}

class _HubScreenState extends State<HubScreen> {
  String _filter = 'All'; // All | Photography | Videography | Content Creators
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SearchProvider>().loadHubCreatives('all');
    });
  }

  final List<Map<String, String>> _categories = [
    {'label': 'Weddings', 'image': 'assets/Weddings.png'},
    {'label': 'Birthdays', 'image': 'assets/Birthdays.png'},
    {'label': 'Products', 'image': 'assets/Products.png'},
    {'label': 'Headshots', 'image': 'assets/Headshots.png'},
    {'label': 'Events', 'image': 'assets/Events.png'},
    {'label': 'Editorial', 'image': 'assets/Editorial.png'},
  ];

  final List<Map<String, String>> _styles = [
    {'label': 'Vintage', 'image': 'assets/Vintage.png', 'text': 'baked'},
    {'label': 'Cinematic', 'image': 'assets/Cinematic.png', 'text': 'baked'},
    {'label': 'Luxury', 'image': 'assets/Luxury.png', 'text': 'baked'},
    {'label': 'Candid', 'image': 'assets/Candid.png', 'text': 'baked'},
    {
      'label': 'Bold and Colourful',
      'image': 'assets/boldandbeautiful.jpg',
      'text': 'overlay',
    },
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Text(
                "Creative's Hub",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Consumer<LocationProvider>(
                builder: (_, loc, __) => Text(
                  loc.currentCity ?? 'Loading location...',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ),
              const SizedBox(height: 12),

              // Search Bar with filter icon
              TextField(
                controller: _searchCtrl,
                onChanged: (v) =>
                    context.read<SearchProvider>().onSearchChanged(v),
                decoration: InputDecoration(
                  hintText:
                      "Search for creatives by style, genre, location...",
                  fillColor: Colors.orange.shade50,
                  filled: true,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: const Icon(Icons.tune, color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Browse by Category
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Browse by Category",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      "See all",
                      style: TextStyle(
                          color: Color(0xFFFF7A33), fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 90,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    return _CategoryTile(
                        label: cat['label']!, image: cat['image']!);
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Find Your Style
              const Text(
                "Find Your Style",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 140,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _styles.length,
                  itemBuilder: (context, index) {
                    final style = _styles[index];
                    return _StyleCard(
                      label: style['label']!,
                      image: style['image']!,
                      overlayText: style['text'] == 'overlay',
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Explore Other Creatives
              const Text(
                "Explore Other Creatives",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              // Filter chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['All', 'Photography', 'Videography', 'Content Creators']
                    .map(
                      (f) => GestureDetector(
                        onTap: () {
                          setState(() => _filter = f);
                          final role = switch (f) {
                            'Photography' => 'photographer',
                            'Videography' => 'videographer',
                            'Content Creators' => 'content_creator',
                            _ => 'all',
                          };
                          context
                              .read<SearchProvider>()
                              .loadHubCreatives(role);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: _filter == f
                                ? const Color(0xFFFF7A33)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _filter == f
                                  ? const Color(0xFFFF7A33)
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: Text(
                            f,
                            style: TextStyle(
                              fontSize: 12,
                              color: _filter == f
                                  ? Colors.white
                                  : Colors.black,
                              fontWeight: _filter == f
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 12),

              // Creatives grid
              Consumer<SearchProvider>(
                builder: (context, searchProvider, _) {
                  if (searchProvider.hubLoading) {
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 0.72,
                      ),
                      itemCount: 6,
                      itemBuilder: (context, index) => const SkeletonPulse(
                        child: SkeletonBox(
                          width: double.infinity,
                          height: double.infinity,
                          radius: 14,
                        ),
                      ),
                    );
                  }

                  // Dedupe — the API can return the same creative multiple
                  // times (e.g. once per portfolio item). Keys vary by
                  // endpoint, so try all the common user id field names.
                  final seen = <String>{};
                  final creatives = searchProvider.hubCreatives.where((p) {
                    final key = (p['photographer_id'] ??
                            p['photographerId'] ??
                            p['user_id'] ??
                            p['id'] ??
                            p['business_name'] ??
                            p['businessName'] ??
                            '')
                        .toString();
                    if (key.isEmpty) return true;
                    if (seen.contains(key)) return false;
                    seen.add(key);
                    return true;
                  }).toList();

                  if (creatives.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: Text('No creatives found',
                            style: TextStyle(color: Colors.grey)),
                      ),
                    );
                  }

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 0.72,
                    ),
                    itemCount: creatives.length,
                    itemBuilder: (context, index) =>
                        _CreativeCard(creative: creatives[index]),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Category tile (circular image + label) ──
class _CategoryTile extends StatelessWidget {
  final String label;
  final String image;
  const _CategoryTile({required this.label, required this.image});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 76,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          ClipOval(
            child: Image.asset(
              image,
              width: 62,
              height: 62,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 62,
                height: 62,
                color: Colors.grey.shade200,
                child: const Icon(Icons.image, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── Style card (tall image + label) ──
class _StyleCard extends StatelessWidget {
  final String label;
  final String image;
  final bool overlayText;
  const _StyleCard({
    required this.label,
    required this.image,
    this.overlayText = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        image: DecorationImage(
          image: AssetImage(image),
          fit: BoxFit.cover,
          onError: (_, __) {},
        ),
      ),
      child: overlayText
          ? Container(
              alignment: Alignment.bottomLeft,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
              child: Text(
                label.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            )
          : null,
    );
  }
}

// ── Creative card in grid ──
class _CreativeCard extends StatelessWidget {
  final Map<String, dynamic> creative;
  const _CreativeCard({required this.creative});

  @override
  Widget build(BuildContext context) {
    final name =
        creative['business_name'] ?? creative['name'] ?? 'Creative';
    final avatarUrl = creative['photographer_profile_photo_url'] ??
        creative['avatarUrl'] ??
        creative['profile_photo_url'];
    final id = creative['photographer_id'] ??
        creative['photographerId'] ??
        creative['user_id'] ??
        creative['id'] ??
        '';
    final role = creative['display_title'] ?? 'Photographer';
    final rating = double.tryParse(
            creative['star_rating']?.toString() ?? '0') ??
        0.0;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              CreativeProfilePage(isOwner: false, creativeId: id),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: const Color(0xFFF5F9F6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(15)),
                child: SizedBox(
                  width: double.infinity,
                  child: avatarUrl != null
                      ? Image.network(
                          avatarUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: const Color(0xFFE8F5E9),
                            child: const Center(
                              child: Icon(Icons.person,
                                  size: 40, color: Colors.grey),
                            ),
                          ),
                        )
                      : Container(
                          color: const Color(0xFFE8F5E9),
                          child: const Center(
                            child: Icon(Icons.person,
                                size: 40, color: Colors.grey),
                          ),
                        ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    role,
                    style: const TextStyle(
                        fontSize: 10, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: List.generate(
                      5,
                      (i) => Icon(
                        i < rating.round()
                            ? Icons.star
                            : Icons.star_border,
                        size: 12,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CreativeProfilePage(
                            isOwner: false, creativeId: id),
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'View Profile',
                      style:
                          TextStyle(fontSize: 10, color: Color(0xFFFF7A33)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
