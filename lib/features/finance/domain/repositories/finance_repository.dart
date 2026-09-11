import 'package:fpdart/fpdart.dart';
import 'package:school_management_system/core/errors/failures.dart';
import 'package:school_management_system/features/finance/domain/entities/payment_entity.dart';

abstract class FinanceRepository {
  Future<Either<Failure, List<PaymentEntity>>> getAllPayments();
  Future<Either<Failure, List<PaymentEntity>>> getPaymentsByStudent(
    int studentId,
  );
  Future<Either<Failure, List<PaymentEntity>>> getPaymentsByStudentAndGroup(
    int studentId,
    int groupId,
  );
  Future<Either<Failure, List<PaymentEntity>>> getOutstandingPayments();
  Future<Either<Failure, Set<String>>> getPaidMonths(
    int studentId,
    int groupId,
  );
  Future<Either<Failure, int>> createPayment(PaymentEntity payment);
  Future<Either<Failure, bool>> updatePayment(PaymentEntity payment);
  Future<Either<Failure, bool>> deletePayment(int id);
  Future<Either<Failure, double>> getTotalPaidByStudent(int studentId);
  Future<Either<Failure, double>> getTotalRemainingByStudent(int studentId);
  Future<Either<Failure, double>> getTotalRevenue();
  Future<Either<Failure, double>> getTotalOutstanding();
}
