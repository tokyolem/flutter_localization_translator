import 'package:localization_translator/src/translator_base/localization_translator_base.dart';
import 'package:localization_translator/src/translator_base/yaml_parameters_reader.dart';
import 'package:localization_translator/src/utils/process_runner.dart';
import 'package:localization_translator/src/utils/translator_logger.dart';
import 'package:localization_translator/src/utils/yaml_configurator_fields.dart';

Future<void> main() async {
  final configuration = await YamlParametersReader.mapConfiguration();
  if (configuration == null) {
    TranslatorLogger.infoLog(
      'Check your localization_translator.yaml configuration.',
    );
    return;
  }

  TranslatorLogger.infoLog('Configuration fetched successfully...');

  try {
    ProcessRunner.runLocalizationGenerator().then(
      (value) {
        value
            ? LocalizationTranslatorBase(configuration)
                .writeTranslatedToArb()
                .whenComplete(ProcessRunner.runLocalizationGenerator)
                .whenComplete(
                  () => ProcessRunner.runDartFormatterForGeneration(
                    configuration[YamlConfiguratorFields.pathToArb],
                  ),
                )
            : TranslatorLogger.infoLog(
                'Check your .arb resources '
                'and '
                'localization_translator.yaml configuration.',
              );
      },
    );
  } catch (_) {
    TranslatorLogger.infoLog(
      'Check your .arb resources '
      'and '
      'localization_translator.yaml configuration.',
    );
  }
}
