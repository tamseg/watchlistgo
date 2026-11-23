import 'package:material_ui/material_ui.dart';
import '../theme/app_theme.dart';

class StatsPage extends StatelessWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Watchlist Stats')),
      body: const Center(
        child: Text(
          'Coming soon...',
          style: TextStyle(
            fontSize: 18,
            color: AppTheme.secondaryTextColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
