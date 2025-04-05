
import 'package:flutter/material.dart';
import '../../components/app_bar/custom_app_bar.dart';
import '../../components/buttons/custom_elevated_button.dart';
import '../../providers/food_provider.dart';

class AddFoodPage extends StatefulWidget {
  final int storeId;

  const AddFoodPage({super.key, required this.storeId});

  @override
  State<AddFoodPage> createState() => _AddFoodPageState();
}

class _AddFoodPageState extends State<AddFoodPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        await FoodProvider.createFood({
          'name': _nameController.text,
          'description': _descriptionController.text,
          'price': double.parse(_priceController.text),
          'storeId': widget.storeId,
        });
        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:const CustomAppBar(title: 'Add New Food Item'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Food Name'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Please enter food name' : null,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Please enter price';
                  if (double.tryParse(value!) == null) return 'Invalid price';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              CustomElevatedButton(
                onPressed: _submitForm,
                text: 'Add Food Item',
              ),
            ],
          ),
        ),
      ),
    );
  }
}