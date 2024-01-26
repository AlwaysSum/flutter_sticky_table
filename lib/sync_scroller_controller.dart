import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Sets up a collection of scroll controllers that mirror their movements to
/// each other.
///
/// Controllers are added and returned via [addAndGet]. The initial offset
/// of the newly created controller is synced to the current offset.
/// Controllers must be `dispose`d when no longer in use to prevent memory
/// leaks and performance degradation.
///
/// If controllers are disposed over the course of the lifetime of this
/// object the corresponding scrollable's should be given unique keys.
/// Without the keys, Flutter may reuse a controller after it has been disposed,
/// which can cause the controller offsets to fall out of sync.
class SyncScrollController {
  SyncScrollController({this.initialScrollOffset = 0.0}) {
    _offsetNotifier = _SyncScrollControllerGroupOffsetNotifier(this);
  }

  final double initialScrollOffset;
  final _allControllers = <String, _SyncScrollController>{};

  late _SyncScrollControllerGroupOffsetNotifier _offsetNotifier;

  /// The current scroll offset of the group.
  double get offset {
    assert(
      _attachedControllers.isNotEmpty,
      'SyncScrollControllerGroup does not have any scroll controllers '
      'attached.',
    );
    return _attachedControllers.first.offset;
  }

  /// Creates a new controller that is Sync to any existing ones.
  ScrollController addAndGet(String key) {
    if (_allControllers.containsKey(key)) {
      return _allControllers[key]!;
    }
    final initialOffset = _attachedControllers.isEmpty
        ? initialScrollOffset
        : _attachedControllers.first.position.pixels;
    final controller =
        _SyncScrollController(this, initialScrollOffset: initialOffset);
    _allControllers[key] = controller;
    controller.addListener(_offsetNotifier.notifyListeners);
    return controller;
  }

  /// Adds a callback that will be called when the value of [offset] changes.
  void addOffsetChangedListener(VoidCallback onChanged) {
    _offsetNotifier.addListener(onChanged);
  }

  /// Removes the specified offset changed listener.
  void removeOffsetChangedListener(VoidCallback listener) {
    _offsetNotifier.removeListener(listener);
  }

  Iterable<_SyncScrollController> get _attachedControllers =>
      _allControllers.entries
          .where((entity) => entity.value.hasClients)
          .map((e) => e.value);

  /// Animates the scroll position of all Sync controllers to [offset].
  Future<void> animateTo(
    double offset, {
    required Curve curve,
    required Duration duration,
  }) async {
    final animations = <Future<void>>[];
    for (final controller in _attachedControllers) {
      animations
          .add(controller.animateTo(offset, duration: duration, curve: curve));
    }
    await Future.wait(animations);
  }

  /// Jumps the scroll position of all Sync controllers to [value].
  void jumpTo(double value) {
    for (final controller in _attachedControllers) {
      controller.jumpTo(value);
    }
  }

  /// Resets the scroll position of all Sync controllers to 0.
  void resetScroll() {
    jumpTo(0.0);
  }

  void dispose() {
    _allControllers.forEach((key, value) {
      value.dispose();
      _allControllers.remove(key);
    });
  }
}

/// This class provides change notification for [SyncScrollController]'s
/// scroll offset.
///
/// This change notifier de-duplicates change events by only firing listeners
/// when the scroll offset of the group has changed.
class _SyncScrollControllerGroupOffsetNotifier extends ChangeNotifier {
  _SyncScrollControllerGroupOffsetNotifier(this.controllerGroup);

  final SyncScrollController controllerGroup;

  /// The cached offset for the group.
  ///
  /// This value will be used in determining whether to notify listeners.
  double? _cachedOffset;

  @override
  void notifyListeners() {
    final currentOffset = controllerGroup.offset;
    if (currentOffset != _cachedOffset) {
      _cachedOffset = currentOffset;
      super.notifyListeners();
    }
  }
}

/// A scroll controller that mirrors its movements to a peer, which must also
/// be a [_SyncScrollController].
class _SyncScrollController extends ScrollController {
  final SyncScrollController _controllers;

  _SyncScrollController(
    this._controllers, {
    required double initialScrollOffset,
  }) : super(
          initialScrollOffset: initialScrollOffset,
          keepScrollOffset: false,
        );

  @override
  void dispose() {
    _controllers._allControllers.remove(this);
    super.dispose();
  }

  @override
  void attach(ScrollPosition position) {
    assert(
        position is _SyncScrollPosition,
        '_SyncScrollControllers can only be used with'
        ' _SyncScrollPositions.');
    final _SyncScrollPosition syncPosition = position as _SyncScrollPosition;
    assert(syncPosition.owner == this,
        '_SyncScrollPosition cannot change controllers once created.');
    super.attach(position);
  }

  @override
  _SyncScrollPosition createScrollPosition(
    ScrollPhysics physics,
    ScrollContext context,
    ScrollPosition? oldPosition,
  ) {
    return _SyncScrollPosition(
      this,
      physics: physics,
      context: context,
      initialPixels: initialScrollOffset,
      oldPosition: oldPosition,
    );
  }

  @override
  double get initialScrollOffset => _controllers._attachedControllers.isEmpty
      ? super.initialScrollOffset
      : _controllers.offset;

  @override
  _SyncScrollPosition get position => super.position as _SyncScrollPosition;

  Iterable<_SyncScrollController> get _allPeersWithClients =>
      _controllers._attachedControllers.where((peer) => peer != this);

  bool get canLinkWithPeers => _allPeersWithClients.isNotEmpty;

  Iterable<_SyncScrollActivity> linkWithPeers(_SyncScrollPosition driver) {
    assert(canLinkWithPeers);
    return _allPeersWithClients
        .map((peer) => peer.link(driver))
        .expand((e) => e);
  }

  Iterable<_SyncScrollActivity> link(_SyncScrollPosition driver) {
    assert(hasClients);
    final activities = <_SyncScrollActivity>[];
    for (final position in positions) {
      final syncPosition = position as _SyncScrollPosition;
      activities.add(syncPosition.link(driver));
    }
    return activities;
  }
}

// Implementation details: Whenever position.setPixels or position.forcePixels
// is called on a _SyncScrollPosition (which may happen programmatically, or
// as a result of a user action),  the _SyncScrollPosition creates a
// _SyncScrollActivity for each Sync position and uses it to move to or jump
// to the appropriate offset.
//
// When a new activity begins, the set of peer activities is cleared.
class _SyncScrollPosition extends ScrollPositionWithSingleContext {
  _SyncScrollPosition(
    this.owner, {
    required ScrollPhysics physics,
    required ScrollContext context,
    double? initialPixels,
    ScrollPosition? oldPosition,
  }) : super(
          physics: physics,
          context: context,
          initialPixels: initialPixels,
          oldPosition: oldPosition,
        );

  final _SyncScrollController owner;

  final Set<_SyncScrollActivity> _peerActivities = <_SyncScrollActivity>{};

  // We override hold to propagate it to all peer controllers.
  @override
  ScrollHoldController hold(VoidCallback holdCancelCallback) {
    for (final controller in owner._allPeersWithClients) {
      controller.position._holdInternal();
    }
    return super.hold(holdCancelCallback);
  }

  // Calls hold without propagating to peers.
  void _holdInternal() {
    super.hold(() {});
  }

  @override
  void beginActivity(ScrollActivity? newActivity) {
    if (newActivity == null) {
      return;
    }
    for (var activity in _peerActivities) {
      activity.unlink(this);
    }

    _peerActivities.clear();

    super.beginActivity(newActivity);
  }

  @override
  double setPixels(double newPixels) {
    if (newPixels == pixels) {
      return 0.0;
    }
    updateUserScrollDirection(newPixels - pixels > 0.0
        ? ScrollDirection.forward
        : ScrollDirection.reverse);

    if (owner.canLinkWithPeers) {
      _peerActivities.addAll(owner.linkWithPeers(this));
      for (var activity in _peerActivities) {
        activity.moveTo(newPixels);
      }
    }

    return setPixelsInternal(newPixels);
  }

  double setPixelsInternal(double newPixels) {
    return super.setPixels(newPixels);
  }

  @override
  void forcePixels(double value) {
    if (value == pixels) {
      return;
    }
    updateUserScrollDirection(value - pixels > 0.0
        ? ScrollDirection.forward
        : ScrollDirection.reverse);

    if (owner.canLinkWithPeers) {
      _peerActivities.addAll(owner.linkWithPeers(this));
      for (var activity in _peerActivities) {
        activity.jumpTo(value);
      }
    }

    forcePixelsInternal(value);
  }

  void forcePixelsInternal(double value) {
    super.forcePixels(value);
  }

  _SyncScrollActivity link(_SyncScrollPosition driver) {
    if (this.activity is! _SyncScrollActivity) {
      beginActivity(_SyncScrollActivity(this));
    }
    final _SyncScrollActivity activity = this.activity as _SyncScrollActivity;
    activity.link(driver);
    return activity;
  }

  void unlink(_SyncScrollActivity activity) {
    _peerActivities.remove(activity);
  }

  @override
  // ignore: unnecessary_overrides, as we want to make it public (overridden method is protected)
  void updateUserScrollDirection(ScrollDirection value) {
    super.updateUserScrollDirection(value);
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('owner: $owner');
  }
}

class _SyncScrollActivity extends ScrollActivity {
  _SyncScrollActivity(_SyncScrollPosition delegate) : super(delegate);

  @override
  _SyncScrollPosition get delegate => super.delegate as _SyncScrollPosition;

  final Set<_SyncScrollPosition> drivers = <_SyncScrollPosition>{};

  void link(_SyncScrollPosition driver) {
    drivers.add(driver);
  }

  void unlink(_SyncScrollPosition driver) {
    drivers.remove(driver);
    if (drivers.isEmpty) {
      delegate.goIdle();
    }
  }

  @override
  bool get shouldIgnorePointer => true;

  @override
  bool get isScrolling => true;

  // _SyncScrollActivity is not self-driven but moved by calls to the [moveTo]
  // method.
  @override
  double get velocity => 0.0;

  void moveTo(double newPixels) {
    _updateUserScrollDirection();
    delegate.setPixelsInternal(newPixels);
  }

  void jumpTo(double newPixels) {
    _updateUserScrollDirection();
    delegate.forcePixelsInternal(newPixels);
  }

  void _updateUserScrollDirection() {
    assert(drivers.isNotEmpty);
    ScrollDirection commonDirection = drivers.first.userScrollDirection;
    for (var driver in drivers) {
      if (driver.userScrollDirection != commonDirection) {
        commonDirection = ScrollDirection.idle;
      }
    }
    delegate.updateUserScrollDirection(commonDirection);
  }

  @override
  void dispose() {
    for (var driver in drivers) {
      driver.unlink(this);
    }
    super.dispose();
  }
}
