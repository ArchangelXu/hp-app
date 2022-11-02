class Serialization {
  static double doubleFromJson(String number) => double.tryParse(number) ?? 0;

  static String? doubleToJson(double? number) => number?.toString();
}
