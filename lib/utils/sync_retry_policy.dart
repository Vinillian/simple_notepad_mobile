/// How long to wait before each automatic retry of a failed sync. The wait
/// grows with every failed attempt, and the retries stop after the last one;
/// the sync button, a restart of the app and the return of the network start
/// over.
class SyncRetryPolicy {
  static const List<Duration> delays = [
    Duration(seconds: 10),
    Duration(seconds: 30),
    Duration(minutes: 2),
    Duration(minutes: 5),
    Duration(minutes: 15),
  ];

  /// The wait before retry number [attempt] (counting from 0), or `null` when
  /// the retries are used up.
  static Duration? delayFor(int attempt) {
    if (attempt < 0 || attempt >= delays.length) return null;
    return delays[attempt];
  }
}
