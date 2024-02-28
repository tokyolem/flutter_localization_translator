/// An auxiliary class that allows you to ignore placeholders
/// when translating lines.
abstract final class PlaceholdersHandler {
  static String putPlaceholders(
      String translatedMessage, List<String> placeholders) {
    var result = translatedMessage;

    for (var i = 0; i < placeholders.length; i++) {
      result = result.replaceAll('<$i>', placeholders[i]);
    }

    return result;
  }

  static String leavePlaceholders(String message, List<String> placeholders) {
    final regex = RegExp(r'{(.*?)}');

    var index = 0;
    var translatedText = message.replaceAllMapped(regex, (match) {
      placeholders.add(match.group(0)!);

      final result = '<$index>';

      index += 1;

      return result;
    });

    return translatedText;
  }
}
