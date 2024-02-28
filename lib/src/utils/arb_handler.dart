import 'dart:convert';

abstract final class ArbHandler {
  static String formattedJsonEncode(Map<String, dynamic>? jsonObject) {
    return JsonEncoder.withIndent("  ").convert(jsonObject);
  }
}
