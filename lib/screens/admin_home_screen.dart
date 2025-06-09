import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'rental_detail_screen.dart';
import 'admin/add_bike_screen.dart';
import 'admin/bike_list_screen.dart';
import 'package:rental_sepeda/utils/app_constants.dart';

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
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Permintaan Sewa Masuk',
              style: AppTextStyles.headline2.copyWith(color: AppColors.textColor),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: AppDecorations.inputDecoration.copyWith(
                      labelText: 'Cari Permintaan',
                      prefixIcon: Icon(Icons.search, color: AppColors.primaryColor),
                    ),
                    style: AppTextStyles.bodyText,
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
                    decoration: AppDecorations.inputDecoration.copyWith(
                      labelText: 'Status',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    ),
                    value: _selectedPendingStatusFilter,
                    hint: Text('Semua', style: AppTextStyles.bodyText.copyWith(color: AppColors.subtitleColor)),
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
                    style: AppTextStyles.bodyText.copyWith(color: AppColors.textColor),
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
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.assignment, size: 60, color: AppColors.subtitleColor),
                        const SizedBox(height: 16),
                        Text('Tidak ada permintaan sewa saat ini.', style: AppTextStyles.subtitle.copyWith(color: AppColors.subtitleColor)),
                      ],
                    ),
                  );
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
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 60, color: AppColors.subtitleColor),
                        const SizedBox(height: 16),
                        Text('Tidak ada hasil yang sesuai dengan pencarian.', style: AppTextStyles.subtitle.copyWith(color: AppColors.subtitleColor)),
                      ],
                    ),
                  );
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

                  return Container(
                    key: ValueKey(doc.id),
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: AppDecorations.cardDecoration,
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RentalDetailScreen(rentalId: doc.id),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(data['fullName'] ?? 'Nama Lengkap Tidak Tersedia',
                                      style: AppTextStyles.title.copyWith(fontSize: 18), overflow: TextOverflow.ellipsis),
                                ),
                                const SizedBox(width: 8),
                                Text(data['status']?.toString().replaceAll('_', ' ').toUpperCase() ?? '-',
                                    style: AppTextStyles.bodyText.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: _getStatusColor(data['status'] ?? 'pending'),
                                    )),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text('Email: ${data['userName'] ?? '-'}', style: AppTextStyles.bodyText.copyWith(color: AppColors.subtitleColor)),
                            const SizedBox(height: 2),
                            Text('Sepeda: ${buildItemsSummary(data['items'] as List?)}', style: AppTextStyles.bodyText.copyWith(fontStyle: FontStyle.italic)),
                            const SizedBox(height: 2),
                            Text('Durasi: ${data['duration'] ?? '-'} hari', style: AppTextStyles.bodyText),
                            const SizedBox(height: 2),
                            if (data['createdAt'] != null)
                              Text('Tanggal Pengajuan: ${(data['createdAt'] as Timestamp).toDate().toString().substring(0, 16)}', style: AppTextStyles.bodyText),
                            const SizedBox(height: 2),
                            if (data['totalPrice'] != null)
                              Text('Total: Rp${(data['totalPrice'] ?? 0.0).toStringAsFixed(0)}', style: AppTextStyles.title.copyWith(color: AppColors.successColor)),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (data['status'] == 'pending')
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.check, color: Colors.white),
                                    label: Text('Setujui', style: AppTextStyles.buttonText.copyWith(color: Colors.white)),
                                    onPressed: () async {
                                      try {
                                        final rentalRef = FirebaseFirestore.instance.collection('rentals').doc(doc.id);
                                        await rentalRef.update({'status': 'awaiting_pickup'});
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Permintaan disetujui. Status diubah menjadi Menunggu Diambil.'), backgroundColor: AppColors.successColor),
                                          );
                                        }
                                      } catch (e) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Gagal menyetujui permintaan: $e'), backgroundColor: AppColors.dangerColor),
                                          );
                                        }
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.successColor,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                const SizedBox(width: 8),
                                if (data['status'] == 'pending' || data['status'] == 'awaiting_pickup')
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.close, color: Colors.white),
                                    label: Text('Tolak', style: AppTextStyles.buttonText.copyWith(color: Colors.white)),
                                    onPressed: () async {
                                      try {
                                        await doc.reference.update({'status': 'rejected'});
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Permintaan ditolak.'), backgroundColor: AppColors.dangerColor),
                                          );
                                        }
                                      } catch (e) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Gagal menolak permintaan: $e'), backgroundColor: AppColors.dangerColor),
                                          );
                                        }
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.dangerColor,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
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
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Riwayat Sewa Selesai',
              style: AppTextStyles.headline2.copyWith(color: AppColors.textColor),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: AppDecorations.inputDecoration.copyWith(
                      labelText: 'Cari Riwayat',
                      prefixIcon: Icon(Icons.search, color: AppColors.primaryColor),
                    ),
                    style: AppTextStyles.bodyText,
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
                    decoration: AppDecorations.inputDecoration.copyWith(
                      labelText: 'Status',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    ),
                    value: _selectedHistoryStatusFilter,
                    hint: Text('Semua', style: AppTextStyles.bodyText.copyWith(color: AppColors.subtitleColor)),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Semua')),
                      DropdownMenuItem(value: 'completed', child: Text('Selesai')),
                      DropdownMenuItem(value: 'rejected', child: Text('Ditolak')),
                      DropdownMenuItem(value: 'in_use', child: Text('Sedang Digunakan')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedHistoryStatusFilter = value;
                      });
                    },
                    style: AppTextStyles.bodyText.copyWith(color: AppColors.textColor),
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
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history, size: 60, color: AppColors.subtitleColor),
                        const SizedBox(height: 16),
                        Text('Belum ada riwayat sewa.', style: AppTextStyles.subtitle.copyWith(color: AppColors.subtitleColor)),
                      ],
                    ),
                  );
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
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 60, color: AppColors.subtitleColor),
                        const SizedBox(height: 16),
                        Text('Tidak ada hasil yang sesuai dengan pencarian.', style: AppTextStyles.subtitle.copyWith(color: AppColors.subtitleColor)),
                      ],
                    ),
                  );
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

                  return Container(
                    key: ValueKey(doc.id),
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: AppDecorations.cardDecoration,
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RentalDetailScreen(rentalId: doc.id),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(data['fullName'] ?? 'Nama Lengkap Tidak Tersedia',
                                      style: AppTextStyles.title.copyWith(fontSize: 18), overflow: TextOverflow.ellipsis),
                                ),
                                const SizedBox(width: 8),
                                Text(data['status']?.toString().replaceAll('_', ' ').toUpperCase() ?? '-',
                                    style: AppTextStyles.bodyText.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: _getStatusColor(data['status'] ?? 'pending'),
                                    )),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text('Email: ${data['userName'] ?? '-'}', style: AppTextStyles.bodyText.copyWith(color: AppColors.subtitleColor)),
                            const SizedBox(height: 2),
                            Text('Sepeda: ${buildItemsSummary(data['items'] as List?)}', style: AppTextStyles.bodyText.copyWith(fontStyle: FontStyle.italic)),
                            const SizedBox(height: 2),
                            Text('Durasi: ${data['duration'] ?? '-'} hari', style: AppTextStyles.bodyText),
                            const SizedBox(height: 2),
                            if (data['createdAt'] != null)
                              Text('Tanggal Pengajuan: ${(data['createdAt'] as Timestamp).toDate().toString().substring(0, 16)}', style: AppTextStyles.bodyText),
                            const SizedBox(height: 2),
                            if (data['totalPrice'] != null)
                              Text('Total: Rp${(data['totalPrice'] ?? 0.0).toStringAsFixed(0)}', style: AppTextStyles.title.copyWith(color: AppColors.successColor)),
                          ],
                        ),
                      ),
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
      // Tab Profil/Logout Admin
      Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            decoration: AppDecorations.cardDecoration,
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.admin_panel_settings_outlined, size: 80, color: AppColors.primaryColor),
                const SizedBox(height: 16),
                Text(
                  user?.email ?? '-',
                  style: AppTextStyles.title,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  icon: const Icon(Icons.logout, color: Colors.white),
                  label: Text('Logout', style: AppTextStyles.buttonText.copyWith(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.dangerColor,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
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
        ),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
      ),
      body: SafeArea(
        child: SizedBox.expand(
          child: _pages[_selectedIndex],
        ),
      ),
      floatingActionButton: _selectedIndex == 2
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddBikeScreen()),
                );
              },
              backgroundColor: AppColors.accentColor,
              foregroundColor: AppColors.textColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: const Icon(Icons.add_road),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: AppColors.primaryColor,
        unselectedItemColor: AppColors.subtitleColor,
        backgroundColor: AppColors.cardColor,
        elevation: 10,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Permintaan'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Riwayat'),
          BottomNavigationBarItem(icon: Icon(Icons.directions_bike), label: 'Sepeda'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return AppColors.accentColor;
      case 'awaiting_pickup':
        return AppColors.primaryColor;
      case 'in_use':
        return Colors.deepPurple;
      case 'completed':
        return AppColors.successColor;
      case 'rejected':
        return AppColors.dangerColor;
      default:
        return AppColors.textColor;
    }
  }
} 