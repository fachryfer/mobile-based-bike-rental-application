import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert'; // Import for jsonDecode
import 'package:http/http.dart' as http; // Import http
import '../models/bike.dart'; // Import Bike model
import 'package:intl/intl.dart' as intl;
import 'package:rental_sepeda/utils/app_constants.dart'; // Import AppConstants

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

  // State variables for bikes
  List<Bike> _availableBikes = [];
  // Changed from single selected bike to a list of selected items
  List<Map<String, dynamic>> _selectedItems = []; // List of {bikeId: String, quantity: int}

  // State variable for calculated total price
  double _totalPrice = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchAvailableBikes(); // Fetch available bikes
    // If bikeId is provided, add it as the initial item
    if (widget.bikeId != null) {
      _selectedItems.add({'bikeId': widget.bikeId, 'quantity': 1});
    }
    _durationController.addListener(_calculateEndDate);
    _durationController.addListener(_updateTotalPrice);
  }

  // Fetch available bikes from Firestore
  Future<void> _fetchAvailableBikes() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('bikes').get();
      final bikes = snapshot.docs.map((doc) => Bike.fromFirestore(doc.data() as Map<String, dynamic>, doc.id)).toList();
      setState(() {
        _availableBikes = bikes;
         // If initial bikeId was provided, ensure it's in the available list and update price
         if (widget.bikeId != null && _availableBikes.any((bike) => bike.id == widget.bikeId)){
            _updateTotalPrice();
         }
      });
    } catch (e) {
      print('Error fetching bikes: $e');
       if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('Gagal memuat daftar sepeda: $e'), backgroundColor: Colors.red),
           );
        }
    }
  }

   // Function to add a new item row
  void _addItem() {
    setState(() {
      _selectedItems.add({'bikeId': null, 'quantity': 1});
    });
  }

  // Function to remove an item row
  void _removeItem(int index) {
    setState(() {
      _selectedItems.removeAt(index);
      _updateTotalPrice(); // Update total price after removing an item
    });
  }

  void _calculateEndDate() {
    if (_selectedDate != null && _durationController.text.isNotEmpty) {
      try {
        final duration = int.parse(_durationController.text.trim());
        setState(() {
          _endDate = _selectedDate!.add(Duration(days: duration));
          // Total price update is now handled by _updateTotalPrice listener on _durationController
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

  // Function to update total price based on all selected items and duration
  void _updateTotalPrice() {
    double calculatedPrice = 0.0;
    final duration = int.tryParse(_durationController.text.trim()) ?? 0; // Use tryParse for safety

    if (duration > 0) {
      for (var item in _selectedItems) {
        final bikeId = item['bikeId'];
        final quantity = item['quantity'] ?? 0;
        if (bikeId != null && quantity > 0) {
          final selectedBike = _availableBikes.firstWhere(
            (bike) => bike.id == bikeId,
            orElse: () => Bike(id: '', name: '', pricePerDay: 0.0, quantity: 0), // Provide a default dummy bike
          );
           calculatedPrice += selectedBike.pricePerDay * quantity * duration; // Use pricePerDay
        }
      }
    }

    setState(() {
      _totalPrice = calculatedPrice;
    });
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
        _updateTotalPrice(); // Update total price when date changes
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
    // Validate form and check if at least one item is selected and has quantity > 0
    if (!_formKey.currentState!.validate() || _selectedDate == null || _selectedItems.isEmpty || _selectedItems.every((item) => item['bikeId'] == null || item['quantity'] <= 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lengkapi semua data dan tambahkan minimal satu sepeda dengan jumlah yang valid!'), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() {
      _isLoading = true;
    });

    // Check available stock before submitting
    for (var item in _selectedItems) {
      final bikeId = item['bikeId'];
      final quantityToRent = item['quantity'] ?? 0;
      if (bikeId != null && quantityToRent > 0) {
         final availableBike = _availableBikes.firstWhere((bike) => bike.id == bikeId);
         if (availableBike.quantity < quantityToRent) {
             if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Stok untuk ${availableBike.name} tidak mencukupi.'), backgroundColor: Colors.orange),
              );
               setState(() {
                _isLoading = false;
              });
            }
             return; // Stop submission if stock is insufficient
         }
      }
    }

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

      // Prepare items data for Firestore
      final rentalItemsData = _selectedItems.map((item) {
        final bike = _availableBikes.firstWhere((b) => b.id == item['bikeId']);
        return {
          'bikeId': item['bikeId'],
          'bikeName': bike.name,
          'quantity': item['quantity'] ?? 0, // Ensure quantity is included in item data
          'pricePerDay': bike.pricePerDay, // Use pricePerDay
        };
      }).toList();


      await FirebaseFirestore.instance.collection('rentals').add({
        'userId': user.uid,
        'userName': userDoc.data()?['name'] ?? '',
        'fullName': _fullNameController.text.trim(),
        'phoneNumber': _phoneNumberController.text.trim(),
        'items': rentalItemsData, // Store list of items
        'duration': int.parse(_durationController.text.trim()),
        'rentalDate': _selectedDate,
        'returnDate': _endDate,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'imageUrl': imageUrl, // Assuming only one image for the whole rental
        'totalPrice': _totalPrice, // Store total price
      });

      // Quantity reduction will be handled by admin approval action now

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
    _durationController.removeListener(_calculateEndDate);
    _durationController.removeListener(_updateTotalPrice);
    _durationController.dispose();
    _fullNameController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Form Sewa Sepeda'),
        // AppBar theme is handled by MaterialApp theme in main.dart
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Isi Detail Penyewaan',
                  style: AppTextStyles.headline2.copyWith(color: AppColors.textColor),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _fullNameController,
                  decoration: AppDecorations.inputDecoration.copyWith(
                    labelText: 'Nama Lengkap',
                    prefixIcon: Icon(Icons.person, color: AppColors.primaryColor),
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Nama lengkap wajib diisi' : null,
                  style: AppTextStyles.bodyText,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneNumberController,
                  decoration: AppDecorations.inputDecoration.copyWith(
                    labelText: 'Nomor Telepon',
                    prefixIcon: Icon(Icons.phone, color: AppColors.primaryColor),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) => value == null || value.isEmpty ? 'Nomor telepon wajib diisi' : null,
                  style: AppTextStyles.bodyText,
                ),
                const SizedBox(height: 16),
                // Dynamic bike selection and quantity
                ..._selectedItems.asMap().entries.map((entry) {
                  int index = entry.key;
                  Map<String, dynamic> item = entry.value;
                  String? currentBikeId = item['bikeId'];
                  int currentQuantity = item['quantity'] ?? 1;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0), // Spasi antar item sepeda
                    child: Container(
                      decoration: AppDecorations.cardDecoration.copyWith(borderRadius: BorderRadius.circular(10)), // Card style for each item
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  decoration: AppDecorations.inputDecoration.copyWith(
                                    labelText: 'Pilih Sepeda',
                                    prefixIcon: Icon(Icons.directions_bike, color: AppColors.primaryColor),
                                    isDense: true,
                                  ),
                                  value: currentBikeId,
                                  hint: Text('Pilih sepeda', style: AppTextStyles.bodyText.copyWith(color: AppColors.subtitleColor)),
                                  isExpanded: true,
                                  items: _availableBikes.map((bike) {
                                    return DropdownMenuItem<String>(
                                      value: bike.id,
                                      child: Text(
                                        '${bike.name} (Stok: ${bike.quantity}, Rp${bike.pricePerDay.toStringAsFixed(0)}/hari)',
                                        style: AppTextStyles.bodyText.copyWith(fontSize: 14), // Reduce font size slightly
                                        maxLines: 1, // Ensure text is on a single line
                                        overflow: TextOverflow.ellipsis, // Add ellipsis if text overflows
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (bikeId) {
                                    setState(() {
                                      item['bikeId'] = bikeId;
                                      _updateTotalPrice();
                                    });
                                  },
                                  validator: (value) => value == null ? 'Pilih sepeda' : null,
                                  style: AppTextStyles.bodyText.copyWith(color: AppColors.textColor, fontSize: 12), // Reduce font size for selected text
                                ),
                              ),
                              if (_selectedItems.length > 1) // Allow removing if more than one item
                                IconButton(
                                  icon: Icon(Icons.remove_circle, color: AppColors.dangerColor, size: 20), // Reduce icon size
                                  onPressed: () => _removeItem(index),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            decoration: AppDecorations.inputDecoration.copyWith(
                              labelText: 'Jumlah',
                              prefixIcon: Icon(Icons.filter_hdr, color: AppColors.primaryColor),
                            ),
                            keyboardType: TextInputType.number,
                            initialValue: currentQuantity.toString(),
                            onChanged: (value) {
                              setState(() {
                                item['quantity'] = int.tryParse(value) ?? 0;
                                _updateTotalPrice();
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Jumlah wajib diisi';
                              }
                              final quantity = int.tryParse(value);
                              if (quantity == null || quantity <= 0) {
                                return 'Jumlah harus lebih dari 0';
                              }
                              // Check stock availability
                              final selectedBike = _availableBikes.firstWhere((bike) => bike.id == currentBikeId, orElse: () => Bike(id: '', name: '', pricePerDay: 0.0, quantity: 0));
                              if (quantity > selectedBike.quantity) {
                                return 'Stok hanya tersisa ${selectedBike.quantity}';
                              }
                              return null;
                            },
                            style: AppTextStyles.bodyText,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
                // Add new item button
                ElevatedButton.icon(
                  onPressed: _addItem,
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: Text('Tambah Sepeda Lain', style: AppTextStyles.buttonText.copyWith(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor, // Warna primer
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: _pickDate,
                  child: AbsorbPointer(
                    child: TextFormField(
                      decoration: AppDecorations.inputDecoration.copyWith(
                        labelText: 'Tanggal Mulai Sewa',
                        prefixIcon: Icon(Icons.calendar_today, color: AppColors.primaryColor),
                      ),
                      controller: TextEditingController(
                        text: _selectedDate == null
                            ? ''
                            : intl.DateFormat('dd MMMM yyyy').format(_selectedDate!),
                      ),
                      validator: (value) => value == null || value.isEmpty ? 'Tanggal mulai sewa wajib diisi' : null,
                      style: AppTextStyles.bodyText,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _durationController,
                  decoration: AppDecorations.inputDecoration.copyWith(
                    labelText: 'Durasi Sewa (hari)',
                    prefixIcon: Icon(Icons.timer, color: AppColors.primaryColor),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Durasi sewa wajib diisi';
                    }
                    if (int.tryParse(value) == null || int.parse(value) <= 0) {
                      return 'Durasi harus angka positif';
                    }
                    return null;
                  },
                  style: AppTextStyles.bodyText,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: AppDecorations.inputDecoration.copyWith(
                    labelText: 'Tanggal Selesai Sewa',
                    prefixIcon: Icon(Icons.event, color: AppColors.primaryColor),
                  ),
                  controller: TextEditingController(
                    text: _endDate == null
                        ? ''
                        : intl.DateFormat('dd MMMM yyyy').format(_endDate!),
                  ),
                  readOnly: true,
                  style: AppTextStyles.bodyText,
                ),
                const SizedBox(height: 24),
                Text(
                  'Total Harga: Rp${_totalPrice.toStringAsFixed(0)}',
                  style: AppTextStyles.headline2.copyWith(color: AppColors.successColor), // Lebih menonjol
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                // Image picker and preview
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 150,
                    decoration: BoxDecoration(
                      color: AppColors.backgroundColor,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: AppColors.primaryColor, width: 2),
                    ),
                    alignment: Alignment.center,
                    child: _selectedImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(13), // Sedikit lebih kecil dari border luar
                            child: Image.file(
                              _selectedImage!,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt, size: 50, color: AppColors.subtitleColor),
                              const SizedBox(height: 8),
                              Text(
                                'Pilih Bukti Pembayaran/KTP',
                                style: AppTextStyles.bodyText.copyWith(color: AppColors.subtitleColor),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text('Sewa Sepeda', style: AppTextStyles.buttonText.copyWith(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.buttonColor,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Existing CameraPosition and Marker definitions (should not be in State class)
// const CameraPosition _kGooglePlex = CameraPosition(
//   target: LatLng(3.558049482634812, 98.65088891654166),
//   zoom: 14.4746,
// );

// const Marker _kPickupLocation = Marker(
//   markerId: MarkerId('pickupLocation'),
//   position: LatLng(3.558049482634812, 98.65088891654166),
//   infoWindow: InfoWindow(title: 'Lokasi Pengambilan Sepeda'),
// ); 