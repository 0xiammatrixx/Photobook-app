import 'package:flutter/material.dart';
import 'package:mobile_frontend/features/client_dashboard/placeholdercard.dart';

class HubScreen extends StatelessWidget {
  const HubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> recommendations = [
      {"name": "Pictures and U", "rating": 5},
      {"name": "Timmon Photography", "rating": 5},
      {"name": "Zero to 1 Photos", "rating": 5},
    ];

    final List<Map<String, dynamic>> others = [
      {"name": "Yur Studios Pics", "rating": 4},
      {"name": "Pictures N", "rating": 4},
      {"name": "Zero & 1 Photos", "rating": 4},
      {"name": "Picturez by Eze", "rating": 3},
      {"name": "Fotography", "rating": 5},
    ];

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Creative's Hub", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const Text("Abuja, Nigeria", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 12),

              // Search Bar
              TextField(
                decoration: InputDecoration(
                  hintText: "Search for creatives by style, genre, location...",
                  fillColor: Colors.orange.shade50,
                  filled: true,
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Top Recommendations
              const Text("Top Recommendations", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              SizedBox(
                height: 180,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: recommendations.length,
                  itemBuilder: (context, index) {
                    final item = recommendations[index];
                    return PlaceholderCard(title: item["name"], rating: item["rating"]);
                  },
                ),
              ),

              const SizedBox(height: 20),

              // Other Creatives
              const Text("Other Creatives", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: others.map((creative) {
                  return SizedBox(
                    width: MediaQuery.of(context).size.width / 2 - 24,
                    child: PlaceholderCard(
                      title: creative["name"],
                      rating: creative["rating"],
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              // More Creatives Button
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {},
                  child: const Text("More Creatives", style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
