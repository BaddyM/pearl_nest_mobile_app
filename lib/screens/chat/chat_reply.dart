import 'package:flutter/material.dart';
import 'package:pearlnest/widgets/app_theme.dart';

class ChatReply {
  const ChatReply({
    required this.sender,
    required this.quotedText,
    required this.message,
  });

  static const _prefix = '↪ Replying to ';

  final String sender;
  final String quotedText;
  final String message;

  static String format({
    required String sender,
    required String quotedText,
    required String message,
  }) {
    final excerpt = quotedText.replaceAll(RegExp(r'\s+'), ' ').trim();
    final clippedExcerpt =
        excerpt.length > 120 ? '${excerpt.substring(0, 120)}…' : excerpt;
    return '$_prefix$sender: $clippedExcerpt\n\n$message';
  }

  static ChatReply? parse(String content) {
    if (!content.startsWith(_prefix)) return null;
    final newline = content.indexOf('\n');
    final separator = content.indexOf('\n\n');
    if (newline < 0 || separator < newline) return null;

    final header = content.substring(_prefix.length, newline);
    final colon = header.indexOf(': ');
    if (colon < 0) return null;

    return ChatReply(
      sender: header.substring(0, colon),
      quotedText: header.substring(colon + 2),
      message: content.substring(separator + 2),
    );
  }
}

class ChatReplyPreview extends StatelessWidget {
  const ChatReplyPreview({
    super.key,
    required this.reply,
    required this.onCancel,
  });

  final ChatReply reply;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
      decoration: BoxDecoration(
        color: AppTheme.primaryblue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: AppTheme.primaryblue, width: 3),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Replying to ${reply.sender}',
                  style: const TextStyle(
                    color: AppTheme.primaryblue,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  reply.quotedText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppTheme.getSecondaryTextColor(context),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Cancel reply',
            visualDensity: VisualDensity.compact,
            onPressed: onCancel,
            icon: const Icon(Icons.close_rounded, size: 18),
          ),
        ],
      ),
    );
  }
}

class SwipeToReply extends StatefulWidget {
  const SwipeToReply({
    super.key,
    required this.onReply,
    required this.child,
  });

  final VoidCallback onReply;
  final Widget child;

  @override
  State<SwipeToReply> createState() => _SwipeToReplyState();
}

class _SwipeToReplyState extends State<SwipeToReply> {
  double _dragDistance = 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragStart: (_) => _dragDistance = 0,
      onHorizontalDragUpdate: (details) => _dragDistance += details.delta.dx,
      onHorizontalDragEnd: (_) {
        if (_dragDistance.abs() >= 48) widget.onReply();
        _dragDistance = 0;
      },
      onHorizontalDragCancel: () => _dragDistance = 0,
      child: widget.child,
    );
  }
}
