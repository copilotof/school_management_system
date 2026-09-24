import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_management_system/core/states/ui_state.dart';
import 'package:school_management_system/features/notifications/domain/entities/notification_entity.dart';
import 'package:school_management_system/features/notifications/domain/repositories/notification_repository.dart';

// Events
abstract class NotificationEvent {}

class FetchNotifications extends NotificationEvent {}

class MarkAsReadEvent extends NotificationEvent {
  final int id;
  MarkAsReadEvent(this.id);
}

class MarkAllAsReadEvent extends NotificationEvent {}

class DeleteNotificationEvent extends NotificationEvent {
  final int id;
  DeleteNotificationEvent(this.id);
}

class DeleteAllNotificationsEvent extends NotificationEvent {}

// State
class NotificationState {
  final UiState<List<NotificationEntity>> notificationsState;
  final int unreadCount;
  final String? errorMessage;

  const NotificationState({
    this.notificationsState = const Initial(),
    this.unreadCount = 0,
    this.errorMessage,
  });

  NotificationState copyWith({
    UiState<List<NotificationEntity>>? notificationsState,
    int? unreadCount,
    String? errorMessage,
  }) {
    return NotificationState(
      notificationsState: notificationsState ?? this.notificationsState,
      unreadCount: unreadCount ?? this.unreadCount,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

// BLoC
class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NotificationRepository repository;

  NotificationBloc({required this.repository})
    : super(const NotificationState()) {
    on<FetchNotifications>(_onFetch);
    on<MarkAsReadEvent>(_onMarkAsRead);
    on<MarkAllAsReadEvent>(_onMarkAllAsRead);
    on<DeleteNotificationEvent>(_onDelete);
    on<DeleteAllNotificationsEvent>(_onDeleteAll);
  }

  Future<void> _onFetch(
    FetchNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    emit(state.copyWith(notificationsState: const Loading()));

    final result = await repository.getAllNotifications();
    final countResult = await repository.getUnreadCount();

    result.fold(
      (failure) => emit(
        state.copyWith(
          notificationsState: Error(failure.message),
          errorMessage: failure.message,
        ),
      ),
      (notifications) {
        countResult.fold(
          (failure) => emit(
            state.copyWith(
              notificationsState: notifications.isEmpty
                  ? const Empty()
                  : Success(notifications),
            ),
          ),
          (count) => emit(
            state.copyWith(
              notificationsState: notifications.isEmpty
                  ? const Empty()
                  : Success(notifications),
              unreadCount: count,
            ),
          ),
        );
      },
    );
  }

  Future<void> _onMarkAsRead(
    MarkAsReadEvent event,
    Emitter<NotificationState> emit,
  ) async {
    await repository.markAsRead(event.id);
    add(FetchNotifications());
  }

  Future<void> _onMarkAllAsRead(
    MarkAllAsReadEvent event,
    Emitter<NotificationState> emit,
  ) async {
    await repository.markAllAsRead();
    add(FetchNotifications());
  }

  Future<void> _onDelete(
    DeleteNotificationEvent event,
    Emitter<NotificationState> emit,
  ) async {
    await repository.deleteNotification(event.id);
    add(FetchNotifications());
  }

  Future<void> _onDeleteAll(
    DeleteAllNotificationsEvent event,
    Emitter<NotificationState> emit,
  ) async {
    await repository.deleteAllNotifications();
    add(FetchNotifications());
  }
}
