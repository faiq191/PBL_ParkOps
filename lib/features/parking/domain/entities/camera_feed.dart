class CameraFeed {
  const CameraFeed({
    required this.id,
    required this.title,
    required this.pageUrl,
  });

  final String id;
  final String title;
  final String pageUrl;

  Uri get pageUri => Uri.parse(pageUrl);
}
