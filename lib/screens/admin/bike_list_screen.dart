import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/bike.dart';
import 'edit_bike_screen.dart';
import 'package:rental_sepeda/utils/app_constants.dart'; // Import AppConstants

class BikeListScreen extends StatelessWidget {
  const BikeListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Daftar Sepeda Tersedia',
            style: AppTextStyles.headline2.copyWith(color: AppColors.textColor),
          ),
        ),
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
                return Center(child: Text('Error memuat daftar sepeda: ${snapshot.error}', style: AppTextStyles.bodyText.copyWith(color: AppColors.dangerColor)));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bike_scooter, size: 60, color: AppColors.subtitleColor),
                      const SizedBox(height: 16),
                      Text('Belum ada sepeda ditambahkan.', style: AppTextStyles.subtitle.copyWith(color: AppColors.subtitleColor)),
                      const SizedBox(height: 8),
                      Text('Tambahkan sepeda baru melalui tombol di bawah.', style: AppTextStyles.bodyText.copyWith(color: AppColors.subtitleColor)),
                    ],
                  ),
                );
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
                  childAspectRatio: 0.7, // Adjusted aspect ratio to give more vertical space
                ),
                itemCount: bikes.length,
                itemBuilder: (context, index) {
                  final bike = bikes[index];
                  return Container(
                    decoration: AppDecorations.cardDecoration, // Menggunakan dekorasi kartu
                    child: Column(
                       crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Bike Image
                          Expanded(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)), // Sudut membulat hanya di atas
                              child: bike.imageUrl != null && bike.imageUrl!.isNotEmpty
                                  ? Image.network(
                                      bike.imageUrl!,
                                      fit: BoxFit.cover, // Ensure image covers the allocated space
                                      errorBuilder: (context, error, stackTrace) => Center(child: Icon(Icons.broken_image, size: 50, color: AppColors.subtitleColor)),
                                    )
                                  : Center(child: Icon(Icons.pedal_bike, size: 50, color: AppColors.subtitleColor)),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
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
                                  'Stok: ${bike.quantity}',
                                  style: AppTextStyles.bodyText.copyWith(color: bike.quantity > 0 ? AppColors.successColor : AppColors.dangerColor, fontWeight: FontWeight.bold),
                                ),
                                if (bike.description != null && bike.description!.isNotEmpty)
                                   Padding(
                                     padding: const EdgeInsets.only(top: 4.0),
                                     child: Text(
                                      bike.description!,
                                      maxLines: 2, // Batasi deskripsi hingga 2 baris
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTextStyles.bodyText.copyWith(fontSize: 12, color: AppColors.subtitleColor),
                                    ),
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
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primaryColor, // Warna primer
                                        foregroundColor: Colors.white, // Warna teks tombol
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                        textStyle: AppTextStyles.buttonText.copyWith(fontSize: 14),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
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
                                              const SnackBar(content: Text('Sepeda berhasil dihapus'), backgroundColor: AppColors.successColor)
                                            );
                                         }
                                       } catch (e) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Gagal menghapus sepeda: $e'), backgroundColor: AppColors.dangerColor)
                                            );
                                          }
                                       }
                                     },
                                     style: ElevatedButton.styleFrom(
                                       backgroundColor: AppColors.dangerColor, // Warna bahaya
                                       foregroundColor: Colors.white, // Warna teks tombol
                                       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                       textStyle: AppTextStyles.buttonText.copyWith(fontSize: 14),
                                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                     ),
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