import 'package:flutter/material.dart';

class Menu extends StatelessWidget {
  final List<Map<String, dynamic>> menuOptions;

  const Menu({Key? key, required this.menuOptions}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
      onSelected: (int index) {
        final selectedScreen = menuOptions[index]['screen'];
        if (selectedScreen is Function) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => selectedScreen()),
          );
        }
      },
      itemBuilder: (BuildContext context) {
        return List.generate(menuOptions.length, (index) {
          final option = menuOptions[index];
          return PopupMenuItem<int>(
            value: index,
            child: Row(
              children: [
                Icon(option['icon'], color: Colors.blue),
                const SizedBox(width: 10),
                Text(option['title']),
              ],
            ),
          );
        });
      },
    );
  }
}
