/// Formats a timestamp as `YYYY-MM-DD HH:MM:SS` in local time. Shared by the
/// Camera and Map pages so both show "last update" times the same way.
String formatTimestamp(DateTime time) {
  final local = time.toLocal();
  final date =
      '${local.year}-${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')}';
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  final second = local.second.toString().padLeft(2, '0');
  return '$date $hour:$minute:$second';
}
