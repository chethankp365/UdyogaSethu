enum DeliveryMode {
  sameDay,
  nextDay,
  preOrder,
}

class DeliverySlot {
  final String id;
  final String farmerId;
  final DateTime slotDate;
  final String windowStart; // e.g. "07:00:00"
  final String windowEnd;   // e.g. "11:00:00"
  final int capacity;
  final int used;

  const DeliverySlot({
    required this.id,
    required this.farmerId,
    required this.slotDate,
    required this.windowStart,
    required this.windowEnd,
    required this.capacity,
    required this.used,
  });

  int get availableCapacity => (capacity - used).clamp(0, capacity);
  bool get isFull => availableCapacity <= 0;

  DeliveryMode get mode {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final slotDay = DateTime(slotDate.year, slotDate.month, slotDate.day);
    final difference = slotDay.difference(today).inDays;

    if (difference <= 0) {
      return DeliveryMode.sameDay;
    } else if (difference == 1) {
      return DeliveryMode.nextDay;
    } else {
      return DeliveryMode.preOrder;
    }
  }

  String get formattedWindow {
    final start = _formatTime(windowStart);
    final end = _formatTime(windowEnd);
    return '$start - $end';
  }

  String get formattedDate {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final weekday = days[slotDate.weekday - 1];
    final month = months[slotDate.month - 1];
    return '$weekday, $month ${slotDate.day}';
  }

  String get freshnessNote {
    switch (mode) {
      case DeliveryMode.sameDay:
        return 'Harvested at 4:30 AM • Delivered fresh within hours';
      case DeliveryMode.nextDay:
        return 'Picked this evening • Early morning farm-to-table delivery';
      case DeliveryMode.preOrder:
        return 'Reserved harvest batch • Peak maturity delivery';
    }
  }

  static String _formatTime(String timeStr) {
    try {
      final parts = timeStr.split(':');
      final hour = int.parse(parts[0]);
      final minute = parts.length > 1 ? parts[1] : '00';
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      return '$displayHour:$minute $period';
    } catch (_) {
      return timeStr;
    }
  }

  factory DeliverySlot.fromJson(Map<String, dynamic> json) {
    return DeliverySlot(
      id: json['id'] as String,
      farmerId: json['farmer_id'] as String,
      slotDate: json['slot_date'] != null
          ? DateTime.parse(json['slot_date'] as String)
          : DateTime.now(),
      windowStart: json['window_start'] as String? ?? '07:00:00',
      windowEnd: json['window_end'] as String? ?? '11:00:00',
      capacity: (json['capacity'] as num?)?.toInt() ?? 10,
      used: (json['used'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'farmer_id': farmerId,
      'slot_date': slotDate.toIso8601String().split('T').first,
      'window_start': windowStart,
      'window_end': windowEnd,
      'capacity': capacity,
      'used': used,
    };
  }
}
