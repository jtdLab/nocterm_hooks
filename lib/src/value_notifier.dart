import 'package:nocterm/nocterm.dart';

/// A [ChangeNotifier] holding a single [value] that notifies its listeners on
/// change. nocterm has `ValueListenable` / `ChangeNotifier` but no concrete
/// `ValueNotifier`, so this provides one (the type `useState` returns).
class ValueNotifier<T> extends ChangeNotifier implements ValueListenable<T> {
  ValueNotifier(this._value);

  T _value;

  @override
  T get value => _value;

  set value(T newValue) {
    if (_value == newValue) return;
    _value = newValue;
    notifyListeners();
  }

  @override
  String toString() => 'ValueNotifier<$T>($value)';
}
