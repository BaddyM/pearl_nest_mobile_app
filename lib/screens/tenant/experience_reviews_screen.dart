import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pearlnest/apis/experience_review_service.dart';
import 'package:pearlnest/models/user.dart';
import 'package:pearlnest/utils/image_helper.dart';
import 'package:pearlnest/widgets/app_theme.dart';

class ExperienceReviewsScreen extends StatefulWidget {
  const ExperienceReviewsScreen({super.key, required this.user});

  final User user;

  @override
  State<ExperienceReviewsScreen> createState() =>
      _ExperienceReviewsScreenState();
}

class _ExperienceReviewsScreenState extends State<ExperienceReviewsScreen> {
  final _reviewController = TextEditingController();
  final Map<String, TextEditingController> _replyControllers = {};
  List<Map<String, dynamic>> _reviews = [];
  int _stars = 5;
  String? _replyingTo;
  bool _isLoading = true;
  bool _isSavingReview = false;
  bool _isSavingReply = false;
  bool _initializedReview = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  @override
  void dispose() {
    _reviewController.dispose();
    for (final controller in _replyControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TextEditingController _replyController(String reviewId) =>
      _replyControllers.putIfAbsent(reviewId, TextEditingController.new);

  Future<void> _loadReviews() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final reviews = await ExperienceReviewService.getReviews();
      if (!mounted) return;
      setState(() {
        if (!_initializedReview) {
          final ownReviews = reviews.where((review) {
            final user = review['user'];
            return user is Map && user['id']?.toString() == widget.user.id;
          }).toList();
          if (ownReviews.isNotEmpty) {
            _reviewController.text =
                ownReviews.first['message']?.toString() ?? '';
            _stars = (ownReviews.first['stars'] as num?)?.toInt() ?? 5;
          }
          _initializedReview = true;
        }
        _reviews = reviews;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = error.toString();
      });
    }
  }

  Future<void> _saveReview() async {
    final message = _reviewController.text.trim();
    if (message.isEmpty) {
      _showMessage('Write a few words about your experience first.');
      return;
    }
    setState(() => _isSavingReview = true);
    try {
      await ExperienceReviewService.saveReview(stars: _stars, message: message);
      if (!mounted) return;
      _reviewController.text = message;
      await _loadReviews();
      if (mounted) _showMessage('Your review is live.');
    } catch (error) {
      if (mounted) _showMessage('Could not save your review: $error');
    } finally {
      if (mounted) setState(() => _isSavingReview = false);
    }
  }

  Future<void> _sendReply(String reviewId) async {
    final controller = _replyController(reviewId);
    final message = controller.text.trim();
    if (message.isEmpty) {
      _showMessage('Write a reply before posting.');
      return;
    }
    setState(() => _isSavingReply = true);
    try {
      await ExperienceReviewService.reply(
        reviewId: reviewId,
        message: message,
      );
      if (!mounted) return;
      controller.clear();
      setState(() => _replyingTo = null);
      await _loadReviews();
    } catch (error) {
      if (mounted) _showMessage('Could not post your reply: $error');
    } finally {
      if (mounted) setState(() => _isSavingReply = false);
    }
  }

  Future<void> _report(String type, String targetId) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report this comment'),
        content: TextField(
          controller: controller,
          maxLength: 500,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Tell us why this should be reviewed',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Send report'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (reason == null || reason.isEmpty) return;
    try {
      await ExperienceReviewService.report(
        type: type,
        targetId: targetId,
        reason: reason,
      );
      if (mounted) _showMessage('Thanks. The team will review this report.');
    } catch (error) {
      if (mounted) _showMessage('Could not submit report: $error');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _date(dynamic value) {
    final parsed = DateTime.tryParse(value?.toString() ?? '');
    return parsed == null ? '' : DateFormat('d MMM yyyy').format(parsed.toLocal());
  }

  Widget _avatar(Map<String, dynamic>? user, {double size = 40}) {
    final name = user?['name']?.toString().trim() ?? '';
    final picture = user?['profilePicture']?.toString() ?? '';
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: AppTheme.primaryblue.withValues(alpha: 0.12),
      backgroundImage: picture.isEmpty
          ? null
          : NetworkImage(ImageHelper.getFullImageUrl(picture)),
      child: picture.isNotEmpty
          ? null
          : Text(
              name.isEmpty ? '?' : name.substring(0, 1).toUpperCase(),
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryblue,
              ),
            ),
    );
  }

  Widget _stars(int count, {double size = 16}) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          5,
          (index) => Icon(
            index < count ? Icons.star_rounded : Icons.star_outline_rounded,
            size: size,
            color: Colors.amber.shade700,
          ),
        ),
      );

  Widget _replyTile(Map<String, dynamic> reply) {
    final user = reply['user'] is Map
        ? Map<String, dynamic>.from(reply['user'] as Map)
        : <String, dynamic>{};
    final own = user['id']?.toString() == widget.user.id;
    return Padding(
      padding: const EdgeInsets.only(left: 30, top: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _avatar(user, size: 32),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  children: [
                    Text(
                      user['name']?.toString() ?? 'Pearl Nest user',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      _date(reply['createdAt']),
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.getSecondaryTextColor(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(reply['message']?.toString() ?? ''),
                if (!own)
                  TextButton(
                    onPressed: () => _report('reply', reply['id'].toString()),
                    child: const Text('Report'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _reviewCard(Map<String, dynamic> review) {
    final user = review['user'] is Map
        ? Map<String, dynamic>.from(review['user'] as Map)
        : <String, dynamic>{};
    final reviewId = review['id']?.toString() ?? '';
    final own = user['id']?.toString() == widget.user.id;
    final replies = (review['replies'] as List? ?? const [])
        .whereType<Map>()
        .map((reply) => Map<String, dynamic>.from(reply))
        .toList();
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _avatar(user),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user['name']?.toString() ?? 'Pearl Nest user',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          _stars((review['stars'] as num?)?.toInt() ?? 0),
                          const SizedBox(width: 8),
                          Text(
                            _date(review['createdAt']),
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.getSecondaryTextColor(context),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (!own)
                  IconButton(
                    tooltip: 'Report review',
                    onPressed: () => _report('review', reviewId),
                    icon: const Icon(Icons.flag_outlined),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              review['message']?.toString() ?? '',
              style: const TextStyle(height: 1.45),
            ),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () => setState(
                    () => _replyingTo = _replyingTo == reviewId ? null : reviewId,
                  ),
                  icon: const Icon(Icons.reply_rounded, size: 18),
                  label: Text('Reply${replies.isEmpty ? '' : ' · ${replies.length}'}'),
                ),
              ],
            ),
            if (_replyingTo == reviewId)
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _replyController(reviewId),
                      maxLength: 1000,
                      decoration: const InputDecoration(
                        hintText: 'Write a thoughtful reply...',
                        counterText: '',
                        isDense: true,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Post reply',
                    onPressed: _isSavingReply ? null : () => _sendReply(reviewId),
                    icon: _isSavingReply
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ...replies.map(_replyTile),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ownReviews = _reviews.where((review) {
      final user = review['user'];
      return user is Map && user['id']?.toString() == widget.user.id;
    }).toList();
    final myReview = ownReviews.isEmpty ? null : ownReviews.first;
    return Scaffold(
      appBar: AppBar(title: const Text('Community reviews')),
      backgroundColor: AppTheme.getBackgroundColor(context),
      body: RefreshIndicator(
        onRefresh: _loadReviews,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: Theme.of(context).dividerColor),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      myReview == null
                          ? 'How has Pearl Nest been for you?'
                          : 'Update your experience review',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    const Text('Your review is public and helps the community.'),
                    const SizedBox(height: 8),
                    Row(
                      children: List.generate(
                        5,
                        (index) => IconButton(
                          visualDensity: VisualDensity.compact,
                          onPressed: () => setState(() => _stars = index + 1),
                          icon: Icon(
                            index < _stars
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            color: Colors.amber.shade700,
                            size: 30,
                          ),
                        ),
                      ),
                    ),
                    TextField(
                      controller: _reviewController,
                      maxLength: 2000,
                      minLines: 3,
                      maxLines: 6,
                      decoration: InputDecoration(
                        hintText: myReview?['message']?.toString() ??
                            'Share your experience...',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton(
                        onPressed: _isSavingReview ? null : _saveReview,
                        child: _isSavingReview
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(myReview == null ? 'Post review' : 'Update review'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'From the community',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 10),
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(28),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_loadError != null)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.cloud_off_outlined),
                  title: const Text('Reviews could not be loaded'),
                  subtitle: Text(_loadError!),
                  trailing: TextButton(
                    onPressed: _loadReviews,
                    child: const Text('Retry'),
                  ),
                ),
              )
            else if (_reviews.isEmpty)
              const Padding(
                padding: EdgeInsets.all(28),
                child: Center(
                  child: Text('Be the first to share your experience.'),
                ),
              )
            else
              ..._reviews.map(_reviewCard),
          ],
        ),
      ),
    );
  }
}
