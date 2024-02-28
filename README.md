## Automatically localization translator
The package helps developers easily translate .arb resources into different languages.

## Installing
Add it to your `pubspec.yaml` file:
```yml
dev_dependencies:
  localization_translator: ^latest_version
```
Install packages from the command line
```
flutter pub get
```
## Usage

You can use this in the following way:

1. Place the `localization_translator.yaml` configuration file in the root directory of your project.
2. Inside `localization_translator.yaml`, specify the necessary parameters. (Below is a table with all available fields and their corresponding meaning)
3. Run translator script using this terminal command inside your project directory:
```
dart run localization_translator
```

## Configuration in `localization_translator.yaml`

| Field                                       | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   |
|---------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| pathToArb (String)                          | Path to the directory with your .arb files. Example: if your .arb is in the lib/l10n directory, then you should specify lib/l10n as the value.                                                                                                                                                                                                                                                                                                                                                                                |
| localeTemplate (String)                     | The language code of the localization, which will be used as a template for translating other localizations, is in ISO-639-1 format. For example, en - if you want to use the English version of your localization as a template. All existing language codes can be found at the following link: https://en.wikipedia.org/wiki/List_of_ISO_639_language_codes                                                                                                                                                                |
| arbTemplate (String)                        | If you name .arb files in a different way than the usual app_en.arb, you must specify in this parameter what prefix your .arb has. For example: your .arb names are anyword_languagecode.arb, then use anyword as the value of this parameter.                                                                                                                                                                                                                                                                                |
| excludedLocales (List<String>)              | A list of language codes for those localizations that will not be included in the list for translation. Each Language code is written in ISO-639-1 format; all available language codes can be found at the link above.                                                                                                                                                                                                                                                                                                       |
| regenerationKeys (List<String>)             | A list of string keys in your .arb file, used as a template for translation. Lines under the specified keys will also be included in the list for translations, even if they have already been added to all localizations previously.                                                                                                                                                                                                                                                                                         |
| specificLocalesConfiguration (List<String>) | A list of language codes for those languages that have different forms of translations. For example: if your project includes Chinese, then when translating such strings you probably noticed that any translator prompts you to select which type (Simplified, Traditional) is needed. For such cases, the language specification is added. Note: if your .arb file already has a language name with a specification (not app_zh.arb, but app_zh-cn.arb), then there is no need to add the specification for this language. |

Click [**here**]([https://github.com/](https://github.com/tokyolem/localization_translator/blob/main/example/localization_translator.yaml)https://github.com/tokyolem/localization_translator/blob/main/example/localization_translator.yaml) to view the example of .yaml configuration.
