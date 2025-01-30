import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../db/database_helper.dart';
import '../widgets/dropdown_menu.dart';
import '../screens/meal_history_screen.dart';
import '../screens/statistiques_scren.dart';
import '../screens/reccommandations_screen.dart';
import 'chatbot_screen.dart';

class ProfileScreen extends StatefulWidget {
  final int userId;

  const ProfileScreen({super.key, required this.userId});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _calorieGoalController = TextEditingController();
  double? _imc;
  String _imcInterpretation = '';
  String? _userName;
  bool _showSaveButton = false;

   int _selectedIndex = 0;

  int _unreadNotificationsCount = 0;
  List<Map<String, dynamic>> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadNotifications();
  }

  Future<void> _loadUserProfile() async {
    final db = DatabaseHelper();
    final user = await db.getUserById(widget.userId);

    if (user != null) {
      setState(() {
        _userName = user['name'];
      });
      _loadProfileData();
    }
  }

  Future<void> _loadProfileData() async {
    final db = DatabaseHelper();
    final profile = await db.getProfileByUserId(widget.userId);

    if (profile != null) {
      setState(() {
        _heightController.text = profile['height'].toString();
        _weightController.text = profile['weight'].toString();
        _calorieGoalController.text = profile['calorieGoal'].toString();
        _calculateIMC();
      });
    }
  }

  Future<void> _saveProfile() async {
    final height = double.tryParse(_heightController.text);
    final weight = double.tryParse(_weightController.text);
    final calorieGoal = double.tryParse(_calorieGoalController.text);

    if (height == null || weight == null || calorieGoal == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer des valeurs valides')),
      );
      return;
    }

    final db = DatabaseHelper();
    await db.insertProfile(height, weight, widget.userId, calorieGoal);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profil mis à jour avec succès')),
    );

    setState(() {
      _showSaveButton = false;
    });
  }

  void _calculateIMC() {
    final height = double.tryParse(_heightController.text);
    final weight = double.tryParse(_weightController.text);

    if (height == null || weight == null || height == 0) {
      setState(() {
        _imc = null;
        _imcInterpretation = 'Valeurs non valides';
      });
      return;
    }

    setState(() {
      _imc = weight / ((height / 100) * (height / 100));
      if (_imc! < 18.5) {
        _imcInterpretation = 'Insuffisance pondérale';
      } else if (_imc! < 25) {
        _imcInterpretation = 'Poids normal';
      } else if (_imc! < 30) {
        _imcInterpretation = 'Surpoids';
      } else {
        _imcInterpretation = 'Obésité';
      }
      _showSaveButton = false;
    });
  }

  Future<void> _loadNotifications() async {
    final db = DatabaseHelper();
    final notifications = await db.getNotificationsByUserId(widget.userId);

    setState(() {
      _notifications = notifications.take(10).toList(); // Dernières 10 notifications
      _unreadNotificationsCount = notifications.where((n) => n['is_read'] == 0).length;
    });
  }

  Future<void> _markNotificationsAsRead() async {
    final db = DatabaseHelper();
    for (var notification in _notifications) {
      if (notification['is_read'] == 0) {
        await db.markNotificationAsRead(notification['id']);
      }
    }
    setState(() {
      _unreadNotificationsCount = 0;
    });
  }

  void _showNotificationsDialog() async {
    await _markNotificationsAsRead();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Notifications'),
          content: SizedBox(
            height: 300,
            width: 300,
            child: ListView.builder(
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                final notification = _notifications[index];
                return ListTile(
                  title: Text(notification['title']),
                  subtitle: Text(notification['message']),
                  trailing: Text(
                    notification['created_at'].toString(),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer'),
            ),
          ],
        );
      },
    );
  }

  void _onBottomNavItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => _menuOptions[index]['screen']()),
    );
  }



  List<Map<String, dynamic>> get _menuOptions => [
        {
          'title': 'Repas',
          'icon': Icons.restaurant,
          'screen': () => MealHistoryScreen(userId: widget.userId),
        },
        {
          'title': 'Statistiques',
          'icon': Icons.bar_chart,
          'screen': () => StatisticsScreen(userId: widget.userId),
        },
        {
          'title': 'Recommandations',
          'icon': Icons.lightbulb,
          'screen': () => RecommendationsScreen(imc: _imc ?? 0),
        },
        {
          'title': 'Chatbot',  
          'icon': Icons.chat,
          'screen': () => ChatbotScreen(userId: widget.userId), 
  },
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Meal Tracker',  
          style: GoogleFonts.lobster(  // Applique la police Lobster
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,  
          ),
        ),
        actions: [
          // Icône de notification avec compteur
          Stack(
            alignment: Alignment.topRight,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: _showNotificationsDialog,
              ),
              if (_unreadNotificationsCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$_unreadNotificationsCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          Menu(menuOptions: _menuOptions),
        ],
        leading: Container(),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_userName != null)
                Text(
                  'Bienvenue, $_userName',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.lightBlueAccent,
                  ),
                ),
              const SizedBox(height: 30),

              // Mini tableau de bord
              Card(
                elevation: 4,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Taille: ${_heightController.text} cm',
                                  style: const TextStyle(fontSize: 16)),
                              Text('Poids: ${_weightController.text} kg',
                                  style: const TextStyle(fontSize: 16)),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'IMC: ${_imc != null ? _imc!.toStringAsFixed(2) : 'N/A'}',
                                style: const TextStyle(fontSize: 16),
                              ),
                              Text(
                                _imcInterpretation,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Seuil de calories: ${_calorieGoalController.text} kcal',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 60),

              // Boutons pour afficher les champs conditionnellement
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightBlueAccent,
                  minimumSize: Size(double.infinity, 48), // Taille uniforme
                ),
                onPressed: () {
                  setState(() {
                    _showSaveButton = true;
                  });
                },
                child: const Text('Calculer IMC'),
              ),
              if (_showSaveButton) ...[
                const SizedBox(height: 10),
                TextField(
                  controller: _heightController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Taille (cm)'),
                ),
                TextField(
                  controller: _weightController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Poids (kg)'),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lightBlueAccent,
                    minimumSize: Size(double.infinity, 48), // Taille uniforme
                  ),
                  onPressed: () {
                    _calculateIMC();
                    setState(() {
                      _showSaveButton = false;
                    });
                  },
                  child: const Text('enregister'),
                ),
              ],
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightBlueAccent,
                  minimumSize: Size(double.infinity, 48), // Taille uniforme
                ),
                onPressed: () {
                  setState(() {
                    _showSaveButton = true;
                  });
                },
                child: const Text('Définir Seuil de Calories'),
              ),
              if (_showSaveButton) ...[
                const SizedBox(height: 10),
                TextField(
                  controller: _calorieGoalController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Seuil de calories journalier (kcal)'),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lightBlueAccent,
                    minimumSize: Size(double.infinity, 48), // Taille uniforme
                  ),
                  onPressed: _saveProfile,
                  child: const Text('Enregistrer'),
                ),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
      items: _menuOptions.map((option) {
        return BottomNavigationBarItem(
          icon: Icon(option['icon']),
          label: option['title'],
        );
      }).toList(),
      currentIndex: _selectedIndex,
      onTap: _onBottomNavItemTapped,
      selectedItemColor: Colors.lightBlueAccent, 
      unselectedItemColor: const Color.fromARGB(136, 48, 46, 46), 
      type: BottomNavigationBarType.fixed,
      showUnselectedLabels: true, 
    ),
  );
    
  }
}



//API KEY  vMUdvD182yzv5ijwsncHNU9ddp9dLqcwX302rFp1