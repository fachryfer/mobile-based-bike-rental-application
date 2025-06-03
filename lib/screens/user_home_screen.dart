import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'rent_bike_form_screen.dart';
import 'rental_detail_screen.dart';
import 'admin/bike_list_screen.dart'; // Import BikeListScreen for user view
import '../models/bike.dart'; // Import Bike model here
import 'user/bike_detail_screen.dart'; // Corrected import path for BikeDetailScreen

enum RentalStatus { // Define RentalStatus enum again for clarity if needed, or ensure it's imported if defined elsewhere
  pending,
  awaiting_pickup,
  in_use,
  completed,
  rejected,
}

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final List<Widget> _pages = [
      // Tab Sepeda Tersedia
      const UserAvailableBikesTab(),
      // Tab Riwayat Penyewaan
      const UserRentalHistoryUnifiedTab(), // Use the unified history tab
      // Tab Profil/Logout
      Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person, size: 80, color: Colors.blue),
            const SizedBox(height: 16),
            Text(user?.email ?? '-', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              },
            ),
          ],
        ),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rental Sepeda'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SizedBox.expand(
          child: _pages[_selectedIndex],
        ),
      ),
      floatingActionButton: _selectedIndex == 0 // Only show button on Sepeda Tersedia tab
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RentBikeFormScreen()),
                );
              },
              child: const Icon(Icons.vpn_key),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        unselectedItemColor: Colors.grey, // Optional: style unselected items
        selectedItemColor: Colors.blue, // Optional: style selected items
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.directions_bike), label: 'Sepeda'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Riwayat'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}

// Helper function to get status color
Color _getStatusColor(String status) {
  switch (status) {
    case 'pending':
      return Colors.orange;
    case 'awaiting_pickup':
      return Colors.blue;
    case 'in_use':
      return Colors.purple;
    case 'completed':
      return Colors.green;
    case 'rejected':
      return Colors.red;
    default:
      return Colors.black;
  }
}

// Widget for User to view available bikes (similar to admin list but without edit/delete)
class UserAvailableBikesTab extends StatelessWidget {
  const UserAvailableBikesTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 16),
        const Text('Sepeda Tersedia', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 8),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('bikes')
                .orderBy('name') // Order by name
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                print('Error fetching available bikes: ${snapshot.error}');
                return Center(child: Text('Error memuat daftar sepeda: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('Tidak ada sepeda tersedia saat ini.'));
              }

              final bikes = snapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return Bike.fromFirestore(data, doc.id);
              }).toList();

              return GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // 2 columns
                  crossAxisSpacing: 12.0, // Spacing between columns
                  mainAxisSpacing: 12.0, // Spacing between rows
                  childAspectRatio: 0.7, // Adjust aspect ratio as needed
                ),
                itemCount: bikes.length,
                itemBuilder: (context, index) {
                  final bike = bikes[index];
                  return Card(
                    elevation: 4.0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                    clipBehavior: Clip.antiAlias, // Clip content to card shape
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => BikeDetailScreen(bikeId: bike.id)),
                        );
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Bike Image
                          Expanded(
                            child: bike.imageUrl != null && bike.imageUrl!.isNotEmpty
                                ? Image.network(
                                    bike.imageUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 50),
                                  )
                                : const Center(child: Icon(Icons.pedal_bike, size: 50, color: Colors.blueGrey)), // Default icon
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
                                // Optional: Add truncated description
                                if (bike.description != null && bike.description!.isNotEmpty)
                                  Text(
                                    bike.description!,
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    maxLines: 2, // Limit description to 2 lines
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                const SizedBox(height: 8),
                                // Sewa Button (only if quantity > 0)
                                if (bike.quantity > 0)
                                   Align(
                                    alignment: Alignment.bottomRight,
                                     child: ElevatedButton(
                                       onPressed: () {
                                         Navigator.push(
                                           context,
                                           MaterialPageRoute(builder: (context) => RentBikeFormScreen(bikeId: bike.id)),
                                         );
                                       },
                                       style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
                                       child: const Text('Sewa'),
                                     ),
                                   ),
                              ],
                            ),
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

// Widget for User's Unified Rental History
class UserRentalHistoryUnifiedTab extends StatelessWidget {
  const UserRentalHistoryUnifiedTab({Key? key}) : super(key: key);

  // Helper to create a summary string of rented items
  String _buildItemsSummary(List<dynamic>? items) {
    if (items == null || items.isEmpty) return 'Tidak ada detail sepeda';
    return items.map((item) {
      if (item is Map<String, dynamic>) {
        final bikeName = item['bikeName'] ?? 'Unknown Bike';
        final quantity = item['quantity'] ?? 0;
        return '${quantity}x $bikeName';
      }
      return '';
    }).join(', '); // Join items with a comma and space
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Pengguna belum login.'));
    }

    return Column(
      children: [
        const SizedBox(height: 16),
        const Text('Riwayat Penyewaan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 8),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('rentals')
                .where('userId', isEqualTo: user.uid) // Filter by current user's ID
                .where('status', whereIn: ['in_use', 'completed', 'rejected', 'awaiting_pickup', 'pending']) // Include all relevant statuses
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                print('Error fetching user rental history: ${snapshot.error}');
                return Center(child: Text('Error memuat riwayat: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('Anda belum memiliki riwayat penyewaan.'));
              }

              final docs = snapshot.data!.docs;
              return ListView.builder(
                itemCount: docs.length,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final currentStatus = data['status'] as String? ?? 'pending';

                  return Card(
                     key: ValueKey(doc.id), // Added ValueKey for better list performance
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      leading: Icon(
                        currentStatus == 'completed' ? Icons.check_circle : (currentStatus == 'rejected' ? Icons.cancel : Icons.history),
                        color: _getStatusColor(currentStatus),
                      ),
                      // Display summary of items instead of single bike name
                      title: Text(_buildItemsSummary(data['items'] as List?), style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Durasi: ${data['duration'] ?? '-'} hari'),
                          Text('Status: ${currentStatus.replaceAll('_', ' ').toUpperCase()}', style: TextStyle(color: _getStatusColor(currentStatus))),
                           if (data['createdAt'] != null)
                             Text('Tanggal: ${(data['createdAt'] as Timestamp).toDate().toString().substring(0, 16)}'),
                           if (data['totalPrice'] != null) // Display total price in history list
                            Text('Total: Rp${(data['totalPrice'] ?? 0.0).toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RentalDetailScreen(rentalId: doc.id),
                          ),
                        );
                      },
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