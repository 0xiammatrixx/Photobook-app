import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mobile_frontend/features/creative_dashboard/ProfilePage/profilepage.dart';
import 'package:mobile_frontend/providers/search_provider.dart';
import 'package:mobile_frontend/providers/user_provider.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  bool _showDropdown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SearchProvider>().loadTopPhotographers();
    });
    _searchFocus.addListener(() {
      setState(
        () => _showDropdown =
            _searchFocus.hasFocus && _searchController.text.isNotEmpty,
      );
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<String> categories = [
      "assets/weddings.svg",
      "assets/birthdays.svg",
      "assets/products.svg",
    ];

    final user = Provider.of<UserProvider>(context).user;

    String firstname = user?['name']?.split(' ').first ?? "Guest";

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user != null ? "Hello ${firstname}," : "Hello Guest,",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text("Abuja, Nigeria", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 12),

              // Search Bar
              Column(
                children: [
                  TextField(
                    controller: _searchController,
                    focusNode: _searchFocus,
                    onChanged: (val) {
                      context.read<SearchProvider>().onSearchChanged(val);
                      setState(() => _showDropdown = val.isNotEmpty);
                    },
                    decoration: InputDecoration(
                      hintText:
                          "Search for creatives by style, genre, location...",
                      fillColor: const Color(0xFFFF7A33).withOpacity(0.05),
                      filled: true,
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                context.read<SearchProvider>().clearSearch();
                                setState(() => _showDropdown = false);
                                _searchFocus.unfocus();
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  if (_showDropdown)
                    Consumer<SearchProvider>(
                      builder: (context, searchProvider, _) {
                        final photographers =
                            searchProvider.searchPhotographers;
                        final tags = searchProvider.searchTags;

                        if (!searchProvider.hasSearchResults &&
                            !searchProvider.isSearching) {
                          return const SizedBox.shrink();
                        }

                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ── Photographers section ──
                              if (photographers.isNotEmpty) ...[
                                _DropdownHeader(label: "Photographers"),
                                ...photographers.map((p) {
                                  final name =
                                      p['business_name'] ??
                                      p['businessName'] ??
                                      p['name'] ??
                                      'Unknown';
                                  final avatarUrl =
                                      p['photographer_profile_photo_url'] ??
                                      p['avatarUrl'];
                                  final id = p['id'] ?? p['user_id'] ?? '';
                                  final displayTitle =
                                      p['display_title'] ??
                                      p['displayTitle'] ??
                                      'Photographer';

                                  return ListTile(
                                    dense: true,
                                    leading: CircleAvatar(
                                      radius: 18,
                                      backgroundImage: avatarUrl != null
                                          ? NetworkImage(avatarUrl)
                                          : null,
                                      child: avatarUrl == null
                                          ? const Icon(Icons.person, size: 18)
                                          : null,
                                    ),
                                    title: Text(
                                      name,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: Text(
                                      displayTitle,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    onTap: () {
                                      _searchController.clear();
                                      context
                                          .read<SearchProvider>()
                                          .clearSearch();
                                      setState(() => _showDropdown = false);
                                      _searchFocus.unfocus();
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => CreativeProfilePage(
                                            isOwner: false,
                                            creativeId: id,
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                }),
                              ],

                              // Divider between sections
                              if (photographers.isNotEmpty && tags.isNotEmpty)
                                Divider(height: 1, color: Colors.grey.shade200),

                              // ── Categories/Tags section ──
                              if (tags.isNotEmpty) ...[
                                _DropdownHeader(label: "Categories"),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  child: Wrap(
                                    spacing: 8,
                                    runSpacing: 6,
                                    children: tags.map((tag) {
                                      return GestureDetector(
                                        onTap: () {
                                          _searchController.text = tag;
                                          context
                                              .read<SearchProvider>()
                                              .onSearchChanged(tag);
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(
                                              0xFFFF7A33,
                                            ).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            border: Border.all(
                                              color: const Color(0xFFFF7A33),
                                              width: 0.8,
                                            ),
                                          ),
                                          child: Text(
                                            tag,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Color(0xFFFF7A33),
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],

                              // Loading indicator
                              if (searchProvider.isSearching)
                                const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Center(
                                    child: SizedBox(
                                      height: 16,
                                      width: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFFFF7A33),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
              const SizedBox(height: 20),

              // Top Recommendations
              const Text(
                "Top Recommendations",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 180,
                child: Consumer<SearchProvider>(
                  builder: (context, searchProvider, _) {
                    if (searchProvider.isLoading) {
                      return const SizedBox(
                        height: 180,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFFF7A33),
                          ),
                        ),
                      );
                    }

                    final photographers = searchProvider.topPhotographers;

                    if (photographers.isEmpty) {
                      return const SizedBox(
                        height: 180,
                        child: Center(child: Text("No recommendations yet")),
                      );
                    }

                    return SizedBox(
                      height: 180,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: photographers.length > 10
                            ? 10
                            : photographers.length,
                        itemBuilder: (context, index) {
                          final p = photographers[index];
                          return _PhotographerCard(photographer: p);
                        },
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              // Categories
              const Text(
                "Browse by Category",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 90,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    return Container(
                      width: 80,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey.shade200,
                      ),
                      alignment: Alignment.center,
                      child: SvgPicture.asset(categories[index]),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              // Map Placeholder
              const Text(
                "Find Creatives Nearby",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.grey.shade300,
                ),
                alignment: Alignment.center,
                child: SvgPicture.asset('assets/map.svg'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotographerCard extends StatelessWidget {
  final Map<String, dynamic> photographer;

  const _PhotographerCard({required this.photographer});

  @override
  Widget build(BuildContext context) {
    final name =
        photographer['business_name'] ??
        photographer['businessName'] ??
        photographer['name'] ??
        'Unknown';
    final avatarUrl =
        photographer['photographer_profile_photo_url'] ??
        photographer['avatarUrl'];
    final rating =
        double.tryParse(photographer['star_rating']?.toString() ?? '0') ?? 0.0;
    final id = photographer['id'] ?? photographer['user_id'] ?? '';
    final displayTitle =
        photographer['display_title'] ??
        photographer['displayTitle'] ??
        'Photographer';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CreativeProfilePage(isOwner: false, creativeId: id),
          ),
        );
      },
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: const Color(0xFFF5F9F6),
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: avatarUrl != null
                  ? Image.network(
                      avatarUrl,
                      width: double.infinity,
                      height: 90,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Image.asset(
                        'assets/profileplaceholder.png',
                        width: double.infinity,
                        height: 90,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Image.asset(
                      'assets/profileplaceholder.png',
                      width: double.infinity,
                      height: 90,
                      fit: BoxFit.cover,
                    ),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              displayTitle,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: List.generate(
                5,
                (i) => Icon(
                  i < rating.round() ? Icons.star : Icons.star_border,
                  size: 12,
                  color: Colors.orange,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DropdownHeader extends StatelessWidget {
  final String label;
  const _DropdownHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, top: 10, bottom: 2),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade500,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
