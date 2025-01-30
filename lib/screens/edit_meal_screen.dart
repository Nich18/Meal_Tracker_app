import 'package:flutter/material.dart';
import '../../db/database_helper.dart'; // Assurez-vous que le chemin est correct

class EditMealScreen extends StatefulWidget {
  final int mealId;

  EditMealScreen({required this.mealId});

  @override
  _EditMealScreenState createState() => _EditMealScreenState();
}

class _EditMealScreenState extends State<EditMealScreen> {
  final _nameController = TextEditingController();
  final _caloriesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Charger les informations du repas pour modification
    _loadMeal();
  }

  Future<void> _loadMeal() async {
    final db = DatabaseHelper();
    final meal = await db.getMeal(widget.mealId); // Récupérer le repas par ID
    if (meal != null) {
      _nameController.text = meal['name']; // Utilisation de la clé 'name'
      _caloriesController.text = meal['calories'].toString(); // Utilisation de la clé 'calories'
    }
  }

  Future<void> _updateMeal() async {
    final name = _nameController.text;
    final calories = double.tryParse(_caloriesController.text);

    if (name.isEmpty || calories == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs')),
      );
      return;
    }

    final db = DatabaseHelper();
    await db.updateMeal(widget.mealId, name, calories); // Logique de mise à jour

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Repas mis à jour avec succès')),
    );

    Navigator.pop(context); // Retour à l'écran précédent
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Modifier le repas')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nom du repas'),
            ),
            TextField(
              controller: _caloriesController,
              decoration: const InputDecoration(labelText: 'Calories'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _updateMeal,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue, // Couleur du bouton
                foregroundColor: Colors.white, // Couleur du texte
                padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 30.0), // Padding
              ),
              child: const Text('Mettre à jour'),
            ),
          ],
        ),
      ),
    );
  }
}