// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:pearlnest/screens/chat/message.dart';
import 'package:pearlnest/widgets/app_theme.dart';

class ChatInput extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool isEnabled;
  final MessageType type;

  const ChatInput({
    super.key,
    required this.controller,
    required this.onSend,
    this.type = MessageType.text,
    this.isEnabled = true,
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final isCurrentlyTyping = widget.controller.text.trim().isNotEmpty;
    if (isCurrentlyTyping != _isTyping) {
      setState(() {
        _isTyping = isCurrentlyTyping;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      decoration: BoxDecoration(
        color: AppTheme.getBackgroundColor(context),
        border: Border(
          top: BorderSide(
            color:
                AppTheme.getSecondaryTextColor(context).withValues(alpha: 0.1),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 120),
                decoration: BoxDecoration(
                  color: AppTheme.getCardColor(context),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: AppTheme.getSecondaryTextColor(context)
                        .withValues(alpha: 0.12),
                  ),
                ),
                child: TextField(
                  controller: widget.controller,
                  enabled: widget.isEnabled,
                  decoration: InputDecoration(
                    hintText:
                        widget.isEnabled ? 'Message' : 'Connecting to chat...',
                    hintStyle: TextStyle(
                      color: AppTheme.getSecondaryTextColor(context),
                      fontSize: 15,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 13,
                    ),
                  ),
                  style: TextStyle(
                    fontSize: 15,
                    color: AppTheme.getTextColor(context),
                  ),
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: (_) {
                    if (_isTyping && widget.isEnabled) {
                      widget.onSend();
                    }
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            AnimatedScale(
              scale: _isTyping ? 1 : 0.94,
              duration: const Duration(milliseconds: 180),
              child: IconButton.filled(
                tooltip: 'Send message',
                onPressed:
                    (_isTyping && widget.isEnabled) ? widget.onSend : null,
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.primaryblue,
                  disabledBackgroundColor:
                      AppTheme.getSecondaryTextColor(context)
                          .withValues(alpha: 0.25),
                  foregroundColor: AppTheme.whiteColor,
                  fixedSize: const Size(48, 48),
                ),
                icon: const Icon(Icons.send_rounded, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
