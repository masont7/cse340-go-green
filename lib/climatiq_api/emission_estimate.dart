/// Represents a CO2 emissions estimate from an API call
class EmissionEstimate {
  /// Emission factor carbon dioxide equivalent
  final double co2;
  /// The unit in which the co2 field is expressed
  final String unit;

  /// Creates an Emissions Estimate with all fields
  /// 
  /// Parameters:
  ///  - co2: the estimated amount of co2 emitted
  ///  - unit: the units of measurement for the co2 estimate
  EmissionEstimate({required this.co2, required this.unit});

  /// Creates an EmissionEstimate from json data.
  /// 
  /// Parameter:
  ///  - json: the data to parse
  factory EmissionEstimate.fromJson(Map<String, dynamic> json) {
    // Throws an error if the 'co2e' key doesn't exist
    if (!json.containsKey('co2e')) {
      throw ArgumentError('co2 estimate not found. json: \n$json');
    }

    // Throws an error if the 'co2e_unit' key doesn't exist
    if (!json.containsKey('co2e_unit')) {
      throw ArgumentError('co2 unit of measurement not found. json: \n$json');
    }
    
    return EmissionEstimate(
      co2: json['co2e'] as double,
      unit: json['co2e_unit'] as String,
    );
  }

  @override
  String toString() {
    return '$co2 $unit emitted';
  }
}