import 'package:intl/intl.dart';

/// Extension methods for DateTime formatting
extension DateTimeExtension on DateTime {
  /// Format date as "Jan 1, 2024"
  String toFormattedDate() {
    return DateFormat('MMM d, y').format(this);
  }

  /// Format date and time as "Jan 1, 2024 10:30 AM"
  String toFormattedDateTime() {
    return DateFormat('MMM d, y h:mm a').format(this);
  }

  /// Get relative time (e.g., "2 hours ago", "just now")
  String toRelativeTime() {
    final now = DateTime.now();
    final difference = now.difference(this);

    if (difference.inSeconds < 60) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return toFormattedDate();
    }
  }

  /// Check if date is today
  bool isToday() {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }
}

/// Extension methods for String utilities
extension StringExtension on String {
  /// Capitalize first letter
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Truncate string with ellipsis
  String truncate(int maxLength) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength)}...';
  }

  /// Validate email format
  bool isValidEmail() {
    return RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(this);
  }
}

/// Extension methods for List utilities
extension ListExtension<T> on List<T> {
  /// Safely get element at index (returns null if out of bounds)
  T? getOrNull(int index) {
    if (index < 0 || index >= length) return null;
    return this[index];
  }
}
