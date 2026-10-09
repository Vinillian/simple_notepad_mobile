/// Hosts for which `network_security_config.xml` allows plain HTTP.
const Set<String> cleartextAllowedHosts = {'10.0.2.2', 'localhost', '127.0.0.1'};

/// Validates a server address typed by the user.
///
/// Returns the normalized address (trimmed, without trailing slashes) or
/// `null` if the input is not a usable http/https URL.
String? normalizeServerUrl(String input) {
  final text = input.trim();
  if (text.isEmpty || text.contains(RegExp(r'\s'))) return null;

  final uri = Uri.tryParse(text);
  if (uri == null || !uri.hasAuthority || uri.host.isEmpty) return null;
  if (uri.scheme != 'http' && uri.scheme != 'https') return null;
  if (uri.hasQuery || uri.hasFragment) return null;

  return text.replaceAll(RegExp(r'/+$'), '');
}

/// Whether Android lets the app talk to [url] over plain HTTP.
/// Always true for https and for the hosts in [cleartextAllowedHosts].
bool isCleartextAllowed(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) return false;
  if (uri.scheme == 'https') return true;
  return cleartextAllowedHosts.contains(uri.host);
}
