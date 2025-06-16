class ChatUtils {
  static String formatLastSeen(DateTime lastSeen) {
    final now = DateTime.now();
    final difference = now.difference(lastSeen);
    
    if (difference.inMinutes < 1) {
      return 'Online';
    } else if (difference.inMinutes < 60) {
      return 'Last seen ${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return 'Last seen ${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return 'Last seen ${difference.inDays}d ago';
    } else {
      return 'Last seen ${lastSeen.day}/${lastSeen.month}/${lastSeen.year}';
    }
  }
  
  static String getMessagePreview(String message, {int maxLength = 50}) {
    if (message.length <= maxLength) {
      return message;
    }
    return '${message.substring(0, maxLength)}...';
  }
  
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && 
           date.month == now.month && 
           date.day == now.day;
  }
  
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(Duration(days: 1));
    return date.year == yesterday.year && 
           date.month == yesterday.month && 
           date.day == yesterday.day;
  }
}
