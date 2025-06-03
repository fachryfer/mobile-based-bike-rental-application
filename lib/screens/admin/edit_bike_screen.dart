import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/bike.dart';
import 'package:flutter/services.dart'; // Import for inputFormatters
import 'package:image_picker/image_picker.dart'; // Import for image picking
import 'dart:io'; // Import for File
import 'dart:convert'; // Import for jsonDecode
import 'package:http/http.dart' as http; // Import http

class EditBikeScreen extends StatefulWidget {
  final String bikeId;

  const EditBikeScreen({Key? key, required this.bikeId}) : super(key: key);

  @override
  _EditBikeScreenState createState() => _EditBikeScreenState();
}

class _EditBikeScreenState extends State<EditBikeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController(); // Add price controller
  final _descriptionController = TextEditingController(); // Add description controller
  bool _isLoading = true; // To show loading while fetching data
  File? _selectedImage; // To hold the new selected image file
  String? _currentImageUrl; // To hold the current image URL from Firestore

  @override
  void initState() {
    super.initState();
    _loadBikeData();
  }

  Future<void> _loadBikeData() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('bikes').doc(widget.bikeId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data != null) {
          _nameController.text = data['name'] ?? '';
          _quantityController.text = (data['quantity'] ?? 0).toString();
          _priceController.text = (data['price'] ?? 0.0).toString(); // Load price
          _descriptionController.text = data['description'] ?? ''; // Load description
          _currentImageUrl = data['imageUrl']; // Load current image URL
        }
      } else {
        // Handle case where bike is not found (maybe show error and pop)
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sepeda tidak ditemukan.'), backgroundColor: Colors.red),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data sepeda: $e'), backgroundColor: Colors.red),
        );
        Navigator.pop(context); // Pop on error
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _priceController.dispose(); // Dispose price controller
    _descriptionController.dispose(); // Dispose description controller
    super.dispose();
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

  Future<String?> _uploadToCloudinary(File imageFile) async {
    final url = Uri.parse('https://api.cloudinary.com/v1_1/dmhbguqqa/image/upload');
    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = 'my_flutter_upload'
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await http.Response.fromStream(response);
        final result = jsonDecode(responseData.body);
        return result['secure_url'];
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

  Future<void> _updateBike() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true; // Use same loading state for update
      });
      try {
        String? imageUrl = _currentImageUrl; // Start with the current URL

        if (_selectedImage != null) { // If a new image is selected
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Mengunggah foto sepeda...'), duration: Duration(seconds: 5),)
            );
          }
          imageUrl = await _uploadToCloudinary(_selectedImage!); // Upload the new image
          if (mounted) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          }

          if (imageUrl == null) { // If upload fails
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Gagal mengunggah foto baru.'), backgroundColor: Colors.red,)
              );
              setState(() {
                _isLoading = false;
              });
            }
            return; // Stop the update process
          }
        }

        await FirebaseFirestore.instance.collection('bikes').doc(widget.bikeId).update({
          'name': _nameController.text,
          'quantity': int.parse(_quantityController.text),
          'price': double.parse(_priceController.text), // Update price
          'description': _descriptionController.text.trim(), // Update description
          // createdAt should not be updated
          'updatedAt': Timestamp.now(), // Optional: add update timestamp
          'imageUrl': imageUrl, // Update image URL
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sepeda berhasil diperbarui'), backgroundColor: Colors.green),
          );
          Navigator.pop(context); // Go back after successful update
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal memperbarui sepeda: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
         setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Sepeda'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: <Widget>[
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Sepeda',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Mohon masukkan nama sepeda';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16.0),
                    TextFormField(
                      controller: _quantityController,
                      decoration: const InputDecoration(
                        labelText: 'Jumlah Ketersediaan',
                        border: OutlineInputBorder(),
                        suffixText: ' pcs', // Added suffix text
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Mohon masukkan jumlah ketersediaan';
                        }
                        if (int.tryParse(value) == null || int.parse(value) < 0) { // Allow 0 for out of stock
                          return 'Mohon masukkan angka non-negatif';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16.0),
                    TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        labelText: 'Harga Sewa per Hari',
                        border: OutlineInputBorder(),
                        prefixText: 'Rp ', // Added prefix text
                      ),
                      keyboardType: TextInputType.numberWithOptions(decimal: true), // Allow decimal input
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^[0-9]+([.][0-9]*)?$')), // Allow one or more digits, optionally followed by a dot and zero or more digits
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Mohon masukkan harga sewa';
                        }
                        if (double.tryParse(value) == null || double.parse(value) <= 0) {
                          return 'Mohon masukkan angka positif untuk harga';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16.0),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Deskripsi (Opsional)',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16.0),
                    if (_currentImageUrl != null && _selectedImage == null) ...[
                      Center(
                        child: Image.network(
                          _currentImageUrl!,
                          height: 150,
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
                          errorBuilder: (context, error, stackTrace) => const Text('Gagal memuat gambar saat ini'),
                        ),
                      ),
                      const SizedBox(height: 16.0),
                    ] else if (_selectedImage != null) ...[
                      Center(
                        child: Image.file(
                          _selectedImage!,
                          height: 150,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 16.0),
                    ],
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.photo),
                          label: const Text('Pilih Foto Baru (Opsional)'),
                        ),
                        const SizedBox(width: 8),
                        if (_selectedImage != null)
                          const Icon(Icons.check_circle, color: Colors.green),
                      ],
                    ),
                    const SizedBox(height: 24.0),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _updateBike,
                      child: _isLoading ? const CircularProgressIndicator() : const Text('Simpan Perubahan'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
} 