import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:time_machine/time_machine.dart';

import 'event.dart';
import 'event_provider.dart';
import 'header/timetable_header.dart';
import 'initial_time_range.dart';
import 'timetable.dart';
import 'utils/scrolling.dart';
import 'utils/utils.dart';
import 'visible_range.dart';

/// Controls a [Timetable] and manages its state.
class TimetableController<E extends Event> {
  TimetableController({
    required this.eventProvider,
    LocalDate? initialDate,
    this.initialTimeRange = const InitialTimeRange.zoom(1),
    this.visibleRange = const VisibleRange.week(),
    this.firstDayOfWeek = DayOfWeek.monday,
  }) : initialDate = initialDate ?? LocalDate.today() {
    _scrollControllers = LinkedScrollControllerGroup(
      initialPage: visibleRange.getTargetPageForFocusDate(
          this.initialDate, firstDayOfWeek),
      viewportFraction: 1 / visibleRange.visibleDays,
    );

    _dateListenable = scrollControllers.pageListenable
        .map((page) => LocalDate.fromEpochDay(page.floor()));
    _currentlyVisibleDatesListenable = scrollControllers.pageListenable
        .map((page) {
      return DateInterval(
        LocalDate.fromEpochDay(page.floor()),
        LocalDate.fromEpochDay(page.ceil() + visibleRange.visibleDays - 1),
      );
    })
          ..addListener(
              () => eventProvider.onVisibleDatesChanged(currentlyVisibleDates));
    eventProvider.onVisibleDatesChanged(currentlyVisibleDates);
  }

  /// The [EventProvider] used for populating [Timetable] with events.
  final EventProvider<E> eventProvider;

  /// The initially visible time range.
  ///
  /// This defaults to the full day.
  final InitialTimeRange initialTimeRange;

  /// The initially focused date.
  ///
  /// This defaults to [LocalDate.today];
  final LocalDate initialDate;

  /// Determines how many days are visible and how these snap to the viewport.
  ///
  /// This defaults to [VisibleRange.week].
  final VisibleRange visibleRange;

  /// The [DayOfWeek] on which a week starts.
  ///
  /// This defaults to [DayOfWeek.monday].
  ///
  /// It is used e.g. by [VisibleRange.week] to snap to the correct range and by
  /// [TimetableHeader] to calculate the current week number.
  final DayOfWeek firstDayOfWeek;

  late LinkedScrollControllerGroup _scrollControllers;

  LinkedScrollControllerGroup get scrollControllers => _scrollControllers;

  late ValueNotifier<LocalDate> _dateListenable;

  ValueListenable<LocalDate> get dateListenable => _dateListenable;

  late ValueNotifier<DateInterval> _currentlyVisibleDatesListenable;

  ValueListenable<DateInterval> get currentlyVisibleDatesListenable =>
      _currentlyVisibleDatesListenable;

  DateInterval get currentlyVisibleDates =>
      currentlyVisibleDatesListenable.value;

  /// Animates today into view.
  ///
  /// The alignment of today inside the viewport depends on [visibleRange].
  Future<void> animateToToday({
    Curve curve = Curves.easeInOut,
    Duration duration = const Duration(milliseconds: 200),
  }) =>
      animateTo(LocalDate.today(), curve: curve, duration: duration);

  /// Animates the given [date] into view.
  ///
  /// The alignment of today inside the viewport depends on [visibleRange].
  Future<void> animateTo(
    LocalDate date, {
    Curve curve = Curves.easeInOut,
    Duration duration = const Duration(milliseconds: 200),
  }) async {
    await scrollControllers.animateTo(
      visibleRange.getTargetPageForFocusDate(date, firstDayOfWeek),
      curve: curve,
      duration: duration,
    );
  }

  /// Discards any resources used by the controller.
  ///
  /// After this is called, the controller is not in a usable state and should
  /// be discarded.
  ///
  /// This method should only be called by the object's owner, usually in
  /// [State.dispose].
  void dispose() {
    eventProvider.dispose();

    _dateListenable.dispose();
    _currentlyVisibleDatesListenable.dispose();
  }
}
