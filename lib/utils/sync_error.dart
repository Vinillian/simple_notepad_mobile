/// A short reason for the user, taken from an error thrown by a sync.
///
/// [ApiClient] wraps every failure in an `Exception('Network error: ...')`,
/// so the kind of failure is read from the text.
String describeSyncError(Object error) {
  final text = error.toString().toLowerCase();

  final status = RegExp(r'server error: (\d{3})').firstMatch(text);
  if (status != null) {
    final code = int.parse(status.group(1)!);
    if (code == 401 || code == 403) {
      return 'сервер отклонил доступ (код $code)';
    }
    if (code >= 500) return 'ошибка на сервере (код $code)';
    return 'сервер отклонил запрос (код $code)';
  }
  if (text.contains('timeout')) return 'сервер не отвечает (таймаут)';
  if (text.contains('failed host lookup') ||
      text.contains('network is unreachable') ||
      text.contains('no address associated')) {
    return 'нет подключения к сети';
  }
  if (text.contains('connection refused') ||
      text.contains('connection closed') ||
      text.contains('connection reset')) {
    return 'сервер недоступен';
  }
  if (text.contains('socketexception')) return 'нет связи с сервером';
  return 'неизвестная ошибка';
}
