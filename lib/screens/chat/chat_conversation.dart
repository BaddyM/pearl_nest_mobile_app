class ChatConversation {
  final String id;
  final String landlordId;
  final String landlordName;
  final String landlordProfilePic;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  final bool isOnline;
  final String propertyTitle;

  ChatConversation({
    required this.id,
    required this.landlordId,
    required this.landlordName,
    required this.landlordProfilePic,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
    this.isOnline = false,
    required this.propertyTitle,
  });

  static List<ChatConversation> getSampleConversations() {
    return [
      ChatConversation(
        id: '1',
        landlordId: 'landlord_1',
        landlordName: 'Sarah Johnson',
        landlordProfilePic: 'assets/images/gojo (1).jpg',
        lastMessage: 'The apartment is available for viewing this weekend. What time works best for you?',
        lastMessageTime: DateTime.now().subtract(Duration(minutes: 15)),
        unreadCount: 2,
        isOnline: true,
        propertyTitle: 'Modern Downtown Apartment',
      ),
      ChatConversation(
        id: '2',
        landlordId: 'landlord_2',
        landlordName: 'Michael Chen',
        landlordProfilePic: 'assets/images/gojo (2).jpg',
        lastMessage: 'Thank you for your interest. The monthly rent includes utilities.',
        lastMessageTime: DateTime.now().subtract(Duration(hours: 2)),
        unreadCount: 0,
        isOnline: false,
        propertyTitle: 'Cozy Studio Near Campus',
      ),
      ChatConversation(
        id: '3',
        landlordId: 'landlord_3',
        landlordName: 'Emma Rodriguez',
        landlordProfilePic: '',
        lastMessage: 'Perfect! I\'ll send you the lease agreement by email.',
        lastMessageTime: DateTime.now().subtract(Duration(hours: 5)),
        unreadCount: 1,
        isOnline: true,
        propertyTitle: 'Luxury 2BR with Pool',
      ),
      ChatConversation(
        id: '4',
        landlordId: 'landlord_4',
        landlordName: 'David Wilson',
        landlordProfilePic: 'assets/images/gojo (4).jpg',
        lastMessage: 'The house has been recently renovated with new appliances.',
        lastMessageTime: DateTime.now().subtract(Duration(days: 1)),
        unreadCount: 0,
        isOnline: false,
        propertyTitle: 'Family House with Garden',
      ),
      ChatConversation(
        id: '5',
        landlordId: 'landlord_5',
        landlordName: 'Lisa Thompson',
        landlordProfilePic: 'assets/images/gojo (5).jpg',
        lastMessage: 'Hi! I saw your inquiry about the hostel room. It\'s still available.',
        lastMessageTime: DateTime.now().subtract(Duration(days: 2)),
        unreadCount: 3,
        isOnline: true,
        propertyTitle: 'Budget Hostel Room',
      ),
      ChatConversation(
        id: '6',
        landlordId: 'landlord_6',
        landlordName: 'James Miller',
        landlordProfilePic: '',
        lastMessage: 'Great! Looking forward to meeting you tomorrow at 3 PM.',
        lastMessageTime: DateTime.now().subtract(Duration(days: 3)),
        unreadCount: 0,
        isOnline: false,
        propertyTitle: 'Penthouse with City View',
      ),
    ];
  }
}
