import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/bike.dart';
import '../rent_bike_form_screen.dart'; // Import RentBikeFormScreen

class BikeDetailScreen extends StatefulWidget {
  final String bikeId;

  const BikeDetailScreen({Key? key, required this.bikeId}) : super(key: key);

  @override
  _BikeDetailScreenState createState() => _BikeDetailScreenState();
}

class _BikeDetailScreenState extends State<BikeDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Sepeda')),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('bikes').doc(widget.bikeId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Sepeda tidak ditemukan.'));
          }

          final bikeData = snapshot.data!.data() as Map<String, dynamic>;
          final bike = Bike.fromFirestore(bikeData, snapshot.data!.id);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Display Bike Image
                if (bike.imageUrl != null && bike.imageUrl!.isNotEmpty)
                  Center(
                    child: Image.network(
                      bike.imageUrl!,
                      height: 250,
                      width: double.infinity,
                      fit: BoxFit.cover,
                       loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 100),
                    ),
                  ),
                const SizedBox(height: 16),
                // Display Bike Details
                Text('Nama: ${bike.name}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Ketersediaan: ${bike.quantity}', style: TextStyle(fontSize: 18, color: bike.quantity > 0 ? Colors.green : Colors.red)),
                const SizedBox(height: 16),
                if (bike.description != null && bike.description!.isNotEmpty) ...[
                   const Text('Deskripsi:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                   const SizedBox(height: 8),
                   Text(bike.description!, style: const TextStyle(fontSize: 16)),
                   const SizedBox(height: 16),
                ],
                
                // Button to Rent Bike (only if quantity > 0)
                if (bike.quantity > 0) 
                  Center(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.shopping_cart),
                      label: const Text('Sewa Sepeda Ini'),
                      onPressed: () {
                         // TODO: Navigate to RentBikeFormScreen and pre-select this bike
                         // For now, just navigate to the form screen
                           Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => RentBikeFormScreen(bikeId: bike.id)), // Pass bikeId
                          ); // Navigate to RentBikeFormScreen
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
} 