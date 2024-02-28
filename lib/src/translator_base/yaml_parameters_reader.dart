import 'dart:io';

import 'package:localization_translator/src/utils/translator_logger.dart';
import 'package:yaml/yaml.dart' as yaml;

abstract final class YamlParametersReader {
  static const String _yamlPath = 'localization_translator.yaml';

  static Future<Map<String, dynamic>?> mapConfiguration() async {
    try {
      final yamlConfigurator = await _fetchYamlConfigurator();

      if (yamlConfigurator == null) {
        _printConfigurationError();
      }

      final yamlString = yamlConfigurator!.readAsStringSync();

      final yamlMap = yaml.loadYaml(yamlString) as yaml.YamlMap;

      return _castYamlMapToMap(yamlMap);
    } catch (e) {
      _printConfigurationError();

      return null;
    }
  }

  static Map<String, dynamic>? _castYamlMapToMap(yaml.YamlMap yamlMap) {
    final keys = yamlMap.keys.map((e) => e.toString());

    return Map.fromIterables(keys, yamlMap.values);
  }

  static Future<File?> _fetchYamlConfigurator() async {
    try {
      TranslatorLogger.infoLog('Fetch translator configuration...');

      final yamlConfiguration = File(_yamlPath);

      return yamlConfiguration;
    } catch (_) {
      _printConfigurationError();

      return null;
    }
  }

  static void _printConfigurationError() => TranslatorLogger.infoLog(
        '<!>Yaml Configurator not found<!>\n'
        'Check for localization_translator.yaml in the project root\n'
        'Also check the list of available options',
      );
}
