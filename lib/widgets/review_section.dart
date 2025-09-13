// widgets/review_section.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import '../screens/review/review.dart';
import '../services/review_service.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';
import '../utils/responsive_controller.dart';

class ReviewSection extends StatefulWidget {
  final String recipeId;
  final String recipeOwnerId;

  const ReviewSection({
    Key? key,
    required this.recipeId,
    required this.recipeOwnerId,
  }) : super(key: key);

  @override
  State<ReviewSection> createState() => _ReviewSectionState();
}

class _ReviewSectionState extends State<ReviewSection> {
  final ReviewService _reviewService = ReviewService();
  final AuthService _authService = AuthService();
  final TextEditingController _commentController = TextEditingController();

  StreamSubscription<List<Review>>? _reviewsSubscription;
  List<Review> _reviews = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  double _userRating = 5.0;
  Review? _editingReview;
  Map<String, dynamic>? _ratingStats;

  @override
  void initState() {
    super.initState();
    _initializeReviews();
  }

  Future<void> _initializeReviews() async {
    setState(() => _isLoading = true);

    try {
      await _reviewService.initialize();

      // Subscribe to review stream for real-time updates
      _reviewsSubscription = _reviewService
          .getReviewsStream(widget.recipeId)
          .listen((reviews) {
        if (mounted) {
          setState(() {
            _reviews = reviews;
            _ratingStats = _reviewService.getRatingStatistics(widget.recipeId);
            _isLoading = false;
          });

          // Check if current user has already reviewed
          final user = _authService.currentUser;
          if (user != null) {
            Review? userReview;
            try {
              userReview = reviews.firstWhere(
                    (review) => review.userId == user.uid,
              );
            } catch (e) {
              userReview = null;
            }

            if (userReview != null && _editingReview == null) {
              setState(() {
                _editingReview = userReview;
                _userRating = userReview!.rating;
                _commentController.text = userReview.comment;
              });
            }
          }
        }
      }, onError: (error) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading reviews: $error'),
              backgroundColor: Colors.red,
            ),
          );
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error initializing reviews: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _reviewsSubscription?.cancel();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    final user = _authService.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to leave a review'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Don't allow recipe owner to review their own recipe
    if (user.uid == widget.recipeOwnerId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You cannot review your own recipe'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please write a comment'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      if (_editingReview != null) {
        // Update existing review
        await _reviewService.updateReview(
          review: _editingReview!,
          rating: _userRating,
          comment: _commentController.text.trim(),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Add new review
        await _reviewService.addReview(
          recipeId: widget.recipeId,
          rating: _userRating,
          comment: _commentController.text.trim(),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Clear form only if it's a new review
      if (_editingReview == null) {
        _commentController.clear();
        _userRating = 5.0;
      }

      // Reviews will update automatically via stream

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting review: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _deleteReview(Review review) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Review'),
        content: const Text('Are you sure you want to delete your review?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.errorColor,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _reviewService.deleteReview(review);

        setState(() {
          _editingReview = null;
          _commentController.clear();
          _userRating = 5.0;
        });

        // Reviews will update automatically via stream

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Review deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting review: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _cancelEdit() {
    setState(() {
      _editingReview = null;
      _commentController.clear();
      _userRating = 5.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    final canReview = user != null && user.uid != widget.recipeOwnerId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRatingOverview(),
        if (canReview) ...[
          ResponsiveSpacing(height: 24),
          _buildReviewForm(),
        ] else if (user != null && user.uid == widget.recipeOwnerId) ...[
          ResponsiveSpacing(height: 16),
          _buildOwnerNotice(),
        ],
        ResponsiveSpacing(height: 24),
        _buildReviewsList(),
      ],
    );
  }

  Widget _buildOwnerNotice() {
    return Card(
      elevation: 1,
      color: Colors.blue.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          ResponsiveController.borderRadius(8),
        ),
      ),
      child: Padding(
        padding: ResponsiveController.padding(all: 16),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: Colors.blue.shade700,
              size: ResponsiveController.iconSize(20),
            ),
            ResponsiveSpacing(width: 12),
            Expanded(
              child: ResponsiveText(
                'As the recipe owner, you cannot review your own recipe',
                baseSize: 14,
                color: Colors.blue.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingOverview() {
    if (_ratingStats == null) {
      return const SizedBox.shrink();
    }

    final average = _ratingStats!['average'] as double;
    final total = _ratingStats!['total'] as int;
    final distribution = _ratingStats!['distribution'] as Map<int, int>;

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
              children: [
                Icon(Icons.star, color: Colors.amber),
                ResponsiveSpacing(width: 8),
                ResponsiveText(
                  'Ratings & Reviews',
                  baseSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ],
            ),
            ResponsiveSpacing(height: 16),
            if (total > 0) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Average rating
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        ResponsiveText(
                          average.toStringAsFixed(1),
                          baseSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                        RatingBarIndicator(
                          rating: average,
                          itemBuilder: (context, index) => const Icon(
                            Icons.star,
                            color: Colors.amber,
                          ),
                          itemCount: 5,
                          itemSize: 20,
                        ),
                        ResponsiveSpacing(height: 4),
                        ResponsiveText(
                          '$total review${total != 1 ? 's' : ''}',
                          baseSize: 12,
                          color: Colors.grey[600],
                        ),
                      ],
                    ),
                  ),
                  // Rating distribution
                  Expanded(
                    flex: 3,
                    child: Column(
                      children: [5, 4, 3, 2, 1].map((rating) {
                        final count = distribution[rating] ?? 0;
                        final percentage = total > 0 ? (count / total) * 100 : 0;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              ResponsiveText(
                                '$rating',
                                baseSize: 12,
                                color: Colors.grey[600],
                              ),
                              Icon(Icons.star, size: 12, color: Colors.amber),
                              ResponsiveSpacing(width: 8),
                              Expanded(
                                child: LinearProgressIndicator(
                                  value: percentage / 100,
                                  backgroundColor: Colors.grey[200],
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.amber,
                                  ),
                                ),
                              ),
                              ResponsiveSpacing(width: 8),
                              SizedBox(
                                width: 30,
                                child: ResponsiveText(
                                  '$count',
                                  baseSize: 12,
                                  color: Colors.grey[600],
                                  textAlign: TextAlign.end,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Center(
                child: Column(
                  children: [
                    ResponsiveSpacing(height: 16),
                    Icon(
                      Icons.rate_review,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    ResponsiveSpacing(height: 12),
                    ResponsiveText(
                      'No reviews yet',
                      baseSize: 16,
                      color: Colors.grey[600],
                    ),
                    ResponsiveSpacing(height: 8),
                    ResponsiveText(
                      'Be the first to review this recipe!',
                      baseSize: 14,
                      color: Colors.grey[500],
                    ),
                    ResponsiveSpacing(height: 16),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReviewForm() {
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
                  _editingReview != null ? 'Edit Your Review' : 'Leave a Review',
                  baseSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                if (_editingReview != null)
                  TextButton(
                    onPressed: _cancelEdit,
                    child: const Text('Cancel Edit'),
                  ),
              ],
            ),
            ResponsiveSpacing(height: 16),
            Center(
              child: Column(
                children: [
                  RatingBar.builder(
                    initialRating: _userRating,
                    minRating: 1,
                    direction: Axis.horizontal,
                    allowHalfRating: true,
                    itemCount: 5,
                    itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                    itemBuilder: (context, _) => const Icon(
                      Icons.star,
                      color: Colors.amber,
                    ),
                    onRatingUpdate: (rating) {
                      setState(() {
                        _userRating = rating;
                      });
                    },
                  ),
                  ResponsiveSpacing(height: 8),
                  ResponsiveText(
                    'Rate: ${_userRating.toStringAsFixed(1)} / 5.0',
                    baseSize: 14,
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ),
            ResponsiveSpacing(height: 16),
            TextField(
              controller: _commentController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Share your experience with this recipe...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    ResponsiveController.borderRadius(8),
                  ),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
            ResponsiveSpacing(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submitReview,
                icon: _isSubmitting
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : Icon(_editingReview != null ? Icons.edit : Icons.send),
                label: Text(
                  _isSubmitting
                      ? 'Submitting...'
                      : (_editingReview != null ? 'Update Review' : 'Submit Review'),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      ResponsiveController.borderRadius(8),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_reviews.isEmpty) {
      return const SizedBox.shrink();
    }

    final user = _authService.currentUser;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ResponsiveText(
          'All Reviews (${_reviews.length})',
          baseSize: 16,
          fontWeight: FontWeight.bold,
        ),
        ResponsiveSpacing(height: 12),
        ...List.generate(_reviews.length, (index) {
          final review = _reviews[index];
          final isOwner = user != null && review.userId == user.uid;

          return Card(
            elevation: 1,
            margin: EdgeInsets.only(bottom: ResponsiveController.spacing(12)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                ResponsiveController.borderRadius(8),
              ),
            ),
            child: Padding(
              padding: ResponsiveController.padding(all: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.primaryColor.withOpacity(0.1),
                        child: Text(
                          review.userName.isNotEmpty
                              ? review.userName[0].toUpperCase()
                              : 'A',
                          style: TextStyle(
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      ResponsiveSpacing(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: ResponsiveText(
                                    review.userName,
                                    baseSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (isOwner) ...[
                                  IconButton(
                                    icon: Icon(
                                      Icons.edit,
                                      size: 16,
                                      color: AppColors.primaryColor,
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () {
                                      setState(() {
                                        _editingReview = review;
                                        _userRating = review.rating;
                                        _commentController.text = review.comment;
                                      });
                                    },
                                  ),
                                  ResponsiveSpacing(width: 8),
                                  IconButton(
                                    icon: Icon(
                                      Icons.delete,
                                      size: 16,
                                      color: AppColors.errorColor,
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () => _deleteReview(review),
                                  ),
                                ],
                              ],
                            ),
                            Row(
                              children: [
                                RatingBarIndicator(
                                  rating: review.rating,
                                  itemBuilder: (context, index) => const Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                  ),
                                  itemCount: 5,
                                  itemSize: 14,
                                ),
                                ResponsiveSpacing(width: 8),
                                ResponsiveText(
                                  review.formattedDate,
                                  baseSize: 12,
                                  color: Colors.grey[600],
                                ),
                                if (review.updatedAt != review.createdAt) ...[
                                  ResponsiveSpacing(width: 8),
                                  ResponsiveText(
                                    '(edited)',
                                    baseSize: 11,
                                    color: Colors.grey[500],
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  ResponsiveSpacing(height: 12),
                  ResponsiveText(
                    review.comment,
                    baseSize: 14,
                    color: Colors.grey[800],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}