extension StringExtension on String? {
  bool get isNotNullOrEmpty => !(this == null || this!.isEmpty);
}