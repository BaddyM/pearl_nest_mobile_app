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

  // Now this can be a regular String function!
  String currencyConverter({required int price}) {
    final putCommas = addCommas();
    String? baseCurrency = _prefs.getString("currency");
    int currencyValue = _prefs.getInt("currencyValue") ?? 1; // Default to 1 to avoid div by zero

    if (baseCurrency == "USD") {
      return "USD ${putCommas((price / currencyValue).toInt())}";
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
