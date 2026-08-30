import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobile_frontend/app/skeleton.dart';
import 'package:mobile_frontend/features/client_dashboard/HomeScreen/notifications_page.dart';
import 'package:mobile_frontend/features/creative_dashboard/ProfilePage/profilepage.dart';
import 'package:mobile_frontend/providers/location_provider.dart';
import 'package:mobile_frontend/providers/notification_provider.dart';
import 'package:mobile_frontend/providers/search_provider.dart';
import 'package:mobile_frontend/providers/user_provider.dart';
import 'package:mobile_frontend/services/location_service.dart';
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
  MapController? _mapController;
  LatLng? _currentPosition;

  // What are you looking for? — only these three
  final List<Map<String, String>> _services = [
    {
      'title': 'Photographers',
      'subtitle': 'Capture your special memories.',
      'image': 'assets/Photographers.png',
    },
    {
      'title': 'Videographers',
      'subtitle': 'Bring your stories to life.',
      'image': 'assets/Videographers.png',
    },
    {
      'title': 'Content Creators',
      'subtitle': 'Create content that stands out.',
      'image': 'assets/ContentCreator.png',
    },
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
      final loc = LatLng(pos.latitude, pos.longitude);
      setState(() => _currentPosition = loc);

      // Load nearby creatives + resolve city name
      if (mounted) {
        final locProvider = context.read<LocationProvider>();
        locProvider.resolveCityName(pos.latitude, pos.longitude);
        locProvider.loadNearby(lat: pos.latitude, lng: pos.longitude);
      }
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
                        "Hi, $firstname 👋",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        "Find and book the perfect creative for\nyour next unforgettable moment.",
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      Consumer<LocationProvider>(
                        builder: (_, loc, __) => Text(
                          loc.currentCity ?? 'Loading location...',
                          style: const TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  // Notifications bell
                  GestureDetector(
                    onTap: () {
                      context.read<NotificationProvider>().load();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const NotificationsPage()),
                      );
                    },
                    child: Stack(
                      children: [
                        const Icon(Icons.notifications_outlined, size: 28),
                        Consumer<NotificationProvider>(
                          builder: (_, notif, __) {
                            if (notif.unreadCount == 0) {
                              return const SizedBox.shrink();
                            }
                            return Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFF7A33),
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  notif.unreadCount > 9
                                      ? '9+'
                                      : '${notif.unreadCount}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          },
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

              // What are you looking for?
              const Text(
                "What are you looking for?",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _services.length,
                  itemBuilder: (context, index) => _ServiceCard(
                    image: _services[index]['image']!,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Available Near You
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Available Near You",
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
              Consumer<LocationProvider>(
                builder: (context, locProvider, _) {
                  if (locProvider.isLoading) {
                    return SizedBox(
                      height: 200,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: 3,
                        separatorBuilder: (_, __) =>
                            const SizedBox(width: 12),
                        itemBuilder: (_, __) => const SkeletonPulse(
                          child: SkeletonBox(
                            width: 140,
                            height: 200,
                            radius: 14,
                          ),
                        ),
                      ),
                    );
                  }
                  final nearby = locProvider.nearbyCreatives;
                  if (nearby.isEmpty) {
                    return SizedBox(
                      height: 180,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.location_off, size: 40, color: Colors.grey.shade400),
                            const SizedBox(height: 8),
                            const Text(
                              "No creatives nearby yet",
                              style: TextStyle(color: Colors.grey),
                            ),
                            const Text(
                              "Enable location sharing to see creatives near you",
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return SizedBox(
                    height: 200,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: nearby.length > 10 ? 10 : nearby.length,
                      itemBuilder: (context, index) {
                        final c = nearby[index];
                        return _NearbyCard(creative: c);
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),

              // Explore Creatives Around You
              const Text(
                "Explore Creatives Around You",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Text(
                "See who's ready and how far they are.",
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: SizedBox(
                  height: 220,
                  child: _currentPosition == null
                      ? const SkeletonPulse(
                          child: SkeletonBox(
                            width: double.infinity,
                            height: double.infinity,
                            radius: 0,
                          ),
                        )
                      : Consumer<LocationProvider>(
                          builder: (_, locProvider, __) {
                            final markers = <Marker>[
                              Marker(
                                point: _currentPosition!,
                                width: 28,
                                height: 28,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 2),
                                  ),
                                ),
                              ),
                              for (final c in locProvider.nearbyCreatives)
                                Marker(
                                  point: LatLng(c.latitude, c.longitude),
                                  width: 36,
                                  height: 36,
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => CreativeProfilePage(
                                            isOwner: false,
                                            creativeId: c.userId,
                                          ),
                                        ),
                                      );
                                    },
                                    child: const Icon(
                                      Icons.location_pin,
                                      color: Color(0xFFFF7A33),
                                      size: 36,
                                    ),
                                  ),
                                ),
                            ];
                            return Stack(
                              children: [
                                FlutterMap(
                                  mapController: _mapController,
                                  options: MapOptions(
                                    initialCenter: _currentPosition!,
                                    initialZoom: 13,
                                  ),
                                  children: [
                                    TileLayer(
                                      urlTemplate:
                                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                      userAgentPackageName:
                                          'com.example.mobile_frontend',
                                    ),
                                    MarkerLayer(markers: markers),
                                  ],
                                ),
                                if (locProvider.nearbyCreatives.isNotEmpty)
                                  Positioned(
                                    left: 10,
                                    bottom: 10,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.15),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            '${locProvider.nearbyCreatives.length} creatives nearby',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                          const Text(
                                            'Within 45mins drive',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            );
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

// "What are you looking for?" card — horizontal tile, the whole card IS
// the image (text is baked into the asset), same size as Hub category tiles.
class _ServiceCard extends StatelessWidget {
  final String image;

  const _ServiceCard({required this.image});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // TODO: navigate to category results
      },
      child: Container(
        width: 130,
        margin: const EdgeInsets.only(right: 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            image,
            width: 130,
            height: 100,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: const Color(0xFFFFE0CC),
              child: const Center(
                child: Icon(Icons.image, color: Colors.grey),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Nearby creative card — shows distance
class _NearbyCard extends StatelessWidget {
  final NearbyCreative creative;
  const _NearbyCard({required this.creative});

  @override
  Widget build(BuildContext context) {
    final name = creative.name ?? 'Creative';
    final role = creative.role ?? 'photographer';
    final km = creative.distanceKm;

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => CreativeProfilePage(
            isOwner: false, creativeId: creative.userId),
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
            // Avatar placeholder
            Container(
              height: 100,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                color: Color(0xFFE8F5E9),
              ),
              child: const Center(
                child: Icon(Icons.person, size: 48, color: Colors.grey),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  Text(
                    role == 'photographer' ? 'Photographer' : role,
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (km != null)
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            size: 12, color: Color(0xFFFF7A33)),
                        const SizedBox(width: 2),
                        Text(
                          '${km.toStringAsFixed(1)} km',
                          style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFFFF7A33),
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => CreativeProfilePage(
                          isOwner: false, creativeId: creative.userId),
                    )),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text("View Profile",
                        style: TextStyle(
                            fontSize: 10, color: Color(0xFFFF7A33))),
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