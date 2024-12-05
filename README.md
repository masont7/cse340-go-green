# GoGreen
GoGreen is an app that allows users to track their carbon emissions based on activities and purchases they make during a day. It also displays recycling centers and second hand store locations in the Seattle Area which can be used to dispose of goods in a more sustainable fashion. 

NOTE FOR GRADERS: We used the DropdownMenu widget to display emission categories and types in our Entry View. We tried adding semantics to this widget, but it was buggy. We spoke with Ben about this and learned that it's an issue with flutter. We tried updating our flutter versions but it still didn't work, so we're documenting it in here. 

We construct the DropdownMenus in a custom widget in `lib/views/entry_widgets/emisison_dropdown_menu.dart`, and we construct that custom widget towards the beginning of `entry_view.dart`'s build method.

## Supported Devices
This app is mainly built for iOS devices. It can run on Windows and Mac devices, but the views are not optimized and we haven't done thorough tests for those operating systems. Linux and web have not been tested.

Due to issues with the flutter_maps package, the Map page of GoGreen will occasionally get stuck in an infinite loading loop on Android devices. Otherwise, the app is fully functional for Android.

## How to Build and Run GoGreen
1. Open the project in VS Code. Make sure to run `flutter pub get` in the terminal.
2. Select which device to deploy the app to. Type `flutter run --release` in the terminal. Alternatively, select the 'flutter release' configuration in your run settings and run the app from the 'Run' tab in VS Code. The app will build and run on your device.

## Project Structure
We used the Model-View-Provider structure for this project, which is contained in the lib folder of this project. 

**Climatiq API:** The climatiq_api folder contains the files that are used directly for calls to the Climatiq API. 
- `emission_checker.dart` sends and retrieves data from the API
- `emission_estimate.dart` is a class to represent the retrieved data. 
- The folder also contains a markdown file with an example of how to call the API from other files in this codebase.

**Models:** This folder contains all of the data structures we use to track the user's app data.
- Emission Factors are used to keep track of the user's emission types. 
- Activity History and Entry are used to represent the Emission Factors that the user tracks and keep a history of it. 
- Recycling Center and its Database (`recycling_center_db.dart`) are used to display locations of recycling centers on the Map page of the app. 

**Providers:** This folder contains the providers we use to update changes the user makes across the UI. Activity Provider is used for updating Entries and the list of all entries in Activity History. Position Provider is used to update the user's position on the Map page of the app as they move.

**Views:** This folder contains all of the views and custom widgets we created for GoGreen. 
- Activity Log View displays the user's full history of tracked emisisons. 
- Entry View allows the user to create a new entry for the Activity Log or update an existing entry. This is where the user can see their carbon emissions for specific activities
    - There are also a few custom widgets for this view in the entry_widgets folder
- Home Page displays the user's all-time carbon emissions from their tracked activities and allows the user to create a new Entry
- Map View displays nearby locations to get rid of used items in the Seattle Area such as recycling centers and second-hand stores.

# Data Design & Data Flow
There are two main parts of this app that store different data for the user: the map and the activity log. We also use a custom data structure called an Emission Factor to send the user's data to the Climatiq API to calculate their carbon emissions. All of this is explained in more detail below.

## The Map: Displaying Recycling Centers to the User
We have a custom database of recycling centers and second-hand stores that we use to show the user nearby locations where they can dispose of goods in a more sustainable fashion. Currently, only locations in Seattle are supported.

### Recycling Center
Each Recycling Center object (found at `./lib/models/recycling_center.dart`) represents a location to drop off used items. This class keeps track of: 
- 2 `String`s: one for the name of the location, and one for the URL of the location's website
- `double`s for the latitute and longitude coordinates of the location

### Recycling Center Database
The Recycling Center Database (found at `./lib/models/recycling_center_db.dart`) contains a list of Recycling centers. This is the list that's used to display all available locations on the map. 

### Map View
The Map View (found at `./lib/views/map_view.dart`) shows users where they are on the map by getting their current location via the Geolocator package, and it uses the Recycling Center Database to show any nearby locations. The user's position is updated with a PositionProvider so that the user can see themselves move on the map in real time.

## The Activity Log: Displaying Emissions Data to the User
The user's emissions data is stored similarly to a journal. They have entries and an activity history. These are displayed directly to the user in the ActivityLogView page of the app.

### Entry
Each Entry (found at `./lib/models/entry.dart`) is used to store user data about one of the user's activities and how much carbon those activities emitted. An entry contains: 
- `Id` to keep track of the entry's id value (handled by Isar)
- 2 `String`s: one to keep track of any notes the user inputs about their activities, and one to keep track of the specific subtype of emissions (bus ride, buying new clothing, etc.)
- 3 `DateTime`s to keep track of when the entry was created, when it was last updated, and what day the entry is tracking emissions for (in case someone wants to track emissions for a previous day)
- `EmissionCategory`: an enum to keep track of the overall category of emissions the user is tracking (travel, food, waste, etc.)
- `double` to keep track of the amount of co2 emissions for this entry in kg.

### Activity History
Activity History (found at `./lib/models/activity_history.dart`) keeps track of a list of Entries. This serves as the user's emissions history, and is integrated with Isar so that the user's data is persisted. 

### Activity Log View
The Activity Log View (found at `./lib/views/activity_log_view.dart`) displays the user's Activity History to them. It gets all of the data it needs through an ActivityProvider so that any changes made to an entry will automatically update in the history.

### Entry View
The Entry View (found at `./lib/views/entry_view.dart`) allows the user to input information about an activity. This sends an Emission Factor object to the Climatiq API and returns an estimate of the carbon emissions associated with that activity. 
This view also keeps track of all of the information stored in an Entry so that the user can return to, view, and edit any previous activities that they entered.

## Sending and retreving data from the Climatiq API
We created a data structure called an EmissionFactor to send data to the Climatiq API, and a data structure called an EmissionEstimate to retrieve data from the API.

### Sending Data: Emission Factors
In general, Climatiq requires the following information to be sent to its servers before it can send data back:
- An ID that tells it what type of emissions it's calculating. Each activity's id is found in the API docs, not determined by us
- A Data Version that that tells Climatiq what version of their database's data to use for calculations
- One or more amounts, usually represented by doubles, that tells Climatiq how much/often/many of that activity to calculate
- Units of measurement for those amounts. This varies depending on the amount type.

The Emission Factor data structure (found in the `./lib/models/emission_factors/base_emission_factors/` folder) keeps track of all of the data that the API needs to be able to estimate an activity's carbon emissions. There are 3 abstract super classes that all Emission Factors are built from: `EmissionFactor`, `MoneyEmissionFactor`, and `WeightEmissionFactor`.
- `EmissionFactor`is an abstract super class for all Emission Factors. It keeps track of: 
    - `String` to represent an activity's id
    - `int` to represent the data version
    - `EmissionCategory`: an enum to represent the overall category of emissions (this is not sent to Climatiq. It's used to make tracking a user's emission types easier).
- `MoneyEmissionFactor` is an abstract class that extends EmissionFactor. It is used for any Emission Factors that use only money to calculate their emissions. It keeps track of:
    - `double` to represent the amount of money spent
    - `MoneyUnit`: an enum to represent the type of currency (USD, EUR, etc.)
- `WeightEmissionFactor` is an abstract class that extends EmissionFactor. It is used for any Emission Factors that use only weight to calculate their emissions. It keeps track of:
    - `weight` to represent the amount of money spent
    - `WeightUnit`: an enum to represent the units of measurement for the weight (lb, g, ton, etc.)

Most non-abstract emission factors (found in the `./lib/models/emission_factors/base_emission_factors/` folder) are subclasses of `MoneyEmissionFactor`s or `WeightEmissionFactor`s because they don't need to track any other data. However, some emission factors use `EmissionFactor` as their direct super class because they require a different combination of data. The full list is below:
- The following extend EmissionFactor:
    - `ClothingEmissions` - calculates some clothing emissions based on money and calculates other clothing emissions based on weight. This is due to how the API handles different types of clothing.
    - `EnergyEmissions` - calculates emissions based on volume
    - `TravelEmissions` - calculates emissions based on distance and number of passengers
- The following extend MoneyEmissionFactor (all factors are calculated based on money alone):
    - `FoodEmissions`
    - `FurnitureEmissions`
    - `PersonalCareEmissions`
- The following extend WeightEmissionFactor (all factors are calculated based on weight alone):
    - `FoodWasteEmissions`
    - `GeneralWasteEmissions`
    - `ElectricalWasteEmissions`

By creating any of the non-abstract subclasses of `EmissionFactor`, we have all the data we need to send to the API.

### Other Emissions Data
In the `./lib/models/emission_data/` folder, there are 2 extra files that are used to help with API calls and displaying options to the user. 
- `emission_data_enums.dart` contains several helper enums that are used to display dropdown lists of options to the user. `EmissionCategory` represents all of the available emission categories, `MoneyUnit` represents the available currency types, `WeightUnit` represents the available units of measurement for weight, and `DistanceUnit` represents the available units of measurement for distance.
- `emission_subtypes.dart` contains several Maps to represent the available subtypes for each emission category. Maps are used here because each subtype requires a 'friendly name' to display to the user, like 'Beef', and an id to send to the API, like 'consumer_goods-type_meat_products_beef'. This greatly reduced the number of switch statements and named constructors with reused code that I had to write when creating the subclasses of `EmissionFactor`.

### Retrieving Data: Emission Estimate
Emission Estimates (found at `./lib/climatiq_api/emission_estimate`) are the objects created from the JSON data returned from the API. Each emission estimate keeps track of:
- `double` to represent the amount of co2 emissions
- `String` to represent the units of measurement for the co2 emissions. With the current implementation of calling the API, this will always be kg. This was left as a field rather than a constant in case of bugs or a need to change the implementation.