import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert'; // Import for jsonDecode
import 'package:http/http.dart' as http; // Import http
import '../models/bike.dart'; // Import Bike model

class RentBikeFormScreen extends StatefulWidget {
  final String? bikeId; // Add nullable bikeId parameter

  const RentBikeFormScreen({super.key, this.bikeId}); // Update constructor

  @override
  State<RentBikeFormScreen> createState() => _RentBikeFormScreenState();
}

class _RentBikeFormScreenState extends State<RentBikeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _durationController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  DateTime? _selectedDate;
  DateTime? _endDate;
  File? _selectedImage;
  bool _isLoading = false;

  // State variables for bikes dropdown
  List<Bike> _availableBikes = [];
  String? _selectedBikeId;

  // State variable for calculated total price
  double _totalPrice = 0.0;

  @override
  void initState() {
    super.initState();
    // If bikeId is provided, pre-select it
    if (widget.bikeId != null) {
      _selectedBikeId = widget.bikeId;
    }
    _durationController.addListener(_calculateEndDate);
  }

  void _calculateEndDate() {
    if (_selectedDate != null && _durationController.text.isNotEmpty) {
      try {
        final duration = int.parse(_durationController.text.trim());
        setState(() {
          _endDate = _selectedDate!.add(Duration(days: duration));
          _updateTotalPrice(); // Update total price when duration changes
        });
      } catch (e) {
        setState(() {
           _endDate = null;
        });
      }
    } else {
      setState(() {
        _endDate = null;
      });
    }
  }

  // Function to update total price
  void _updateTotalPrice() {
    if (_selectedBikeId != null && _durationController.text.isNotEmpty) {
      try {
        final selectedBike = _availableBikes.firstWhere((bike) => bike.id == _selectedBikeId);
        final duration = int.parse(_durationController.text.trim());
        setState(() {
          _totalPrice = selectedBike.price * duration;
        });
      } catch (e) {
        setState(() {
          _totalPrice = 0.0; // Reset if calculation fails
        });
      }
    } else {
      setState(() {
        _totalPrice = 0.0; // Reset if bike or duration is not selected/entered
      });
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _calculateEndDate();
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  // Fungsi untuk upload ke Cloudinary
  Future<String?> _uploadToCloudinary(File imageFile) async {
    // Ganti dengan Cloud Name dan Upload Preset Anda
    final url = Uri.parse('https://api.cloudinary.com/v1_1/dmhbguqqa/image/upload'); // Ganti dmhbguqqa
    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = 'my_flutter_upload' // Ganti public_uploads menjadi nama preset yang benar
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await http.Response.fromStream(response);
        final result = jsonDecode(responseData.body);
        return result['secure_url']; // Ini adalah URL file yang diunggah
      } else {
        print('Cloudinary upload failed with status: ${response.statusCode}');
        final responseData = await http.Response.fromStream(response);
        print('Response body: ${responseData.body}');
        return null;
      }
    } catch (e) {
      print('Error uploading to Cloudinary: $e');
      return null;
    }
  }

  Future<void> _submit() async {
    // Check if a bike is selected
    if (!_formKey.currentState!.validate() || _selectedDate == null || _selectedBikeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lengkapi semua data dan pilih sepeda!'), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() {
      _isLoading = true;
    });
    try {
      final user = FirebaseAuth.instance.currentUser;
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();

      String? imageUrl;
      if (_selectedImage != null) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Mengunggah foto...'), duration: Duration(seconds: 5),) // Tampilkan pesan loading
           );
        }
        imageUrl = await _uploadToCloudinary(_selectedImage!);
        if (mounted) {
           ScaffoldMessenger.of(context).hideCurrentSnackBar(); // Sembunyikan pesan mengunggah
        }

        if (imageUrl == null) {
          if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(content: Text('Gagal mengunggah foto.'), backgroundColor: Colors.red,)
             );
             setState(() {
               _isLoading = false;
             });
          }
          return; // Batalkan submit jika upload gagal
        }
      }

      // Find the selected bike object from the available list using its ID
      final selectedBike = _availableBikes.firstWhere((bike) => bike.id == _selectedBikeId);

      // Calculate total price
      final duration = int.parse(_durationController.text.trim());
      final totalPrice = selectedBike.price * duration;

      await FirebaseFirestore.instance.collection('rentals').add({
        'userId': user.uid,
        'userName': userDoc.data()?['name'] ?? '',
        'fullName': _fullNameController.text.trim(),
        'phoneNumber': _phoneNumberController.text.trim(),
        'bikeId': selectedBike.id,
        'bikeName': selectedBike.name,
        'duration': int.parse(_durationController.text.trim()),
        'rentalDate': _selectedDate,
        'returnDate': _endDate,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'imageUrl': imageUrl,
        'pricePerDay': selectedBike.price, // Added price per day
        'totalPrice': totalPrice, // Added total price
      });

      // TODO: Implement quantity reduction on approval later

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permintaan sewa berhasil dikirim!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengirim: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _durationController.dispose();
    _fullNameController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Form Sewa Sepeda')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Replace TextFormField with DropdownButtonFormField
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('bikes').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      print('Error fetching bikes for dropdown: ${snapshot.error}');
                      return const Center(child: Text('Error memuat daftar sepeda'));
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                       return const Center(child: Text('Tidak ada sepeda tersedia'));
                    }

                    _availableBikes = snapshot.data!.docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return Bike.fromFirestore(data, doc.id);
                    }).toList();

                    // Filter bikes with quantity > 0
                    final availableBikesWithStock = _availableBikes.where((bike) => bike.quantity > 0).toList();

                    if (availableBikesWithStock.isEmpty) {
                       return const Center(child: Text('Tidak ada sepeda dengan stok tersedia'));
                    }

                    // If selectedBike is no longer in available list (e.g. quantity became 0),
                    // reset selectedBike to null.
                    if (_selectedBikeId != null && !availableBikesWithStock.any((bike) => bike.id == _selectedBikeId)){
                         _selectedBikeId = null;
                    }

                    return DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Pilih Sepeda',
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedBikeId,
                      items: availableBikesWithStock.map((bike) {
                        return DropdownMenuItem<String>(
                          value: bike.id,
                          child: Text('${bike.name} (Tersedia: ${bike.quantity})'),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedBikeId = newValue;
                          _updateTotalPrice(); // Update total price when bike changes
                        });
                      },
                      validator: (value) => value == null ? 'Wajib memilih sepeda' : null,
                    );
                  },
                ),
                // Display price of selected bike
                if (_selectedBikeId != null) ...[
                   const SizedBox(height: 8),
                   FutureBuilder<DocumentSnapshot>( // Use FutureBuilder to get the bike price
                     future: FirebaseFirestore.instance.collection('bikes').doc(_selectedBikeId).get(),
                     builder: (context, snapshot) {
                       if (snapshot.connectionState == ConnectionState.waiting) {
                         return const Text('Memuat harga...');
                       }
                       if (snapshot.hasError) {
                         return Text('Error memuat harga: ${snapshot.error}');
                       }
                       if (!snapshot.hasData || !snapshot.data!.exists) {
                         return const Text('Harga tidak tersedia');
                       }
                       final bikeData = snapshot.data!.data() as Map<String, dynamic>;
                       final price = (bikeData['price'] ?? 0.0).toDouble();
                       return Text(
                         'Harga per Hari: Rp${price.toStringAsFixed(0)}', // Display price
                         style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                       );
                     },
                   ),
                ],
                const SizedBox(height: 16),
                TextFormField(
                  controller: _fullNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Lengkap',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Nomor Telepon',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _durationController,
                  decoration: const InputDecoration(labelText: 'Durasi (hari)'),
                  keyboardType: TextInputType.number,
                  validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                          _selectedDate == null
                              ? 'Tanggal sewa belum dipilih'
                              : 'Tanggal Sewa: ${_selectedDate!.toLocal().toString().split(' ')[0]}'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(onPressed: _pickDate, child: const Text('Pilih Tanggal Sewa')),
                  ],
                ),
                const SizedBox(height: 8),
                if (_endDate != null)
                  Text(
                      'Tanggal Pengembalian: ${_endDate!.toLocal().toString().split(' ')[0]}',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.photo),
                      label: const Text('Upload Foto KTP (Opsional)'),
                    ),
                    const SizedBox(width: 8),
                    if (_selectedImage != null)
                      const Icon(Icons.check_circle, color: Colors.green),
                  ],
                ),
                const SizedBox(height: 32),
                Text(
                  'Total Harga: Rp${_totalPrice.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Kirim Permintaan Sewa'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 