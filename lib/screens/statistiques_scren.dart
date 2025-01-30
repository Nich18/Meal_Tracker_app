import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../db/database_helper.dart';
import 'package:intl/intl.dart';

class StatisticsScreen extends StatefulWidget {
  final int userId;

  const StatisticsScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _StatisticsScreenState createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  double? _calorieGoal;
  List<double> _caloriesHistory = List.filled(31, 0.0); // 31 jours pour le mois
  DateTime _selectedDate = DateTime.now();
  DateTimeRange? _selectedWeek;

  @override
  void initState() {
    super.initState();
    _loadCalorieGoal();
    _loadCaloriesHistory();
  }

  Future<void> _loadCalorieGoal() async {
    final db = DatabaseHelper();
    final profile = await db.getProfileByUserId(widget.userId);
    if (profile != null) {
      setState(() {
        _calorieGoal = profile['calorieGoal'];
      });
    }
  }

  Future<void> _loadCaloriesHistory() async {
    final db = DatabaseHelper();
    final today = DateTime.now();
    final List<Map<String, dynamic>> calories = await db.getCaloriesByMonth(today.year, today.month);
  
    for (var entry in calories) {
      int day = entry['date'];
      double caloriesValue = entry['calories'];
      setState(() {
        _caloriesHistory[day - 1] = caloriesValue; // Mettre à jour l'historique
      });
    }
  }

  Future<void> _calculateDailyCalories() async {
  // Sélectionner une date
  DateTime? selectedDate = await _selectDate();
  if (selectedDate == null) return;

  final db = DatabaseHelper();

  // Récupérer les calories pour la date spécifique
  final dailyCalories = await db.getTotalCaloriesBySpecificDateRange(
    widget.userId,
    selectedDate,
    selectedDate.add(Duration(days: 1)),
  );

  // Vérifier s'il y a des données pour la date sélectionnée
  if (dailyCalories == 0) {
    _showAlert('Aucune donnée disponible pour la date sélectionnée.');
    return;
  }

  // Afficher le résultat des calories
  _showAlert('Calories consommées : $dailyCalories.');

  // Vérifier si le seuil est dépassé et afficher une alerte si nécessaire
  _showAlertIfExceeded(dailyCalories, 'journalière');
}

  Future<void> _calculateWeeklyCalories() async {
    DateTimeRange? selectedWeek = await _selectWeek();
    if (selectedWeek == null) return;

    final db = DatabaseHelper();
    final weeklyCalories = await db.getTotalCaloriesBySpecificDateRange(
      widget.userId,
      selectedWeek.start,
      selectedWeek.end,
    );
    if (weeklyCalories == 0) {
    _showAlert('Aucune donnée disponible pour la date sélectionnée.');
    return;}
    _showAlert('Calories consommées : $weeklyCalories.');
    _showAlertIfExceeded(weeklyCalories, 'hebdomadaire');
  }

  Future<void> _calculateMonthlyCalories() async {
    int? month = await _selectMonth();
    int? year = await _selectYear();
    if (month == null || year == null) return;

    final db = DatabaseHelper();
    final monthlyCalories = await db.getTotalCaloriesByMonth(year, month);
    if (monthlyCalories== 0) {
    _showAlert('Aucune donnée disponible pour la date sélectionnée.');
    return;}
    _showAlert('Calories consommées : $monthlyCalories.');
    _showAlertIfExceeded(monthlyCalories, 'mensuelle');
  }

  Future<void> _calculateYearlyCalories() async {
    int? year = await _selectYear();
    if (year == null) return;

    final db = DatabaseHelper();
    final yearlyCalories = await db.getTotalCaloriesByYear(widget.userId, year);
    if (yearlyCalories == 0) {
    _showAlert('Aucune donnée disponible pour la date sélectionnée.');
    return;}
    _showAlert('Calories consommées : $yearlyCalories.');
    _showAlertIfExceeded(yearlyCalories, 'annuelle');
  }

  Future<void> _calculateWeeklyAverageCalories() async {
    final db = DatabaseHelper();
    final averageCalories = await db.getAverageCaloriesForWeek(widget.userId, DateTime.now());
    if (averageCalories == 0) {
    _showAlert('Aucune donnée disponible pour la date sélectionnée.');
    return;}
    _showAlert('Calories consommées : $averageCalories.');
    _showAlertIfExceeded(averageCalories, 'moyenne hebdomadaire');
  }

  Future<void> _showAlertIfExceeded(double calories, String type) async {
  if (_calorieGoal != null && calories > _calorieGoal!) {
    String message =
        'Vous avez dépassé votre seuil de calories $type (${DateFormat.yMd().format(DateTime.now())}) !';

    // Ajouter la notification dans la base de données
    final db = DatabaseHelper();
    await db.addNotification(
      userId: widget.userId,
      title: 'Alerte',
      message: message,
    );

    // Afficher l'alerte
    _showAlert(message);
  }
}

  Future<void> _showAlert(String message) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Alerte !'),
          content: SingleChildScrollView(
            child: ListBody(children: <Widget>[Text(message)]),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<DateTime?> _selectDate() async {
    return await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
  }

  Future<DateTimeRange?> _selectWeek() async {
    return await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
  }

  Future<int?> _selectMonth() async {
    int? selectedMonth;

    await showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Sélectionnez un mois"),
          content: DropdownButton<int>(
            value: selectedMonth,
            hint: Text("Choisissez un mois"),
            items: List.generate(12, (index) {
              return DropdownMenuItem<int>(
                value: index + 1,
                child: Text(DateFormat('MMMM').format(DateTime(0, index + 1))),
              );
            }),
            onChanged: (value) {
              selectedMonth = value;
              Navigator.of(context).pop(value);
            },
          ),
        );
      },
    );

    return selectedMonth;
  }

  Future<int?> _selectYear() async {
    int? selectedYear;

    await showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Sélectionnez une année"),
          content: DropdownButton<int>(
            value: selectedYear,
            hint: Text("Choisissez une année"),
            items: List.generate(21, (index) {
              final year = DateTime.now().year - index;
              return DropdownMenuItem<int>(
                value: year,
                child: Text(year.toString()),
              );
            }),
            onChanged: (value) {
              selectedYear = value;
              Navigator.of(context).pop(value);
            },
          ),
        );
      },
    );

    return selectedYear;
  }
@override
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Statistiques'),
      backgroundColor: Colors.lightBlue, // Couleur de l'AppBar
    ),
    body: Container(
      color: Colors.white, // Couleur d'arrière-plan de la page
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Évolution des calories :',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.lightBlue, // Couleur du texte
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(
                height: 200,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(show: false),
                    titlesData: FlTitlesData(show: true),
                    borderData: FlBorderData(show: true),
                    minX: 0,
                    maxX: 31,
                    minY: 0,
                    maxY: _caloriesHistory.reduce((a, b) => a > b ? a : b) + 200,
                    lineBarsData: [
                      LineChartBarData(
                        spots: _caloriesHistory
                            .asMap()
                            .entries
                            .map((entry) =>
                                FlSpot(entry.key.toDouble(), entry.value))
                            .toList(),
                        isCurved: true,
                        color: Colors.lightBlue, // Couleur du graphique
                        dotData: FlDotData(show: false),
                        belowBarData: BarAreaData(show: false),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton(
                    onPressed: _calculateDailyCalories,
                    child: const Text('Calories Journalières'),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _calculateWeeklyCalories,
                    child: const Text('Calories Hebdomadaires'),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _calculateMonthlyCalories,
                    child: const Text('Calories Mensuelles'),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _calculateYearlyCalories,
                    child: const Text('Calories Annuelles'),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _calculateWeeklyAverageCalories,
                    child: const Text('Moyenne Hebdomadaire'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
}