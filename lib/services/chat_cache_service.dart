import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatCacheService {
  static const _cachePrefix = 'chat_cache_v1_';
  static const _retention = Duration(days: 30);
  static const _maxMessages = 200;
  static const _maxConversations = 100;
  static const _maxEncodedCharacters = 512 * 1024;

  static String _conversationListKey(String userId) =>
      '${_cachePrefix}list:$userId';

  static String _messagesKey(
    String userId,
    String peerId,
    String? propertyId,
  ) =>
      '${_cachePrefix}messages:$userId:$peerId:${propertyId ?? 'general'}';

  static Future<Map<String, dynamic>?> readConversationList(
    String userId,
  ) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      return await _readMap(preferences, _conversationListKey(userId));
    } catch (error, stackTrace) {
      debugPrint('Could not access the cached chat list: $error\n$stackTrace');
      return null;
    }
  }

  static Future<void> saveConversationList(
    String userId,
    List<Map<String, dynamic>> conversations, {
    required bool isAdminList,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    await _write(
      preferences,
      _conversationListKey(userId),
      {'data': conversations, 'isAdminList': isAdminList},
    );
  }

  static Future<Map<String, dynamic>?> readMessages(
    String userId,
    String peerId,
    String? propertyId,
  ) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      return await _readMap(
        preferences,
        _messagesKey(userId, peerId, propertyId),
      );
    } catch (error, stackTrace) {
      debugPrint('Could not access cached chat messages: $error\n$stackTrace');
      return null;
    }
  }

  static Future<void> saveMessages(
    String userId,
    String peerId,
    String? propertyId,
    Map<String, dynamic> conversation,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    await _write(
      preferences,
      _messagesKey(userId, peerId, propertyId),
      conversation,
    );
    await _pruneMessageCaches(preferences, userId);
  }

  static Future<void> clearAll() async {
    final preferences = await SharedPreferences.getInstance();
    final cacheKeys = preferences
        .getKeys()
        .where((key) => key.startsWith(_cachePrefix))
        .toList();
    for (final key in cacheKeys) {
      await preferences.remove(key);
    }
  }

  static Future<Map<String, dynamic>?> _readMap(
    SharedPreferences preferences,
    String key,
  ) async {
    final cachedJson = preferences.getString(key);
    if (cachedJson == null) return null;

    try {
      final decoded = jsonDecode(cachedJson);
      if (decoded is! Map) {
        throw const FormatException('Cached chat data must be an object.');
      }
      final cached = Map<String, dynamic>.from(decoded);
      final cachedAt = DateTime.tryParse(cached['_cachedAt']?.toString() ?? '');
      if (cachedAt == null ||
          DateTime.now().difference(cachedAt) > _retention) {
        await preferences.remove(key);
        return null;
      }
      cached.remove('_cachedAt');
      return cached;
    } catch (error, stackTrace) {
      debugPrint('Could not read cached chat data: $error\n$stackTrace');
      try {
        await preferences.remove(key);
      } catch (removeError) {
        debugPrint('Could not remove invalid chat cache: $removeError');
      }
      return null;
    }
  }

  static Future<void> _write(
    SharedPreferences preferences,
    String key,
    Map<String, dynamic> data,
  ) async {
    final bounded = Map<String, dynamic>.from(data);
    final conversations = bounded['data'];
    if (conversations is List) {
      bounded['data'] = conversations.take(_maxConversations).toList();
    }
    final messages = bounded['messages'];
    if (messages is List) {
      final retainedMessages = messages.where((message) {
        if (message is! Map) return false;
        final createdAt =
            DateTime.tryParse(message['createdAt']?.toString() ?? '');
        return createdAt != null &&
            DateTime.now().difference(createdAt) <= _retention;
      }).toList();
      bounded['messages'] = retainedMessages.length > _maxMessages
          ? retainedMessages.sublist(retainedMessages.length - _maxMessages)
          : retainedMessages;
    }
    bounded['_cachedAt'] = DateTime.now().toIso8601String();
    var encoded = jsonEncode(bounded);
    if (encoded.length > _maxEncodedCharacters && bounded['messages'] is List) {
      final retainedMessages = bounded['messages'] as List;
      bounded['messages'] = retainedMessages.length > 50
          ? retainedMessages.sublist(retainedMessages.length - 50)
          : retainedMessages;
      encoded = jsonEncode(bounded);
    }
    if (encoded.length > _maxEncodedCharacters) {
      throw StateError('The chat cache exceeded its safe storage limit.');
    }
    final saved = await preferences.setString(key, encoded);
    if (!saved) {
      throw StateError('The chat cache could not be saved.');
    }
  }

  static Future<void> _pruneMessageCaches(
    SharedPreferences preferences,
    String userId,
  ) async {
    final prefix = '${_cachePrefix}messages:$userId:';
    final entries = <MapEntry<String, DateTime>>[];
    final now = DateTime.now();

    for (final key
        in preferences.getKeys().where((key) => key.startsWith(prefix))) {
      final encoded = preferences.getString(key);
      if (encoded == null) {
        await preferences.remove(key);
        continue;
      }

      try {
        final decoded = jsonDecode(encoded);
        final cachedAt = decoded is Map
            ? DateTime.tryParse(decoded['_cachedAt']?.toString() ?? '')
            : null;
        if (cachedAt == null || now.difference(cachedAt) > _retention) {
          await preferences.remove(key);
          continue;
        }
        entries.add(MapEntry(key, cachedAt));
      } on FormatException catch (error) {
        debugPrint('Removing invalid cached chat data: $error');
        await preferences.remove(key);
      }
    }

    entries.sort((left, right) => left.value.compareTo(right.value));
    final excess = entries.length - _maxConversations;
    for (var index = 0; index < excess; index++) {
      await preferences.remove(entries[index].key);
    }
  }
}
