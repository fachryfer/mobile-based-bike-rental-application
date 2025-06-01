import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class RentalDetailScreen extends StatefulWidget {
  final String rentalId;

  const RentalDetailScreen({super.key, required this.rentalId});

  @override
  State<RentalDetailScreen> createState() => _RentalDetailScreenState();
}

class _RentalDetailScreenState extends State<RentalDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Penyewaan')),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('rentals').doc(widget.rentalId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Detail penyewaan tidak ditemukan.'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final isAdmin = true; // TODO: Check actual user role

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nama Sepeda: ${data['bikeName'] ?? '-'}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Penyewa: ${data['userName'] ?? '-'}', style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 8),
                Text('Durasi: ${data['duration'] ?? '-'} hari', style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 8),
                Text('Tanggal Sewa: ${data['date'] != null ? (data['date'] as Timestamp).toDate().toString().substring(0, 10) : '-'}', style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 8),
                Text('Status: ${data['status'] ?? 'pending'}', style: const TextStyle(fontSize: 16, color: Colors.blue)),
                const SizedBox(height: 16),

                if (data['imageUrl'] != null && data['imageUrl'].isNotEmpty) ...[
                  const Text('Foto/Dokumen:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Center(
                    child: Image.network(
                      data['imageUrl'],
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
                      errorBuilder: (context, error, stackTrace) => const Text('Gagal memuat gambar'),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                if (isAdmin && data['status'] == 'pending') ...[
                   const Text('Aksi Admin:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                   const SizedBox(height: 8),
                   Row(
                     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                     children: [
                       ElevatedButton.icon(
                         icon: const Icon(Icons.check, color: Colors.white),
                         label: const Text('Setujui'),
                         style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                         onPressed: () async {
                           await snapshot.data!.reference.update({'status': 'approved'});
                           if (mounted) {
                             ScaffoldMessenger.of(context).showSnackBar(
                               const SnackBar(content: Text('Penyewaan disetujui!'), backgroundColor: Colors.green),
                             );
                              Navigator.pop(context);
                           }
                         },
                       ),
                       ElevatedButton.icon(
                         icon: const Icon(Icons.close, color: Colors.white),
                         label: const Text('Tolak'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                         onPressed: () async {
                           await snapshot.data!.reference.update({'status': 'rejected'});
                           if (mounted) {
                             ScaffoldMessenger.of(context).showSnackBar(
                               const SnackBar(content: Text('Penyewaan ditolak.'), backgroundColor: Colors.red),
                             );
                              Navigator.pop(context);
                           }
                         },
                       ),
                     ],
                   ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
} 