import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobile_frontend/features/client_dashboard/HomeScreen/notifications_page.dart';
import 'package:mobile_frontend/features/creative_dashboard/ProfilePage/profilepage.dart';
import 'package:mobile_frontend/providers/search_provider.dart';
import 'package:mobile_frontend/providers/user_provider.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  bool _showDropdown = false;
  GoogleMapController? _mapController;
  LatLng? _currentPosition;

  // Categories with placeholder colors until you add images
  final List<Map<String, dynamic>> _categories = [
    {'label': 'Photographers', 'color': Color(0xFFFFE0CC), 'icon': Icons.camera_alt_outlined},
    {'label': 'Videographers', 'color': Color(0xFFE8F5E9), 'icon': Icons.videocam_outlined},
    {'label': 'Content Creators', 'color': Color(0xFFE3F2FD), 'icon': Icons.phone_android_outlined},
    {'label': 'Weddings', 'color': Color(0xFFFCE4EC), 'icon': Icons.favorite_outline},
    {'label': 'Birthdays', 'color': Color(0xFFFFF9C4), 'icon': Icons.cake_outlined},
    {'label': 'Products', 'color': Color(0xFFF3E5F5), 'icon': Icons.inventory_2_outlined},
    {'label': 'Headshots', 'color': Color(0xFFE0F7FA), 'icon': Icons.portrait_outlined},
    {'label': 'Events', 'color': Color(0xFFFFF3E0), 'icon': Icons.event_outlined},
    {'label': 'Editorial', 'color': Color(0xFFEDE7F6), 'icon': Icons.auto_stories_outlined},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SearchProvider>().loadTopPhotographers();
    });
    _searchFocus.addListener(() {
      setState(() => _showDropdown =
          _searchFocus.hasFocus && _searchController.text.isNotEmpty);
    });
    _getLocation();
  }

  Future<void> _getLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) return;

      final pos = await Geolocator.getCurrentPosition();
      setState(() => _currentPosition = LatLng(pos.latitude, pos.longitude));
    } catch (e) {
      // fallback — Abuja coords
      setState(() => _currentPosition = const LatLng(9.0765, 7.3986));
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;
    final firstname = user?['name']?.split(' ').first ?? "Guest";

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Hello $firstname,",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        "Abuja, Nigeria",
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                  // Notifications bell
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NotificationsPage()),
                    ),
                    child: Stack(
                      children: [
                        const Icon(Icons.notifications_outlined, size: 28),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFF7A33),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Search Bar
              _buildSearchBar(),
              const SizedBox(height: 20),

              // Find the Right Creative Service
              const Text(
                "Find The Right Creative Service",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Text(
                "What service are you looking for?",
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 110,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    return _CategoryCard(
                      label: cat['label'],
                      color: cat['color'],
                      icon: cat['icon'],
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Top Recommendations
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Top Recommendations",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      "See all",
                      style: TextStyle(color: Color(0xFFFF7A33), fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Consumer<SearchProvider>(
                builder: (context, searchProvider, _) {
                  if (searchProvider.isLoading) {
                    return const SizedBox(
                      height: 180,
                      child: Center(child: CircularProgressIndicator(color: Color(0xFFFF7A33))),
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
                    height: 200,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: photographers.length > 10 ? 10 : photographers.length,
                      itemBuilder: (context, index) {
                        return _PhotographerCard(photographer: photographers[index]);
                      },
                    ),
                  );
                },
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
                      style: TextStyle(color: Color(0xFFFF7A33), fontSize: 13),
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
                    return _CategoryCircle(
                      label: cat['label'],
                      color: cat['color'],
                      icon: cat['icon'],
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Find Creatives Nearby
              const Text(
                "Find Creatives Nearby",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: SizedBox(
                  height: 220,
                  child: _currentPosition == null
                      ? Container(
                          color: Colors.grey.shade200,
                          child: const Center(
                            child: CircularProgressIndicator(color: Color(0xFFFF7A33)),
                          ),
                        )
                      : GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: _currentPosition!,
                            zoom: 13,
                          ),
                          myLocationEnabled: true,
                          myLocationButtonEnabled: false,
                          zoomControlsEnabled: false,
                          onMapCreated: (controller) => _mapController = controller,
                          // Creative pins will go here once location is stored
                          markers: {
                            Marker(
                              markerId: const MarkerId('me'),
                              position: _currentPosition!,
                              infoWindow: const InfoWindow(title: 'You are here'),
                            ),
                          },
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Column(
      children: [
        TextField(
          controller: _searchController,
          focusNode: _searchFocus,
          onChanged: (val) {
            context.read<SearchProvider>().onSearchChanged(val);
            setState(() => _showDropdown = val.isNotEmpty);
          },
          decoration: InputDecoration(
            hintText: "Search for creatives by style, genre, location...",
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
        if (_showDropdown) _buildSearchDropdown(),
      ],
    );
  }

  Widget _buildSearchDropdown() {
    return Consumer<SearchProvider>(
      builder: (context, searchProvider, _) {
        final photographers = searchProvider.searchPhotographers;
        final tags = searchProvider.searchTags;

        if (!searchProvider.hasSearchResults && !searchProvider.isSearching) {
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
              if (photographers.isNotEmpty) ...[
                _DropdownHeader(label: "Photographers"),
                ...photographers.map((p) {
                  final name = p['business_name'] ?? p['name'] ?? 'Unknown';
                  final avatarUrl = p['photographer_profile_photo_url'] ?? p['avatarUrl'];
                  final id = p['id'] ?? p['user_id'] ?? '';
                  final displayTitle = p['display_title'] ?? 'Photographer';
                  return ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      radius: 18,
                      backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                      child: avatarUrl == null ? const Icon(Icons.person, size: 18) : null,
                    ),
                    title: Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    subtitle: Text(displayTitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    onTap: () {
                      _searchController.clear();
                      context.read<SearchProvider>().clearSearch();
                      setState(() => _showDropdown = false);
                      _searchFocus.unfocus();
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => CreativeProfilePage(isOwner: false, creativeId: id),
                      ));
                    },
                  );
                }),
              ],
              if (photographers.isNotEmpty && tags.isNotEmpty)
                Divider(height: 1, color: Colors.grey.shade200),
              if (tags.isNotEmpty) ...[
                _DropdownHeader(label: "Categories"),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: tags.map((tag) => GestureDetector(
                      onTap: () {
                        _searchController.text = tag;
                        context.read<SearchProvider>().onSearchChanged(tag);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF7A33).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFFF7A33), width: 0.8),
                        ),
                        child: Text(tag, style: const TextStyle(fontSize: 11, color: Color(0xFFFF7A33))),
                      ),
                    )).toList(),
                  ),
                ),
              ],
              if (searchProvider.isSearching)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Center(child: SizedBox(height: 16, width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFF7A33)))),
                ),
            ],
          ),
        );
      },
    );
  }
}

// Category card (horizontal scroll service type)
class _CategoryCard extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _CategoryCard({required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 130,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 28, color: Colors.black87),
          const Spacer(),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Explore", style: TextStyle(fontSize: 10, color: Colors.grey)),
              Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF7A33),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_forward, size: 12, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Category circle (browse section)
class _CategoryCircle extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _CategoryCircle({required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, size: 24, color: Colors.black87),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 10),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _PhotographerCard extends StatelessWidget {
  final Map<String, dynamic> photographer;
  const _PhotographerCard({required this.photographer});

  @override
  Widget build(BuildContext context) {
    final name = photographer['business_name'] ?? photographer['name'] ?? 'Unknown';
    final avatarUrl = photographer['photographer_profile_photo_url'] ?? photographer['avatarUrl'];
    final rating = double.tryParse(photographer['star_rating']?.toString() ?? '0') ?? 0.0;
    final id = photographer['id'] ?? photographer['user_id'] ?? '';
    final displayTitle = photographer['display_title'] ?? 'Photographer';

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => CreativeProfilePage(isOwner: false, creativeId: id),
      )),
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: const Color(0xFFF5F9F6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              child: avatarUrl != null
                  ? Image.network(avatarUrl, width: double.infinity, height: 100, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Image.asset('assets/profileplaceholder.png',
                          width: double.infinity, height: 100, fit: BoxFit.cover))
                  : Image.asset('assets/profileplaceholder.png', width: double.infinity, height: 100, fit: BoxFit.cover),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(displayTitle, style: const TextStyle(fontSize: 10, color: Colors.grey),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: List.generate(5, (i) => Icon(
                      i < rating.round() ? Icons.star : Icons.star_border,
                      size: 12, color: Colors.orange,
                    )),
                  ),
                  TextButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => CreativeProfilePage(isOwner: false, creativeId: id),
                    )),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text("View Profile",
                        style: TextStyle(fontSize: 10, color: Color(0xFFFF7A33))),
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

class _DropdownHeader extends StatelessWidget {
  final String label;
  const _DropdownHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, top: 10, bottom: 2),
      child: Text(label.toUpperCase(),
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold,
              color: Colors.grey.shade500, letterSpacing: 0.8)),
    );
  }
}