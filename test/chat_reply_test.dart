import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pearlnest/screens/chat/chat_reply.dart';

void main() {
  group('ChatReply', () {
    test('formats and parses quoted replies', () {
      final formatted = ChatReply.format(
        sender: 'Taylor',
        quotedText: 'Could we view the apartment tomorrow?',
        message: 'Yes, that works for me.',
      );

      final reply = ChatReply.parse(formatted);

      expect(reply?.sender, 'Taylor');
      expect(reply?.quotedText, 'Could we view the apartment tomorrow?');
      expect(reply?.message, 'Yes, that works for me.');
    });

    test('limits the quoted excerpt without changing the reply', () {
      final quotedText = List.filled(140, 'A').join();
      final reply = ChatReply.parse(
        ChatReply.format(
          sender: 'Taylor',
          quotedText: quotedText,
          message: 'My response',
        ),
      );

      expect(reply?.quotedText, '${List.filled(120, 'A').join()}…');
      expect(reply?.message, 'My response');
    });

    test('does not parse normal messages as replies', () {
      expect(ChatReply.parse('A normal message'), isNull);
    });
  });

  testWidgets('swiping either direction starts a reply', (tester) async {
    var replyCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SwipeToReply(
              onReply: () => replyCount++,
              child: const ColoredBox(
                color: Colors.blue,
                child: SizedBox(width: 200, height: 100),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.drag(find.byType(SwipeToReply), const Offset(100, 0));
    await tester.pump();
    expect(replyCount, 1);

    await tester.drag(find.byType(SwipeToReply), const Offset(-100, 0));
    await tester.pump();
    expect(replyCount, 2);
  });
}
