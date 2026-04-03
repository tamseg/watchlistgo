import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GradientPillSwitch extends StatelessWidget {
  final bool isMoviesSelected;
  final ValueChanged<bool> onChanged;

  const GradientPillSwitch({
    super.key,
    required this.isMoviesSelected,
    required this.onChanged
  });

  @override
  Widget build(BuildContext context) {
    const double totalWidth = 280.0;
    const double height = 36.0;
    const double itemWidth = totalWidth / 2;

    return GestureDetector(
      onTap: () => onChanged(!isMoviesSelected),
      child: Container(
        width: totalWidth,
        height: height,
        decoration: BoxDecoration(
          color: const Color.fromARGB(59, 209, 203, 203),
          borderRadius: BorderRadius.circular(25.0)
        ),
        child: Stack(
          children: [
            AnimatedAlign(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              alignment: isMoviesSelected ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: itemWidth,
                height: height,
                padding: const EdgeInsets.all(3.5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25.0),
                  gradient: LinearGradient(
                    begin: Alignment(-0.5, -3.0),
                    end: Alignment(0.5, 3.0),
                    colors: [
                      Color(0xFF5edde0),
                      Color(0xFF538feb),
                      Color(0xFF7f73ea),
                    ],
                    stops: [0.30, 0.65, 0.80],
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: const Color.fromARGB(255, 206, 198, 198).withValues(alpha: 0.5),
                        blurRadius: 3.5,
                        offset: const Offset(0, 0)
                      )
                    ],
                    borderRadius: BorderRadius.circular(23.5),
                    gradient: AppTheme.primaryGradient,
                  )
                )
              )
            ),
            Row(
              children: [
                _buildLabel('My Series', !isMoviesSelected),
                _buildLabel('My Movies', isMoviesSelected),
              ]
            )
          ]
        )
      )
    );
  }

  Widget _buildLabel(String text, bool isSelected) {
    return Expanded(
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color.fromARGB(176, 39, 38, 38),
            fontWeight: FontWeight.bold,
            fontSize: 16
          )
        )
      )
    );
  }
}
