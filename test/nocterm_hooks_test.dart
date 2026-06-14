import 'package:nocterm/nocterm.dart';
import 'package:nocterm_hooks/nocterm_hooks.dart';
import 'package:test/test.dart';

void main() {
  group('useState', () {
    test('persists across rebuilds and rebuilds on change', () async {
      await testNocterm('useState', (tester) async {
        ValueNotifier<int>? counter;
        await tester.pumpComponent(
          _Sized(
            _HookText((context) {
              final count = useState(0);
              counter = count;
              return 'count: ${count.value}';
            }),
          ),
        );
        expect(tester.renderToString(showBorders: false), contains('count: 0'));

        counter!.value = 7;
        await tester.pump();
        expect(tester.renderToString(showBorders: false), contains('count: 7'));
      });
    });
  });

  group('useEffect', () {
    test('runs once, cleans up on unmount', () async {
      await testNocterm('useEffect once', (tester) async {
        final events = <String>[];
        final show = ValueNotifier<bool>(true);
        await tester.pumpComponent(
          _Sized(_EffectHost(show: show, events: events)),
        );
        expect(events, ['run']);

        // Toggle the effect child out of the tree → it unmounts.
        show.value = false;
        await tester.pump();
        expect(events, ['run', 'dispose']);
      });
    });

    test('re-runs when keys change', () async {
      await testNocterm('useEffect keys', (tester) async {
        final runs = <int>[];
        ValueNotifier<int>? dep;
        await tester.pumpComponent(
          _Sized(
            _HookText((context) {
              final value = useState(0);
              dep = value;
              useEffect(() {
                runs.add(value.value);
                return null;
              }, [value.value]);
              return 'v: ${value.value}';
            }),
          ),
        );
        expect(runs, [0]);

        dep!.value = 1;
        await tester.pump();
        expect(runs, [0, 1]);
      });
    });
  });

  group('useMemoized', () {
    test('keeps the same value across rebuilds', () async {
      await testNocterm('useMemoized', (tester) async {
        final created = <Object>[];
        ValueNotifier<int>? rebuild;
        await tester.pumpComponent(
          _Sized(
            _HookText((context) {
              final tick = useState(0);
              rebuild = tick;
              useMemoized(() {
                created.add(Object());
                return Object();
              });
              return '${created.length}/${tick.value}';
            }),
          ),
        );
        expect(created, hasLength(1));

        rebuild!.value = 1;
        await tester.pump();
        expect(created, hasLength(1)); // not rebuilt
      });
    });
  });

  group('ValueNotifier', () {
    test('notifies only on change', () {
      final notifier = ValueNotifier<int>(0);
      var notifications = 0;
      notifier.addListener(() => notifications++);
      expect(notifications, 0);
      notifier.value = 0; // no change → no notification
      expect(notifications, 0);
      notifier.value = 1;
      expect(notifications, 1);
      notifier.dispose();
    });
  });
}

/// A [HookComponent] that renders a single [Text] from a hook-driven builder.
class _HookText extends HookComponent {
  const _HookText(this.text);

  final String Function(BuildContext context) text;

  @override
  Component build(BuildContext context) => Text(text(context));
}

class _Sized extends HookComponent {
  const _Sized(this.child);

  final Component child;

  @override
  Component build(BuildContext context) =>
      Container(width: 30, height: 1, child: child);
}

/// Renders an effect-using child only while [show] is true, so toggling [show]
/// off unmounts the child within a single tree (the reliable unmount path).
class _EffectHost extends HookComponent {
  const _EffectHost({required this.show, required this.events});

  final ValueNotifier<bool> show;
  final List<String> events;

  @override
  Component build(BuildContext context) {
    useListenable(show);
    return show.value ? _EffectChild(events) : const Text('hidden');
  }
}

class _EffectChild extends HookComponent {
  const _EffectChild(this.events);

  final List<String> events;

  @override
  Component build(BuildContext context) {
    useEffect(() {
      events.add('run');
      return () => events.add('dispose');
    }, const []);
    return const Text('child');
  }
}
