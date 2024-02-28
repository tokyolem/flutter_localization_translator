import 'dart:convert';
import 'dart:io';

import 'package:flutter_localization_translator/src/utils/arb_handler.dart';
import 'package:flutter_localization_translator/src/utils/placeholders_handler.dart';
import 'package:flutter_localization_translator/src/utils/translator_logger.dart';
import 'package:flutter_localization_translator/src/utils/yaml_configurator_fields.dart';
import 'package:translator/translator.dart';

final class LocalizationTranslatorBase {
  final Map<String, dynamic> configuration;

  late final String _pathToArb;
  late final String _arbTemplate;
  late final String _localeTemplate;
  late final List<String> _excludedLocales;
  late final List<String> _regenerationKeys;
  late final List<String> _specificLocalesConfiguration;

  LocalizationTranslatorBase(this.configuration)
      : _pathToArb = configuration[YamlConfiguratorFields.pathToArb],
        _arbTemplate =
            configuration[YamlConfiguratorFields.arbTemplate] ?? 'app',
        _localeTemplate = configuration[YamlConfiguratorFields.localeTemplate] {
    _excludedLocales = (configuration[YamlConfiguratorFields.excludedLocales]
                as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    _regenerationKeys = (configuration[YamlConfiguratorFields.regenerationKeys]
                as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    _specificLocalesConfiguration =
        (configuration[YamlConfiguratorFields.specificLocalesConfiguration]
                    as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [];
  }

  final _translator = GoogleTranslator();

  /// This method converts the translated strings from the Map object
  /// into typical JSON, and then writes it to the required .arb file.
  Future<void> writeTranslatedToArb() async {
    final translateMismatches = await _translateMismatches();
    if (translateMismatches == null) {
      TranslatorLogger.infoLog(
        '<!>Something went wrong<!>'
        'Check your .arb resources.',
      );
      return;
    }
    if (translateMismatches.isEmpty) {
      TranslatorLogger.infoLog('🔵 No new lines for translation. 🔵\n\n');
      return;
    }

    final allArbPaths = _identifyLocalesArbPaths();

    for (final mismatchLocale in translateMismatches.keys) {
      final allMismatchLocaleTranslations = _localeTranslations(mismatchLocale);

      if (allMismatchLocaleTranslations == null) {
        TranslatorLogger.infoLog(
          '<!>Something went wrong<!>'
          'Check your $mismatchLocale .arb resources.',
        );

        return;
      }

      final localeMismatchesMap = translateMismatches[mismatchLocale]!;
      final pathForWriting = allArbPaths.firstWhere(
        (e) => e.contains('${_arbTemplate}_$mismatchLocale'),
        orElse: () => 'none',
      );

      if (pathForWriting == 'none') return;

      final arbFile = File(pathForWriting).openSync(mode: FileMode.append);

      for (final mismatchStringKey in localeMismatchesMap.keys) {
        allMismatchLocaleTranslations[mismatchStringKey] =
            localeMismatchesMap[mismatchStringKey]!;
      }

      arbFile
        ..truncateSync(0)
        ..setPositionSync(0)
        ..writeStringSync(
          ArbHandler.formattedJsonEncode(allMismatchLocaleTranslations),
        )
        ..closeSync();
    }

    TranslatorLogger.infoLog(
      'Translation of new lines has been completed successfully. '
      'Check your .arb resources for newlines',
    );
  }

  Future<String> _translateMessage({
    required String message,
    required String fromLocale,
    required String toLocale,
  }) async {
    final translation = await _translator.translate(
      message,
      from: fromLocale,
      to: toLocale,
    );

    return translation.text;
  }

  /// A method for translating all discrepancies into the appropriate language.
  ///
  /// <!> Be careful, package, until you know how to translate plural forms.
  ///
  /// Note: All placeholders will maintain the sequence required
  /// for the language and will not be translated
  /// Example: "Hello {user} - Привет {user}"
  /// <!> Placeholder typing will be skipped.
  Future<Map<String, Map<String, dynamic>>?> _translateMismatches() async {
    final untranslatedMessages = _identifyUntranslatedKeys();
    if (untranslatedMessages == null) return null;
    if (untranslatedMessages.isEmpty) return {};

    TranslatorLogger.infoLog(
      'Start translation process for next languages and lines:',
    );
    TranslatorLogger.infoLog(
      '${untranslatedMessages.entries.map((e) => '${e.key}: ${e.value}')}\n',
    );

    final templateLocale = _localeTranslations();
    if (templateLocale == null) return null;

    final translationsResult = <String, Map<String, dynamic>>{};
    for (final locale in untranslatedMessages.keys) {
      translationsResult[locale] = <String, dynamic>{};

      final localeUntranslatedKeys = untranslatedMessages[locale]!;

      for (final messageKey in localeUntranslatedKeys) {
        final messageForTranslate = templateLocale[messageKey]!;

        final placeholders = <String>[];
        final specificLocaleName = _identifySpecificLocaleName(locale);

        final translatedMessage = messageKey.startsWith('@')
            ? messageForTranslate
            : await _translateMessage(
                message: PlaceholdersHandler.leavePlaceholders(
                  messageForTranslate,
                  placeholders,
                ),
                fromLocale: _localeTemplate,
                toLocale: specificLocaleName ?? locale,
              );

        translationsResult[locale]!.addAll(
          {
            messageKey: messageKey.startsWith('@')
                ? translatedMessage
                : PlaceholdersHandler.putPlaceholders(
                    translatedMessage,
                    placeholders,
                  ),
          },
        );
      }

      TranslatorLogger.infoLog('Finished translation for locale: $locale');
    }

    return translationsResult;
  }

  /// The method checks the languageCode for any specific variations,
  /// for example, for the Chinese language there are several possible
  /// localizations (Simplified, Traditional),
  /// which corresponds to the language code zh-cn and zh-tw.
  ///
  /// In the .yaml configuration you specify similar locales
  /// in the list under the "specificLocalesConfiguration" key.
  String? _identifySpecificLocaleName(String localeName) {
    final specificLocaleName = _specificLocalesConfiguration.firstWhere(
      (e) => e.contains(localeName),
      orElse: () => '',
    );

    return specificLocaleName.isEmpty ? null : specificLocaleName;
  }

  /// The method determines the difference between your template localization
  /// and all other available ones.
  ///
  /// Returns a Map object, where the key is languageCode
  /// and the value is a list of keys that are missing
  /// in localizations compared to the template one.
  Map<String, List<String>>? _identifyUntranslatedKeys() {
    final supportedLocales = _identifySupportedLocales();
    final templateTranslations = _localeTranslations();

    if (templateTranslations == null) return null;

    final templateMessagesKeys = Set.of(templateTranslations.keys);
    final localesMismatches = <String, List<String>>{};

    for (final locale in supportedLocales) {
      final localeTranslations = _localeTranslations(locale);
      if (localeTranslations == null) return null;

      final currentLocaleKeys = Set.of(localeTranslations.keys);

      final mismatchesWithTemplate = templateMessagesKeys.difference(
        currentLocaleKeys,
      )..addAll(_regenerationKeys);
      if (mismatchesWithTemplate.isNotEmpty) {
        localesMismatches[locale] = mismatchesWithTemplate.toList();
      }
    }

    return localesMismatches;
  }

  /// The method accesses the directory with .arb resources
  /// and returns an Iterable of paths to each localization file.
  Iterable<String> _identifyLocalesArbPaths() {
    final directory = Directory(_pathToArb);

    final arbFilesPaths = directory.listSync().map((e) => e.path).toList()
      ..removeWhere(
        (e) => !e.contains('.arb'),
      );

    return arbFilesPaths;
  }

  /// The method is required to obtain all existing localizations
  /// using the path to .arb resources passed to the configuration.
  ///
  /// In the configuration file you can pass a list of those locales
  /// for which there is no need for translation.
  ///
  /// Note:
  /// Please name your .arb files according to the Dart code style.
  /// For example:
  /// You can name your .arb like app_${languageCode.toLowerCase()} - app_en.arb
  /// or otherwise, but observing the same rule
  /// For example:
  /// You can name your .arb like
  /// ${yourProjectName.toLowerCase()}_${languageCode}.arb - word_en.arb
  ///
  /// <!> You cannot name your .arb using camel case notation,
  /// or any other notation other than underscore notation.
  List<String> _identifySupportedLocales() {
    final supportedLocales = _identifyLocalesArbPaths()
        .map(
          (e) => e
              .replaceAll(
                _pathToArb.endsWith('/')
                    ? '$_pathToArb$_arbTemplate'
                    : '$_pathToArb/$_arbTemplate',
                '',
              )
              .replaceAll(RegExp(r'[^a-zA-Z]'), '')
              .replaceAll('arb', ''),
        )
        .toList()
      ..sort();

    supportedLocales.removeWhere((e) => e.contains(_localeTemplate));

    for (final excludedLocale in _excludedLocales) {
      supportedLocales.removeWhere((e) => e.contains(excludedLocale));
    }

    return supportedLocales;
  }

  /// The method is necessary to obtain all localized strings from
  /// a specific locale and convert the resulting data into a familiar Map.
  ///
  /// Params:
  /// [localeName] - international language code
  /// (Example: en - English, ru - Russian, fr - French, etc.)
  Map<String, dynamic>? _localeTranslations([String? localeName]) {
    try {
      final templatePath = _identifyLocalesArbPaths().firstWhere(
        (e) => e.contains(localeName ?? _localeTemplate),
      );
      final templateFile = File(templatePath);

      if (templateFile.readAsStringSync().isEmpty) return {};

      final decodedMap =
          jsonDecode(templateFile.readAsStringSync()) as Map<String, dynamic>;

      return decodedMap;
    } catch (e) {
      TranslatorLogger.infoLog('$e');

      return null;
    }
  }
}
