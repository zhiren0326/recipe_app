// screens/profile/location_picker_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../../utils/constants.dart';
import '../../utils/responsive_controller.dart';

class LocationPickerScreen extends StatefulWidget {
  final LatLng? initialLocation;
  final String? initialAddress;

  const LocationPickerScreen({
    Key? key,
    this.initialLocation,
    this.initialAddress,
  }) : super(key: key);

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  late final MapController _mapController;
  late final TextEditingController _searchController;
  final FocusNode _searchFocusNode = FocusNode();

  LatLng? _selectedLocation;
  String _selectedAddress = '';
  bool _isLoadingAddress = false;
  bool _isLoadingLocation = false;
  bool _isSearching = false;
  bool _showSearchField = false;

  // Search related
  List<Map<String, dynamic>> _searchSuggestions = [];
  bool _showSuggestions = false;
  Timer? _debounceTimer;

  // Default location for Malaysia (Kuala Lumpur)
  static const LatLng _defaultLocation = LatLng(3.1390, 101.6869);
  static const String _defaultAddress = 'Kuala Lumpur, Malaysia';

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _searchController = TextEditingController();

    if (widget.initialLocation != null) {
      _selectedLocation = widget.initialLocation;
      _selectedAddress = widget.initialAddress ?? '';
    } else {
      // Set default to Malaysia
      _selectedLocation = _defaultLocation;
      _selectedAddress = _defaultAddress;
      // Try to get current location if in Malaysia or nearby
      _getCurrentLocation();
    }

    _searchController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(() {
      if (!_searchFocusNode.hasFocus) {
        setState(() {
          _showSuggestions = false;
        });
      }
    });
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    final query = _searchController.text.trim();

    if (query.isEmpty || query.length < 2) {
      setState(() {
        _searchSuggestions = [];
        _showSuggestions = false;
      });
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _searchLocations(query);
    });
  }

  Future<void> _searchLocations(String query) async {
    setState(() {
      _isSearching = true;
    });

    try {
      // Add Malaysia bias to search
      final searchQuery = query.contains('Malaysia') ? query : '$query, Malaysia';

      final uri = Uri.parse(
          'https://nominatim.openstreetmap.org/search'
              '?q=${Uri.encodeComponent(searchQuery)}'
              '&format=json'
              '&limit=5'
              '&addressdetails=1'
              '&countrycodes=MY' // Prioritize Malaysian results
      );

      final response = await http.get(
        uri,
        headers: {'User-Agent': 'RecipeApp/1.0'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        // If no Malaysian results, search globally
        List<dynamic> finalData = data;
        if (data.isEmpty) {
          final globalUri = Uri.parse(
              'https://nominatim.openstreetmap.org/search'
                  '?q=${Uri.encodeComponent(query)}'
                  '&format=json'
                  '&limit=5'
                  '&addressdetails=1'
          );

          final globalResponse = await http.get(
            globalUri,
            headers: {'User-Agent': 'RecipeApp/1.0'},
          );

          if (globalResponse.statusCode == 200) {
            finalData = json.decode(globalResponse.body);
          }
        }

        setState(() {
          _searchSuggestions = finalData.map((item) {
            String displayName = '';
            if (item['address'] != null) {
              final address = item['address'];
              List<String> parts = [];

              if (address['city'] != null) {
                parts.add(address['city']);
              } else if (address['town'] != null) {
                parts.add(address['town']);
              } else if (address['village'] != null) {
                parts.add(address['village']);
              }

              if (address['state'] != null) {
                parts.add(address['state']);
              }

              if (address['country'] != null) {
                parts.add(address['country']);
              }

              displayName = parts.join(', ');
            }

            return {
              'display_name': displayName.isNotEmpty ? displayName : item['display_name'],
              'lat': double.parse(item['lat']),
              'lon': double.parse(item['lon']),
            };
          }).toList();

          _showSuggestions = _searchSuggestions.isNotEmpty;
          _isSearching = false;
        });
      }
    } catch (e) {
      print('Error searching locations: $e');
      setState(() {
        _searchSuggestions = [];
        _showSuggestions = false;
        _isSearching = false;
      });
    }
  }

  void _selectSearchResult(Map<String, dynamic> result) {
    final location = LatLng(result['lat'], result['lon']);

    setState(() {
      _selectedLocation = location;
      _selectedAddress = result['display_name'];
      _showSuggestions = false;
      _searchSuggestions = [];
      _showSearchField = false;
      _searchController.clear();
    });

    _mapController.move(location, 15);
    FocusScope.of(context).unfocus();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        _showLocationPermissionDialog();
        setState(() => _isLoadingLocation = false);
        return;
      }

      if (permission == LocationPermission.denied) {
        setState(() => _isLoadingLocation = false);
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final newLocation = LatLng(position.latitude, position.longitude);

      setState(() {
        _selectedLocation = newLocation;
        _isLoadingLocation = false;
      });

      _mapController.move(newLocation, 15);
      _getAddressFromLatLng(newLocation);

    } catch (e) {
      print('Error getting location: $e');
      setState(() => _isLoadingLocation = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not get current location: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _showLocationPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Permission'),
        content: const Text(
          'Location permission is permanently denied. Please enable it in your device settings to use current location.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Geolocator.openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _getAddressFromLatLng(LatLng location) async {
    setState(() {
      _isLoadingAddress = true;
      _selectedAddress = 'Loading address...';
    });

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        List<String> addressParts = [];

        if (place.locality != null && place.locality!.isNotEmpty) {
          addressParts.add(place.locality!);
        } else if (place.subAdministrativeArea != null &&
            place.subAdministrativeArea!.isNotEmpty) {
          addressParts.add(place.subAdministrativeArea!);
        }

        if (place.administrativeArea != null &&
            place.administrativeArea!.isNotEmpty) {
          addressParts.add(place.administrativeArea!);
        }

        if (place.country != null && place.country!.isNotEmpty) {
          addressParts.add(place.country!);
        }

        setState(() {
          _selectedAddress = addressParts.join(', ');
          _isLoadingAddress = false;
        });
      } else {
        setState(() {
          _selectedAddress = 'Location selected';
          _isLoadingAddress = false;
        });
      }
    } catch (e) {
      print('Error getting address: $e');
      setState(() {
        _selectedAddress = 'Could not get address';
        _isLoadingAddress = false;
      });
    }
  }

  void _onMapTap(TapPosition tapPosition, LatLng location) {
    setState(() {
      _selectedLocation = location;
    });
    _getAddressFromLatLng(location);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showSuggestions = false;
        });
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          title: ResponsiveText(
            'Select Location',
            baseSize: 20,
            fontWeight: FontWeight.bold,
          ),
          actions: [
            IconButton(
              icon: Icon(
                Icons.search,
                size: ResponsiveController.iconSize(24),
              ),
              onPressed: () {
                setState(() {
                  _showSearchField = !_showSearchField;
                  if (_showSearchField) {
                    _searchFocusNode.requestFocus();
                  } else {
                    _showSuggestions = false;
                    _searchController.clear();
                  }
                });
              },
              tooltip: 'Search location',
            ),
            IconButton(
              icon: Icon(
                Icons.my_location,
                size: ResponsiveController.iconSize(24),
              ),
              onPressed: _isLoadingLocation ? null : _getCurrentLocation,
              tooltip: 'Use current location',
            ),
          ],
        ),
        body: Stack(
          children: [
            // Map
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _selectedLocation ?? _defaultLocation,
                initialZoom: 13,
                onTap: _onMapTap,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.recipe.app',
                ),
                if (_selectedLocation != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _selectedLocation!,
                        width: 80,
                        height: 80,
                        child: Icon(
                          Icons.location_pin,
                          color: Colors.red,
                          size: ResponsiveController.iconSize(40),
                        ),
                      ),
                    ],
                  ),
              ],
            ),

            // Search field (animated)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              top: _showSearchField ? 10 : -100,
              left: 10,
              right: 10,
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    ResponsiveController.borderRadius(12),
                  ),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: ResponsiveController.padding(all: 8),
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        decoration: InputDecoration(
                          hintText: 'Search for a location...',
                          prefixIcon: Icon(
                            Icons.search,
                            size: ResponsiveController.iconSize(20),
                          ),
                          suffixIcon: _isSearching
                              ? Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.primaryColor,
                                ),
                              ),
                            ),
                          )
                              : _searchController.text.isNotEmpty
                              ? IconButton(
                            icon: Icon(
                              Icons.clear,
                              size: ResponsiveController.iconSize(20),
                            ),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchSuggestions = [];
                                _showSuggestions = false;
                              });
                            },
                          )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              ResponsiveController.borderRadius(8),
                            ),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                        ),
                        style: TextStyle(
                          fontSize: ResponsiveController.fontSize(16),
                        ),
                      ),
                    ),
                    if (_showSuggestions && _searchSuggestions.isNotEmpty)
                      Container(
                        constraints: BoxConstraints(
                          maxHeight: 200,
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _searchSuggestions.length,
                          itemBuilder: (context, index) {
                            final suggestion = _searchSuggestions[index];
                            return ListTile(
                              leading: Icon(
                                Icons.location_on,
                                size: ResponsiveController.iconSize(20),
                                color: AppColors.primaryColor,
                              ),
                              title: ResponsiveText(
                                suggestion['display_name'],
                                baseSize: 14,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onTap: () => _selectSearchResult(suggestion),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Location info card at the bottom-top
            Positioned(
              top: _showSearchField ? 80 : 10,
              left: 10,
              right: 10,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: _showSearchField ? 0 : 1,
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      ResponsiveController.borderRadius(12),
                    ),
                  ),
                  child: Padding(
                    padding: ResponsiveController.padding(all: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ResponsiveText(
                          'Selected Location',
                          baseSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                        ResponsiveSpacing(height: 4),
                        if (_isLoadingAddress)
                          Row(
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.primaryColor,
                                  ),
                                ),
                              ),
                              ResponsiveSpacing(width: 8),
                              ResponsiveText(
                                'Loading address...',
                                baseSize: 16,
                                color: Colors.grey[600],
                              ),
                            ],
                          )
                        else
                          ResponsiveText(
                            _selectedAddress.isNotEmpty
                                ? _selectedAddress
                                : 'Tap on the map to select location',
                            baseSize: 16,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Loading overlay
            if (_isLoadingLocation)
              Container(
                color: Colors.black26,
                child: Center(
                  child: Card(
                    child: Padding(
                      padding: ResponsiveController.padding(all: 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primaryColor,
                            ),
                          ),
                          ResponsiveSpacing(height: 16),
                          ResponsiveText(
                            'Getting current location...',
                            baseSize: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // Confirm button at the bottom
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: ElevatedButton(
                onPressed: _selectedLocation != null && !_isLoadingAddress
                    ? () {
                  Navigator.pop(context, {
                    'location': _selectedLocation,
                    'address': _selectedAddress,
                  });
                }
                    : null,
                style: ElevatedButton.styleFrom(
                  padding: ResponsiveController.padding(vertical: 16),
                  backgroundColor: AppColors.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      ResponsiveController.borderRadius(25),
                    ),
                  ),
                  elevation: 4,
                ),
                child: ResponsiveText(
                  'Confirm Location',
                  baseSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Instructions
            Positioned(
              bottom: 90,
              left: 20,
              right: 20,
              child: Container(
                padding: ResponsiveController.padding(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(
                    ResponsiveController.borderRadius(20),
                  ),
                ),
                child: ResponsiveText(
                  'Tap map to select or use search',
                  baseSize: 13,
                  color: Colors.white,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _mapController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }
}