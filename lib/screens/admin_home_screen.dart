import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'rental_detail_screen.dart';
import 'admin/add_bike_screen.dart';
import 'admin/bike_list_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
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
      // Permintaan Sewa
      Column(
        children: [
          const SizedBox(height: 16),
          const Text('Permintaan Sewa', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('rentals')
                  .where('status', isEqualTo: 'pending')
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
                  return const Center(child: Text('Tidak ada permintaan sewa.'));
                }
                final docs = snapshot.data!.docs;
                final pendingRentalWidgets = docs.map((doc) {
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
                          Text('Nama: ${data['userName'] ?? '-'}'),
                          Text('Durasi: ${data['duration'] ?? '-'} hari'),
                          if (data['createdAt'] != null)
                            Text('Tanggal: ${(data['createdAt'] as Timestamp).toDate().toString().substring(0, 16)}'),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.check, color: Colors.green),
                            onPressed: () async {
                              try {
                                // Get bikeId from the rental document
                                final bikeId = data['bikeId'];
                                if (bikeId != null) {
                                  final bikeRef = FirebaseFirestore.instance.collection('bikes').doc(bikeId);

                                  await FirebaseFirestore.instance.runTransaction((transaction) async {
                                    // Get the current bike data within the transaction
                                    final bikeSnapshot = await transaction.get(bikeRef);
                                    if (bikeSnapshot.exists) {
                                      final currentQuantity = bikeSnapshot.data()?['quantity'] ?? 0;
                                      if (currentQuantity > 0) {
                                        // Decrement quantity by 1
                                        transaction.update(bikeRef, {'quantity': currentQuantity - 1});
                                        // Update rental status to approved
                                        transaction.update(doc.reference, {'status': 'approved'});
                                         if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Permintaan disetujui dan stok sepeda diperbarui!'), backgroundColor: Colors.green)
                                          );
                                        }
                                      } else {
                                        // Handle case where quantity is already 0
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Stok sepeda habis.'), backgroundColor: Colors.orange)
                                          );
                                        }
                                      }
                                    } else {
                                      // Handle case where bike document doesn't exist
                                       if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Data sepeda tidak ditemukan.'), backgroundColor: Colors.red)
                                          );
                                        }
                                    }
                                  });
                                } else {
                                   if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('ID Sepeda tidak ditemukan di data sewa.'), backgroundColor: Colors.red)
                                      );
                                    }
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Gagal menyetujui permintaan: $e'), backgroundColor: Colors.red)
                                  );
                                }
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () async {
                              await doc.reference.update({'status': 'rejected'});
                            },
                          ),
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
                }).toList();
                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  children: pendingRentalWidgets,
                );
              },
            ),
          ),
        ],
      ),
      // Riwayat Sewa
      Column(
        children: [
          const SizedBox(height: 16),
          const Text('Riwayat Sewa', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('rentals')
                  .where('status', whereIn: ['approved', 'rejected'])
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
                final historyRentalWidgets = docs.map((doc) {
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
                          Text('Nama: ${data['userName'] ?? '-'}'),
                          Text('Durasi: ${data['duration'] ?? '-'} hari'),
                          Text('Status: ${data['status'] ?? '-'}'),
                          if (data['createdAt'] != null)
                            Text('Tanggal: ${(data['createdAt'] as Timestamp).toDate().toString().substring(0, 16)}'),
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
                }).toList();
                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  children: historyRentalWidgets,
                );
              },
            ),
          ),
        ],
      ),
      // Daftar Sepeda
      const BikeListScreen(),
      // Profil/Logout
      Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.admin_panel_settings, size: 80, color: Colors.blue),
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
        title: const Text('Dashboard Admin'),
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
                Navigator.push(context, MaterialPageRoute(builder: (context) => const AddBikeScreen()));
              },
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        unselectedItemColor: Colors.grey, // Optional: style unselected items
        selectedItemColor: Colors.blue, // Optional: style selected items
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.pending_actions), label: 'Permintaan'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Riwayat'),
          BottomNavigationBarItem(icon: Icon(Icons.directions_bike), label: 'Sepeda'), // New tab item
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
} 