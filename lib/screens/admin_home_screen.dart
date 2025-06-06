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
  String _pendingSearchQuery = '';
  String _historySearchQuery = '';
  String? _selectedPendingStatusFilter;
  String? _selectedHistoryStatusFilter;

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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Cari Permintaan',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    onChanged: (query) {
                      setState(() {
                        _pendingSearchQuery = query;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  flex: 1,
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    ),
                    value: _selectedPendingStatusFilter,
                    hint: const Text('Semua'),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Semua')),
                      DropdownMenuItem(value: 'pending', child: Text('Pending')),
                      DropdownMenuItem(value: 'awaiting_pickup', child: Text('Diambil')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedPendingStatusFilter = value;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('rentals')
                  .where('status', whereIn: _selectedPendingStatusFilter == null
                       ? ['pending', 'awaiting_pickup']
                       : [_selectedPendingStatusFilter!])
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
                final filteredDocs = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final query = _pendingSearchQuery.toLowerCase();
                  if (query.isEmpty) return true;
                  final fullName = (data['fullName'] as String? ?? '').toLowerCase();
                  final userName = (data['userName'] as String? ?? '').toLowerCase();
                  final items = data['items'] as List<dynamic>?;

                  bool itemMatch = false;
                  if (items != null) {
                    itemMatch = items.any((item) {
                      if (item is Map<String, dynamic>) {
                        final bikeName = (item['bikeName'] as String? ?? '').toLowerCase();
                        return bikeName.contains(query);
                      }
                      return false;
                    });
                  }

                  return fullName.contains(query) || userName.contains(query) || itemMatch;
                }).toList();

                if (filteredDocs.isEmpty) {
                  return const Center(child: Text('Tidak ada hasil yang sesuai dengan pencarian.'));
                }

                final pendingRentalWidgets = filteredDocs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  String buildItemsSummary(List<dynamic>? items) {
                    if (items == null || items.isEmpty) return 'Tidak ada detail sepeda';
                    return items.map((item) {
                      if (item is Map<String, dynamic>) {
                        final bikeName = item['bikeName'] ?? 'Unknown Bike';
                        final quantity = item['quantity'] ?? 0;
                        return '$quantity x $bikeName';
                      }
                      return '';
                    }).join(', ');
                  }

                  return Card(
                    key: ValueKey(doc.id),
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      leading: const Icon(Icons.pedal_bike, color: Colors.blue),
                      title: Text(data['fullName'] ?? 'Nama Lengkap Tidak Tersedia', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Pengguna: ${data['userName'] ?? '-'}', style: const TextStyle(fontSize: 13)),
                          const SizedBox(height: 2),
                          Text('Sepeda: ${buildItemsSummary(data['items'] as List?)}', style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic)),
                          const SizedBox(height: 2),
                          Text('Durasi: ${data['duration'] ?? '-'} hari', style: const TextStyle(fontSize: 13)),
                          Text('Status: ${data['status']?.toString().replaceAll('_', ' ').toUpperCase() ?? '-'}', style: TextStyle(color: _getStatusColor(data['status'] ?? 'pending'), fontWeight: FontWeight.w600, fontSize: 13)),
                          if (data['createdAt'] != null)
                            Text('Tanggal Pengajuan: ${(data['createdAt'] as Timestamp).toDate().toString().substring(0, 16)}', style: const TextStyle(fontSize: 13)),
                          if (data['totalPrice'] != null)
                            Text('Total: Rp${(data['totalPrice'] ?? 0.0).toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green)),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (data['status'] == 'pending')
                            IconButton(
                              icon: const Icon(Icons.check, color: Colors.green),
                              onPressed: () async {
                                try {
                                  final rentalRef = FirebaseFirestore.instance.collection('rentals').doc(doc.id);
                                  await rentalRef.update({'status': 'awaiting_pickup'});
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Permintaan disetujui. Status diubah menjadi Menunggu Diambil.'), backgroundColor: Colors.green),
                                    );
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Cari Riwayat',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    onChanged: (query) {
                      setState(() {
                        _historySearchQuery = query;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  flex: 1,
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    ),
                    value: _selectedHistoryStatusFilter,
                    hint: const Text('Semua'),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Semua')),
                      DropdownMenuItem(value: 'in_use', child: Text('Digunakan')),
                      DropdownMenuItem(value: 'completed', child: Text('Selesai')),
                      DropdownMenuItem(value: 'rejected', child: Text('Ditolak')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedHistoryStatusFilter = value;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('rentals')
                  .where('status', whereIn: _selectedHistoryStatusFilter == null
                       ? ['in_use', 'completed', 'rejected']
                       : [_selectedHistoryStatusFilter!])
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
                final filteredDocs = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final query = _historySearchQuery.toLowerCase();
                  if (query.isEmpty) return true;
                  final fullName = (data['fullName'] as String? ?? '').toLowerCase();
                  final userName = (data['userName'] as String? ?? '').toLowerCase();
                  final items = data['items'] as List<dynamic>?;

                  bool itemMatch = false;
                  if (items != null) {
                    itemMatch = items.any((item) {
                      if (item is Map<String, dynamic>) {
                        final bikeName = (item['bikeName'] as String? ?? '').toLowerCase();
                        return bikeName.contains(query);
                      }
                      return false;
                    });
                  }

                  return fullName.contains(query) || userName.contains(query) || itemMatch;
                }).toList();

                if (filteredDocs.isEmpty) {
                  return const Center(child: Text('Tidak ada hasil yang sesuai dengan pencarian.'));
                }

                final historyRentalWidgets = filteredDocs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  String buildItemsSummary(List<dynamic>? items) {
                    if (items == null || items.isEmpty) return 'Tidak ada detail sepeda';
                    return items.map((item) {
                      if (item is Map<String, dynamic>) {
                        final bikeName = item['bikeName'] ?? 'Unknown Bike';
                        final quantity = item['quantity'] ?? 0;
                        return '$quantity x $bikeName';
                      }
                      return '';
                    }).join(', ');
                  }

                  return Card(
                    key: ValueKey(doc.id),
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      leading: const Icon(Icons.pedal_bike, color: Colors.grey),
                      title: Text(data['fullName'] ?? 'Nama Lengkap Tidak Tersedia', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Pengguna: ${data['userName'] ?? '-'}', style: const TextStyle(fontSize: 13)),
                          const SizedBox(height: 2),
                          Text('Sepeda: ${buildItemsSummary(data['items'] as List?)}', style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic)),
                          const SizedBox(height: 2),
                          Text('Durasi: ${data['duration'] ?? '-'} hari', style: const TextStyle(fontSize: 13)),
                          Text('Status: ${data['status']?.toString().replaceAll('_', ' ').toUpperCase() ?? '-'}', style: TextStyle(color: _getStatusColor(data['status'] ?? 'pending'), fontWeight: FontWeight.w600, fontSize: 13)),
                          if (data['createdAt'] != null)
                            Text('Tanggal Sewa: ${(data['createdAt'] as Timestamp).toDate().toString().substring(0, 16)}', style: const TextStyle(fontSize: 13)),
                          if (data['totalPrice'] != null)
                            Text('Total: Rp${(data['totalPrice'] ?? 0.0).toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green)),
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
} 