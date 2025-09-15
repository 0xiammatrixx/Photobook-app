import 'package:flutter/material.dart';
import 'package:mobile_frontend/features/dashboard/placeholdercard.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> recommendations = [
      {"name": "Timmon Photography", "rating": 5},
      {"name": "Pictures and U", "rating": 5},
      {"name": "Zero to 1 Photos", "rating": 5},
    ];

    final List<String> categories = ["Weddings", "Birthdays", "Products"];

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Hello Tolu,", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
                    return PlaceholderCard(
                      title: item["name"],
                      rating: item["rating"],
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              // Categories
              const Text("Browse by Category", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                      child: Text(categories[index]),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              // Map Placeholder
              const Text("Find Creatives Nearby", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.grey.shade300,
                ),
                alignment: Alignment.center,
                child: const Text("[ Map Placeholder ]"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
