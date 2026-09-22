abstract class AppClock {
  DateTime now();
}

class SystemAppClock implements AppClock {
  const SystemAppClock();

  @override
  DateTime now() => DateTime.now();
}

class TestAppClock implements AppClock {
  DateTime _current;

  TestAppClock([DateTime? initial])
      : _current = initial ?? DateTime(2026, 9, 20, 12, 0, 0);

  @override
  DateTime now() => _current;

  void set(DateTime time) {
    _current = time;
  }

  void advance(Duration duration) {
    _current = _current.add(duration);
  }
}
