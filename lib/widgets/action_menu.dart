import 'package:flutter/material.dart';

class ActionMenu extends StatelessWidget {
  final VoidCallback onRemove;

  const ActionMenu({super.key, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      color: Colors.grey[100],
      elevation: 4.0,
      offset: const Offset(-40, 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      onSelected: (value) {
        if (value == 'remove') {
          onRemove();
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'remove',
          child: Row(
            children: [
              Icon(Icons.delete_outline, color: Colors.red, size: 20),
              SizedBox(width: 8),
              Text('Remove', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }
}
