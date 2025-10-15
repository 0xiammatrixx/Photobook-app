import 'package:flutter/material.dart';
import 'package:mobile_frontend/app/ratecard_provider.dart';
import 'package:provider/provider.dart';

class RateCardPage extends StatelessWidget {
  final bool isOwner;
  final String photographerName;
  final String photographerRole;
  final String imageUrl;

  const RateCardPage({
    Key? key,
    required this.isOwner,
    required this.photographerName,
    required this.photographerRole,
    required this.imageUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final services = context.watch<RateCardProvider>().services;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context), // Go back to previous page
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photographer Info
            Row(
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundImage: NetworkImage(imageUrl),
                ),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      photographerName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Text(photographerRole),
                    Row(
                      children: List.generate(
                        5,
                        (index) =>
                            Icon(Icons.star, color: Colors.orange, size: 18),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 20),

            // Buttons
            Row(
              children: [
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                  child: Text("Book Now"),
                ),
                SizedBox(width: 10),
                OutlinedButton(onPressed: () {}, child: Text("Message")),
              ],
            ),

            SizedBox(height: 30),

            // Rate Card Table
            Text("Services", style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 10),

            Expanded(
              child: ListView.builder(
                itemCount: services.length,
                itemBuilder: (context, index) {
                  final item = services[index];
                  return Container(
                    margin: EdgeInsets.symmetric(vertical: 4),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey.shade100,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(item.service)),
                        Text(item.qty),
                        Text(
                          item.pricing,
                          style: TextStyle(
                            color: item.pricing == "Contact admin"
                                ? Colors.green
                                : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            if (isOwner)
              Align(
                alignment: Alignment.bottomCenter,
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate to edit rate card page
                  },
                  child: Text("Edit Rate Card"),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
