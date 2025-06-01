import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/bike.dart';

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
  bool _isLoading = true; // To show loading while fetching data

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
    super.dispose();
  }

  Future<void> _updateBike() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true; // Use same loading state for update
      });
      try {
        await FirebaseFirestore.instance.collection('bikes').doc(widget.bikeId).update({
          'name': _nameController.text,
          'quantity': int.parse(_quantityController.text),
          // createdAt should not be updated
          'updatedAt': Timestamp.now(), // Optional: add update timestamp
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
                      ),
                      keyboardType: TextInputType.number,
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