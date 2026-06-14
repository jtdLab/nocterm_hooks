# nocterm_hooks

A port of [`flutter_hooks`](https://pub.dev/packages/flutter_hooks) for [nocterm](https://pub.dev/packages/nocterm) — reusable, composable local state for nocterm components, so you can skip hand-written `State` subclasses.

If you know `flutter_hooks` from Flutter, this package brings the same model to the nocterm world: write components as pure functions of their inputs plus hooks.

## Why this exists

[`flutter_hooks`](https://pub.dev/packages/flutter_hooks) lets you use hooks like `useState` and `useEffect` inside `HookWidget` instead of managing lifecycle in a `State` class. **nocterm_hooks** is the equivalent for nocterm: extend `HookComponent` and call hooks from `build`.

| flutter_hooks | nocterm_hooks |
|---|---|
| `HookWidget` | `HookComponent` |
| `useState` | `useState` |
| `useEffect` | `useEffect` |
| `useMemoized` | `useMemoized` |
| `useRef` | `useRef` |
| `useCallback` | `useCallback` |
| `useListenable` | `useListenable` |
| `useValueListenable` | `useValueListenable` |
| `useIsMounted` | `useIsMounted` |

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  nocterm_hooks: ^0.0.1
```

## Publishing

From a local checkout, after `dart pub token add https://pub.dev`:

```bash
chmod +x tool/publish.sh
./tool/publish.sh           # analyze, test, dry-run, then publish
./tool/publish.sh --dry-run   # validate only
```

## Usage

```dart
import 'package:nocterm/nocterm.dart';
import 'package:nocterm_hooks/nocterm_hooks.dart';

class Counter extends HookComponent {
  const Counter({super.key});

  @override
  Component build(BuildContext context) {
    final count = useState(0);

    return Row(
      children: [
        Text('${count.value}'),
        Button(
          onPressed: () => count.value++,
          child: const Text('+'),
        ),
      ],
    );
  }
}
```

Hooks must be called unconditionally and in the same order on every build — the same rules as `flutter_hooks`.

## Available hooks

- **`useState`** — mutable state that triggers a rebuild when changed
- **`useEffect`** — side effects with optional cleanup and dependency keys
- **`useMemoized`** — cache a value until keys change
- **`useRef`** — mutable ref that does not trigger rebuilds
- **`useCallback`** — memoized callback
- **`useListenable`** / **`useValueListenable`** — subscribe to listenables
- **`useIsMounted`** — guard async work after unmount
- **`use`** — register a custom `Hook`

## Custom hooks

Define a `Hook` subclass and call it with `use`, same pattern as `flutter_hooks`:

```dart
ValueNotifier<int> useCounter([int initial = 0]) => use(_CounterHook(initial));
```

## License

See the repository for license details.
