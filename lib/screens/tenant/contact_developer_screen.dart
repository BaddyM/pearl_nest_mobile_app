import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pearlnest/widgets/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';

class ContactDeveloperScreen extends StatefulWidget {
  const ContactDeveloperScreen({super.key});

  @override
  State<ContactDeveloperScreen> createState() => _ContactDeveloperScreenState();
}

class _ContactDeveloperScreenState extends State<ContactDeveloperScreen> {
  PackageInfo? _packageInfo;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
  }

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _packageInfo = info;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      appBar: AppBar(
        backgroundColor: AppTheme.primaryblue,
        elevation: 0,
        automaticallyImplyLeading: true,
        iconTheme: IconThemeData(color: AppTheme.whiteColor),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDeveloperCard(),
            SizedBox(height: 24),
            _buildContactMethods(context),
            SizedBox(height: 24),
            SizedBox(height: 24),
            _buildFeedbackSection(context),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildDeveloperCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primaryblue,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.code_rounded,
            size: 60,
            color: AppTheme.whiteColor,
          ),
          SizedBox(height: 16),
          Text(
            'PearlNest Development Team',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.whiteColor,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'DevelopWithEffect',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.whiteColor.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactMethods(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Get in Touch',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.getTextColor(context),
            ),
          ),
          SizedBox(height: 16),
          _buildContactItem(
            context,
            Icons.email,
            'Email Support',
            'info@developwitheffect.com',
            'Send us an email for detailed inquiries',
            () => _launchEmail('info@developwitheffect.com'),
          ),
          SizedBox(height: 12),
          _buildContactItem(
            context,
            Icons.bug_report,
            'Report Bug',
            'info@developwitheffect.com',
            'Found a bug? Let us know!',
            () => _launchEmail('info@developwitheffect.com'),
          ),
          SizedBox(height: 12),
          _buildContactItem(
            context,
            Icons.lightbulb_outline,
            'Feature Request',
            'info@developwitheffect.com',
            'Suggest new features or improvements',
            () => _launchEmail('info@developwitheffect.com'),
          ),
          SizedBox(height: 12),
          _buildContactItem(
            context,
            Icons.chat_outlined,
            'WhatsApp Support',
            '+256 757 919 472',
            'Message us during working days',
            () => _launchUrl('https://wa.me/256757919472'),
          ),
          SizedBox(height: 12),
          _buildContactItem(
            context,
            Icons.phone,
            'Phone Support',
            '+256 757 919 472',
            'Call us during business hours',
            () => _launchPhone('+256757919472'),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(
    BuildContext context,
    IconData icon,
    String title,
    String contact,
    String description,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: AppTheme.getCardColor(context),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryblue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AppTheme.primaryblue,
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppTheme.getTextColor(context),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              contact,
              style: TextStyle(
                color: AppTheme.primaryblue,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 2),
            Text(
              description,
              style: TextStyle(
                color: AppTheme.getSecondaryTextColor(context),
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.copy, color: AppTheme.getSecondaryTextColor(context), size: 20),
              onPressed: () => _copyToClipboard(context, contact),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.getSecondaryTextColor(context)),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildFeedbackSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: AppTheme.getCardColor(context),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quick Feedback',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.getTextColor(context),
                ),
              ),
              SizedBox(height: 12),
              Text(
                'How would you rate your experience with PearlNest?',
                style: TextStyle(
                  color: AppTheme.getSecondaryTextColor(context),
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildFeedbackButton(context, '😞', 'Poor'),
                  _buildFeedbackButton(context, '😐', 'Fair'),
                  _buildFeedbackButton(context, '😊', 'Good'),
                  _buildFeedbackButton(context, '😍', 'Excellent'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeedbackButton(BuildContext context, String emoji, String label) {
    return GestureDetector(
      onTap: () {
        _showFloatingEmojis(context, emoji);
      },
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryblue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              emoji,
              style: TextStyle(fontSize: 24),
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.getSecondaryTextColor(context),
            ),
          ),
        ],
      ),
    );
  }

  void _launchEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=PearlNest App Inquiry',
    );
    
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  void _launchPhone(String phone) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phone);
    
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  void _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
        
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied to clipboard'),
        backgroundColor: AppTheme.primaryblue,
        duration: Duration(milliseconds: 500),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
      ),
    );
  }

  void _showFloatingEmojis(BuildContext context, String emoji) {
    final overlay = Overlay.of(context);
    if (overlay == null) return;

    // Get the render box of the specific feedback button that was tapped
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final Offset globalPosition = renderBox.localToGlobal(Offset.zero);
    final Size size = renderBox.size;

    // Create multiple floating emojis
    for (int i = 0; i < 7; i++) {
      _createFloatingEmoji(overlay, emoji, globalPosition, size, i);
    }
  }

  void _createFloatingEmoji(
    OverlayState overlay,
    String emoji,
    Offset startPosition,
    Size buttonSize,
    int index,
  ) {
    final random = Random();
    
    // Calculate starting position (center of the button)
    final double startX = startPosition.dx + (buttonSize.width / 2) - 15; // Center horizontally
    final double startY = startPosition.dy + (buttonSize.height / 2) - 15; // Center vertically
    
    // Random variations for more natural animation
    final double horizontalDrift = (random.nextDouble() - 0.5) * 100; // -50 to 50
    final double verticalDistance = 150 + random.nextDouble() * 50; // 150-200px up
    final int animationDelay = index * 100; // Stagger animations
    
    late OverlayEntry overlayEntry;
    
    overlayEntry = OverlayEntry(
      builder: (BuildContext context) {
        return FloatingEmojiWidget(
          emoji: emoji,
          startX: startX,
          startY: startY,
          horizontalDrift: horizontalDrift,
          verticalDistance: verticalDistance,
          delay: animationDelay,
          onAnimationComplete: () {
            // Safely remove the overlay entry
            try {
              overlayEntry.remove();
            } catch (e) {
              // Handle case where overlay is already removed
              debugPrint('Overlay entry already removed: $e');
            }
          },
        );
      },
    );
    
    overlay.insert(overlayEntry);
  }
}

class FloatingEmojiWidget extends StatefulWidget {
  final String emoji;
  final double startX;
  final double startY;
  final double horizontalDrift;
  final double verticalDistance;
  final int delay;
  final VoidCallback onAnimationComplete;

  const FloatingEmojiWidget({
    Key? key,
    required this.emoji,
    required this.startX,
    required this.startY,
    required this.horizontalDrift,
    required this.verticalDistance,
    required this.delay,
    required this.onAnimationComplete,
  }) : super(key: key);

  @override
  State<FloatingEmojiWidget> createState() => _FloatingEmojiWidgetState();
}

class _FloatingEmojiWidgetState extends State<FloatingEmojiWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _verticalAnimation;
  late Animation<double> _horizontalAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: Duration(milliseconds: 2000),
      vsync: this,
    );

    // Vertical movement (upward)
    _verticalAnimation = Tween<double>(
      begin: 0,
      end: -widget.verticalDistance,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    // Horizontal drift
    _horizontalAnimation = Tween<double>(
      begin: 0,
      end: widget.horizontalDrift,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    // Opacity (fade out)
    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Interval(0.7, 1.0, curve: Curves.easeOut),
    ));

    // Scale (slight grow then shrink)
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    // Add listener for animation completion
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onAnimationComplete();
      }
    });

    // Start animation after delay
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          left: widget.startX + _horizontalAnimation.value,
          top: widget.startY + _verticalAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Text(
                widget.emoji,
                style: TextStyle(
                  fontSize: 28,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}