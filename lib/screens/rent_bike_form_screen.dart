import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert'; // Import for jsonDecode
import 'package:http/http.dart' as http; // Import http
import '../models/bike.dart'; // Import Bike model
import 'package:intl/intl.dart' as intl;

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
      appBar: AppBar(title: const Text('Form Sewa Sepeda')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- Input Fields (Full Name, Phone Number, Date, Duration) ---
                 TextFormField(
                  controller: _fullNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Lengkap',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Mohon masukkan nama lengkap';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                 TextFormField(
                  controller: _phoneNumberController,
                   decoration: const InputDecoration(
                    labelText: 'Nomor Telepon',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Mohon masukkan nomor telepon';
                    }
                    return null;
                  },
                ),
                 const SizedBox(height: 16),
                 ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: Text(_selectedDate == null ? 'Pilih Tanggal Sewa' : 'Tanggal Sewa: ${intl.DateFormat('dd/MM/yyyy').format(_selectedDate!)}'),
                   trailing: const Icon(Icons.arrow_downward),
                  onTap: _pickDate,
                ),
                 const SizedBox(height: 16),
                 TextFormField(
                  controller: _durationController,
                   decoration: const InputDecoration(
                    labelText: 'Durasi Sewa (hari)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.timer),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Mohon masukkan durasi sewa';
                    }
                    if (int.tryParse(value) == null || int.parse(value) <= 0) {
                      return 'Durasi harus angka positif';
                    }
                    return null;
                  },
                ),
                if (_endDate != null) ...[
                  const SizedBox(height: 16),
                  Text('Tanggal Pengembalian: ${intl.DateFormat('dd/MM/yyyy').format(_endDate!)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
                 const SizedBox(height: 24),

                // --- Bike Selection and Quantity (Dynamic List) ---
                const Text('Pilih Sepeda:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(), // Disable scrolling for nested ListView
                  itemCount: _selectedItems.length,
                  itemBuilder: (context, index) {
                    return _buildBikeItemRow(index);
                  },
                ),
                 const SizedBox(height: 16),
                Center(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Tambah Sepeda Lain'),
                    onPressed: _addItem,
                  ),
                ),

                const SizedBox(height: 24),

                // --- Photo Upload ---
                const Text('Unggah Foto/Dokumen (Opsional):', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                 OutlinedButton.icon(
                   icon: const Icon(Icons.camera_alt),
                  label: Text(_selectedImage == null ? 'Pilih Foto' : 'Foto Terpilih'),
                   onPressed: _pickImage,
                 ),
                if (_selectedImage != null) ...[
                  const SizedBox(height: 16),
                  Image.file(_selectedImage!, height: 150),
                ],

                const SizedBox(height: 24),

                 // --- Total Price Display ---
                Text(
                   'Total Harga: Rp${_totalPrice.toStringAsFixed(0)}',
                   style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
                 ),

                const SizedBox(height: 32),

                // --- Submit Button ---
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading ? const CircularProgressIndicator() : const Text('Kirim Permintaan Sewa'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper widget to build each bike item row
  Widget _buildBikeItemRow(int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Jenis Sepeda',
                border: OutlineInputBorder(),
                 contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16), // Adjust padding
              ),
              value: _selectedItems[index]['bikeId'],
              items: _availableBikes.map((bike) {
                // Only show bikes with quantity > 0
                if (bike.quantity > 0) {
                  return DropdownMenuItem<String>(
                    value: bike.id,
                    // Display bike name and available stock
                    child: Text('${bike.name} (Stok: ${bike.quantity})'),
                  );
                } else {
                  return null; // Don't show if stock is 0
                }
              }).whereType<DropdownMenuItem<String>>().toList(), // Filter out nulls
              onChanged: (value) {
                setState(() {
                  _selectedItems[index]['bikeId'] = value;
                  _updateTotalPrice(); // Update total price when bike changes
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Pilih jenis sepeda';
                }
                return null;
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 1,
            child: TextFormField(
              initialValue: _selectedItems[index]['quantity'].toString(),
              decoration: const InputDecoration(
                labelText: 'Jumlah',
                border: OutlineInputBorder(),
                 contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16), // Adjust padding
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return ''; // Validator message handled by the overall form validation
                }
                 final quantity = int.tryParse(value);
                 if (quantity == null || quantity <= 0) {
                   return ''; // Validator message handled by the overall form validation
                 }
                 // Check against available stock for this specific bike type
                 final selectedBikeId = _selectedItems[index]['bikeId'];
                 if (selectedBikeId != null) {
                    final availableBike = _availableBikes.firstWhere((bike) => bike.id == selectedBikeId);
                    if (quantity > availableBike.quantity) {
                      return 'Stok tidak cukup';
                    }
                 }
                return null;
              },
              onChanged: (value) {
                 final quantity = int.tryParse(value) ?? 0; // Use tryParse
                setState(() {
                  _selectedItems[index]['quantity'] = quantity;
                   _updateTotalPrice(); // Update total price when quantity changes
                });
              },
            ),
          ),
          // Add remove button if there's more than one item
          if (_selectedItems.length > 1) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
              onPressed: () => _removeItem(index),
            ),
          ],
        ],
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