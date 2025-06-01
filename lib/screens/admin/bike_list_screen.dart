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

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemCount: bikes.length,
                itemBuilder: (context, index) {
                  final bike = bikes[index];
                  return Card(
                    key: ValueKey(bike.id),
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      leading: const Icon(Icons.pedal_bike, color: Colors.blueGrey),
                      title: Text(bike.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Tersedia: ${bike.quantity}'),
                      // TODO: Add options for editing/deleting bikes later
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Edit Button
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () {
                              // TODO: Implement edit navigation
                              // print('Edit bike ${bike.id}'); // Placeholder
                               Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EditBikeScreen(bikeId: bike.id),
                                ),
                              );
                            },
                          ),
                          // Delete Button
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              // Implement delete functionality
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
                          ),
                        ],
                      ),
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