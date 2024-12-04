import 'package:go_green/models/emission_data/emission_data_enums.dart';
import 'package:go_green/models/emission_data/emission_subtypes.dart';
import 'package:go_green/models/emission_factors/base_emission_factors/money_emission_factor.dart';

/// Represents emissions from personal care and accessory items
class PersonalCareEmissions extends MoneyEmissionFactor {
  /// The type of personal care or accessory
  final String personalCareType;

  /// Creates an Emission Factor for furniture.
  /// 
  /// Parameters:
  ///  - money: the amount of money spent
  ///  - moneyUnit: the type of currency for money
  ///  - personalCareType: the type of personal care or accessory
  PersonalCareEmissions({
    required super.money, 
    required super.moneyUnit,
    required this.personalCareType
  }): super(
    category: EmissionCategory.furniture,
    id: EmissionSubtypes().personalCareTypes[personalCareType] ?? 'type not found'
  );
  
  @override 
  String toString() {
    String result = '${super.toString()},\n';
    result += '  type: ${personalCareType.toString()}';
    return result;
  }
}

/// Enum to represent the type of personal care item used
enum PersonalCareType{
  jewellery, perfume, toiletries, soap, toiletPaper, feminineHygiene, disposableDiaper;

  @override
  String toString() {
    String result = super.toString();
    if (result.isEmpty) return result;

    // get rid of the enum type at the beginning of the string
    final int startIndex = result.indexOf('.') + 1;
    result = result.substring(startIndex);

    // Check for uppercase letters - that means that the name contains multiple words
    for (int i = 0; i < result.length; i++) {
      final String copy = result;
      if (copy[i] == copy[i].toUpperCase()) {
        // uppercase letter found, add space before it
        result = '${result.substring(0, i)} ${result.substring(i, result.length)}';
        // increment since a character was added to the string
        i++; 
      }
    }

    // Make the 1st letter uppercase
    return result[0].toUpperCase() + result.substring(1).toLowerCase();
  }  
}