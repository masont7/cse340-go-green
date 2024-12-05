import 'package:flutter/material.dart';
import 'package:go_green/providers/activity_provider.dart';
import 'package:go_green/views/entry_view.dart';
import 'package:go_green/models/entry.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// A stateless widget that displays a list of activity log entries.
/// Allows navigation to view or edit entries.
class ActivityLogView extends StatefulWidget {
  const ActivityLogView({super.key});

  @override
  ActivityLogViewState createState() => ActivityLogViewState();
}

class ActivityLogViewState extends State<ActivityLogView> {
  String _sortOption = 'Most Recent'; // default sorting
  int _currentIndex = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Background gradient decoration for the entire screen
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color.fromARGB(255, 242, 232, 207), Color.fromARGB(255, 242, 232, 207)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: <Widget>[
            const SizedBox(height: 50,),
            // Sorting Dropdown
            Padding(
              padding: const EdgeInsets.all(16),
              child: DropdownButton<String>(
                value: _sortOption,
                items: [
                  'Most Recent',
                  'Least Recent',
                  'Most CO2',
                  'Least CO2',
                ].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _sortOption = newValue ?? 'Most Recent';
                  });
                },
                dropdownColor: const Color.fromARGB(255, 224, 214, 186),
                style: const TextStyle(color: Color(0xFF386641)),
              ),
            ),
            Expanded(
  child: Stack(
    children: [
      Positioned(
        top: -40.0, // Shifts the content up by 40 pixels
        left: 0,
        right: 0,
        child: SizedBox(
          height: MediaQuery.of(context).size.height, // Constrain height
          child: Consumer<ActivityProvider>(
            builder: (context, activityProvider, child) {
              List<Entry> entries = activityProvider.activityHistory.entries;

                          // Sorting entries based on selected option
                          if (_sortOption == 'Most Recent') {
                            entries.sort((a, b) => b.emissionsDate.compareTo(a.emissionsDate));
                          } else if (_sortOption == 'Least Recent') {
                            entries.sort((a, b) => a.emissionsDate.compareTo(b.emissionsDate));
                          } else if (_sortOption == 'Most CO2') {
                            entries.sort((a, b) => b.co2.compareTo(a.co2));
                          } else if (_sortOption == 'Least CO2') {
                            entries.sort((a, b) => a.co2.compareTo(b.co2));
                          }

                          // all the entries
                          return ListView.builder(
                            itemCount: entries.length,
                            itemBuilder: (context, index) {
                              return _createListElementForEntry(context, entries[index]);
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      // The bottom navigation bar of the Scaffold.
    bottomNavigationBar: Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF2E8CF), //background color
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      // The child of the Container widget.
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });

          if (index == 2) {
            Navigator.pushNamed(context, '/location'); // to map
          } else if (index == 0) {
            Navigator.pushNamed(context, '/'); // to home page
          }
        },
        backgroundColor: const Color(0xFFF2E8CF),
        selectedItemColor: const Color(0xFFBC4749),
        unselectedItemColor: const Color(0xFF386641),
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        items: const [
          // The Home BottomNavigationBarItem.
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          // The History BottomNavigationBarItem.
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
          // The Map BottomNavigationBarItem.
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Map',
          ),
        ],
      ),
    )
    );
  }

  /// Creates a styled ListTile widget to display individual activity entry details.
  Widget _createListElementForEntry(BuildContext context, Entry entry) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 5,
        shadowColor: Colors.black,
        child: ListTile(
          tileColor: const Color.fromARGB(255, 234, 224, 198),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text(
            '${entry.category} - ${entry.subtype}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF386641),
            ),
            semanticsLabel: entry.category.toString(),
          ),
          subtitle: Text(
            _formatDateTime(entry.emissionsDate),
            style: const TextStyle(color: Color(0xFF2B2B2B)),
            semanticsLabel: _formatDateTime(entry.emissionsDate),
          ),
          trailing: Text(
            'CO2: ${entry.co2.toStringAsFixed(2)} kg',
            style: const TextStyle(
              color: Color(0xFF064B8F),
              fontStyle: FontStyle.italic,
            ),
            semanticsLabel: 'CO2 emissions: ${entry.co2.toStringAsFixed(2)} kg',
          ),
          onTap: () => _navigateToEntry(context, entry), // Navigates to EntryView for editing
        ),
      ),
    );
  }

  /// Navigates to EntryView to edit or add an activity entry. After returning, it upserts the entry into the provider.
  Future<void> _navigateToEntry(BuildContext context, Entry entry) async {
    // Navigate to EntryView, where user can edit the entry
    final newEntry = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EntryView(curEntry: entry)),
    );

    // Ensure that context is still valid after the navigation
    if (!context.mounted) return;

    // If an updated entry is returned, upsert it into the activity provider
    if (newEntry != null) {
      Provider.of<ActivityProvider>(context, listen: false).upsertEntry(newEntry);
    }
  }

  /// Helper method to format a DateTime as a readable string for display.
  String _formatDateTime(DateTime when) {
    return DateFormat.yMd().add_jm().format(when);
  }
}