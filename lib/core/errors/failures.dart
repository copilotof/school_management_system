import 'package:equatable/equatable.dart';

/// 📁 حالات الفشل - تمثل الأخطاء في طبقة المجال

abstract class Failure extends Equatable {
  final String message;
  final int? code;
  const Failure(this.message, {this.code});

  @override
  List<Object?> get props => [message, code];
}

/// فشل في قاعدة البيانات
class DatabaseFailure extends Failure {
  const DatabaseFailure(super.message, {super.code});
}

/// فشل في الشبكة
class NetworkFailure extends Failure {
  const NetworkFailure(super.message, {super.code});
}

/// فشل غير متوقع
class UnexpectedFailure extends Failure {
  const UnexpectedFailure([super.message = 'حدث خطأ غير متوقع']);
}

/// فشل في التحقق
class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

/// فشل في المصادقة
class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.code});
}

/// فشل: غير موجود
class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message);
}
