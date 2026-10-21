/// Validates user-chosen PINs to prevent trivially guessable combinations.
class WeakPinValidator {
  WeakPinValidator._();

  static const Set<String> _obviousPins = {
    '0000',
    '1111',
    '2222',
    '3333',
    '4444',
    '5555',
    '6666',
    '7777',
    '8888',
    '9999',
    '1234',
    '4321',
    '1212',
    '1122',
    '2211',
    '1313',
    '1357',
    '2468',
    '2580',
    '0852',
    '1004',
    '6969',
    '0123',
    '3210',
    '12345',
    '54321',
    '123456',
    '654321',
    '00000',
    '11111',
    '000000',
    '111111',
  };

  /// Returns true if the PIN is weak or violates security constraints.
  static bool isWeak(String pin) {
    if (pin.length < 4 || pin.length > 6) return true;
    if (!RegExp(r'^\d+$').hasMatch(pin)) return true;

    // Check obvious list
    if (_obviousPins.contains(pin)) return true;

    // Check all repeated digits (e.g. 77777)
    if (RegExp(r'^(\d)\1+$').hasMatch(pin)) return true;

    // Check sequential ascending or descending
    bool isAscending = true;
    bool isDescending = true;
    for (int i = 0; i < pin.length - 1; i++) {
      final current = int.parse(pin[i]);
      final next = int.parse(pin[i + 1]);
      if (next != current + 1) isAscending = false;
      if (next != current - 1) isDescending = false;
    }

    if (isAscending || isDescending) return true;

    return false;
  }
}
