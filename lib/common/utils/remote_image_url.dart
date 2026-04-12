/// True when the URL should not be loaded over the network (test placeholders,
/// known-broken hosts, TLS issues on simulators, etc.).
bool isPlaceholderOrUnreliableImageUrl(String? url) {
  if (url == null) return true;
  final trimmed = url.trim();
  if (trimmed.isEmpty) return true;
  final u = trimmed.toLowerCase();
  return u.contains('via.placeholder.com') ||
      u.contains('placeholder.com') ||
      u.contains('placehold.it');
}
