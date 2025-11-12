class SupportTicket {
  final int id;
  final String ticketNumber;
  final int userId;
  final String subject;
  final String description;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? resolvedAt;
  final String? resolutionNotes;
  final int messageCount;
  final DateTime? lastMessageAt;

  SupportTicket({
    required this.id,
    required this.ticketNumber,
    required this.userId,
    required this.subject,
    required this.description,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.resolvedAt,
    this.resolutionNotes,
    this.messageCount = 0,
    this.lastMessageAt,
  });

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    return SupportTicket(
      id: int.parse(json['id'].toString()),
      ticketNumber: json['ticket_number'] ?? '',
      userId: int.parse(json['user_id'].toString()),
      subject: json['subject'] ?? '',
      description: json['description'] ?? json['message'] ?? '',
      status: json['status'] ?? 'pending',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      resolvedAt: json['resolved_at'] != null ? DateTime.parse(json['resolved_at']) : null,
      resolutionNotes: json['resolution_notes'],
      messageCount: int.tryParse(json['message_count']?.toString() ?? '0') ?? 0,
      lastMessageAt: json['last_message_at'] != null ? DateTime.parse(json['last_message_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ticket_number': ticketNumber,
      'user_id': userId,
      'subject': subject,
      'description': description,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'resolved_at': resolvedAt?.toIso8601String(),
      'resolution_notes': resolutionNotes,
      'message_count': messageCount,
      'last_message_at': lastMessageAt?.toIso8601String(),
    };
  }

  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'in_progress':
        return 'In Progress';
      case 'resolved':
        return 'Resolved';
      default:
        return status;
    }
  }
}

class SupportTicketMessage {
  final int id;
  final int ticketId;
  final int senderId;
  final String message;
  final DateTime createdAt;
  final String? senderFname;
  final String? senderLname;
  final int? senderUserTypeId;

  SupportTicketMessage({
    required this.id,
    required this.ticketId,
    required this.senderId,
    required this.message,
    required this.createdAt,
    this.senderFname,
    this.senderLname,
    this.senderUserTypeId,
  });

  factory SupportTicketMessage.fromJson(Map<String, dynamic> json) {
    return SupportTicketMessage(
      id: int.parse(json['id'].toString()),
      ticketId: int.parse(json['ticket_id'].toString()),
      senderId: int.parse(json['sender_id'].toString()),
      message: json['message'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      senderFname: json['fname'],
      senderLname: json['lname'],
      senderUserTypeId: json['user_type_id'] != null ? int.parse(json['user_type_id'].toString()) : null,
    );
  }

  String get senderFullName {
    if (senderFname != null && senderLname != null) {
      return '$senderFname $senderLname';
    }
    return 'Unknown';
  }

  bool get isFromAdmin {
    return senderUserTypeId == 1 || senderUserTypeId == 2; // Admin or Staff
  }
}

