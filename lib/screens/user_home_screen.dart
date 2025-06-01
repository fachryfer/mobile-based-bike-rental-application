import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'rent_bike_form_screen.dart';
import 'rental_detail_screen.dart';
import 'admin/bike_list_screen.dart'; // Import BikeListScreen for user view
import '../models/bike.dart'; // Import Bike model here
import 'user/bike_detail_screen.dart'; // Corrected import path for BikeDetailScreen

// Widget for User's Pending Rentals
class UserPendingRentalsTab extends StatelessWidget {
  const UserPendingRentalsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text('User not logged in')); // Basic null check

    return Column(
      children: [
        const SizedBox(height: 16),
        const Text('Permintaan Saya', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 8),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('rentals')
                .where('userId', isEqualTo: user.uid)
                .where('status', isEqualTo: 'pending') // Filter by pending status
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                print('Error fetching pending rentals: ${snapshot.error}');
                return Center(child: Text('Error memuat data: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('Tidak ada permintaan pending.'));
              }
              final docs = snapshot.data!.docs;

              final rentalWidgets = docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return Card(
                  key: ValueKey(doc.id),
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    leading: const Icon(Icons.pedal_bike, color: Colors.blue),
                    title: Text(data['bikeName'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Status: ${data['status'] ?? 'pending'}'),
                        if (data['createdAt'] != null)
                          Text('Tanggal: ${(data['createdAt'] as Timestamp).toDate().toString().substring(0, 16)}'),
                      ],
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
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
              }).toList();

              return ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                children: rentalWidgets,
              );
            },
          ),
        ),
      ],
    );
  }
}

// Widget for User's Rental History (Approved/Rejected)
class UserRentalHistoryTab extends StatelessWidget {
  const UserRentalHistoryTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
     if (user == null) return const Center(child: Text('User not logged in')); // Basic null check

    return Column(
      children: [
        const SizedBox(height: 16),
        const Text('Riwayat Saya', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 8),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('rentals')
                 .where('userId', isEqualTo: user.uid)
                .where('status', whereIn: ['approved', 'rejected']) // Filter by approved/rejected status
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                 print('Error fetching rental history: ${snapshot.error}');
                return Center(child: Text('Error memuat data: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('Belum ada riwayat sewa.'));
              }
              final docs = snapshot.data!.docs;

              final rentalWidgets = docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return Card(
                  key: ValueKey(doc.id),
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                     leading: const Icon(Icons.pedal_bike, color: Colors.grey),
                    title: Text(data['bikeName'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Status: ${data['status'] ?? '-'}'),
                        if (data['createdAt'] != null)
                          Text('Tanggal: ${(data['createdAt'] as Timestamp).toDate().toString().substring(0, 16)}'),
                      ],
                    ),
                     trailing: const Icon(Icons.arrow_forward_ios, size: 16),
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
              }).toList();

              return ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                children: rentalWidgets,
              );
            },
          ),
        ),
      ],
    );
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
                 // .where('quantity', isGreaterThan: 0) // Remove this filter
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
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
      // Permintaan Saya (Index 0)
      const UserPendingRentalsTab(),
      // Riwayat Saya (Index 1)
      const UserRentalHistoryTab(),
       // Daftar Sepeda (Index 2) - Changed from Sewa Form
      const UserAvailableBikesTab(),
      // Profil/Logout (Index 3)
      Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.account_circle, size: 80, color: Colors.blue),
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
      floatingActionButton: _selectedIndex == 2 // Only show button on Daftar Sepeda tab
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
          BottomNavigationBarItem(icon: Icon(Icons.pending_actions), label: 'Pending'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Riwayat'),
          BottomNavigationBarItem(icon: Icon(Icons.directions_bike), label: 'Sepeda'), // Changed icon and label
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
} 