import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/bike.dart';
import 'edit_bike_screen.dart';

class BikeListScreen extends StatelessWidget {
  const BikeListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 16),
        const Text('Daftar Sepeda', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 8),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('bikes')
                .orderBy('name') // Order by name for now
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                 print('Error fetching bikes: ${snapshot.error}');
                return Center(child: Text('Error memuat data sepeda: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('Belum ada sepeda ditambahkan.'));
              }

              final bikes = snapshot.data!.docs.map((doc) {
                 final data = doc.data() as Map<String, dynamic>;
                 return Bike.fromFirestore(data, doc.id);
              }).toList();

              return GridView.builder(
                 padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12.0,
                  mainAxisSpacing: 12.0,
                  childAspectRatio: 0.75, // Adjusted aspect ratio to give more vertical space
                ),
                itemCount: bikes.length,
                itemBuilder: (context, index) {
                  final bike = bikes[index];
                  return Card(
                     elevation: 4.0,
                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                       crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Bike Image
                          Expanded(
                            child: bike.imageUrl != null && bike.imageUrl!.isNotEmpty
                                ? Image.network(
                                    bike.imageUrl!,
                                    fit: BoxFit.cover, // Ensure image covers the allocated space
                                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 50),
                                  )
                                : const Center(child: Icon(Icons.pedal_bike, size: 50, color: Colors.blueGrey)),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  bike.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Stok: ${bike.quantity}',
                                  style: TextStyle(fontSize: 14, color: bike.quantity > 0 ? Colors.green : Colors.red),
                                ),
                                if (bike.description != null && bike.description!.isNotEmpty)
                                   Text(
                                    bike.description!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                              ],
                            ),
                          ),
                           const Spacer(), // Push buttons to the bottom
                           Padding(
                             padding: const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 8.0),
                             child: Row(
                               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                               mainAxisSize: MainAxisSize.max,
                               children: [
                                 Expanded(
                                   child: ElevatedButton(
                                     onPressed: () {
                                         Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (context) => EditBikeScreen(bikeId: bike.id)),
                                        );
                                     },
                                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4), textStyle: const TextStyle(fontSize: 11)), // Adjusted padding and text size
                                     child: const Text('Edit'),
                                   ),
                                 ),
                                 const SizedBox(width: 8),
                                 Expanded(
                                   child: ElevatedButton(
                                     onPressed: () async {
                                       try {
                                         await FirebaseFirestore.instance.collection('bikes').doc(bike.id).delete();
                                         if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Sepeda berhasil dihapus'), backgroundColor: Colors.green)
                                            );
                                         }
                                       } catch (e) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Gagal menghapus sepeda: $e'), backgroundColor: Colors.red)
                                            );
                                          }
                                       }
                                     },
                                     style: ElevatedButton.styleFrom(backgroundColor: Colors.red, padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4), textStyle: const TextStyle(fontSize: 11)), // Adjusted padding and text size
                                     child: const Text('Hapus'),
                                   ),
                                 ),
                               ],
                             ),
                           ),
                        ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
} 