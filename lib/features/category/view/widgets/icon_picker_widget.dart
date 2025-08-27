import 'package:flutter/material.dart';

class IconPickerWidget extends StatelessWidget {
  const IconPickerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final List<IconData> icons = [
      Icons.restaurant, Icons.wifi, Icons.local_pizza, Icons.water_drop,
      Icons.checkroom, Icons.shopping_bag, Icons.medication, Icons.shopping_cart,
      Icons.directions_bus, Icons.category, Icons.home, Icons.pets,
      Icons.phone_android, Icons.school, Icons.fitness_center, Icons.card_giftcard,
      Icons.movie, Icons.lightbulb, Icons.flight, Icons.build,
    ];

    return AlertDialog(
      title: const Text('Selecione um Ícone'),
      content: SizedBox(
        width: double.maxFinite,
        child: GridView.builder(
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: icons.length,
          itemBuilder: (context, index) {
            return IconButton(
              icon: Icon(icons[index]),
              onPressed: () => Navigator.of(context).pop(icons[index]),
            );
          },
        ),
      ),
    );
  }
}