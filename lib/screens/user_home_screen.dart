import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'rent_bike_form_screen.dart';
import 'rental_detail_screen.dart';
import 'admin/bike_list_screen.dart'; // Import BikeListScreen for user view
import '../models/bike.dart'; // Import Bike model here
import 'user/bike_detail_screen.dart'; // Corrected import path for BikeDetailScreen
import 'package:rental_sepeda/utils/app_constants.dart'; // Import AppConstants

enum RentalStatus {
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
  String _searchQuery = '';

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
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            decoration: AppDecorations.cardDecoration,
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.person_outline, size: 80, color: AppColors.primaryColor),
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
                    backgroundColor: AppColors.dangerColor, // Warna merah untuk logout
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
        title: const Text('Rental Sepeda'),
        // AppBar theme is now handled by MaterialApp theme in main.dart
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
              backgroundColor: AppColors.accentColor, // Menggunakan warna aksen
              foregroundColor: AppColors.textColor, // Warna ikon/teks
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), // Bentuk FAB
              child: const Icon(Icons.add_road), // Mengganti ikon
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: AppColors.primaryColor,
        unselectedItemColor: AppColors.subtitleColor,
        backgroundColor: AppColors.cardColor,
        elevation: 10,
        type: BottomNavigationBarType.fixed, // Memastikan semua item terlihat
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.directions_bike), label: 'Sepeda'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Riwayat'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }

  // Helper method untuk membuat item fitur
  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0), // Add horizontal padding
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, // Center content vertically
        children: [
          Icon(icon, size: 25, color: AppColors.primaryColor), // Further reduce icon size
          const SizedBox(height: 2), // Further reduce SizedBox height
          Text(title, style: AppTextStyles.subtitle.copyWith(color: AppColors.textColor, fontSize: 13)),
          const SizedBox(height: 4),
          Text(
            description,
            style: AppTextStyles.bodyText.copyWith(color: AppColors.subtitleColor, fontSize: 10),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// Helper function to get status color (using AppColors)
Color _getStatusColor(String status) {
  switch (status) {
    case 'pending':
      return AppColors.accentColor;
    case 'awaiting_pickup':
      return AppColors.primaryColor;
    case 'in_use':
      return Colors.deepPurple; // Warna khusus atau tambahkan ke AppColors
    case 'completed':
      return AppColors.successColor;
    case 'rejected':
      return AppColors.dangerColor;
    default:
      return AppColors.textColor;
  }
}

// Widget for User to view available bikes (similar to admin list but without edit/delete)
class UserAvailableBikesTab extends StatefulWidget {
  const UserAvailableBikesTab({Key? key}) : super(key: key);

  @override
  State<UserAvailableBikesTab> createState() => _UserAvailableBikesTabState();
}

class _UserAvailableBikesTabState extends State<UserAvailableBikesTab> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            decoration: AppDecorations.inputDecoration.copyWith(
              labelText: 'Cari Sepeda',
              prefixIcon: Icon(Icons.search, color: AppColors.primaryColor),
            ),
            style: AppTextStyles.bodyText,
            onChanged: (query) {
              setState(() {
                _searchQuery = query;
              });
            },
          ),
        ),
        // Kenapa Harus Memilih Kami - Compact Design
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16.0),
          padding: const EdgeInsets.all(16.0),
          decoration: AppDecorations.cardDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kenapa Harus Memilih Kami?',
                style: AppTextStyles.title.copyWith(color: AppColors.primaryColor),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildFeatureItem(
                      icon: Icons.security,
                      title: 'Terpercaya',
                      description: 'Layanan terjamin dan aman',
                    ),
                  ),
                  Expanded(
                    child: _buildFeatureItem(
                      icon: Icons.attach_money,
                      title: 'Harga Terjangkau',
                      description: 'Biaya sewa terjangkau dan bersahabat',
                    ),
                  ),
                  Expanded(
                    child: _buildFeatureItem(
                      icon: Icons.support_agent,
                      title: 'Layanan 24/7',
                      description: 'Dukungan pelanggan siap membantu',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Jelajahi Sepeda Kami!',
            style: AppTextStyles.headline2.copyWith(color: AppColors.textColor),
          ),
        ),
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
                return Center(child: Text('Error memuat daftar sepeda: ${snapshot.error}', style: AppTextStyles.bodyText.copyWith(color: AppColors.dangerColor)));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.sentiment_dissatisfied, size: 60, color: AppColors.subtitleColor),
                      const SizedBox(height: 16),
                      Text('Tidak ada sepeda tersedia saat ini.', style: AppTextStyles.subtitle.copyWith(color: AppColors.subtitleColor)),
                    ],
                  ),
                );
              }

              final bikes = snapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return Bike.fromFirestore(data, doc.id);
              }).toList();

              // Filter bikes based on search query
              final filteredBikes = _searchQuery.isEmpty
                  ? bikes
                  : bikes.where((bike) =>
                      bike.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

              if (filteredBikes.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 64, color: AppColors.subtitleColor),
                      const SizedBox(height: 16),
                      Text(
                        'Tidak ada sepeda yang sesuai dengan pencarian',
                        style: AppTextStyles.bodyText.copyWith(color: AppColors.subtitleColor),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              return GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // 2 columns
                  crossAxisSpacing: 12.0, // Spacing between columns
                  mainAxisSpacing: 12.0, // Spacing between rows
                  childAspectRatio: 0.7, // Adjust aspect ratio as needed
                ),
                itemCount: filteredBikes.length,
                itemBuilder: (context, index) {
                  final bike = filteredBikes[index];
                  return Container(
                    decoration: AppDecorations.cardDecoration,
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
                            flex: 3,
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                              child: bike.imageUrl != null && bike.imageUrl!.isNotEmpty
                                  ? Image.network(
                                      bike.imageUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Center(child: Icon(Icons.broken_image, size: 50, color: AppColors.subtitleColor)),
                                    )
                                  : Center(child: Icon(Icons.directions_bike, size: 64, color: AppColors.primaryColor)),
                            ),
                          ),
                          // Bike Info
                          Expanded(
                            flex: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    bike.name,
                                    style: AppTextStyles.title.copyWith(fontSize: 16),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Rp${bike.pricePerDay.toStringAsFixed(0)}/hari',
                                    style: AppTextStyles.bodyText.copyWith(
                                      color: AppColors.primaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Stok: ${bike.quantity} unit',
                                    style: AppTextStyles.bodyText.copyWith(
                                      color: AppColors.subtitleColor,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
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

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0), // Add horizontal padding
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, // Center content vertically
        children: [
          Icon(icon, size: 25, color: AppColors.primaryColor), // Further reduce icon size
          const SizedBox(height: 2), // Further reduce SizedBox height
          Text(title, style: AppTextStyles.subtitle.copyWith(color: AppColors.textColor, fontSize: 13)),
          const SizedBox(height: 4),
          Text(
            description,
            style: AppTextStyles.bodyText.copyWith(color: AppColors.subtitleColor, fontSize: 10),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// Unified tab for User Rental History
class UserRentalHistoryUnifiedTab extends StatelessWidget {
  const UserRentalHistoryUnifiedTab({Key? key}) : super(key: key);

  // Helper to create a list of widgets displaying rented item details
  List<Widget> _buildItemWidgets(List<dynamic>? items) {
    if (items == null || items.isEmpty) return [const Text('Tidak ada detail sepeda')];
    return items.map((item) {
      if (item is Map<String, dynamic>) {
        final bikeName = item['bikeName'] ?? 'Unknown Bike';
        final quantity = item['quantity'] ?? 0;
        final pricePerDay = item['pricePerDay'] ?? 0.0; // Assume pricePerDay is stored in items list
        return Text(
          '- ${quantity}x $bikeName (Rp${pricePerDay.toStringAsFixed(0)}/hari)',
          style: AppTextStyles.bodyText.copyWith(fontStyle: FontStyle.italic),
        );
      }
      return const Text('');
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Center(child: Text('Silakan login untuk melihat riwayat penyewaan.', style: AppTextStyles.bodyText));
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Riwayat Penyewaan Anda',
            style: AppTextStyles.headline2.copyWith(color: AppColors.textColor),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('rentals')
                .where('userId', isEqualTo: user.uid)
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                print('Error fetching user rentals: ${snapshot.error}');
                return Center(child: Text('Error memuat riwayat penyewaan: ${snapshot.error}', style: AppTextStyles.bodyText.copyWith(color: AppColors.dangerColor)));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long, size: 60, color: AppColors.subtitleColor),
                      const SizedBox(height: 16),
                      Text('Belum ada riwayat penyewaan.', style: AppTextStyles.subtitle.copyWith(color: AppColors.subtitleColor)),
                    ],
                  ),
                );
              }

              final rentals = snapshot.data!.docs;

              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: rentals.length,
                itemBuilder: (context, index) {
                  final doc = rentals[index];
                  final rental = doc.data() as Map<String, dynamic>;

                  String displayedBikeName = 'Sepeda Tidak Dikenal';
                  if (rental['items'] is List && (rental['items'] as List).isNotEmpty) {
                    final firstItem = (rental['items'] as List).first as Map<String, dynamic>;
                    displayedBikeName = firstItem['bikeName'] ?? 'Sepeda Tidak Dikenal';
                  }

                  final String status = rental['status'] ?? 'pending';
                  final String imageUrl = rental['imageUrl'] ?? '';

                  return Container(
                    key: ValueKey(doc.id),
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    decoration: AppDecorations.cardDecoration, // Menggunakan dekorasi kartu
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => RentalDetailScreen(rentalId: doc.id)),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            // Image/Icon placeholder
                            Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                color: AppColors.backgroundColor,
                                borderRadius: BorderRadius.circular(10),
                                image: imageUrl.isNotEmpty
                                    ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover)
                                    : null,
                              ),
                              child: imageUrl.isEmpty
                                  ? Icon(Icons.directions_bike, size: 40, color: AppColors.primaryColor)
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    displayedBikeName, // Use the extracted bike name
                                    style: AppTextStyles.title.copyWith(fontSize: 16),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Status:',
                                    style: AppTextStyles.bodyText.copyWith(color: AppColors.subtitleColor, fontSize: 12),
                                  ),
                                  Text(
                                    status.toUpperCase(),
                                    style: AppTextStyles.bodyText.copyWith(color: _getStatusColor(status), fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios, color: AppColors.subtitleColor, size: 16),
                          ],
                        ),
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