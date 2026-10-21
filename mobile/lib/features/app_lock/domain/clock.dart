/// Abstract clock interface to provide monotonic and elapsed time logic
/// that survives system clock changes and enables deterministic unit testing.
abstract class Clock {
  DateTime now();
  Stopwatch createStopwatch();
}

/// Production clock delegating to system time.
class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();

  @override
  Stopwatch createStopwatch() => Stopwatch();
}

/// Fake clock for unit tests allowing explicit time advancement.
class FakeClock implements Clock {
  FakeClock([DateTime? initialTime])
      : _currentTime = initialTime ?? DateTime(2026, 10, 21, 12, 0, 0);

  DateTime _currentTime;

  @override
  DateTime now() => _currentTime;

  void advance(Duration duration) {
    _currentTime = _currentTime.add(duration);
  }

  void setTime(DateTime time) {
    _currentTime = time;
  }

  @override
  Stopwatch createStopwatch() => _FakeStopwatch(this);
}

class _FakeStopwatch implements Stopwatch {
  _FakeStopwatch(this._clock);

  final FakeClock _clock;
  DateTime? _startedAt;
  Duration _accumulated = Duration.zero;
  bool _isRunning = false;

  @override
  int get elapsedMicroseconds => elapsed.inMicroseconds;

  @override
  int get elapsedMilliseconds => elapsed.inMilliseconds;

  @override
  Duration get elapsed {
    if (_isRunning && _startedAt != null) {
      return _accumulated + _clock.now().difference(_startedAt!);
    }
    return _accumulated;
  }

  @override
  int get elapsedTicks => elapsedMicroseconds;

  @override
  int get frequency => 1000000;

  @override
  bool get isRunning => _isRunning;

  @override
  void reset() {
    _accumulated = Duration.zero;
    if (_isRunning) {
      _startedAt = _clock.now();
    }
  }

  @override
  void start() {
    if (!_isRunning) {
      _startedAt = _clock.now();
      _isRunning = true;
    }
  }

  @override
  void stop() {
    if (_isRunning && _startedAt != null) {
      _accumulated += _clock.now().difference(_startedAt!);
      _isRunning = false;
    }
  }
}
