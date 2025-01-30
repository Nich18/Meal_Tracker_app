import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../db/database_helper.dart';
import 'edit_meal_screen.dart';
import 'add_meal_screen.dart';
import 'Meal_deatil_screen.dart';

class MealHistoryScreen extends StatefulWidget {
  final int userId;

  const MealHistoryScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _MealHistoryScreenState createState() => _MealHistoryScreenState();
}

class _MealHistoryScreenState extends State<MealHistoryScreen> {
  List<Map<String, dynamic>> _meals = [];

  @override
  void initState() {
    super.initState();
    _loadMeals();
  }

  Future<void> _loadMeals() async {
    final db = DatabaseHelper();
    final meals = await db.getMealsByUserId(widget.userId);
    setState(() {
      _meals = meals;
    });
  }

  Future<void> _deleteMeal(int id) async {
    final db = DatabaseHelper();
    await db.deleteMeal(id);
    _loadMeals();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Repas supprimé avec succès')),
    );
  }

  void _editMeal(int id) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditMealScreen(mealId: id),
      ),
    );
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Historique des repas'),
      backgroundColor: Colors.lightBlueAccent,
    ),
    body: Container(
      color: Colors.white,
      child: _meals.isEmpty
          ? const Center(
              child: Text(
                'Aucun repas enregistré',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: _meals.length,
              itemBuilder: (context, index) {
                final meal = _meals[index];
                final image = meal['photo'] as Uint8List?;
                final dateTime = DateTime.parse(meal['datetime']);
                final formattedDate = '${dateTime.toLocal()}'.split(' ')[0];
                final formattedTime = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 3,
                  child: ListTile(
                    leading: image != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: Image.memory(
                              image,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Icon(Icons.fastfood, color: Colors.lightBlueAccent, size: 40),
                    title: Text(
                      meal['name'],
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${meal['calories']} calories\n$formattedDate à $formattedTime',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MealDetailScreen(meal: meal),
                        ),
                      );
                    },
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.lightBlueAccent),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditMealScreen(mealId: meal['id']),
                              ),
                            ).then((_) => _loadMeals()); // Actualiser après modification
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () => _deleteMeal(meal['id']),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddMealScreen(userId: widget.userId),
          ),
        ).then((_) => _loadMeals()); // Actualiser après ajout
      },
      backgroundColor: Colors.lightBlueAccent,
      child: const Icon(Icons.add),
      tooltip: 'Ajouter un repas',
    ),
  );
}
}