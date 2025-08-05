class Message {
  final int id;
  final int senderId;
  final int receiverId;
  final String message;
  final DateTime timestamp;
  final bool isRead;

  Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.timestamp,
    required this.isRead,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      senderId: json['sender_id'],
      receiverId: json['receiver_id'],
      message: json['message'],
      timestamp: DateTime.parse(json['timestamp']),
      isRead: json['is_read'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'is_read': isRead ? 1 : 0,
    };
  }
}

class Conversation {
  final int id;
  final int participant1Id;
  final int participant2Id;
  final DateTime createdAt;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final int unreadCount;
  final UserInfo otherUser;

  Conversation({
    required this.id,
    required this.participant1Id,
    required this.participant2Id,
    required this.createdAt,
    this.lastMessage,
    this.lastMessageTime,
    required this.unreadCount,
    required this.otherUser,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'],
      participant1Id: json['participant1_id'],
      participant2Id: json['participant2_id'],
      createdAt: DateTime.parse(json['created_at']),
      lastMessage: json['last_message'],
      lastMessageTime: json['last_message_time'] != null 
          ? DateTime.parse(json['last_message_time']) 
          : null,
      unreadCount: json['unread_count'] ?? 0,
      otherUser: UserInfo.fromJson(json['other_user']),
    );
  }
}

class UserInfo {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final int userTypeId;
  final bool isOnline;

  UserInfo({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.userTypeId,
    this.isOnline = false,
  });

  String get fullName => '$firstName $lastName';
  String get initials => '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}';
  bool get isCoach => userTypeId == 3;

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id: json['id'],
      firstName: json['fname'] ?? '',
      lastName: json['lname'] ?? '',
      email: json['email'] ?? '',
      userTypeId: json['user_type_id'] ?? 4,
      isOnline: json['is_online'] == 1,
    );
  }
}