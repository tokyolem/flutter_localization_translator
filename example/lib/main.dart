import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

void main() {
  runApp(const App());
}

final class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return Center(
              child: Text(
                context.locale.hello('New User'),
              ),
            );
          },
        ),
      ),
    );
  }
}

extension LocalizationExt on BuildContext {
  AppLocalizations get locale => AppLocalizations.of(this)!;
}
