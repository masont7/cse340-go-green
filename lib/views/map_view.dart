// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:go_green/models/recycling_center.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_green/models/recycling_center_db.dart';
import 'package:go_green/providers/position_provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';

// MapView is a StatefulWidget that displays a map with recycling centers and second hand stores near the user's location.
class MapView extends StatefulWidget {
  // The PositionProvider instance that provides the user's current location.
  final PositionProvider positionProvider;
  // The RecyclingCentersDB instance that provides the recycling centers and second hand stores.
  final RecyclingCentersDB recyclingCenters;

  const MapView({
    required this.positionProvider,
    required this.recyclingCenters,
    super.key,
  });

  @override
  MapViewState createState() => MapViewState();
}

// MapViewState is the state of the MapView widget.
class MapViewState extends State<MapView> {
  // The index of the current page in the BottomNavigationBar.
  int _currentIndex = 2;

  late final PositionProvider positionProvider;
  late final RecyclingCentersDB recyclingCenters;

  // The stream of the user's current location.
  final _positionStream = const LocationMarkerDataStreamFactory().fromGeolocatorPositionStream(
    stream: Geolocator.getPositionStream(
      // The location settings for the Geolocator.
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        distanceFilter: 50,
        timeLimit: Duration(minutes: 1),
      ),
    ),
  );

  @override
  // Initializes the state of the widget.
  void initState() {
    super.initState();
    positionProvider = widget.positionProvider;
    recyclingCenters = widget.recyclingCenters;
  }

 @override
 // Builds the widget.
Widget build(BuildContext context) {
  return Scaffold(
    // The background color of the Scaffold.
    backgroundColor: const Color(0xFFF2E8CF),
    body: SafeArea(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Text(
              // The title of the page.
              'Recycling Centers and Second Hand Stores Near Me',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF386641),
              ),
            ),
          ),
          Expanded(
            // The child of the Expanded widget.
            child: StreamBuilder<Position>(
              // The stream of the user's current location.
              stream: Geolocator.getPositionStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting || !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                } else {
                  final position = snapshot.data!;
                 return SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(
                    height: 400, // Fixed height for the map
                    child: Semantics(
                      label: 'Map showing recycling centers and second-hand stores near you.',
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter: LatLng(position.latitude, position.longitude),
                          initialZoom: 15,
                          maxZoom: 19,
                          minZoom: 5,
                        ),
                        children: [
                          mapBoxOverlay(),
                          // The location marker layer.
                          markerWithClusters(context),
                          // The current location layer.
                          CurrentLocationLayer(
                            positionStream: _positionStream,
                          ),
                          mapBoxAttribution(),
                        ],
                      ),
                    ),
                  ),
                        const SizedBox(height: 20),
                       Center(
          child: Column(
            mainAxisSize: MainAxisSize.min, // Adjusts to the size of its children
            children: [
              const Text(
                'Unsure of how to dispose of something?',
                textAlign: TextAlign.center, // Centers the text within its box
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF386641),
                ),
              ),
          const SizedBox(height: 16), // Adds space between text and button
          Semantics(
                  label: 'Click here for more information on how to dispose of things.',
                  button: true, // Makes the button accessible as a button
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF386641), // Button color
                      padding: const EdgeInsets.all(16),
                    ),
            onPressed: () async {
              const url = 'https://seattle.gov/utilities/your-services/collection-and-disposal/where-does-it-go#/a-z';
              if (await canLaunchUrl(Uri.parse(url))) {
                await launchUrl(Uri.parse(url));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Could not open the link")),
                );
              }
            },
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.search, color: Colors.white), // Search icon
                SizedBox(width: 8), // Space between icon and text
                Text(
                  'Click here',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white,
              ),
            ),
          ],
        ),
      ),
      ),
    ],
  ),
),

                        const SizedBox(height: 20),
                      ],
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    ),
    // The bottom navigation bar of the Scaffold.
    bottomNavigationBar: Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF2E8CF),
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

          if (index == 1) {
            Navigator.pushNamed(context, '/history');
          } else if (index == 0) {
            Navigator.pushNamed(context, '/');
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
    ),
  );
}

  // The TileLayer that displays the map.
  // Returns a TileLayer.
  TileLayer mapBoxOverlay() {
    // The TileLayer that displays the map.
    return TileLayer(
      urlTemplate:
          'https://api.mapbox.com/styles/v1/mapbox/light-v11/tiles/512/{z}/{x}/{y}@2x?access_token=pk.eyJ1IjoiYXZuaXJhbyIsImEiOiJjbTN4cHl4cmYxZ2xoMmxwdTEwdXM3YXdnIn0.KTv-MpYEgAi9Gf4VHS-Enw',
      userAgentPackageName: 'com.recycling.goGreen',
      tileProvider: CancellableNetworkTileProvider(),
    );
  }

  // The MarkerClusterLayerWidget that displays the recycling centers and second hand stores.
  // Returns a MarkerClusterLayerWidget.
  // The context of the widget.
  MarkerClusterLayerWidget markerWithClusters(BuildContext context) {
   
    return MarkerClusterLayerWidget(
      options: MarkerClusterLayerOptions(
        disableClusteringAtZoom: 18,
        size: const Size(40, 40),
        zoomToBoundsOnClick: false,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(50),
        maxZoom: 15,
        markers: recyclingCenters.all
            .map(
              (venue) => Marker(
                point: LatLng(venue.latitude, venue.longitude),
                child: locationButton(context, venue),
              ),
            )
            .toList(),
        builder: (context, markers) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Theme.of(context).colorScheme.secondary,
            ),
            child: Center(
              child: Text(
                markers.length.toString(),
                style: const TextStyle(
                  color: Color(0xFFF2E8CF),
                  decoration: TextDecoration.none,
                  fontSize: 20,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // The DefaultTextStyle that displays the map attribution.
  // Returns a DefaultTextStyle.
  DefaultTextStyle mapBoxAttribution() {
    return const DefaultTextStyle(
      style: TextStyle(fontSize: 15, color: Colors.black),
      child: RichAttributionWidget(
        attributions: [
          TextSourceAttribution('Mapbox, © OpenStreetMap'),
          TextSourceAttribution('Recycling Data from Google'),
        ],
      ),
    );
  }

  // The GestureDetector that displays the location button.
  // Returns a GestureDetector.
  GestureDetector locationButton(BuildContext context, RecyclingCenter recyclingCenter) {
    return GestureDetector(
    onTapDown: (tapDetails) => openPlacePage(context, tapDetails, recyclingCenter),
    child: const Icon(
      Icons.travel_explore, // tree icon
      size: 30.0, // size of the icon
      color: Color(0xFFBC4749), // red color
    ),
  );
  }

  // Opens the place page for the recycling center.
  void openPlacePage(
  BuildContext context,
  TapDownDetails tapDetails,
  RecyclingCenter recyclingCenter,
) {
  final offset = tapDetails.globalPosition;
  
  // Construct the Google Maps URL using the recycling center's latitude and longitude.
  final googleMapsUrl =
      'https://www.google.com/maps/search/?api=1&query=${recyclingCenter.latitude},${recyclingCenter.longitude}';
  
  // The menu items for the recycling center.
  List<PopupMenuEntry<int>> menu = [];
  
  // The clickable name of the recycling center.
  menu.add(PopupMenuItem(
    value: 1,
    child: InkWell(
      onTap: () async {
        if (await canLaunchUrl(Uri.parse(googleMapsUrl))) {
          await launchUrl(Uri.parse(googleMapsUrl));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Could not open Google Maps")),
          );
        }
      },
      child: Text(
        recyclingCenter.name,
        style: const TextStyle(
          fontSize: 15,
          color: Color(0xFF386641),
          decoration: TextDecoration.underline, // Makes the text look like a link.
        ),
        textAlign: TextAlign.center,
      ),
    ),
  ));
  
  menu.add(const PopupMenuDivider(height: 2));

  // Add other menu items, like the recycling center's website if applicable.
  var website = recyclingCenter.url;
  if (website.isNotEmpty) {
    menu.add(
      PopupMenuItem(
        onTap: () async {
          if (await canLaunchUrl(Uri.parse(website))) {
            await launchUrl(Uri.parse(website));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Could not open the website")),
            );
          }
        },
        child: const Text(
          'Visit Website',
          style: TextStyle(fontSize: 15, color: Color(0xFF386641)),
        ),
      ),
    );
  }

  // Show the popup menu at the tap position.
  showMenu(
    context: context,
    position: RelativeRect.fromLTRB(offset.dx, offset.dy, offset.dx + 1, offset.dy + 1),
    items: menu,
  );
}
}