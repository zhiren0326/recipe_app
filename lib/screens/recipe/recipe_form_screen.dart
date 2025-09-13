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

class _RecipeFormScreenState extends State<RecipeFormScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final RecipeService _recipeService = RecipeService();
  final AuthService _authService = AuthService();
  final ImagePicker _imagePicker = ImagePicker();

  // Animation Controllers
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late AnimationController _fabAnimationController;

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
    _initializeAnimations();
    _initializeControllers();
    _loadRecipeTypes();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _animationController.forward();
    _fabAnimationController.forward();
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

      if (recipe.imageUrl != null && recipe.imageUrl!.startsWith('data:image')) {
        _base64Image = recipe.imageUrl;
      }

      for (String ingredient in recipe.ingredients) {
        _ingredientControllers.add(TextEditingController(text: ingredient));
      }

      for (String step in recipe.steps) {
        _stepControllers.add(TextEditingController(text: step));
      }
    } else {
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

  Future<String?> _convertImageToBase64(File imageFile) async {
    try {
      setState(() => _isProcessingImage = true);

      final bytes = await imageFile.readAsBytes();
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

      final base64String = base64Encode(bytes);
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

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 70,
      );

      if (pickedFile != null) {
        final file = File(pickedFile.path);
        setState(() {
          _selectedImage = file;
        });

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
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Add Recipe Photo',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildImageOption(
                      icon: Icons.camera_alt_rounded,
                      label: 'Camera',
                      color: const Color(0xFF6C63FF),
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.camera);
                      },
                    ),
                    _buildImageOption(
                      icon: Icons.photo_library_rounded,
                      label: 'Gallery',
                      color: const Color(0xFF4ECDC4),
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.gallery);
                      },
                    ),
                    if (_selectedImage != null || _base64Image != null)
                      _buildImageOption(
                        icon: Icons.delete_rounded,
                        label: 'Remove',
                        color: Colors.red,
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
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildImageOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 32,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _fabAnimationController.dispose();
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
          backgroundColor: const Color(0xFFF8F9FA),
          appBar: _buildAppBar(),
          body: _isLoading
              ? Center(
            child: CircularProgressIndicator(
              color: AppColors.primaryColor,
            ),
          )
              : FadeTransition(
            opacity: _fadeAnimation,
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    _buildHeroSection(),
                    Padding(
                      padding: ResponsiveController.padding(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ResponsiveSpacing(height: 30),
                          _buildImageSection(),
                          ResponsiveSpacing(height: 24),
                          _buildBasicInfoSection(),
                          ResponsiveSpacing(height: 24),
                          _buildRecipeDetailsSection(),
                          ResponsiveSpacing(height: 24),
                          _buildIngredientsSection(),
                          ResponsiveSpacing(height: 24),
                          _buildStepsSection(),
                          ResponsiveSpacing(height: 32),
                          _buildSaveButton(),
                          ResponsiveSpacing(height: 40),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          floatingActionButton: ScaleTransition(
            scale: _fabAnimationController,
            child: FloatingActionButton.extended(
              onPressed: _isSaving ? null : _saveRecipe,
              backgroundColor: AppColors.primaryColor,
              icon: _isSaving
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
                  : const Icon(Icons.save_rounded, color: Colors.white),
              label: Text(
                _isSaving
                    ? 'Saving...'
                    : (widget.recipe != null ? 'Update' : 'Create'),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              widget.recipe != null ? Icons.edit_rounded : Icons.add_rounded,
              color: AppColors.primaryColor,
              size: ResponsiveController.iconSize(24),
            ),
          ),
          ResponsiveSpacing(width: 12),
          ResponsiveText(
            widget.recipe != null ? 'Edit Recipe' : 'New Recipe',
            baseSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    final user = _authService.currentUser;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryColor.withOpacity(0.1),
            AppColors.primaryColor.withOpacity(0.05),
          ],
        ),
      ),
      child: Padding(
        padding: ResponsiveController.padding(all: 30),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryColor.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(
                widget.recipe != null ? Icons.edit_document : Icons.restaurant_menu_rounded,
                size: 40,
                color: AppColors.primaryColor,
              ),
            ),
            ResponsiveSpacing(height: 20),
            ResponsiveText(
              widget.recipe != null ? 'Editing Recipe' : 'Creating New Recipe',
              baseSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            ResponsiveSpacing(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: AppColors.primaryColor.withOpacity(0.2),
                    child: Icon(
                      Icons.person,
                      size: 14,
                      color: AppColors.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'By ${user?.displayName ?? user?.email ?? 'Unknown User'}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: ResponsiveController.padding(all: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.image_rounded,
                  color: AppColors.primaryColor,
                  size: ResponsiveController.iconSize(20),
                ),
                ResponsiveSpacing(width: 8),
                ResponsiveText(
                  '📸 Recipe Photo',
                  baseSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ],
            ),
            ResponsiveSpacing(height: 20),
            InkWell(
              onTap: _showImageSourceDialog,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                height: ResponsiveController.height(25),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.grey[100]!,
                      Colors.grey[50]!,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primaryColor.withOpacity(0.2),
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
                      ResponsiveSpacing(height: 12),
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
                  borderRadius: BorderRadius.circular(18),
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
                        top: 12,
                        right: 12,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.edit_rounded,
                              color: Colors.white,
                              size: 20,
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
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryColor.withOpacity(0.05),
            AppColors.primaryColor.withOpacity(0.1),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.add_a_photo_rounded,
              size: 40,
              color: AppColors.primaryColor,
            ),
          ),
          ResponsiveSpacing(height: 16),
          ResponsiveText(
            'Tap to Add Photo',
            baseSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryColor,
          ),
          ResponsiveSpacing(height: 4),
          ResponsiveText(
            'Camera or Gallery',
            baseSize: 12,
            color: Colors.grey[600],
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: ResponsiveController.padding(all: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: const Color(0xFF6C63FF),
                  size: ResponsiveController.iconSize(20),
                ),
                ResponsiveSpacing(width: 8),
                ResponsiveText(
                  '📝 Basic Information',
                  baseSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ],
            ),
            ResponsiveSpacing(height: 20),
            _buildModernTextField(
              controller: _nameController,
              label: 'Recipe Name',
              icon: Icons.restaurant_menu,
              color: const Color(0xFF6C63FF),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter recipe name';
                }
                return null;
              },
            ),
            ResponsiveSpacing(height: 16),
            _buildModernDropdown(),
            ResponsiveSpacing(height: 16),
            _buildModernTextField(
              controller: _descriptionController,
              label: 'Description',
              icon: Icons.description_rounded,
              color: const Color(0xFFFF6B6B),
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

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color color,
    int maxLines = 1,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: const TextStyle(fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[600]),
        prefixIcon: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 20,
            color: color,
          ),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: color,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Colors.red,
            width: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildModernDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedTypeId,
      decoration: InputDecoration(
        labelText: 'Recipe Type',
        labelStyle: TextStyle(color: Colors.grey[600]),
        prefixIcon: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF4ECDC4).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.category_rounded,
            size: 20,
            color: Color(0xFF4ECDC4),
          ),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xFF4ECDC4),
            width: 2,
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
    );
  }

  Widget _buildRecipeDetailsSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: ResponsiveController.padding(all: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.settings_rounded,
                  color: const Color(0xFFFFD93D),
                  size: ResponsiveController.iconSize(20),
                ),
                ResponsiveSpacing(width: 8),
                ResponsiveText(
                  '⚙️ Recipe Details',
                  baseSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ],
            ),
            ResponsiveSpacing(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildModernTextField(
                    controller: _prepTimeController,
                    label: 'Prep (min)',
                    icon: Icons.timer_rounded,
                    color: const Color(0xFF6C63FF),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildModernTextField(
                    controller: _cookTimeController,
                    label: 'Cook (min)',
                    icon: Icons.local_fire_department_rounded,
                    color: const Color(0xFFFF6B6B),
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
                  child: _buildModernTextField(
                    controller: _servingsController,
                    label: 'Servings',
                    icon: Icons.people_rounded,
                    color: const Color(0xFF4ECDC4),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDifficultySelector(),
                ),
              ],
            ),
            ResponsiveSpacing(height: 20),
            _buildRatingSelector(),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultySelector() {
    final difficulties = ['Easy', 'Medium', 'Hard'];
    final colors = {
      'Easy': Colors.green,
      'Medium': Colors.orange,
      'Hard': Colors.red,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Difficulty',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: difficulties.map((diff) {
            final isSelected = _selectedDifficulty == diff;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedDifficulty = diff),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colors[diff]!.withOpacity(0.1)
                        : Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? colors[diff]!
                          : Colors.grey[300]!,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      diff,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? colors[diff] : Colors.grey[600],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRatingSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.star_rounded,
              color: Colors.amber,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Initial Rating: ${_rating.toStringAsFixed(1)}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Colors.amber,
            inactiveTrackColor: Colors.amber.withOpacity(0.2),
            thumbColor: Colors.amber,
            overlayColor: Colors.amber.withOpacity(0.3),
            trackHeight: 6,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
          ),
          child: Slider(
            value: _rating,
            min: 1.0,
            max: 5.0,
            divisions: 8,
            onChanged: (value) => setState(() => _rating = value),
          ),
        ),
      ],
    );
  }

  Widget _buildIngredientsSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: ResponsiveController.padding(all: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.shopping_cart_rounded,
                      color: const Color(0xFF6C63FF),
                      size: ResponsiveController.iconSize(20),
                    ),
                    ResponsiveSpacing(width: 8),
                    ResponsiveText(
                      '🥘 Ingredients',
                      baseSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ],
                ),
                IconButton(
                  onPressed: _addIngredient,
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C63FF).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: Color(0xFF6C63FF),
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            ResponsiveSpacing(height: 16),
            ...List.generate(_ingredientControllers.length, (index) {
              return _buildListItem(
                controller: _ingredientControllers[index],
                index: index,
                hint: 'Enter ingredient',
                color: const Color(0xFF6C63FF),
                onRemove: _ingredientControllers.length > 1
                    ? () => _removeIngredient(index)
                    : null,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildStepsSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: ResponsiveController.padding(all: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.format_list_numbered_rounded,
                      color: const Color(0xFF4ECDC4),
                      size: ResponsiveController.iconSize(20),
                    ),
                    ResponsiveSpacing(width: 8),
                    ResponsiveText(
                      '📋 Instructions',
                      baseSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ],
                ),
                IconButton(
                  onPressed: _addStep,
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4ECDC4).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: Color(0xFF4ECDC4),
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            ResponsiveSpacing(height: 16),
            ...List.generate(_stepControllers.length, (index) {
              return _buildListItem(
                controller: _stepControllers[index],
                index: index,
                hint: 'Enter step',
                color: const Color(0xFF4ECDC4),
                maxLines: 2,
                onRemove: _stepControllers.length > 1
                    ? () => _removeStep(index)
                    : null,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildListItem({
    required TextEditingController controller,
    required int index,
    required String hint,
    required Color color,
    int maxLines = 1,
    VoidCallback? onRemove,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color,
                  color.withOpacity(0.8),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              controller: controller,
              maxLines: maxLines,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: Colors.grey[400]),
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: color.withOpacity(0.5),
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          if (onRemove != null)
            IconButton(
              onPressed: onRemove,
              icon: Icon(
                Icons.remove_circle,
                color: Colors.red.withOpacity(0.7),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryColor,
            AppColors.primaryColor.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: _isSaving ? null : _saveRecipe,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: _isSaving
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        )
            : const Icon(Icons.save_rounded, color: Colors.white),
        label: Text(
          _isSaving
              ? 'Saving...'
              : (widget.recipe != null ? 'Update Recipe' : 'Create Recipe'),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}