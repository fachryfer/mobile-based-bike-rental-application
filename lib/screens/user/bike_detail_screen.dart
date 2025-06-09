import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/bike.dart';
import '../rent_bike_form_screen.dart'; // Import RentBikeFormScreen
import 'package:rental_sepeda/utils/app_constants.dart'; // Import AppConstants

class BikeDetailScreen extends StatefulWidget {
  final String bikeId;

  const BikeDetailScreen({Key? key, required this.bikeId}) : super(key: key);

  @override
  _BikeDetailScreenState createState() => _BikeDetailScreenState();
}

class _BikeDetailScreenState extends State<BikeDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Sepeda'),
        // AppBar theme is handled by MaterialApp theme in main.dart
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('bikes').doc(widget.bikeId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            print('Error fetching bike details: ${snapshot.error}');
            return Center(child: Text('Error memuat detail sepeda: ${snapshot.error}', style: AppTextStyles.bodyText.copyWith(color: AppColors.dangerColor)));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bike_scooter, size: 60, color: AppColors.subtitleColor),
                  const SizedBox(height: 16),
                  Text('Sepeda tidak ditemukan atau sudah dihapus.', style: AppTextStyles.subtitle.copyWith(color: AppColors.subtitleColor)),
                ],
              ),
            );
          }

          final bikeData = snapshot.data!.data() as Map<String, dynamic>;
          final bike = Bike.fromFirestore(bikeData, snapshot.data!.id);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Image and Title
                Container(
                  decoration: AppDecorations.cardDecoration.copyWith(borderRadius: BorderRadius.circular(15)),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      if (bike.imageUrl != null && bike.imageUrl!.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            bike.imageUrl!,
                            height: 250,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) => Center(child: Icon(Icons.broken_image, size: 100, color: AppColors.subtitleColor)),
                          ),
                        )
                      else
                        Center(child: Icon(Icons.pedal_bike, size: 150, color: AppColors.subtitleColor)),
                      const SizedBox(height: 16),
                      Text(
                        bike.name,
                        style: AppTextStyles.headline1.copyWith(color: AppColors.textColor),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Details Card
                Container(
                  decoration: AppDecorations.cardDecoration,
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Informasi Sepeda', style: AppTextStyles.title.copyWith(color: AppColors.primaryColor)),
                      const Divider(height: 24, thickness: 1, color: AppColors.subtitleColor),
                      _buildDetailRow('Harga per Hari', 'Rp${bike.pricePerDay.toStringAsFixed(0)}', Icons.money_rounded),
                      _buildDetailRow('Stok Tersedia', '${bike.quantity}', Icons.inventory_2,
                          valueColor: bike.quantity > 0 ? AppColors.successColor : AppColors.dangerColor),
                      if (bike.description != null && bike.description!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text('Deskripsi', style: AppTextStyles.title.copyWith(color: AppColors.primaryColor)),
                        const Divider(height: 24, thickness: 1, color: AppColors.subtitleColor),
                        Text(bike.description!, style: AppTextStyles.bodyText),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Rent Button
                if (bike.quantity > 0)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.shopping_cart, color: Colors.white),
                    label: Text('Sewa Sepeda Ini', style: AppTextStyles.buttonText.copyWith(color: Colors.white)),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => RentBikeFormScreen(bikeId: bike.id)),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.buttonColor,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: AppDecorations.cardDecoration.copyWith(color: AppColors.dangerColor.withOpacity(0.1)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, color: AppColors.dangerColor),
                        const SizedBox(width: 8),
                        Text('Stok sepeda ini sedang habis.', style: AppTextStyles.bodyText.copyWith(color: AppColors.dangerColor, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primaryColor, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.bodyText.copyWith(color: AppColors.subtitleColor)),
                Text(value, style: AppTextStyles.title.copyWith(color: valueColor ?? AppColors.textColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 