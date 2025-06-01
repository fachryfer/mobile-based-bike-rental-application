import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RentalDetailScreen extends StatefulWidget {
  final String rentalId;

  const RentalDetailScreen({super.key, required this.rentalId});

  @override
  State<RentalDetailScreen> createState() => _RentalDetailScreenState();
}

class _RentalDetailScreenState extends State<RentalDetailScreen> {
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
  }

  Future<void> _checkUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (mounted) {
        setState(() {
          _userRole = userDoc.data()?['role'] as String?;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Penyewaan')),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('rentals').doc(widget.rentalId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting || _userRole == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Detail penyewaan tidak ditemukan.'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final isAdmin = _userRole == 'admin';

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
                           try {
                              // Get bikeId from the rental document
                              final data = snapshot.data!.data() as Map<String, dynamic>; // Get data again if needed
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
                                      transaction.update(snapshot.data!.reference, {'status': 'approved'});
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Penyewaan disetujui dan stok sepeda diperbarui!'), backgroundColor: Colors.green)
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
                               if (mounted) {
                                  // Pop only after transaction attempt
                                  Navigator.pop(context);
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