import 'dart:core';
import 'package:flutter/material.dart';
import 'package:go_green/climatiq_api/emission_checker.dart';
import 'package:go_green/climatiq_api/emission_estimate.dart';
import 'package:go_green/models/emission_data/emission_data_enums.dart';
import 'package:go_green/models/emission_data/emission_subtypes.dart';
import 'package:go_green/models/emission_factors/base_emission_factors/emission_factors.dart';
import 'package:go_green/models/emission_factors/clothing_emissions.dart';
import 'package:go_green/models/emission_factors/electrical_waste_emissions.dart';
import 'package:go_green/models/emission_factors/energy_emissions.dart';
import 'package:go_green/models/emission_factors/food_emissions.dart';
import 'package:go_green/models/emission_factors/food_waste_emissions.dart';
import 'package:go_green/models/emission_factors/furniture_emissions.dart';
import 'package:go_green/models/emission_factors/general_waste.dart';
import 'package:go_green/models/emission_factors/personal_care_emissions.dart';
import 'package:go_green/models/emission_factors/travel_emissions.dart';
import 'package:go_green/models/entry.dart';
import 'package:go_green/views/entry_widgets/amount_input.dart';
import 'package:go_green/views/entry_widgets/custom_dropdown.dart';
import 'package:go_green/views/entry_widgets/emission_dropdown_menu.dart';
import 'package:intl/intl.dart';


/// A StatefulWidget that displays and allows editing of a single Entry.
class EntryView extends StatefulWidget{
  final Entry curEntry;

  const EntryView({super.key, required this.curEntry});

  @override
  State<EntryView> createState() => _EntryViewState();
}

class _EntryViewState extends State<EntryView>{

  // menu entries for category 
  List<DropdownMenuEntry<EmissionCategory>> dropdownMenuEntries = EmissionCategory.values.map((category) {
    return DropdownMenuEntry<EmissionCategory>(value: category, label: category.toString(), 
    style: const ButtonStyle(foregroundColor: WidgetStatePropertyAll(Color(0xFF386641)), 
    textStyle: WidgetStatePropertyAll(TextStyle(fontSize: 14))));
  }).toList();

  // menu entries for subtypes
  List<DropdownMenuEntry<String>> subtypeDropdownMenuEntries = [];


  // State variables for storing editable text fields
  String notes = '';
  DateTime updatedAt = DateTime.now();
  DateTime createdAt = DateTime.now();
  DateTime emissionsDate = DateTime.now();
  EmissionCategory category = EmissionCategory.clothing;
  String subtype = 'Leather';
  double co2 = 0;
  EmissionChecker checker = EmissionChecker();

  // for clothing
  double? amount; // also for money, weight, distance
  MoneyUnit? moneyUnit;
  WeightUnit? weightUnit;
  String curEst = 'N/A';

  // for energy
  EnergyAmount? energyAmount;

  // for travel
  DistanceUnit? distanceUnit;
  int? passengers;
  PassengerAmount? passengerAmount;
  VehicleSize? size;

  @override
  void initState() {
    super.initState();
    // Initialize state variables with values from the provided journal entry
    notes = widget.curEntry.notes;
    updatedAt = widget.curEntry.updatedAt;
    createdAt = widget.curEntry.createdAt;
    emissionsDate = widget.curEntry.emissionsDate;
    category = widget.curEntry.category;
    co2 = widget.curEntry.co2;
    subtype = widget.curEntry.subtype;

    // intialize the dropdown menus
    _updateSubtypeDropdown(category);
  }


  @override
  Widget build(BuildContext context){
    return PopScope(
      onPopInvokedWithResult: _onPopInvokedWithResult,
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFFF2E8CF),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF2E8CF),
          title: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.eco, color: Color(0xFF6A994E)), // Leaf icon for GoGreen theme
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Flexible(
                    child: Semantics(
                      child: const Text(
                        'Track Here', 
                        style: TextStyle(
                          color: Color(0xFF386641), 
                          fontWeight: FontWeight.bold,
                          overflow: TextOverflow.fade
                        ),
                        semanticsLabel: 'Go Green: Track your emissions here.',
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        body:
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 10,),
                  // first row of the page, two drop down menus and one date selector
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Dropdown for category selection
                      EmissionDropdownMenu(
                        label: 'Emission Category:',
                        semanticsLabel: 'Select Emission Category below.',
                        initialSelection: category, 
                        options: dropdownMenuEntries,
                        onSelected: (EmissionCategory? value) {
                          setState(() {
                            category = value ?? category;
                          });
                          _updateSubtypeDropdown(category);
                        },
                      ),
                      // Dropdown for subtype selection
                      EmissionDropdownMenu(
                        label: 'Emission Type:',
                        semanticsLabel: 'Select Emission Type below.',
                        onSelected: (String? value) {
                          setState(() {
                            subtype = value ?? subtype;
                          });
                        },
                        initialSelection: subtype, 
                        options: subtypeDropdownMenuEntries,
                      ),
                    ],
                  ),
              
                  const SizedBox(height: 10),
              
                  // Date selector button
                  SizedBox(
                    width: 150, // Set uniform width for dropdown and button
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 234, 224, 198), // Button background color
                        foregroundColor: const Color(0xFF386641), // Text color
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0), // Rounded corners matching dropdown
                        ),
                      ),
                      onPressed: () async {
                        DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: emissionsDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                          builder: (BuildContext context, Widget? child) {
                            return Theme(
                              data: ThemeData.light().copyWith(
                                primaryColor: const Color(0xFF6A994E), // Header background color (e.g., calendar title)
                                colorScheme: const ColorScheme.light(
                                  primary: Color(0xFF6A994E), // Color for selected date and confirm button
                                  onPrimary: Color(0xFFF2E8CF), // Text color on the confirm button
                                  surface: Color(0xFFF2E8CF), // Background color of the calendar
                                  onSurface: Color(0xFF386641), // Color for the date text
                                ),
                                dialogBackgroundColor: const Color(0xFFF2E8CF), // Background color of the date picker dialog
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (pickedDate != null && pickedDate != emissionsDate) {
                          setState(() {
                            emissionsDate = pickedDate;
                          });
                        }
                      },
                      child: Text(
                        'Choose Date: ${DateFormat.yMd().format(emissionsDate)}',
                        style: const TextStyle(
                          color: Color(0xFF386641),
                          fontWeight: FontWeight.bold
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 10),
              
                  // selections for differenct categories
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (category == EmissionCategory.clothing)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (subtype == 'Used Clothing')
                              _buildWeightInputSection()
                            else
                              _buildMoneyInputSection(),
                          ],
                        )
                      else if (category == EmissionCategory.electricalWaste || category == EmissionCategory.foodWaste 
                      || category == EmissionCategory.personalCareAndAccessories || category == EmissionCategory.generalWaste)
                        _buildWeightInputSection()
                      else if (category == EmissionCategory.energy)
                        _buildEnergyInputSection()
                      else if (category == EmissionCategory.food || category == EmissionCategory.furniture
                      || category == EmissionCategory.personalCareAndAccessories)
                        _buildMoneyInputSection()
                      else if (category == EmissionCategory.travel)
                        _buildTravelInputSection(subtype),
                    ],
                  ),
                  
                  // notes field
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        child: const Text(
                          'Notes:', 
                          style: TextStyle(color: Color(0xFF386641), fontSize: 16),
                          semanticsLabel: 'Enter any additional notes below.',
                        ),
                      ),
                      SizedBox(
                        width: 250,
                        height: 100,
                        child: TextFormField(
                          maxLines: 10,
                          initialValue: notes,
                          onChanged: (value) { setState(() => notes = value); },
                          decoration: InputDecoration(
                            labelStyle: TextStyle(color: Colors.grey.shade800),
                            filled: true,
                            fillColor: const Color.fromARGB(52, 193, 185, 102),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onTapOutside: (event) => FocusScope.of(context).unfocus()
                        ),
                      ),
                    ],
                  ),
              
                  const SizedBox(height: 30),
              
                  // estimate button
                  SizedBox(
                    width: 160,
                    height: 80,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 234, 224, 198), // Button background color
                        foregroundColor: const Color(0xFF386641), // Text color
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0), // Rounded corners
                        ),
                      ),
                      onPressed: () async {
                        EmissionEstimate? estimate = await checker.getEmissions(_estimateEmission());
                        if (estimate != null) {
                          setState(() {
                            curEst = estimate.toString();
                            co2 = estimate.co2;
                          });
                        } else {
                          setState(() {
                            curEst = 'Please try again later';
                          });
                        }
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(10.0), // Padding for better appearance
                        child: Text(
                          'Estimate\nEmission',
                          style: TextStyle(fontSize: 18),
                          semanticsLabel: 'Estimate Emission',
                        ),
                      ),
                    ),
                  ),
                
                const SizedBox(height: 20),
              
                // Box to Display Estimated Emission
                Container(
                  padding: const EdgeInsets.all(15.0),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 224, 214, 186), // Background color
                    borderRadius: BorderRadius.circular(15.0), // Rounded corners
                    border: Border.all(
                      color: const Color(0xFF386641),
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    'Estimate: $curEst',
                    semanticsLabel: 'Estimate: $curEst',
                    style: const TextStyle(
                      fontSize: 22,
                      color: Colors.black,
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
              
                // Save Button
                SizedBox(
                  width: 130,
                  height: 70,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 234, 224, 198), // Button background color
                      foregroundColor: const Color(0xFF386641), // Text color
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0), // Rounded corners
                      ),
                    ),
                    onPressed: () {
                      _popback(context);
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(0), // Padding for better appearance
                      child: Text(
                        'Save',
                        semanticsLabel: 'Save',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
                        ),
            ),
        ),
      ),
    );
  }


  // dynamic estimation 
  EmissionFactor _estimateEmission() {
    switch (category) {
      // clothing case
      case EmissionCategory.clothing:
        switch (subtype) {
          case 'Leather':
            return ClothingEmissions.leather(money: amount ?? 0, moneyUnit: moneyUnit ?? MoneyUnit.usd);
          case 'Footwear':
            return ClothingEmissions.footwear(money: amount ?? 0, moneyUnit: moneyUnit ?? MoneyUnit.usd);
          case 'New Clothing':
            return ClothingEmissions.newClothing(money: amount ?? 0, moneyUnit: moneyUnit ?? MoneyUnit.usd);
          case 'Infant Clothing':
            return ClothingEmissions.infantClothing(money: amount ?? 0, moneyUnit: moneyUnit ?? MoneyUnit.usd);
          case 'Used Clothing':
            return ClothingEmissions.usedClothing(weight: amount ?? 0, weightUnit: weightUnit ?? WeightUnit.kg);
        }
      case EmissionCategory.electricalWaste:
        return ElectricalWasteEmissions(weight: amount ?? 0, weightUnit: WeightUnit.kg, electricalWasteType: subtype);
      case EmissionCategory.energy:
        switch(subtype) {
          case 'Electricity':
            return EnergyEmissions.electricity(energy: energyAmount ?? EnergyAmount.average);
          case 'Natural Gas':
            return EnergyEmissions.naturalGas(volume: energyAmount ?? EnergyAmount.average);
        }
      case EmissionCategory.food:
        return FoodEmissions(foodType: subtype, money: amount ?? 0, moneyUnit: moneyUnit ?? MoneyUnit.usd);
      case EmissionCategory.foodWaste:
        return FoodWasteEmissions(foodWasteType: subtype, weight: amount ?? 0, weightUnit: weightUnit ?? WeightUnit.kg);
      case EmissionCategory.furniture:
        return FurnitureEmissions(furnitureType: subtype, money: amount ?? 0, moneyUnit: moneyUnit ?? MoneyUnit.usd);
      case EmissionCategory.generalWaste:
        return GeneralWasteEmissions(wasteType: subtype, weight: amount ?? 0, weightUnit: weightUnit ?? WeightUnit.kg);
      case EmissionCategory.personalCareAndAccessories:
        return PersonalCareEmissions(money: amount ?? 0, moneyUnit: moneyUnit ?? MoneyUnit.usd, personalCareType: subtype);
      case EmissionCategory.travel:
        switch(subtype){
          case 'Gas Car':
            return TravelEmissions.gasCar(distance: amount ?? 0, distanceUnit: distanceUnit ?? DistanceUnit.km, passengers: passengers);
          case 'Electric Car':
            return TravelEmissions.electricCar(distance: amount ?? 0, distanceUnit: distanceUnit ?? DistanceUnit.km, passengers: passengers);
          case 'Hybrid Car':
            return TravelEmissions.hybridCar(distance: amount ?? 0, distanceUnit: distanceUnit ?? DistanceUnit.km);
          case 'Bus':
            return TravelEmissions.bus(distance: amount ?? 0, distanceUnit: distanceUnit ?? DistanceUnit.km, 
            passengerAmt: passengerAmount ?? PassengerAmount.average);
          case 'Light Rail/Tram':
            return TravelEmissions.lightRailTram(distance: amount ?? 0, distanceUnit: distanceUnit ?? DistanceUnit.km, 
            passengerAmt: passengerAmount ?? PassengerAmount.average);
          case 'Train':
            return TravelEmissions.train(distance: amount ?? 0, distanceUnit: distanceUnit ?? DistanceUnit.km, 
            passengerAmt: passengerAmount ?? PassengerAmount.average);
          case 'Ferry: On Foot':
            return TravelEmissions.ferry(distance: amount ?? 0, distanceUnit: distanceUnit ?? DistanceUnit.km, 
            passengerAmt: passengerAmount ?? PassengerAmount.average, onFoot: true);
          case 'Ferry: With a Car':
            return TravelEmissions.ferry(distance: amount ?? 0, distanceUnit: distanceUnit ?? DistanceUnit.km, 
            passengerAmt: passengerAmount ?? PassengerAmount.average, onFoot: false);
          case 'International Flight':
            return TravelEmissions.flight(distance: amount ?? 0, distanceUnit: distanceUnit ?? DistanceUnit.km, 
            size: size ?? VehicleSize.medium, 
              passengerAmt: passengerAmount ?? PassengerAmount.average, isDomestic: false);
          case 'Domestic Flight':
            return TravelEmissions.flight(distance: amount ?? 0, distanceUnit: distanceUnit ?? DistanceUnit.km, 
            size: size ?? VehicleSize.medium, passengerAmt: passengerAmount ?? PassengerAmount.average, isDomestic: true);
        }

      // Add other category cases for emission estimation here
      default:
        return ClothingEmissions.leather(money: amount ?? 0, moneyUnit: moneyUnit ?? MoneyUnit.usd);
    }
    //throw StateError('Unsupported category or subtype: $category, $subtype');
    return ClothingEmissions.leather(money: amount ?? 0, moneyUnit: moneyUnit ?? MoneyUnit.usd);
  }

  // Saves the current state of the entry and returns to the previous screen.
  void _popback(BuildContext context){
    // Create an updated Entry with current state values
    final curEntry = Entry(
      id: widget.curEntry.id,
      notes: notes,
      updatedAt: DateTime.now(),
      createdAt: createdAt,
      emissionsDate: emissionsDate,
      category: category,
      co2: co2,
      subtype: subtype,
    );

    // Pass the updated entry back to the previous screen and close this view
    Navigator.pop(context, curEntry);
  }

  // method for popping back
  void _onPopInvokedWithResult(bool didPop, dynamic canPop) {
    if (!didPop) {
      _popback(context);
    }
  }

  // Update the subtype dropdown menu based on the selected category
  void _updateSubtypeDropdown(EmissionCategory selectedCategory) {
    Map<String, String> subtypeMap;

    switch (selectedCategory) {
      case EmissionCategory.clothing:
        subtypeMap = EmissionSubtypes().clothingTypes;
        break;
      case EmissionCategory.electricalWaste:
        subtypeMap = EmissionSubtypes().electricalWasteTypes;
        break;
      case EmissionCategory.energy:
        subtypeMap = EmissionSubtypes().energyTypes;
        break;
      case EmissionCategory.food:
        subtypeMap = EmissionSubtypes().foodTypes;
        break;
      case EmissionCategory.foodWaste:
        subtypeMap = EmissionSubtypes().foodWasteTypes;
        break;
      case EmissionCategory.furniture:
        subtypeMap = EmissionSubtypes().furnitureTypes;
        break;
      case EmissionCategory.generalWaste:
        subtypeMap = EmissionSubtypes().generalWasteTypes;
        break;
      case EmissionCategory.personalCareAndAccessories:
        subtypeMap = EmissionSubtypes().personalCareTypes;
        break;
      case EmissionCategory.travel:
        subtypeMap = EmissionSubtypes().travelTypes;
        break;
      default:
        subtypeMap = {};
    }

    // Update the dropdown menu entries for subtypes
    setState(() {
      subtypeDropdownMenuEntries = subtypeMap.entries
          .map((e) => DropdownMenuEntry<String>(
                value: e.key,
                label: e.key,
                style: const ButtonStyle(foregroundColor: WidgetStatePropertyAll(Color(0xFF386641)))
              ))
          .toList();
      subtype = subtypeMap.entries.first.key;
    });
  }

  // Weight Input Section
  Widget _buildWeightInputSection() {
    print('building weight input');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0), // Increased vertical padding
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Weight input field
              AmountInput(
                label: 'Weight:',
                semanticsLabel: 'Enter weight of $subtype below.',
                onChanged: (value) {
                  setState(() {
                    amount = double.tryParse(value) ?? 0;
                  });
                }, 
                description: 'Weight'
              ),
              const SizedBox(width: 20), // Increased spacing between fields
              // Weight Unit Dropdown
              CustomDropdown<WeightUnit>(
                label: 'Units',
                semanticsLabel: 'Select units of measurement for weight below.',
                onChanged: (WeightUnit? value) {
                  setState(() {
                    weightUnit = value ?? weightUnit;
                  });
                },
                value: weightUnit,
                options: WeightUnit.values,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Money Input Section
  Widget _buildMoneyInputSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0), // Increased vertical padding
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Money input field
          AmountInput(
            label: 'Amount spent:',
            semanticsLabel: 'Enter amount spent on $subtype below.',
            onChanged: (value) {
              setState(() {
                amount = double.tryParse(value) ?? 0;
              });
            }, 
            description: 'Enter amount'
          ),
          const SizedBox(width: 20), // Increased spacing between fields
          // Money Unit Dropdown
          CustomDropdown<MoneyUnit>(
            label: 'Currency:',
            semanticsLabel: 'Select type of currency below',
            onChanged: (MoneyUnit? value) {
              setState(() {
                moneyUnit = value ?? moneyUnit;
              });
            }, 
            value: moneyUnit, 
            options: MoneyUnit.values,
          ),
        ],
      ),
    );
  }

  // Energy Input Section
  Widget _buildEnergyInputSection() {
    return Column(
      children: [
        Theme(
          data: Theme.of(context).copyWith(
            canvasColor: const Color.fromARGB(255, 224, 214, 186), // Background color when dropdown is open
          ),
          child: CustomDropdown<EnergyAmount>(
            label: 'How much energy did you use?',
            semanticsLabel: 'Select how much energy you used below.',
            onChanged: (EnergyAmount? value) {
              setState(() {
                energyAmount = value!;
              });
            }, 
            value: energyAmount, 
            options: EnergyAmount.values,
            width: 300
          ),
        ),
      ],
    );
  }

  // Travel Input Section
  Widget _buildTravelInputSection(String subtype) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AmountInput(
              label: 'Distance:',
              semanticsLabel: 'Enter distance travelled by $subtype below.',
              onChanged: (value) {
                setState(() {
                  amount = double.tryParse(value) ?? 0;
                });
              }, 
              description: 'Distance'
            ),
            const SizedBox(width: 20),
            // Distance Unit Dropdown
            CustomDropdown<DistanceUnit>(
              label: 'Units',
              onChanged: (DistanceUnit? value) {
                setState(() {
                  distanceUnit = value ?? distanceUnit;
                });
              },
              value: distanceUnit, 
              options: DistanceUnit.values
            ),
          ],
        ),
        const SizedBox(height: 20,),
        // Distance input field
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const SizedBox(height: 20), // Increased spacing between dropdowns
            // Passenger Amount Dropdown
            if (subtype == 'Gas Car' || subtype == 'Electric Car') ...[
              AmountInput(
                label: '# of Passengers:',
                semanticsLabel: 'Enter number of passengers below.',
                description: 'Passengers',
                onChanged: (value) {
                  setState(() {
                    amount = double.tryParse(value) ?? 0;
                  });
                },
              ),
            ] else if (subtype == 'Hybrid Car') ...[
              // Hybrid car displays nothing here
              // It requries no additional passenger information
            ] else ...[
              CustomDropdown<PassengerAmount>(
                label: 'How full was\nthe ride?',
                semanticsLabel: 'Select approximately how full the vehicle was below.',
                width: 150,
                onChanged: (PassengerAmount? value) {
                  setState(() {
                    passengerAmount = value!;
                  });
                }, 
                // hintFontSize: 10,
                value: passengerAmount, 
                options: PassengerAmount.values,
              ),
            ],
    
            const SizedBox(width: 20,),
    
            if (subtype == 'International Flight' || subtype == 'Domestic Flight') ...[
              CustomDropdown<VehicleSize>(
                label: 'Plane size:',
                semanticsLabel: 'Select the size of your plane below',
                onChanged: (VehicleSize? value) {
                  setState(() {
                    size = value!;
                  });
                }, 
                value: size, 
                options: VehicleSize.values
              ),
            ]
          ],
        )
      ],
    );
  }
}