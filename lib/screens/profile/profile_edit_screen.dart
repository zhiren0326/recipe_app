// screens/profile/profile_edit_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import '../../services/user_service.dart';
import '../../utils/constants.dart';
import '../../utils/responsive_controller.dart';
import 'location_picker_screen.dart';

class ProfileEditScreen extends StatefulWidget {
  final UserProfile userProfile;

  const ProfileEditScreen({
    Key? key,
    required this.userProfile,
  }) : super(key: key);

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final UserService _userService = UserService();

  late TextEditingController _displayNameController;
  late TextEditingController _bioController;
  late TextEditingController _phoneController;

  // Location variables
  String? _selectedLocationAddress;
  LatLng? _selectedLocationCoordinates;

  DateTime? _selectedDateOfBirth;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _displayNameController = TextEditingController(
      text: widget.userProfile.displayName ?? '',
    );
    _bioController = TextEditingController(
      text: widget.userProfile.bio ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.userProfile.phone ?? '',
    );

    // Initialize location from profile
    _selectedLocationAddress = widget.userProfile.location;

    // If you store coordinates in the user profile, initialize them here
    // For example:
    // if (widget.userProfile.latitude != null && widget.userProfile.longitude != null) {
    //   _selectedLocationCoordinates = LatLng(
    //     widget.userProfile.latitude!,
    //     widget.userProfile.longitude!,
    //   );
    // }

    _selectedDateOfBirth = widget.userProfile.dateOfBirth;
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _openLocationPicker() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => LocationPickerScreen(
          initialLocation: _selectedLocationCoordinates,
          initialAddress: _selectedLocationAddress,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedLocationCoordinates = result['location'] as LatLng;
        _selectedLocationAddress = result['address'] as String;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, deviceType, orientation) {
        return Scaffold(
          appBar: AppBar(
            title: ResponsiveText(
              'Edit Profile',
              baseSize: 20,
              fontWeight: FontWeight.bold,
            ),
            actions: [
              TextButton(
                onPressed: _isLoading ? null : _saveProfile,
                child: _isLoading
                    ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primaryColor,
                    ),
                  ),
                )
                    : ResponsiveText(
                  'Save',
                  baseSize: 16,
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          body: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Center(
                child: ResponsiveContainer(
                  padding: ResponsiveController.padding(all: 20),
                  maxWidth: ResponsiveController.containerWidth(maxWidth: 600),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPersonalInfoSection(),
                      ResponsiveSpacing(height: 40),
                      _buildSaveButton(),
                      ResponsiveSpacing(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPersonalInfoSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          ResponsiveController.borderRadius(12),
        ),
      ),
      child: Padding(
        padding: ResponsiveController.padding(all: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ResponsiveText(
              'Personal Information',
              baseSize: 18,
              fontWeight: FontWeight.bold,
            ),
            ResponsiveSpacing(height: 20),

            // Display Name
            _buildTextFormField(
              controller: _displayNameController,
              label: 'Display Name',
              icon: Icons.person_outline,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Display name is required';
                }
                return null;
              },
            ),
            ResponsiveSpacing(height: 16),

            // Bio
            _buildTextFormField(
              controller: _bioController,
              label: 'Bio',
              icon: Icons.info_outline,
              maxLines: 3,
              maxLength: 200,
            ),
            ResponsiveSpacing(height: 16),

            // Phone
            _buildTextFormField(
              controller: _phoneController,
              label: 'Phone Number',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s\(\)]')),
              ],
            ),
            ResponsiveSpacing(height: 16),

            // Date of Birth
            _buildDateField(),
            ResponsiveSpacing(height: 16),

            // Location with map picker
            _buildLocationPickerField(),
          ],
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
    int? maxLength,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      maxLength: maxLength,
      style: TextStyle(
        fontSize: ResponsiveController.fontSize(16),
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          icon,
          size: ResponsiveController.iconSize(20),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            ResponsiveController.borderRadius(8),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            ResponsiveController.borderRadius(8),
          ),
          borderSide: BorderSide(
            color: AppColors.primaryColor,
            width: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildDateField() {
    return InkWell(
      onTap: _selectDateOfBirth,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Date of Birth',
          prefixIcon: Icon(
            Icons.cake_outlined,
            size: ResponsiveController.iconSize(20),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(
              ResponsiveController.borderRadius(8),
            ),
          ),
        ),
        child: ResponsiveText(
          _selectedDateOfBirth != null
              ? '${_selectedDateOfBirth!.day}/${_selectedDateOfBirth!.month}/${_selectedDateOfBirth!.year}'
              : 'Select date of birth',
          baseSize: 16,
          color: _selectedDateOfBirth != null
              ? Colors.black87
              : Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildLocationPickerField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Location field with map icon
        InkWell(
          onTap: _openLocationPicker,
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: 'Location',
              prefixIcon: Icon(
                Icons.location_on_outlined,
                size: ResponsiveController.iconSize(20),
              ),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_selectedLocationAddress != null && _selectedLocationAddress!.isNotEmpty)
                    IconButton(
                      icon: Icon(
                        Icons.clear,
                        size: ResponsiveController.iconSize(20),
                        color: Colors.grey[600],
                      ),
                      onPressed: () {
                        setState(() {
                          _selectedLocationAddress = null;
                          _selectedLocationCoordinates = null;
                        });
                      },
                    ),
                  Icon(
                    Icons.map_outlined,
                    size: ResponsiveController.iconSize(20),
                    color: AppColors.primaryColor,
                  ),
                  ResponsiveSpacing(width: 12),
                ],
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  ResponsiveController.borderRadius(8),
                ),
              ),
            ),
            child: ResponsiveText(
              _selectedLocationAddress ?? 'Tap to select location on map',
              baseSize: 16,
              color: _selectedLocationAddress != null
                  ? Colors.black87
                  : Colors.grey[600],
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),

        // Optional: Show coordinates if location is selected
        if (_selectedLocationCoordinates != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Container(
              padding: ResponsiveController.padding(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(
                  ResponsiveController.borderRadius(6),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.gps_fixed,
                    size: ResponsiveController.iconSize(14),
                    color: Colors.grey[600],
                  ),
                  ResponsiveSpacing(width: 8),
                  Expanded(
                    child: ResponsiveText(
                      'Coordinates: ${_selectedLocationCoordinates!.latitude.toStringAsFixed(4)}, ${_selectedLocationCoordinates!.longitude.toStringAsFixed(4)}',
                      baseSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          padding: ResponsiveController.padding(vertical: 16),
          backgroundColor: AppColors.primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              ResponsiveController.borderRadius(8),
            ),
          ),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        )
            : ResponsiveText(
          'Save Changes',
          baseSize: 16,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _selectDateOfBirth() async {
    final initialDate = _selectedDateOfBirth ?? DateTime(2000);
    final firstDate = DateTime(1900);
    final lastDate = DateTime.now().subtract(const Duration(days: 365 * 13)); // At least 13 years old

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(firstDate)
          ? firstDate
          : initialDate.isAfter(lastDate)
          ? lastDate
          : initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate != null) {
      setState(() {
        _selectedDateOfBirth = selectedDate;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Update the user profile in Firestore using the current user's UID
      // Note: You may want to save both the address and coordinates
      await _userService.updateUserProfile(
        displayName: _displayNameController.text.trim(),
        bio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        dateOfBirth: _selectedDateOfBirth,
        location: _selectedLocationAddress,
        // If your UserService supports saving coordinates, uncomment these:
        // latitude: _selectedLocationCoordinates?.latitude,
        // longitude: _selectedLocationCoordinates?.longitude,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate successful update
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}