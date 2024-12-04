import 'package:go_green/models/emission_data/emission_data_enums.dart';
import 'package:isar/isar.dart';
part 'entry.g.dart';


/// Class to represent an emissions entry
@Collection()
class Entry {
  /// This Entry's identifying number.
  /// invariant: must be unique
  Id? id;

  ///The user's notes for this entry
  final String notes;

  /// The last time this Entry was updated.
  /// Invariant: must be equal to or later than createdAt.
  final DateTime updatedAt;

  /// The time this Entry was created.
  /// Invariant: must be equal to or earlier than updatedAt.
  final DateTime createdAt;

  /// the date this entry is tracking emissions for
  final DateTime emissionsDate;

  /// the category of emissions for this entry
  @enumerated
  final EmissionCategory category;

  /// the subtype of this entry
  final String subtype;

  /// co2 emissions for this entry
  final double co2;

  /// Constructs an Entry using all fields
  Entry({
    required this.id,
    required this.notes,
    required this.updatedAt,
    required this.createdAt,
    required this.emissionsDate,
    required this.category,
    required this.subtype,
    this.co2 = 0
  });

  /// Constructs a new entry given an emission category.
  /// Optionally pass in a date and notes for the entry. If no date is passed, sets the date to now.
  factory Entry.fromEmissions({required EmissionCategory category, notes = '', emissionsDate}) {
    final when = DateTime.now();
    return Entry (
      id: Isar.autoIncrement,
      notes: notes,
      updatedAt: when,
      createdAt: when,
      // sets the date for this entry to the given date, or DateTime.now if it's not provided
      emissionsDate: emissionsDate ?? when,
      category: category,
      subtype: 'Leather'
    );
  }

}