import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_management_system/core/states/ui_state.dart';
import 'package:school_management_system/features/finance/domain/entities/payment_entity.dart';
import 'package:school_management_system/features/finance/domain/repositories/finance_repository.dart';

import '../../../notifications/domain/repositories/notification_repository.dart';

// ====== Events ======
abstract class FinanceEvent {}

class FetchAllFinanceData extends FinanceEvent {}

class FetchPayments extends FinanceEvent {}

class CreatePaymentEvent extends FinanceEvent {
  final PaymentEntity payment;
  CreatePaymentEvent(this.payment);
}

class UpdatePaymentEvent extends FinanceEvent {
  final PaymentEntity payment;
  UpdatePaymentEvent(this.payment);
}

class DeletePaymentEvent extends FinanceEvent {
  final int id;
  DeletePaymentEvent(this.id);
}

// ====== State ======
class FinanceState {
  final UiState<List<PaymentEntity>> paymentsState;
  final double totalRevenue;
  final double totalOutstanding;
  final String? errorMessage;

  const FinanceState({
    this.paymentsState = const Initial(),
    this.totalRevenue = 0,
    this.totalOutstanding = 0,
    this.errorMessage,
  });

  FinanceState copyWith({
    UiState<List<PaymentEntity>>? paymentsState,
    double? totalRevenue,
    double? totalOutstanding,
    String? errorMessage,
  }) {
    return FinanceState(
      paymentsState: paymentsState ?? this.paymentsState,
      totalRevenue: totalRevenue ?? this.totalRevenue,
      totalOutstanding: totalOutstanding ?? this.totalOutstanding,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

// ====== BLoC ======
class FinanceBloc extends Bloc<FinanceEvent, FinanceState> {
  final FinanceRepository repository;
  final NotificationRepository notificationRepository;

  FinanceBloc({required this.repository, required this.notificationRepository})
    : super(const FinanceState()) {
    on<FetchAllFinanceData>(_onFetchAll);
    on<FetchPayments>(_onFetchPayments);
    on<CreatePaymentEvent>(_onCreatePayment);
    on<UpdatePaymentEvent>(_onUpdatePayment);
    on<DeletePaymentEvent>(_onDeletePayment);
  }

  Future<void> _onFetchAll(
    FetchAllFinanceData event,
    Emitter<FinanceState> emit,
  ) async {
    add(FetchPayments());

    final revenue = await repository.getTotalRevenue();
    revenue.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (value) => emit(state.copyWith(totalRevenue: value)),
    );

    final outstanding = await repository.getTotalOutstanding();
    outstanding.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (value) => emit(state.copyWith(totalOutstanding: value)),
    );
  }

  Future<void> _onFetchPayments(
    FetchPayments event,
    Emitter<FinanceState> emit,
  ) async {
    emit(state.copyWith(paymentsState: const Loading()));
    final result = await repository.getAllPayments();
    result.fold(
      (failure) => emit(
        state.copyWith(
          paymentsState: Error(failure.message),
          errorMessage: failure.message,
        ),
      ),
      (payments) => emit(
        state.copyWith(
          paymentsState: payments.isEmpty ? const Empty() : Success(payments),
        ),
      ),
    );
  }

  Future<void> _onCreatePayment(
    CreatePaymentEvent event,
    Emitter<FinanceState> emit,
  ) async {
    final result = await repository.createPayment(event.payment);

    await result.fold(
      (failure) async {
        emit(state.copyWith(errorMessage: failure.message));
      },
      (_) async {
        // ✅ إذا كانت دفعة حقيقية (ليس إعفاء)، احذف إشعار الدفع
        if (event.payment.type != 'exemption') {
          await notificationRepository.deletePaymentNotificationsByStudent(
            event.payment.studentId,
          );
          debugPrint(
            '🟢 تم حذف إشعارات الدفع للطالب ${event.payment.studentId}',
          );
        }

        add(FetchAllFinanceData());
      },
    );
  }

  Future<void> _onUpdatePayment(
    UpdatePaymentEvent event,
    Emitter<FinanceState> emit,
  ) async {
    final result = await repository.updatePayment(event.payment);
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (_) => add(FetchAllFinanceData()),
    );
  }

  Future<void> _onDeletePayment(
    DeletePaymentEvent event,
    Emitter<FinanceState> emit,
  ) async {
    final result = await repository.deletePayment(event.id);
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (_) => add(FetchAllFinanceData()),
    );
  }
}
