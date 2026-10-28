import 'package:add_comma/add_comma.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileService {
  // 1. Create a private static instance of the class
  static final ProfileService _instance = ProfileService._internal();

  // 2. Factory constructor that returns the same instance every time
  factory ProfileService() {
    return _instance;
  }

  // 3. Private named constructor (prevents external instantiation)
  ProfileService._internal();

  late SharedPreferences _prefs;

  // Call this in your main()
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  String get currencyCode =>
      _prefs.getString("currency")?.toUpperCase() == "USD" ? "USD" : "UGX";

  int get currencyValue {
    final value = _prefs.getInt("currencyValue") ?? 1;
    return value > 0 ? value : 1;
  }

  int toBaseCurrency(num displayAmount) =>
      currencyCode == "USD"
          ? (displayAmount * currencyValue).round()
          : displayAmount.round();

  int fromBaseCurrency(num baseAmount) =>
      currencyCode == "USD"
          ? (baseAmount / currencyValue).round()
          : baseAmount.round();

  // Now this can be a regular String function!
  String currencyConverter({required int price}) {
    final putCommas = addCommas();
    if (currencyCode == "USD") {
      return "USD ${putCommas(fromBaseCurrency(price))}";
    }
    return "UGX ${putCommas(price)}";
  }

  //Capitalize the first letter
  String stringCapitalize(String text) {
    String capitalized = text[0].toUpperCase() + text.substring(1);
    String cleanString = capitalized.replaceAll("_", " ");

    return (cleanString); // Result: "Hello world"
  }
}
