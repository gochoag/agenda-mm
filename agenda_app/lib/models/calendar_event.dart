class CalendarEvent {
  final int id;
  final int userId;
  final String? username;
  final String detail;
  final String eventDate;
  final String status;
  final String? createdAt;

  CalendarEvent({
    required this.id,
    required this.userId,
    this.username,
    required this.detail,
    required this.eventDate,
    required this.status,
    this.createdAt,
  });

  bool get isCompleted => status == 'completado';

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      username: json['username'] as String?,
      detail: json['detail'] as String? ?? '',
      eventDate: json['event_date'] as String? ?? '',
      status: json['status'] as String? ?? 'pendiente',
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'username': username,
      'detail': detail,
      'event_date': eventDate,
      'status': status,
      'created_at': createdAt,
    };
  }
}
