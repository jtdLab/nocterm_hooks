import 'package:nocterm/nocterm.dart';
import 'package:nocterm_hooks/src/hook.dart';
import 'package:nocterm_hooks/src/value_notifier.dart';

/// A cleanup callback returned by a [useEffect] effect.
typedef Dispose = void Function();

/// Creates a [ValueNotifier] that survives rebuilds, initialised to
/// [initialData]. The component rebuilds whenever its `value` changes — read it
/// to render, set it to update.
ValueNotifier<T> useState<T>(T initialData) => use(_StateHook<T>(initialData));

class _StateHook<T> extends Hook<ValueNotifier<T>> {
  const _StateHook(this.initialData);

  final T initialData;

  @override
  HookState<ValueNotifier<T>, _StateHook<T>> createState() =>
      _StateHookState<T>();
}

class _StateHookState<T> extends HookState<ValueNotifier<T>, _StateHook<T>> {
  late final ValueNotifier<T> _notifier;

  @override
  void initHook() {
    _notifier = ValueNotifier<T>(hook.initialData)..addListener(_onChange);
  }

  void _onChange() => setState(() {});

  @override
  ValueNotifier<T> build(BuildContext context) => _notifier;

  @override
  void dispose() {
    _notifier
      ..removeListener(_onChange)
      ..dispose();
  }
}

/// Runs [effect] after build, re-running it whenever [keys] change. Return a
/// [Dispose] from [effect] to clean up before the next run / on unmount. With
/// `keys` null it runs every build; with `const []` it runs once.
void useEffect(Dispose? Function() effect, [List<Object?>? keys]) =>
    use(_EffectHook(effect, keys));

class _EffectHook extends Hook<void> {
  const _EffectHook(this.effect, [List<Object?>? keys]) : super(keys: keys);

  final Dispose? Function() effect;

  @override
  HookState<void, _EffectHook> createState() => _EffectHookState();
}

class _EffectHookState extends HookState<void, _EffectHook> {
  Dispose? _dispose;

  @override
  void initHook() => _run();

  @override
  void didUpdateHook(_EffectHook oldHook) {
    if (hook.keys == null || !hookKeysEqual(oldHook.keys, hook.keys)) {
      _cleanup();
      _run();
    }
  }

  void _run() => _dispose = hook.effect();

  void _cleanup() {
    _dispose?.call();
    _dispose = null;
  }

  @override
  void dispose() => _cleanup();

  @override
  void build(BuildContext context) {}
}

/// Caches the result of [valueBuilder] across rebuilds, recomputing only when
/// [keys] change. Use for objects that should not be rebuilt every frame
/// (controllers, derived values).
T useMemoized<T>(T Function() valueBuilder, [List<Object?> keys = const []]) =>
    use(_MemoizedHook<T>(valueBuilder, keys));

class _MemoizedHook<T> extends Hook<T> {
  const _MemoizedHook(this.valueBuilder, List<Object?> keys)
    : super(keys: keys);

  final T Function() valueBuilder;

  @override
  HookState<T, _MemoizedHook<T>> createState() => _MemoizedHookState<T>();
}

class _MemoizedHookState<T> extends HookState<T, _MemoizedHook<T>> {
  late T _value;

  @override
  void initHook() => _value = hook.valueBuilder();

  @override
  void didUpdateHook(_MemoizedHook<T> oldHook) {
    if (!hookKeysEqual(oldHook.keys, hook.keys)) _value = hook.valueBuilder();
  }

  @override
  T build(BuildContext context) => _value;
}

/// A mutable reference whose [ObjectRef.value] persists across rebuilds without
/// triggering one when changed.
ObjectRef<T> useRef<T>(T initialValue) => use(_RefHook<T>(initialValue));

/// The container returned by [useRef].
class ObjectRef<T> {
  ObjectRef(this.value);

  T value;
}

class _RefHook<T> extends Hook<ObjectRef<T>> {
  const _RefHook(this.initialValue);

  final T initialValue;

  @override
  HookState<ObjectRef<T>, _RefHook<T>> createState() => _RefHookState<T>();
}

class _RefHookState<T> extends HookState<ObjectRef<T>, _RefHook<T>> {
  late final ObjectRef<T> _ref = ObjectRef<T>(hook.initialValue);

  @override
  ObjectRef<T> build(BuildContext context) => _ref;
}

/// Returns a function that reports whether the enclosing component is still
/// mounted — guard `await` continuations with it before touching context/state.
bool Function() useIsMounted() => use(const _IsMountedHook());

class _IsMountedHook extends Hook<bool Function()> {
  const _IsMountedHook();

  @override
  HookState<bool Function(), _IsMountedHook> createState() =>
      _IsMountedHookState();
}

class _IsMountedHookState
    extends HookState<bool Function(), _IsMountedHook> {
  bool _isMounted = true;

  @override
  void dispose() => _isMounted = false;

  @override
  bool Function() build(BuildContext context) => () => _isMounted;
}

/// Returns [callback] memoized — the same reference across rebuilds until
/// [keys] change.
T useCallback<T extends Function>(
  T callback, [
  List<Object?> keys = const [],
]) => useMemoized<T>(() => callback, keys);

/// Subscribes to [listenable] and rebuilds the component whenever it notifies.
/// Returns the same [listenable].
L useListenable<L extends Listenable?>(L listenable) =>
    use(_ListenableHook<L>(listenable));

class _ListenableHook<L extends Listenable?> extends Hook<L> {
  const _ListenableHook(this.listenable);

  final L listenable;

  @override
  HookState<L, _ListenableHook<L>> createState() => _ListenableHookState<L>();
}

class _ListenableHookState<L extends Listenable?>
    extends HookState<L, _ListenableHook<L>> {
  @override
  void initHook() => hook.listenable?.addListener(_onChange);

  @override
  void didUpdateHook(_ListenableHook<L> oldHook) {
    if (oldHook.listenable != hook.listenable) {
      oldHook.listenable?.removeListener(_onChange);
      hook.listenable?.addListener(_onChange);
    }
  }

  void _onChange() => setState(() {});

  @override
  L build(BuildContext context) => hook.listenable;

  @override
  void dispose() => hook.listenable?.removeListener(_onChange);
}

/// Subscribes to [valueListenable] and rebuilds when it notifies, returning its
/// current `value`.
T useValueListenable<T>(ValueListenable<T> valueListenable) {
  useListenable(valueListenable);
  return valueListenable.value;
}
