import 'package:drift/drift.dart';
import 'package:fpdart/fpdart.dart';
import 'package:school_management_system/core/errors/failures.dart';
import 'package:school_management_system/core/services/translation_service.dart';
import 'package:school_management_system/features/finance/data/models/finance_mapper.dart';
import 'package:school_management_system/features/finance/data/sources/finance_local_source.dart';
import 'package:school_management_system/features/finance/domain/entities/payment_entity.dart';
import 'package:school_management_system/features/finance/domain/repositories/finance_repository.dart';

class FinanceRepositoryImpl implements FinanceRepository {
  final FinanceLocalDataSource localDataSource;

  FinanceRepositoryImpl({required this.localDataSource});

  /// ✅ رسالة فشل مترجَمة — المستودع بلا `BuildContext` فيستخدم خدمة الترجمة
  /// (دالة واحدة تمنع تكرار نفس البناء في 12 موضعًا)
  DatabaseFailure _failure(String key, Object error) => DatabaseFailure(
    TranslationService.instance.tr(key, params: {'error': '$error'}),
  );

  @override
  Future<Either<Failure, List<PaymentEntity>>> getAllPayments() async {
    try {
      final rows = await localDataSource.getAllPayments();
      return Right(rows.map((r) => r.toEntity()).toList());
    } catch (e) {
      return Left(_failure('errors.fetchPayments', e));
    }
  }

  @override
  Future<Either<Failure, List<PaymentEntity>>> getPaymentsByStudent(
    int studentId,
  ) async {
    try {
      final rows = await localDataSource.getPaymentsByStudent(studentId);
      return Right(rows.map((r) => r.toEntity()).toList());
    } catch (e) {
      return Left(_failure('errors.fetchStudentPayments', e));
    }
  }

  @override
  Future<Either<Failure, List<PaymentEntity>>> getPaymentsByStudentAndGroup(
    int studentId,
    int groupId,
  ) async {
    try {
      final rows = await localDataSource.getPaymentsByStudentAndGroup(
        studentId,
        groupId,
      );
      return Right(rows.map((r) => r.toEntity()).toList());
    } catch (e) {
      return Left(_failure('errors.fetchStudentPayments', e));
    }
  }

  @override
  Future<Either<Failure, List<PaymentEntity>>> getOutstandingPayments() async {
    try {
      final rows = await localDataSource.getOutstandingPayments();
      return Right(rows.map((r) => r.toEntity()).toList());
    } catch (e) {
      return Left(_failure('errors.fetchOutstanding', e));
    }
  }

  @override
  Future<Either<Failure, Set<String>>> getPaidMonths(
    int studentId,
    int groupId,
  ) async {
    try {
      return Right(await localDataSource.getPaidMonths(studentId, groupId));
    } catch (e) {
      return Left(_failure('errors.fetchPaidMonths', e));
    }
  }

  @override
  Future<Either<Failure, int>> createPayment(PaymentEntity payment) async {
    try {
      final companion = PaymentMapper.fromEntity(payment);
      return Right(await localDataSource.createPayment(companion));
    } catch (e) {
      return Left(_failure('errors.createPayment', e));
    }
  }

  @override
  Future<Either<Failure, bool>> updatePayment(PaymentEntity payment) async {
    try {
      final rows = await localDataSource.getAllPayments();
      final row = rows.where((r) => r.id == payment.id).firstOrNull;
      if (row == null) {
        return Left(
          NotFoundFailure(TranslationService.instance.tr('errors.notFound')),
        );
      }
      final updated = row.copyWith(
        amount: payment.amount,
        remainingAmount: payment.remainingAmount,
        notes: Value(payment.notes),
      );
      return Right(await localDataSource.updatePayment(updated));
    } catch (e) {
      return Left(_failure('errors.updatePayment', e));
    }
  }

  @override
  Future<Either<Failure, bool>> deletePayment(int id) async {
    try {
      return Right(await localDataSource.deletePayment(id) > 0);
    } catch (e) {
      return Left(_failure('errors.deletePayment', e));
    }
  }

  @override
  Future<Either<Failure, double>> getTotalPaidByStudent(int studentId) async {
    try {
      return Right(await localDataSource.getTotalPaidByStudent(studentId));
    } catch (e) {
      return Left(_failure('errors.fetchPaidTotal', e));
    }
  }

  @override
  Future<Either<Failure, double>> getTotalRemainingByStudent(
    int studentId,
  ) async {
    try {
      return Right(await localDataSource.getTotalRemainingByStudent(studentId));
    } catch (e) {
      return Left(_failure('errors.fetchRemainingTotal', e));
    }
  }

  @override
  Future<Either<Failure, double>> getTotalRevenue() async {
    try {
      return Right(await localDataSource.getTotalRevenue());
    } catch (e) {
      return Left(_failure('errors.fetchRevenue', e));
    }
  }

  @override
  Future<Either<Failure, double>> getTotalOutstanding() async {
    try {
      return Right(await localDataSource.getTotalOutstanding());
    } catch (e) {
      return Left(_failure('errors.fetchOutstanding', e));
    }
  }
}
