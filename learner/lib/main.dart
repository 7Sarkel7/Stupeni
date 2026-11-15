import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'src/app.dart';
import 'src/models.dart';
import 'src/progress_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final prefs = await SharedPreferences.getInstance();
    final raw = await rootBundle.loadString('assets/content/catalog.json');
    final catalog = Catalog.parse(raw);
    runApp(
      StupeniApp(
        catalog: catalog,
        progress: ProgressStore(prefs),
        load: (path) => rootBundle.loadString('assets/content/$path'),
      ),
    );
  } catch (error) {
    runApp(StartupFailure(message: '$error'));
  }
}

class StartupFailure extends StatelessWidget {
  const StartupFailure({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Каталог уроков не открылся.\n\n'
            'Из корня репозитория выполните ./tool/sync_content.sh '
            'и запустите приложение снова.\n\n$message',
          ),
        ),
      ),
    );
  }
}
