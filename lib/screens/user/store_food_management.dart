import 'package:flutter/material.dart';
import '../../components/app_bar/custom_app_bar.dart';
import '../../components/card/custom_card.dart';
import '../../providers/food_provider.dart';

class StoreFoodManagement extends StatefulWidget {
  final int storeId;

  const StoreFoodManagement({super.key, required this.storeId});

  @override
  State<StoreFoodManagement> createState() => _StoreFoodManagementState();
}

class _StoreFoodManagementState extends State<StoreFoodManagement> {
  late Future<List<Map<String, dynamic>>> _foodsFuture;

  @override
  void initState() {
    super.initState();
    _loadFoods();
  }

  void _loadFoods() {
    _foodsFuture = FoodProvider.getStoreFoods(widget.storeId);
  }

  Future<void> _deleteFood(int foodId) async {
    try {
      await FoodProvider.deleteFood(foodId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Food deleted successfully')),
      );
      setState(() {
        _loadFoods();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting food: $e')),
      );
    }
  }

  Future<void> _showEditDialog(Map<String, dynamic> food) async {
    final nameController = TextEditingController(text: food['name']);
    final descriptionController = TextEditingController(text: food['description']);
    final priceController = TextEditingController(text: food['price'].toString());

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Food'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await FoodProvider.updateFood(
                  food['id'],
                  {
                    'name': nameController.text,
                    'description': descriptionController.text,
                    'price': double.parse(priceController.text),
                  },
                );
                Navigator.pop(context);
                setState(() {
                  _loadFoods();
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Food updated successfully')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error updating food: $e')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:const CustomAppBar(
        title: 'Food Management',
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.pushNamed(
            context,
            '/add-food',
            arguments: widget.storeId,
          );
          setState(() {
            _loadFoods();
          });
        },
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _foodsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final foods = snapshot.data ?? [];

          if (foods.isEmpty) {
            return const Center(child: Text('No food items yet'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: foods.length,
            itemBuilder: (context, index) {
              final food = foods[index];
              return CustomCard(
                child: ListTile(
                  title: Text(food['name'] ?? ''),
                  subtitle: Text('${food['description'] ?? ''}\nPrice: \$${food['price']}'),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showEditDialog(food),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Food'),
                              content: const Text('Are you sure you want to delete this food item?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _deleteFood(food['id']);
                                  },
                                  child: const Text('Delete'),
                                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}