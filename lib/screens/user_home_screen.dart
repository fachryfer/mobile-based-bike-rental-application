import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'rent_bike_form_screen.dart';
import 'rental_detail_screen.dart';

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
      // Beranda: Riwayat Penyewaan
      Column(
        children: [
          const SizedBox(height: 16),
          const Text('Riwayat Penyewaan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('rentals')
                  .where('userId', isEqualTo: user?.uid)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  print('Error fetching rentals: ${snapshot.error}');
                  return Center(child: Text('Error memuat data: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Belum ada penyewaan.'));
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
      ),
      // Sewa Sepeda (Form)
      Center(
        child: ElevatedButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('Form Sewa Sepeda'),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const RentBikeFormScreen()),
            );
          },
        ),
      ),
      // Profil/Logout
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.pedal_bike), label: 'Sewa'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
} 