import 'dart:io';

import 'package:localization_translator/src/utils/translator_logger.dart';

abstract final class ProcessRunner {
  static Future<bool> runLocalizationGenerator() async {
    return Process.run('flutter', ['gen-l10n']).then(
      (result) {
        TranslatorLogger.infoLog(
          result.exitCode == 0 ? result.stdout : result.stderr,
        );

        return result.exitCode == 0;
      },
    );
  }

  static Future<bool> runDartFormatterForGeneration(String pathToArb) async {
    return Process.run('dart', ['format'], workingDirectory: pathToArb).then(
      (result) {
        TranslatorLogger.infoLog(
          result.exitCode == 0 ? result.stdout : result.stderr,
        );

        return result.exitCode == 0;
      },
    );
  }
}
