/// A port of `flutter_hooks` to the nocterm world: write components that own
/// local state with `HookComponent` and hooks (`useState`, `useEffect`,
/// `useMemoized`, …) instead of a hand-written `State` subclass.
library;

export 'src/hook.dart'
    show Hook, HookComponent, HookComponentState, HookState, use;
export 'src/hooks.dart';
export 'src/value_notifier.dart';
