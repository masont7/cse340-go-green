# GoGreen
GoGreen is an app that allows users to track their carbon emissions based on activities and purchases they make during a day. It also displays recycling centers and second hand store locations in the Seattle Area which can be used to dispose of goods in a more sustainable fashion. 

# Data Design & Data Flow
There are two main parts of this app that store different data for the user: the activity log and the map. We also use a custom data structure called an Emission Factor to send the user's data to the Climatiq API to calculate their carbon emissions. 

## Displaying Recycling Centers to the User
We have a custom database of recycling centers and second-hand stores that we use to show the user nearby locations where they can dispose of goods in a more sustainable fashion. Currently, only locations in Seattle are supported.

### Recycling Center
Each Recycling Center object (found at `./lib/models/recycling_center.dart`) represents a location to drop off used items. This class keeps track of: 
- 2 `String`s: one for the name of the location, and one for the URL of the location's website
- `double`s for the latitute and longitude coordinates of the location

### Recycling Center Database
The Recycling Center Database (found at `./lib/models/recycling_center_db.dart`) contains a list of Recycling centers. This is the list that's used to display all available locations on the map. 

### Map View
The Map View (found at `./lib/views/map_view.dart`) shows users where they are on the map by getting their current location via the Geolocator package, and it uses the Recycling Center Database to show any nearby locations. The user's position is updated with a PositionProvider so that the user can see themselves move on the map in real time.

## Displaying Emissions Data to the User
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

