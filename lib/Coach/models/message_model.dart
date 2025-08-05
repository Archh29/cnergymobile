class Message {
  final int id;
  final int senderId;
  final int receiverId;
  final String message;
  final DateTime? timestamp;
  final bool isRead;

  Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.message,
    this.timestamp,
    required this.isRead,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] ?? 0,
      senderId: json['sender_id'] ?? 0,
      receiverId: json['receiver_id'] ?? 0,
      message: json['message'] ?? '',
      timestamp: json['timestamp'] != null 
          ? DateTime.tryParse(json['timestamp']) 
          : null,
      isRead: json['is_read'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'message': message,
      'timestamp': timestamp?.toIso8601String(),
      'is_read': isRead ? 1 : 0,
    };
  }

  @override
  String toString() {
    return 'Message(id: $id, senderId: $senderId, receiverId: $receiverId, message: $message, timestamp: $timestamp, isRead: $isRead)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Message &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class Conversation {
  final int id;
  final int participant1Id;
  final int participant2Id;
  final DateTime? createdAt;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final int unreadCount;
  final UserInfo otherUser;

  Conversation({
    required this.id,
    required this.participant1Id,
    required this.participant2Id,
    this.createdAt,
    this.lastMessage,
    this.lastMessageTime,
    required this.unreadCount,
    required this.otherUser,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] ?? 0,
      participant1Id: json['participant1_id'] ?? 0,
      participant2Id: json['participant2_id'] ?? 0,
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at']) 
          : null,
      lastMessage: json['last_message'],
      lastMessageTime: json['last_message_time'] != null 
          ? DateTime.tryParse(json['last_message_time']) 
          : null,
      unreadCount: json['unread_count'] ?? 0,
      otherUser: UserInfo.fromJson(json['other_user'] ?? {}),
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
      id: json['id'] ?? 0,
      firstName: json['fname'] ?? '',
      lastName: json['lname'] ?? '',
      email: json['email'] ?? '',
      userTypeId: json['user_type_id'] ?? 4,
      isOnline: json['is_online'] == 1,
    );
  }
}
