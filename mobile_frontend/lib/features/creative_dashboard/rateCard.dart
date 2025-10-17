import 'package:flutter/material.dart';
import 'package:mobile_frontend/app/ratecard_provider.dart';
import 'package:provider/provider.dart';

class RateCardPage extends StatelessWidget {
  final bool isOwner;
  final String businessName;
  final String? avatarUrl;

  const RateCardPage({
    Key? key,
    required this.isOwner,
    required this.businessName,
    this.avatarUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final services = context.watch<RateCardProvider>().services;

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

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: isOwner
            ? Text(
                'My Rate Card',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              )
            : Text(
                "$businessName${businessName.endsWith('s') ? "'" : "'s"} Rate Card",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
        actions: [
          IconButton(
            icon: Icon(Icons.close, color: Colors.black),
            onPressed: () => Navigator.pop(context), // Go back to previous page
          ),
        ],
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photographer Info
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: const Color(0xFFF5F9F6),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [imageWidget]),
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
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            SizedBox(height: 8),
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
                          SizedBox(height: 5),
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
                      ),
                    ],
                  ),
                ],
              ),
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
