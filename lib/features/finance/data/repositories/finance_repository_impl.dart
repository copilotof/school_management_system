import 'package:drift/drift.dart';
import 'package:fpdart/fpdart.dart';
import 'package:school_management_system/core/errors/failures.dart';
import 'package:school_management_system/features/finance/data/models/finance_mapper.dart';
import 'package:school_management_system/features/finance/data/sources/finance_local_source.dart';
import 'package:school_management_system/features/finance/domain/entities/payment_entity.dart';
import 'package:school_management_system/features/finance/domain/repositories/finance_repository.dart';

class FinanceRepositoryImpl implements FinanceRepository {
  final FinanceLocalDataSource localDataSource;

  FinanceRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, List<PaymentEntity>>> getAllPayments() async {
    try {
      final rows = await localDataSource.getAllPayments();
      return Right(rows.map((r) => r.toEntity()).toList());
    } catch (e) {
      return Left(DatabaseFailure('فشل في جلب العمليات: $e'));
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
      return Left(DatabaseFailure('فشل في جلب عمليات الطالب: $e'));
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
      return Left(DatabaseFailure('فشل في جلب عمليات الطالب: $e'));
    }
  }

  @override
  Future<Either<Failure, List<PaymentEntity>>> getOutstandingPayments() async {
    try {
      final rows = await localDataSource.getOutstandingPayments();
      return Right(rows.map((r) => r.toEntity()).toList());
    } catch (e) {
      return Left(DatabaseFailure('فشل في جلب المتأخرات: $e'));
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
      return Left(DatabaseFailure('فشل في جلب الأشهر المدفوعة: $e'));
    }
  }

  @override
  Future<Either<Failure, int>> createPayment(PaymentEntity payment) async {
    try {
      final companion = PaymentMapper.fromEntity(payment);
      return Right(await localDataSource.createPayment(companion));
    } catch (e) {
      return Left(DatabaseFailure('فشل في تسجيل العملية: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> updatePayment(PaymentEntity payment) async {
    try {
      final rows = await localDataSource.getAllPayments();
      final row = rows.where((r) => r.id == payment.id).firstOrNull;
      if (row == null) return const Left(NotFoundFailure('العملية غير موجودة'));
      final updated = row.copyWith(
        amount: payment.amount,
        remainingAmount: payment.remainingAmount,
        notes: Value(payment.notes),
      );
      return Right(await localDataSource.updatePayment(updated));
    } catch (e) {
      return Left(DatabaseFailure('فشل في تحديث العملية: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> deletePayment(int id) async {
    try {
      return Right(await localDataSource.deletePayment(id) > 0);
    } catch (e) {
      return Left(DatabaseFailure('فشل في حذف العملية: $e'));
    }
  }

  @override
  Future<Either<Failure, double>> getTotalPaidByStudent(int studentId) async {
    try {
      return Right(await localDataSource.getTotalPaidByStudent(studentId));
    } catch (e) {
      return Left(DatabaseFailure('فشل في جلب المدفوع: $e'));
    }
  }

  @override
  Future<Either<Failure, double>> getTotalRemainingByStudent(
    int studentId,
  ) async {
    try {
      return Right(await localDataSource.getTotalRemainingByStudent(studentId));
    } catch (e) {
      return Left(DatabaseFailure('فشل في جلب المتبقي: $e'));
    }
  }

  @override
  Future<Either<Failure, double>> getTotalRevenue() async {
    try {
      return Right(await localDataSource.getTotalRevenue());
    } catch (e) {
      return Left(DatabaseFailure('فشل في جلب الإيرادات: $e'));
    }
  }

  @override
  Future<Either<Failure, double>> getTotalOutstanding() async {
    try {
      return Right(await localDataSource.getTotalOutstanding());
    } catch (e) {
      return Left(DatabaseFailure('فشل في جلب المتأخرات: $e'));
    }
  }
}
