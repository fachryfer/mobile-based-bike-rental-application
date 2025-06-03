import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

enum RentalStatus {
  pending,
  awaiting_pickup,
  in_use,
  completed,
  rejected,
}

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
          final currentStatus = data['status'] as String? ?? 'pending';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Detail Sepeda
                Card(
                  margin: const EdgeInsets.only(bottom: 16.0),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Detail Sepeda', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const Divider(height: 16, thickness: 1),
                        // Loop through items to display each rented bike
                        if (data['items'] is List) // Check if 'items' exists and is a List
                           ...(data['items'] as List).map((item) {
                             if (item is Map<String, dynamic>) {
                               return Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0), // Add spacing between items
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                     children: [
                                       _buildDetailRow(context, 'Jenis Sepeda', item['bikeName'] ?? '-', icon: Icons.bike_scooter),
                                       _buildDetailRow(context, 'Jumlah', (item['quantity'] ?? 0).toString(), icon: Icons.format_list_numbered),
                                       _buildDetailRow(context, 'Harga per Hari', 'Rp${(item['pricePerDay'] ?? 0.0).toStringAsFixed(0)}', icon: Icons.money),
                                       // Optionally display subtotal per item if needed
                                      //  _buildDetailRow(context, 'Subtotal', 'Rp${((item['pricePerDay'] ?? 0.0) * (item['quantity'] ?? 0) * (data['duration'] ?? 0)).toStringAsFixed(0)}', icon: Icons.money),
                                     ],
                                  ),
                               );
                             }
                             return const SizedBox.shrink(); // Return empty widget if item format is unexpected
                           }).toList(),

                         // Removed single bike details
                        // _buildDetailRow(context, 'Nama Sepeda', data['bikeName'] ?? '-', icon: Icons.bike_scooter),
                        _buildDetailRow(context, 'Durasi', '${data['duration'] ?? '-'} hari', icon: Icons.timer),
                        // _buildDetailRow(context, 'Harga per Hari', 'Rp${(data['pricePerDay'] ?? 0.0).toStringAsFixed(0)}', icon: Icons.money),
                        _buildDetailRow(context, 'Total Harga', 'Rp${(data['totalPrice'] ?? 0.0).toStringAsFixed(0)}', icon: Icons.payment, isBold: true),
                        _buildDetailRow(context, 'Tanggal Sewa', data['rentalDate'] != null ? (data['rentalDate'] as Timestamp).toDate().toString().substring(0, 10) : '-', icon: Icons.calendar_today),
                        _buildDetailRow(context, 'Tanggal Pengembalian', data['returnDate'] != null ? (data['returnDate'] as Timestamp).toDate().toString().substring(0, 10) : '-', icon: Icons.calendar_month),
                         _buildDetailRow(context, 'Status', currentStatus.replaceAll('_', ' ').toUpperCase(), icon: Icons.info_outline, valueColor: _getStatusColor(currentStatus)),
                      ],
                    ),
                  ),
                ),

                 // Detail Penyewa
                Card(
                  margin: const EdgeInsets.only(bottom: 16.0),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Detail Penyewa', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                         const Divider(height: 16, thickness: 1),
                        _buildDetailRow(context, 'Nama Pengguna', data['userName'] ?? '-', icon: Icons.person_outline),
                        _buildDetailRow(context, 'Nama Lengkap', data['fullName'] ?? '-', icon: Icons.badge),
                        _buildDetailRow(context, 'Nomor Telepon', data['phoneNumber'] ?? '-', icon: Icons.phone, onTap: () => _launchPhone(data['phoneNumber'])),
                      ],
                    ),
                  ),
                ),

                // Foto/Dokumen
                if (data['imageUrl'] != null && data['imageUrl'].isNotEmpty) ...[
                  Card(
                    margin: const EdgeInsets.only(bottom: 16.0),
                    child: Padding(
                       padding: const EdgeInsets.all(16.0),
                      child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Foto/Dokumen:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                           const Divider(height: 16, thickness: 1),
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
                        ],
                      ),
                    ),
                  ),
                ],

                // Lokasi Pengambilan (Button)
                 Card(
                   margin: const EdgeInsets.only(bottom: 16.0),
                   child: Padding(
                     padding: const EdgeInsets.all(16.0),
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         const Text('Lokasi Pengambilan:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          const Divider(height: 16, thickness: 1),
                         Center(
                           child: ElevatedButton.icon(
                             icon: const Icon(Icons.map), // Map icon
                             label: const Text('Lihat Lokasi Pengambilan di Peta'),
                             onPressed: _launchMap,
                           ),
                         ),
                       ],
                     ),
                   ),
                 ),

                // Aksi Admin
                if (isAdmin) ...[
                   Card(
                     margin: const EdgeInsets.only(bottom: 16.0),
                     child: Padding(
                        padding: const EdgeInsets.all(16.0),
                       child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           const Text('Aksi Admin:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            const Divider(height: 16, thickness: 1),
                            if (currentStatus == RentalStatus.pending.name) ...[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.check, color: Colors.white),
                                    label: const Text('Setujui (Menunggu Diambil)'),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                    onPressed: () async {
                                      try {
                                        await snapshot.data!.reference.update({'status': RentalStatus.awaiting_pickup.name});
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Permintaan disetujui. Status diubah menjadi Menunggu Diambil.'), backgroundColor: Colors.green),
                                          );
                                          Navigator.pop(context);
                                        }
                                      } catch (e) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Gagal menyetujui permintaan: $e'), backgroundColor: Colors.red),
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
                                      try {
                                        await snapshot.data!.reference.update({'status': RentalStatus.rejected.name});
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Penyewaan ditolak.'), backgroundColor: Colors.red),
                                          );
                                          Navigator.pop(context);
                                        }
                                      } catch (e) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Gagal menolak permintaan: $e'), backgroundColor: Colors.red),
                                          );
                                        }
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ] else if (currentStatus == RentalStatus.awaiting_pickup.name) ...[
                              Center(
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.bike_scooter, color: Colors.white),
                                  label: const Text('Sepeda Diambil (Sedang Digunakan)'),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                                  onPressed: () async {
                                    try {
                                      // Ensure data is available
                                      final data = snapshot.data!.data() as Map<String, dynamic>;
                                      final List<dynamic>? items = data['items'];

                                      if (items == null || items.isEmpty) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Data item sewa tidak ditemukan.'), backgroundColor: Colors.red),
                                          );
                                        }
                                        return; // Exit if no items
                                      }

                                      await FirebaseFirestore.instance.runTransaction((transaction) async {
                                        bool stockError = false;
                                        // Map to store current quantities read in the first pass
                                        Map<String, int> currentQuantities = {};

                                        // FIRST PASS: READ all necessary bike data to check stock
                                        for (var item in items) {
                                          if (item is Map<String, dynamic>) {
                                            final bikeId = item['bikeId'];
                                            final quantityToRent = item['quantity'] ?? 0;
                                            if (bikeId != null && quantityToRent > 0) {
                                              final bikeRef = FirebaseFirestore.instance.collection('bikes').doc(bikeId);
                                              final bikeSnapshot = await transaction.get(bikeRef); // Read 1

                                              if (!bikeSnapshot.exists) {
                                                stockError = true;
                                                if (mounted) {
                                                   // Note: SnackBar inside transaction is not ideal, but for immediate feedback
                                                   // we'll keep it here for now. Better error handling would be outside.
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(content: Text('Data sepeda dengan ID $bikeId tidak ditemukan.'), backgroundColor: Colors.red),
                                                  );
                                                }
                                                return; // Exit transaction
                                              }

                                              final currentQuantity = bikeSnapshot.data()?['quantity'] ?? 0;
                                              currentQuantities[bikeId] = currentQuantity; // Store current quantity

                                              if (currentQuantity < quantityToRent) {
                                                stockError = true;
                                                if (mounted) {
                                                   ScaffoldMessenger.of(context).showSnackBar(
                                                      const SnackBar(content: Text('Stok sepeda tidak mencukupi untuk satu atau lebih item.'), backgroundColor: Colors.orange),
                                                    );
                                                }
                                                return; // Exit transaction
                                              }
                                            } else {
                                              stockError = true;
                                               if (mounted) {
                                                 ScaffoldMessenger.of(context).showSnackBar(
                                                   const SnackBar(content: Text('Data item sewa tidak valid.'), backgroundColor: Colors.red),
                                                 );
                                               }
                                              return; // Exit transaction
                                            }
                                          } else {
                                             stockError = true;
                                             if (mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text('Format item sewa tidak valid.'), backgroundColor: Colors.red),
                                                );
                                             }
                                            return; // Exit transaction
                                          }
                                        }

                                        if (stockError) {
                                            // If stockError is true, the transaction would have already exited
                                            // via 'return' in the loop. This check is defensive.
                                            return;
                                        }

                                        // SECOND PASS: WRITE (update stock and rental status)
                                        // This only happens if all stock checks in the first pass succeeded
                                        for (var item in items) {
                                          if (item is Map<String, dynamic>) {
                                            final bikeId = item['bikeId'];
                                            final quantityToRent = item['quantity'] ?? 0;
                                            if (bikeId != null && quantityToRent > 0) {
                                              final bikeRef = FirebaseFirestore.instance.collection('bikes').doc(bikeId);
                                              final currentQuantity = currentQuantities[bikeId] ?? 0; // Use the quantity read earlier
                                              transaction.update(bikeRef, {'quantity': currentQuantity - quantityToRent}); // Write 1
                                            }
                                          }
                                        }

                                        // Update rental status to in_use after reducing stock for all items
                                        transaction.update(snapshot.data!.reference, {'status': RentalStatus.in_use.name}); // Write 2

                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Status penyewaan diubah menjadi Sedang Digunakan dan stok diperbarui!'), backgroundColor: Colors.green),
                                          );
                                          Navigator.pop(context); // Go back after action
                                        }
                                      });

                                    } catch (e) {
                                      // Handle potential errors outside the transaction block if needed,
                                      // although the transaction itself catches many.
                                      print('Error during "Sepeda Diambil" action: $e'); // Log the error
                                       if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Terjadi error: $e'), backgroundColor: Colors.red),
                                          );
                                       }
                                    }
                                  },
                                ),
                              ),
                            ] else if (currentStatus == RentalStatus.in_use.name) ...[
                              Center(
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.assignment_returned, color: Colors.white),
                                  label: const Text('Tandai Selesai / Sepeda Dikembalikan'),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                  onPressed: () async {
                                    try {
                                      final data = snapshot.data!.data() as Map<String, dynamic>;
                                      final List<dynamic>? items = data['items']; // Get the list of items

                                      if (items == null || items.isEmpty) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Data item sewa tidak ditemukan. Stok tidak dapat diperbarui.'), backgroundColor: Colors.red),
                                          );
                                        }
                                        return; // Exit if no items
                                      }

                                      await FirebaseFirestore.instance.runTransaction((transaction) async {
                                         // Map to store current quantities read in the first pass
                                        Map<String, int> currentQuantities = {};

                                        // FIRST PASS: READ all necessary bike data to get current quantities for increment
                                        for (var item in items) {
                                             if (item is Map<String, dynamic>) {
                                                final bikeId = item['bikeId'];
                                                final quantityReturned = item['quantity'] ?? 0;
                                                if (bikeId != null && quantityReturned > 0) {
                                                    final bikeRef = FirebaseFirestore.instance.collection('bikes').doc(bikeId);
                                                    // READ: Reading bike data to get current quantity for increment
                                                    final bikeSnapshot = await transaction.get(bikeRef); // Read 1

                                                     if (!bikeSnapshot.exists) {
                                                       if (mounted) {
                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                            SnackBar(content: Text('Data sepeda dengan ID $bikeId tidak ditemukan. Stok tidak dapat diperbarui.'), backgroundColor: Colors.orange),
                                                          );
                                                       }
                                                        return; // Exit transaction if bike data is missing
                                                     }

                                                      final currentQuantity = bikeSnapshot.data()?['quantity'] ?? 0;
                                                      currentQuantities[bikeId] = currentQuantity; // Store current quantity

                                                } else if (quantityReturned <= 0) {
                                                   if (mounted) {
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        const SnackBar(content: Text('Jumlah sepeda yang dikembalikan harus lebih dari 0.'), backgroundColor: Colors.orange),
                                                      );
                                                   }
                                                   return; // Exit transaction if quantity is invalid
                                                }
                                             } else {
                                                if (mounted) {
                                                   ScaffoldMessenger.of(context).showSnackBar(
                                                     const SnackBar(content: Text('Format item sewa tidak valid.'), backgroundColor: Colors.red),
                                                   );
                                                }
                                                return; // Exit transaction if item format is invalid
                                             }
                                          }

                                          // SECOND PASS: WRITE (increment stock and update rental status)
                                          // This only happens if all reads in the first pass succeeded
                                          for (var item in items) {
                                             if (item is Map<String, dynamic>) {
                                                final bikeId = item['bikeId'];
                                                final quantityReturned = item['quantity'] ?? 0;
                                                if (bikeId != null && quantityReturned > 0) {
                                                    final bikeRef = FirebaseFirestore.instance.collection('bikes').doc(bikeId);
                                                    final currentQuantity = currentQuantities[bikeId] ?? 0; // Use the quantity read earlier
                                                    transaction.update(bikeRef, {'quantity': currentQuantity + quantityReturned}); // Write 1
                                                }
                                             }
                                          }

                                          // Update rental status to completed
                                          transaction.update(snapshot.data!.reference, {'status': RentalStatus.completed.name}); // Write 2

                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Penyewaan berhasil ditandai selesai dan stok sepeda diperbarui.'), backgroundColor: Colors.green),
                                            );
                                            Navigator.pop(context); // Go back after action
                                          }
                                        });
                                       } catch (e) {
                                         if (mounted) {
                                           ScaffoldMessenger.of(context).showSnackBar(
                                             SnackBar(content: Text('Gagal menandai selesai: $e'), backgroundColor: Colors.red),
                                           );
                                         }
                                       }
                                    },
                                ),
                              ),
                            ],
                          ],
                       ),
                     ),
                   ),
                ],

                // Pesan untuk Pengguna non-Admin (awaiting_pickup)
                if (!isAdmin && currentStatus == RentalStatus.awaiting_pickup.name) ...[
                  Card(
                     margin: const EdgeInsets.only(bottom: 16.0),
                     child: Padding(
                        padding: const EdgeInsets.all(16.0),
                       child: Center(
                         child: Text(
                           '''Terima kasih telah menggunakan jasa kami!
Permintaan Anda disetujui. Sepeda siap diambil di lokasi kami sesuai dengan tanggal yang telah ditentukan.''',
                           textAlign: TextAlign.center,
                           style: TextStyle(fontSize: 16, color: Colors.green, fontWeight: FontWeight.bold),
                         ),
                       ),
                     ),
                   ),
                ],

                const SizedBox(height: 24),

                const Text('Penjelasan Status:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: RentalStatus.values.map((status) {
                    String description;
                    Color color = Colors.black;
                    switch (status) {
                      case RentalStatus.pending:
                        description = 'Permintaan penyewaan masih dalam proses peninjauan oleh admin.';
                        color = Colors.orange;
                        break;
                      case RentalStatus.awaiting_pickup:
                        description = 'Permintaan disetujui. Sepeda siap diambil di lokasi sesuai dengan tanggal yang telah ditentukan.';
                        color = Colors.blue;
                        break;
                      case RentalStatus.in_use:
                        description = 'Sepeda sedang digunakan oleh penyewa.';
                        color = Colors.purple;
                        break;
                      case RentalStatus.completed:
                        description = 'Penyewaan telah selesai dan sepeda sudah dikembalikan.';
                        color = Colors.green;
                        break;
                      case RentalStatus.rejected:
                        description = 'Permintaan penyewaan ditolak oleh admin.';
                        color = Colors.red;
                        break;
                    }
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 4.0, right: 8.0),
                            width: 8.0,
                            height: 8.0,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              '${status.name.replaceAll('_', ' ').toUpperCase()}: $description',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),



              ],
            ),
          );
        },
      ),
    );
  }

  // Helper widget to build detail rows
  Widget _buildDetailRow(BuildContext context, String title, String value, {IconData? icon, Color? valueColor, bool isBold = false, VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) Icon(icon, size: 20, color: Theme.of(context).primaryColor), // Use primary color for icons
          if (icon != null) const SizedBox(width: 12), // Spacing after icon
          Expanded(
            flex: 2,
            child: Text(
              '$title:',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600), // Semi-bold title
            ),
          ),
          Expanded(
            flex: 3,
            child: GestureDetector(
              onTap: onTap,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  color: onTap != null ? Colors.blue : (valueColor ?? Colors.black87),
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                   decoration: onTap != null ? TextDecoration.underline : TextDecoration.none, // Underline if tappable
                ),
                overflow: TextOverflow.ellipsis, // Prevent overflow
              ),
            ),
          ),
        ],
      ),
    );
  }

    // Function to launch a phone call
  Future<void> _launchPhone(String? phoneNumber) async {
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      final Uri phoneLaunchUri = Uri(scheme: 'tel', path: phoneNumber);
      if (await canLaunchUrl(phoneLaunchUri)) {
        await launchUrl(phoneLaunchUri);
      } else {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tidak dapat melakukan panggilan.'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }


  // Function to launch the map
  Future<void> _launchMap() async {
    const double latitude = 3.558049482634812;
    const double longitude = 98.65088891654166;
    final Uri googleMapsUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=$latitude,$longitude');
    final Uri appleMapsUrl = Uri.parse('https://maps.apple.com/?q=$latitude,$longitude');

    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl);
    } else if (await canLaunchUrl(appleMapsUrl)) {
      await launchUrl(appleMapsUrl);
    } else {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka aplikasi peta.'), backgroundColor: Colors.red),
        );
      }
    }
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

const CameraPosition _kGooglePlex = CameraPosition(
  target: LatLng(3.558049482634812, 98.65088891654166), // Updated with actual coordinates
  zoom: 14.4746,
);

const Marker _kPickupLocation = Marker(
  markerId: MarkerId('pickupLocation'),
  position: LatLng(3.558049482634812, 98.65088891654166), // Updated with actual coordinates
  infoWindow: InfoWindow(title: 'Lokasi Pengambilan Sepeda'),
); 