import 'package:flutter/material.dart';
import '../../db/database_helper.dart';
import 'Meal_deatil_screen.dart';

class RecommendationsScreen extends StatefulWidget {
  final double imc;

  const RecommendationsScreen({Key? key, required this.imc}) : super(key: key);

  @override
  _RecommendationsScreenState createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> {
  List<Map<String, dynamic>> _recommendedMeals = [];

  @override
  void initState() {
    super.initState();
    _fetchRecommendedMeals();
  }

  Future<void> _fetchRecommendedMeals() async {
    final db = DatabaseHelper();
    final meals = await db.getMeals();

    setState(() {
      _recommendedMeals = meals.where((meal) {
        if (widget.imc < 18.5) {
          return meal['calories'] > 400;
        } else if (widget.imc < 25) {
          return meal['calories'] <= 500;
        } else {
          return meal['calories'] < 250;
        }
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recommandations de Repas')),
      body: _recommendedMeals.isEmpty
          ? const Center(child: Text('Aucune recommandation pour le moment', style: TextStyle(fontSize: 18, color: Colors.grey)))
          : ListView.builder(
              itemCount: _recommendedMeals.length,
              itemBuilder: (context, index) {
                final meal = _recommendedMeals[index];
                return Card(
                  margin: const EdgeInsets.all(8.0),
                  child: ListTile(
                    title: Text(meal['name']),
                    subtitle: Text('${meal['calories']} kcal'),
                    leading: meal['photo'] != null
                        ? Image.memory(meal['photo'], width: 50, height: 50, fit: BoxFit.cover)
                        : null,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MealDetailScreen(meal: meal),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}