enum NotificationType { info, warning, critical }

class AppNotification {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime timestamp;
  final bool isRead;

  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    this.isRead = false,
  });

  AppNotification copyWith({
    String? title,
    String? message,
    NotificationType? type,
    DateTime? timestamp,
    bool? isRead,
  }) {
    return AppNotification(
      id: id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
    );
  }

  static List<AppNotification> get mockData => [
    AppNotification(
      id: '1',
      title: 'Connectivity Issue',
      message: 'Connection lost with Tracker #4421 in Warehouse A.',
      type: NotificationType.critical,
      timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
    ),
    AppNotification(
      id: '2',
      title: 'Battery Warning',
      message: 'Tracker #8892 battery is below 15%.',
      type: NotificationType.warning,
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    AppNotification(
      id: '3',
      title: 'Firmware Update',
      message: 'A new firmware version (v2.1.0) is available for 3 devices.',
      type: NotificationType.info,
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];
}
