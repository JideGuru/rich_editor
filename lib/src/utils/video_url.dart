final _youtubeId = RegExp(r'^[A-Za-z0-9_-]{6,}$');

/// The embed URL of a YouTube video link, or null if [url] isn't one.
///
/// Handles watch, youtu.be, embed, shorts and live links and drops extra
/// parameters such as playlists and timestamps.
String? youtubeEmbedUrl(String url) {
  final uri = Uri.tryParse(url.trim());
  if (uri == null) return null;

  final host = uri.host.toLowerCase().replaceFirst(RegExp(r'^(www|m)\.'), '');
  final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
  String? id;

  if (host == 'youtu.be') {
    id = segments.isEmpty ? null : segments.first;
  } else if (host == 'youtube.com' ||
      host == 'music.youtube.com' ||
      host == 'youtube-nocookie.com') {
    if (segments.length == 1 && segments.first == 'watch') {
      id = uri.queryParameters['v'];
    } else if (segments.length >= 2 &&
        const ['embed', 'shorts', 'live', 'v'].contains(segments.first)) {
      id = segments[1];
    }
  }

  if (id == null || !_youtubeId.hasMatch(id)) return null;
  return 'https://www.youtube.com/embed/$id';
}
