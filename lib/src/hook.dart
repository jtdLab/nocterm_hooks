import 'package:nocterm/nocterm.dart';

/// A reusable, composable piece of stateful logic used inside a
/// [HookComponent.build] via [use]. Analogous to `flutter_hooks`' `Hook`.
///
/// Subclasses are tiny config objects; the real state lives in their
/// [HookState]. When [keys] is non-null, the hook reacts only when the keys
/// change between builds (see [HookState.didUpdateHook]).
abstract class Hook<R> {
  const Hook({this.keys});

  /// When non-null, the hook should only re-run its effect / recompute its
  /// value when these change between builds.
  final List<Object?>? keys;

  HookState<R, Hook<R>> createState();
}

/// The mutable state backing a [Hook] — the nocterm equivalent of `State`.
abstract class HookState<R, H extends Hook<R>> {
  /// The current hook configuration for this state.
  H get hook => _hook;
  late H _hook;

  late HookComponentState _owner;

  /// The build context of the enclosing [HookComponent].
  BuildContext get context => _owner.context;

  /// Whether the enclosing component is still mounted.
  bool get mounted => _owner.mounted;

  /// Called once, when this hook is first used.
  void initHook() {}

  /// Called on every rebuild after the first, with the previous [hook] config.
  /// Compare `oldHook.keys` to `hook.keys` to decide whether to react.
  void didUpdateHook(covariant H oldHook) {}

  /// Releases resources; called when the hook is removed or the component is
  /// disposed.
  void dispose() {}

  /// The value [use] returns for this hook on the current build.
  R build(BuildContext context);

  /// Mutates state via [fn] and rebuilds the enclosing component.
  void setState(VoidCallback fn) {
    fn();
    _owner._scheduleRebuild();
  }
}

/// A component whose [build] may call hooks ([use], `useState`, …) — the
/// nocterm equivalent of `flutter_hooks`' `HookWidget`. Lets a component own
/// local state without a hand-written [State] subclass, so the component stays
/// a pure function of its inputs + hooks.
abstract class HookComponent extends StatefulComponent {
  const HookComponent({super.key});

  /// Builds the component. Call hooks here — unconditionally and in the same
  /// order on every build.
  Component build(BuildContext context);

  @override
  State<HookComponent> createState() => HookComponentState();
}

/// Drives a [HookComponent]'s ordered hook list. Public so the machinery is
/// testable; you never reference it directly.
class HookComponentState extends State<HookComponent> {
  final List<HookState<Object?, Hook<Object?>>> _hooks =
      <HookState<Object?, Hook<Object?>>>[];
  int _index = 0;
  BuildContext? _context;

  @override
  BuildContext get context => _context ?? super.context;

  void _scheduleRebuild() {
    if (mounted) setState(() {});
  }

  @override
  Component build(BuildContext context) {
    _context = context;
    _index = 0;
    final previous = _activeState;
    _activeState = this;
    try {
      return component.build(context);
    } finally {
      _activeState = previous;
      // Hooks no longer used this build (the list shrank) are disposed.
      if (_index < _hooks.length) {
        for (var i = _index; i < _hooks.length; i++) {
          _hooks[i].dispose();
        }
        _hooks.removeRange(_index, _hooks.length);
      }
    }
  }

  R _use<R>(Hook<R> hook) {
    final HookState<Object?, Hook<Object?>> state;
    if (_index >= _hooks.length) {
      state = _create(hook);
      _hooks.add(state);
    } else {
      final existing = _hooks[_index];
      if (existing._hook.runtimeType != hook.runtimeType) {
        existing.dispose();
        state = _create(hook);
        _hooks[_index] = state;
      } else {
        final oldHook = existing._hook;
        existing
          .._hook = hook
          ..didUpdateHook(oldHook);
        state = existing;
      }
    }
    _index++;
    return state.build(context) as R;
  }

  HookState<Object?, Hook<Object?>> _create(Hook<Object?> hook) =>
      hook.createState()
        .._owner = this
        .._hook = hook
        ..initHook();

  @override
  void dispose() {
    for (final hook in _hooks) {
      hook.dispose();
    }
    _hooks.clear();
    super.dispose();
  }
}

HookComponentState? _activeState;

/// Registers and evaluates [hook] for the enclosing [HookComponent], returning
/// its value for this build. Call from inside a [HookComponent] build,
/// unconditionally, and in the same order every time.
R use<R>(Hook<R> hook) {
  assert(
    _activeState != null,
    'use()/a hook was called outside of a HookComponent.build().',
  );
  return _activeState!._use(hook);
}

/// Whether two hook key lists are equal (element-wise). Used by hooks that take
/// `keys` to decide when to re-run.
bool hookKeysEqual(List<Object?>? a, List<Object?>? b) {
  if (identical(a, b)) return true;
  if (a == null || b == null) return false;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
