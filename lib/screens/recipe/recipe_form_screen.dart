// screens/recipe/recipe_form_screen.dart
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:recipe_app/screens/recipe/recipe_type.dart';
import '../../services/recipe_service.dart';
import '../../services/auth_service.dart';
import '../../utils/constants.dart';
import '../../utils/responsive_controller.dart';

class RecipeFormScreen extends StatefulWidget {
  final Recipe? recipe;

  const RecipeFormScreen({
    Key? key,
    this.recipe,
  }) : super(key: key);

  @override
  State<RecipeFormScreen> createState() => _RecipeFormScreenState();
}

class _RecipeFormScreenState extends State<RecipeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final RecipeService _recipeService = RecipeService();
  final AuthService _authService = AuthService();
  final ImagePicker _imagePicker = ImagePicker();

  // Form Controllers
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _prepTimeController;
  late TextEditingController _cookTimeController;
  late TextEditingController _servingsController;

  // Lists for ingredients and steps
  List<TextEditingController> _ingredientControllers = [];
  List<TextEditingController> _stepControllers = [];

  // Selected values
  String? _selectedTypeId;
  String? _selectedTypeName;
  String _selectedDifficulty = 'Medium';
  double _rating = 4.0;

  // Image handling
  File? _selectedImage;
  String? _base64Image;
  bool _isProcessingImage = false;

  List<RecipeType> _recipeTypes = [];
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadRecipeTypes();
  }

  void _initializeControllers() {
    final recipe = widget.recipe;

    _nameController = TextEditingController(text: recipe?.name ?? '');
    _descriptionController = TextEditingController(text: recipe?.description ?? '');
    _prepTimeController = TextEditingController(text: recipe?.preparationTime.toString() ?? '');
    _cookTimeController = TextEditingController(text: recipe?.cookingTime.toString() ?? '');
    _servingsController = TextEditingController(text: recipe?.servings.toString() ?? '');

    if (recipe != null) {
      _selectedTypeId = recipe.typeId;
      _selectedTypeName = recipe.typeName;
      _selectedDifficulty = recipe.difficulty;
      _rating = recipe.rating;

      // Load existing base64 image if it's not a URL
      if (recipe.imageUrl != null && recipe.imageUrl!.startsWith('data:image')) {
        _base64Image = recipe.imageUrl;
      }

      // Initialize ingredient controllers
      for (String ingredient in recipe.ingredients) {
        _ingredientControllers.add(TextEditingController(text: ingredient));
      }

      // Initialize step controllers
      for (String step in recipe.steps) {
        _stepControllers.add(TextEditingController(text: step));
      }
    } else {
      // Add one empty field for new recipe
      _ingredientControllers.add(TextEditingController());
      _stepControllers.add(TextEditingController());
    }
  }

  Future<void> _loadRecipeTypes() async {
    setState(() => _isLoading = true);
    try {
      await _recipeService.initialize();
      setState(() {
        _recipeTypes = _recipeService.getRecipeTypes();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading recipe types: $e')),
        );
      }
    }
  }

  // Convert image to base64
  Future<String?> _convertImageToBase64(File imageFile) async {
    try {
      setState(() => _isProcessingImage = true);

      // Read image bytes
      final bytes = await imageFile.readAsBytes();

      // Check file size (warn if over 500KB since Firestore docs have 1MB limit)
      final sizeInKB = bytes.length / 1024;
      if (sizeInKB > 500) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image is large. Consider taking a smaller photo for better performance.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }

      // Convert to base64
      final base64String = base64Encode(bytes);

      // Create data URL with proper MIME type
      final extension = imageFile.path.split('.').last.toLowerCase();
      final mimeType = extension == 'png' ? 'png' : 'jpeg';
      final dataUrl = 'data:image/$mimeType;base64,$base64String';

      setState(() {
        _base64Image = dataUrl;
        _isProcessingImage = false;
      });

      return dataUrl;
    } catch (e) {
      setState(() => _isProcessingImage = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error processing image: $e')),
        );
      }
      return null;
    }
  }

  // Image selection methods
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 800,  // Reduced from 1200 for smaller file size
        maxHeight: 800, // Reduced from 1200 for smaller file size
        imageQuality: 70, // Reduced from 85 for smaller file size
      );

      if (pickedFile != null) {
        final file = File(pickedFile.path);
        setState(() {
          _selectedImage = file;
        });

        // Convert to base64 immediately
        await _convertImageToBase64(file);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(ResponsiveController.borderRadius(20)),
        ),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: ResponsiveController.padding(all: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ResponsiveText(
                'Select Image Source',
                baseSize: 18,
                fontWeight: FontWeight.bold,
              ),
              ResponsiveSpacing(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildImageSourceOption(
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.camera);
                    },
                  ),
                  _buildImageSourceOption(
                    icon: Icons.photo_library,
                    label: 'Gallery',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                  if (_selectedImage != null || _base64Image != null)
                    _buildImageSourceOption(
                      icon: Icons.delete,
                      label: 'Remove',
                      color: AppColors.errorColor,
                      onTap: () {
                        Navigator.pop(context);
                        setState(() {
                          _selectedImage = null;
                          _base64Image = null;
                        });
                      },
                    ),
                ],
              ),
              ResponsiveSpacing(height: 10),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImageSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ResponsiveController.borderRadius(12)),
      child: Container(
        padding: ResponsiveController.padding(all: 16),
        child: Column(
          children: [
            Icon(
              icon,
              size: ResponsiveController.iconSize(32),
              color: color ?? AppColors.primaryColor,
            ),
            ResponsiveSpacing(height: 8),
            ResponsiveText(
              label,
              baseSize: 14,
              color: color ?? Colors.black87,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          ResponsiveController.borderRadius(12),
        ),
      ),
      child: Padding(
        padding: ResponsiveController.padding(all: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ResponsiveText(
              'Recipe Image',
              baseSize: 18,
              fontWeight: FontWeight.bold,
            ),
            ResponsiveSpacing(height: 16),
            InkWell(
              onTap: _showImageSourceDialog,
              borderRadius: BorderRadius.circular(ResponsiveController.borderRadius(12)),
              child: Container(
                height: ResponsiveController.height(25),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(
                    ResponsiveController.borderRadius(12),
                  ),
                  border: Border.all(
                    color: Colors.grey[300]!,
                    width: 2,
                  ),
                ),
                child: _isProcessingImage
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        color: AppColors.primaryColor,
                      ),
                      ResponsiveSpacing(height: 8),
                      ResponsiveText(
                        'Processing image...',
                        baseSize: 14,
                        color: Colors.grey[600],
                      ),
                    ],
                  ),
                )
                    : _base64Image != null
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(
                    ResponsiveController.borderRadius(10),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.memory(
                        base64Decode(_base64Image!.split(',').last),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildPlaceholderImage();
                        },
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: IconButton(
                            icon: Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: ResponsiveController.iconSize(20),
                            ),
                            onPressed: _showImageSourceDialog,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
                    : _buildPlaceholderImage(),
              ),
            ),
            ResponsiveSpacing(height: 12),
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: ResponsiveController.iconSize(16),
                  color: Colors.grey[600],
                ),
                ResponsiveSpacing(width: 8),
                Expanded(
                  child: ResponsiveText(
                    'Tap to add or change image (max 800x800px)',
                    baseSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_a_photo,
          size: ResponsiveController.iconSize(48),
          color: Colors.grey[400],
        ),
        ResponsiveSpacing(height: 12),
        ResponsiveText(
          'Add Recipe Image',
          baseSize: 16,
          color: Colors.grey[600],
        ),
        ResponsiveSpacing(height: 4),
        ResponsiveText(
          'Take a photo or select from gallery',
          baseSize: 12,
          color: Colors.grey[500],
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _prepTimeController.dispose();
    _cookTimeController.dispose();
    _servingsController.dispose();

    for (var controller in _ingredientControllers) {
      controller.dispose();
    }
    for (var controller in _stepControllers) {
      controller.dispose();
    }

    super.dispose();
  }

  void _addIngredient() {
    setState(() {
      _ingredientControllers.add(TextEditingController());
    });
  }

  void _removeIngredient(int index) {
    setState(() {
      _ingredientControllers[index].dispose();
      _ingredientControllers.removeAt(index);
    });
  }

  void _addStep() {
    setState(() {
      _stepControllers.add(TextEditingController());
    });
  }

  void _removeStep(int index) {
    setState(() {
      _stepControllers[index].dispose();
      _stepControllers.removeAt(index);
    });
  }

  Future<void> _saveRecipe() async {
    if (!_formKey.currentState!.validate()) return;

    final user = _authService.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to save recipes')),
      );
      return;
    }

    if (_selectedTypeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a recipe type')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Get non-empty ingredients and steps
      final ingredients = _ingredientControllers
          .map((c) => c.text.trim())
          .where((text) => text.isNotEmpty)
          .toList();

      final steps = _stepControllers
          .map((c) => c.text.trim())
          .where((text) => text.isNotEmpty)
          .toList();

      if (ingredients.isEmpty || steps.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add at least one ingredient and one step')),
        );
        setState(() => _isSaving = false);
        return;
      }

      // Use base64 image if available, otherwise use default
      String imageUrl = _base64Image ??
          (widget.recipe?.imageUrl ??
              'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500');

      final now = DateTime.now();
      final recipe = Recipe(
        id: widget.recipe?.id ?? _recipeService.generateNewId(),
        name: _nameController.text.trim(),
        typeId: _selectedTypeId!,
        typeName: _selectedTypeName!,
        description: _descriptionController.text.trim(),
        imageUrl: imageUrl,
        ingredients: ingredients,
        steps: steps,
        preparationTime: int.tryParse(_prepTimeController.text) ?? 15,
        cookingTime: int.tryParse(_cookTimeController.text) ?? 30,
        servings: int.tryParse(_servingsController.text) ?? 4,
        difficulty: _selectedDifficulty,
        rating: _rating,
        createdBy: user.uid,
        createdByName: user.displayName ?? user.email ?? 'Unknown User',
        createdAt: widget.recipe?.createdAt ?? now,
        updatedAt: now,
        firebaseId: widget.recipe?.firebaseId,
      );

      if (widget.recipe != null) {
        await _recipeService.updateRecipe(recipe);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Recipe updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        await _recipeService.addRecipe(recipe);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Recipe created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving recipe: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, deviceType, orientation) {
        return Scaffold(
          appBar: AppBar(
            title: ResponsiveText(
              widget.recipe != null ? 'Edit Recipe' : 'New Recipe',
              baseSize: 20,
              fontWeight: FontWeight.bold,
            ),
            actions: [
              if (!_isSaving)
                TextButton.icon(
                  onPressed: _saveRecipe,
                  icon: const Icon(Icons.save, color: Colors.white),
                  label: const Text(
                    'Save',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
            ],
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: ResponsiveController.padding(all: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User Info Display
                  _buildUserInfoCard(),
                  ResponsiveSpacing(height: 24),
                  _buildBasicInfoSection(),
                  ResponsiveSpacing(height: 24),
                  _buildImageSection(), // Image section
                  ResponsiveSpacing(height: 24),
                  _buildRecipeDetailsSection(),
                  ResponsiveSpacing(height: 24),
                  _buildIngredientsSection(),
                  ResponsiveSpacing(height: 24),
                  _buildStepsSection(),
                  ResponsiveSpacing(height: 32),
                  _buildSaveButton(),
                  ResponsiveSpacing(height: 32),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildUserInfoCard() {
    final user = _authService.currentUser;

    return Card(
      elevation: 1,
      color: AppColors.primaryColor.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          ResponsiveController.borderRadius(8),
        ),
      ),
      child: Padding(
        padding: ResponsiveController.padding(all: 16),
        child: Row(
          children: [
            CircleAvatar(
              radius: ResponsiveController.iconSize(20),
              backgroundColor: AppColors.primaryColor,
              child: Icon(
                Icons.person,
                size: ResponsiveController.iconSize(20),
                color: Colors.white,
              ),
            ),
            ResponsiveSpacing(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ResponsiveText(
                    'Recipe by: ${user?.displayName ?? user?.email ?? 'Unknown User'}',
                    baseSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  ResponsiveText(
                    widget.recipe != null ? 'Editing existing recipe' : 'Creating new recipe',
                    baseSize: 12,
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          ResponsiveController.borderRadius(12),
        ),
      ),
      child: Padding(
        padding: ResponsiveController.padding(all: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ResponsiveText(
              'Basic Information',
              baseSize: 18,
              fontWeight: FontWeight.bold,
            ),
            ResponsiveSpacing(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Recipe Name *',
                prefixIcon: const Icon(Icons.restaurant_menu),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    ResponsiveController.borderRadius(8),
                  ),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter recipe name';
                }
                return null;
              },
            ),
            ResponsiveSpacing(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedTypeId,
              decoration: InputDecoration(
                labelText: 'Recipe Type *',
                prefixIcon: const Icon(Icons.category),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    ResponsiveController.borderRadius(8),
                  ),
                ),
              ),
              items: _recipeTypes.map((type) {
                return DropdownMenuItem(
                  value: type.id,
                  child: Text(type.name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedTypeId = value;
                  _selectedTypeName = _recipeTypes
                      .firstWhere((t) => t.id == value)
                      .name;
                });
              },
            ),
            ResponsiveSpacing(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description *',
                prefixIcon: const Icon(Icons.description),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    ResponsiveController.borderRadius(8),
                  ),
                ),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter description';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipeDetailsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          ResponsiveController.borderRadius(12),
        ),
      ),
      child: Padding(
        padding: ResponsiveController.padding(all: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ResponsiveText(
              'Recipe Details',
              baseSize: 18,
              fontWeight: FontWeight.bold,
            ),
            ResponsiveSpacing(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _prepTimeController,
                    decoration: InputDecoration(
                      labelText: 'Prep Time (min)',
                      prefixIcon: const Icon(Icons.timer),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          ResponsiveController.borderRadius(8),
                        ),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _cookTimeController,
                    decoration: InputDecoration(
                      labelText: 'Cook Time (min)',
                      prefixIcon: const Icon(Icons.local_fire_department),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          ResponsiveController.borderRadius(8),
                        ),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
              ],
            ),
            ResponsiveSpacing(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _servingsController,
                    decoration: InputDecoration(
                      labelText: 'Servings',
                      prefixIcon: const Icon(Icons.people),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          ResponsiveController.borderRadius(8),
                        ),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedDifficulty,
                    isDense: true,
                    decoration: InputDecoration(
                      labelText: 'Difficulty',
                      prefixIcon: const Icon(Icons.speed),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          ResponsiveController.borderRadius(8),
                        ),
                      ),
                    ),
                    items: ['Easy', 'Medium', 'Hard'].map((difficulty) {
                      return DropdownMenuItem(
                        value: difficulty,
                        child: Text(
                          difficulty,
                          style: const TextStyle(fontSize: 12.5),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedDifficulty = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
            ResponsiveSpacing(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber),
                    const SizedBox(width: 8),
                    Text(
                      'Rating: ${_rating.toStringAsFixed(1)}',
                      style: TextStyle(
                        fontSize: ResponsiveController.fontSize(14),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _rating,
                  min: 1.0,
                  max: 5.0,
                  divisions: 8,
                  activeColor: Colors.amber,
                  onChanged: (value) {
                    setState(() {
                      _rating = value;
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIngredientsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          ResponsiveController.borderRadius(12),
        ),
      ),
      child: Padding(
        padding: ResponsiveController.padding(all: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ResponsiveText(
                  'Ingredients',
                  baseSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                IconButton(
                  icon: Icon(Icons.add_circle, color: AppColors.primaryColor),
                  onPressed: _addIngredient,
                ),
              ],
            ),
            ResponsiveSpacing(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _ingredientControllers.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontSize: ResponsiveController.fontSize(12),
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _ingredientControllers[index],
                          decoration: InputDecoration(
                            hintText: 'Enter ingredient',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                ResponsiveController.borderRadius(8),
                              ),
                            ),
                            contentPadding: ResponsiveController.padding(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ),
                      if (_ingredientControllers.length > 1)
                        IconButton(
                          icon: Icon(Icons.remove_circle, color: AppColors.errorColor),
                          onPressed: () => _removeIngredient(index),
                        ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          ResponsiveController.borderRadius(12),
        ),
      ),
      child: Padding(
        padding: ResponsiveController.padding(all: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ResponsiveText(
                  'Instructions',
                  baseSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                IconButton(
                  icon: Icon(Icons.add_circle, color: AppColors.primaryColor),
                  onPressed: _addStep,
                ),
              ],
            ),
            ResponsiveSpacing(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _stepControllers.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontSize: ResponsiveController.fontSize(12),
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _stepControllers[index],
                          decoration: InputDecoration(
                            hintText: 'Enter step',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                ResponsiveController.borderRadius(8),
                              ),
                            ),
                            contentPadding: ResponsiveController.padding(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          maxLines: 2,
                        ),
                      ),
                      if (_stepControllers.length > 1)
                        IconButton(
                          icon: Icon(Icons.remove_circle, color: AppColors.errorColor),
                          onPressed: () => _removeStep(index),
                        ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: _isSaving ? null : _saveRecipe,
        icon: _isSaving
            ? SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        )
            : const Icon(Icons.save),
        label: ResponsiveText(
          _isSaving
              ? 'Saving...'
              : (widget.recipe != null ? 'Update Recipe' : 'Create Recipe'),
          baseSize: 16,
          fontWeight: FontWeight.bold,
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              ResponsiveController.borderRadius(8),
            ),
          ),
        ),
      ),
    );
  }
}