import 'package:equatable/equatable.dart';

/// 📁 الحالات الموحدة للواجهة

sealed class UiState<T> extends Equatable {
  const UiState();

  @override
  List<Object?> get props => [];

  bool get isLoading => this is Loading<T>;
  bool get isSuccess => this is Success<T>;
  bool get isError => this is Error<T>;
  bool get isEmpty => this is Empty<T>;
  bool get isInitial => this is Initial<T>;

  T? get data => this is Success<T> ? (this as Success<T>).data : null;
  String? get errorMessage =>
      this is Error<T> ? (this as Error<T>).message : null;
}

/// الحالة الأولية
class Initial<T> extends UiState<T> {
  const Initial();
}

/// جاري التحميل
class Loading<T> extends UiState<T> {
  const Loading();
}

/// نجاح مع بيانات
class Success<T> extends UiState<T> {
  final T data;
  const Success(this.data);

  @override
  List<Object?> get props => [data];
}

/// خطأ
class Error<T> extends UiState<T> {
  final String message;
  final int? code;
  const Error(this.message, {this.code});

  @override
  List<Object?> get props => [message, code];
}

/// نجاح بدون بيانات
class Empty<T> extends UiState<T> {
  const Empty();
}
