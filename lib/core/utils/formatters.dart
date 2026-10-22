import 'package:intl/intl.dart';

String formatTime(DateTime? date) =>
    date == null ? '—' : DateFormat.jm().format(date.toLocal());
String formatDate(DateTime date) =>
    DateFormat('EEE, d MMM yyyy').format(date.toLocal());
String relativeTime(DateTime date) {
  final difference = DateTime.now().difference(date);
  if (difference.inMinutes < 1) return 'Just now';
  if (difference.inHours < 1) return '${difference.inMinutes}m ago';
  if (difference.inDays < 1) return '${difference.inHours}h ago';
  return DateFormat('d MMM, h:mm a').format(date.toLocal());
}
