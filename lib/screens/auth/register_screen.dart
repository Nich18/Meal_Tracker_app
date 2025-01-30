import 'package:flutter/material.dart';
import '../../db/database_helper.dart';
import '../profile_screen.dart'; 

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key}); // Utilisation du super.key pour la performance

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    // Libération des contrôleurs pour éviter les fuites de mémoire
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      final db = DatabaseHelper();

      // Capture du contexte pour éviter les problèmes asynchrones
      final currentContext = context;

      // Insertion de l'utilisateur dans la base de données
      await db.insertUser(
        _nameController.text,
        _emailController.text,
        _passwordController.text,
      );

      if (!mounted) return; // Vérifiez que le widget est encore monté

      ScaffoldMessenger.of(currentContext).showSnackBar(
        const SnackBar(content: Text('Inscription réussie !')),
      );

      // Récupérer l'utilisateur après l'inscription
      final user = await db.getUser(_emailController.text, _passwordController.text);

      // Si l'utilisateur existe, on le redirige vers le profil
      if (user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileScreen(userId: user['id']),
          ),
        );
      } else {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la récupération de l\'utilisateur')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inscription'),
        backgroundColor: Colors.lightBlueAccent, // Couleur uniforme de l'AppBar
      ),
      body: Container(
        color: Colors.white, // Fond blanc pour l'harmonie
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Créez votre compte',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.lightBlueAccent, // Titre en bleu ciel
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    labelStyle: TextStyle(color: Colors.grey[700]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  validator: (value) => value!.isEmpty ? 'Entrez votre nom' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: TextStyle(color: Colors.grey[700]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  validator: (value) {
                    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer une adresse email';
                    } else if (!emailRegex.hasMatch(value)) {
                      return 'Entrez une adresse email valide';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Mot de passe',
                    labelStyle: TextStyle(color: Colors.grey[700]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  obscureText: true,
                  validator: (value) =>
                      value != null && value.length < 6
                          ? 'Mot de passe trop court (min. 6 caractères)'
                          : null,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lightBlueAccent, // Couleur du bouton
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: const Center(
                    child: Text(
                      'S\'inscrire',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
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
