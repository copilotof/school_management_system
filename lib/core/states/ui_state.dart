import 'package:equatable/equatable.dart';

/// 📁 الحالات الموحّدة للواجهة
///
/// نظام واحد لكل الشاشات: `Initial` / `Loading` / `Success` / `Error` / `Empty`
/// مبني على `sealed class` (Dart 3) ليستفيد من `switch` الشامل الآمن.
///
/// **مثال في الواجهة:**
/// ```dart
/// final child = switch (state.studentsState) {
///   Initial() => const SizedBox.shrink(),
///   Loading() => const CircularProgressIndicator(),
///   Success(data: final students) => StudentsList(students),
///   Error(message: final msg) => ErrorView(message: msg),
///   Empty() => const EmptyView(),
/// };
/// ```
sealed class UiState<T> extends Equatable {
  const UiState();

  @override
  List<Object?> get props => <Object?>[];

  // ============================================
  // فحوصات الحالة
  // ============================================

  /// هل الحالة `Initial`؟
  bool get isInitial => this is Initial<T>;

  /// هل الحالة `Loading`؟
  bool get isLoading => this is Loading<T>;

  /// هل الحالة `Success`؟
  bool get isSuccess => this is Success<T>;

  /// هل الحالة `Error`؟
  bool get isError => this is Error<T>;

  /// هل الحالة `Empty`؟
  bool get isEmpty => this is Empty<T>;

  /// هل انتهى التحميل؟ (نجاح أو فراغ)
  bool get isCompleted => isSuccess || isEmpty;

  // ============================================
  // الوصول للبيانات
  // ============================================

  /// البيانات الحالية (فقط عند `Success`) — وإلا `null`
  ///
  /// ملاحظة: الاسم `data` محفوظ كما هو لأن المشروع يستخدمه في ~95 موضعًا،
  /// و`dataOrNull` مرادف أوضح للكود الجديد.
  T? get data {
    final UiState<T> current = this;
    return switch (current) {
      Success<T>(data: final T value) => value,
      _ => null,
    };
  }

  /// مرادف أوضح لـ `data` — للاستخدام في الكود الجديد
  T? get dataOrNull => data;

  /// البيانات أو قيمة افتراضية إن لم تكن متاحة
  T dataOrDefault(T defaultValue) => data ?? defaultValue;

  /// هل يوجد بيانات؟
  bool get hasData => data != null;

  /// رسالة الخطأ (فقط عند `Error`)
  String? get errorMessage {
    final UiState<T> current = this;
    return switch (current) {
      Error<T>(message: final String message) => message,
      _ => null,
    };
  }

  /// كود الخطأ (فقط عند `Error`)
  int? get errorCode {
    final UiState<T> current = this;
    return switch (current) {
      Error<T>(code: final int? code) => code,
      _ => null,
    };
  }

  // ============================================
  // أدوات التعامل مع الحالة
  // ============================================

  /// تطبيق دالة حسب الحالة الحالية (تشمل كل الحالات)
  R when<R>({
    required R Function() initial,
    required R Function() loading,
    required R Function(T data) success,
    required R Function(String message, int? code) error,
    required R Function() empty,
  }) {
    final UiState<T> current = this;
    return switch (current) {
      Initial<T>() => initial(),
      Loading<T>() => loading(),
      Success<T>(data: final T value) => success(value),
      Error<T>(message: final String message, code: final int? code) =>
        error(message, code),
      Empty<T>() => empty(),
    };
  }

  /// مثل `when` لكن مع قيم افتراضية و`orElse` إلزامية
  R maybeWhen<R>({
    R Function()? initial,
    R Function()? loading,
    R Function(T data)? success,
    R Function(String message, int? code)? error,
    R Function()? empty,
    required R Function() orElse,
  }) {
    final UiState<T> current = this;
    return switch (current) {
      Initial<T>() => initial?.call() ?? orElse(),
      Loading<T>() => loading?.call() ?? orElse(),
      Success<T>(data: final T value) => success?.call(value) ?? orElse(),
      Error<T>(message: final String message, code: final int? code) =>
        error?.call(message, code) ?? orElse(),
      Empty<T>() => empty?.call() ?? orElse(),
    };
  }

  /// تحويل نوع البيانات مع الحفاظ على الحالة
  UiState<R> map<R>(R Function(T data) mapper) {
    final UiState<T> current = this;
    return switch (current) {
      Initial<T>() => Initial<R>(),
      Loading<T>() => Loading<R>(),
      Success<T>(data: final T value) => Success<R>(mapper(value)),
      Error<T>(message: final String message, code: final int? code) =>
        Error<R>(message, code: code),
      Empty<T>() => Empty<R>(),
    };
  }

  /// نسخة جديدة ببيانات مختلفة (تعمل فقط على `Success`)
  UiState<T> copyWithData(T newData) {
    return isSuccess ? Success<T>(newData) : this;
  }
}

// ================================================
// 📁 الحالات الفردية
// ================================================

/// 🔵 الحالة الأولية (قبل أي عملية)
class Initial<T> extends UiState<T> {
  const Initial();
}

/// 🟡 جاري التحميل
class Loading<T> extends UiState<T> {
  const Loading();
}

/// 🟢 نجاح مع بيانات
class Success<T> extends UiState<T> {
  const Success(this.data);

  /// يعمل كتجاوز لدالة `data` المعرَّفة في `UiState`
  @override
  final T data;

  @override
  List<Object?> get props => <Object?>[data];
}

/// 🔴 خطأ
class Error<T> extends UiState<T> {
  const Error(this.message, {this.code});

  final String message;
  final int? code;

  @override
  List<Object?> get props => <Object?>[message, code];
}

/// ⚪ نجاح بدون بيانات (قائمة فارغة مثلًا)
class Empty<T> extends UiState<T> {
  const Empty();
}

// ================================================
// 📁 أدوات مساعدة للقوائم
// ================================================

/// قائمة فارغة ثابتة (بلا أي تخصيص ذاكرة).
///
/// ⚠️ لا يمكن كتابة `const <T>[]` لأن التعبيرات الثابتة (const) لا تقبل
/// معامل نوع عام. و`List<Never>` تُسند إلى أي `List<T>` لأن `Never` نوع فرعي
/// لكل الأنواع.
const List<Never> _emptyList = <Never>[];

/// كل استخدامات `UiState` في المشروع تقريبًا هي `UiState<List<...>>`،
/// لذا هذه الأدوات تختصر فحوصات متكررة.
extension UiStateListExtensions<T> on UiState<List<T>> {
  /// عناصر القائمة (أو `null`)
  List<T>? get items => data;

  /// عناصر القائمة أو قائمة فارغة
  List<T> get itemsOrEmpty => data ?? _emptyList;

  /// عدد العناصر (أو صفر)
  int get itemsCount => data?.length ?? 0;

  /// هل القائمة فارغة؟
  bool get isListEmpty => itemsCount == 0;
}
