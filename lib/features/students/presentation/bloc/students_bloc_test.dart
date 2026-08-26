import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_management_system/core/errors/failures.dart';
import 'package:school_management_system/core/states/ui_state.dart';
import 'package:school_management_system/features/students/domain/entities/student_entity.dart';
import 'package:school_management_system/features/students/domain/usecases/create_student.dart';
import 'package:school_management_system/features/students/domain/usecases/delete_student.dart';
import 'package:school_management_system/features/students/domain/usecases/get_all_students.dart';
import 'package:school_management_system/features/students/domain/usecases/search_students.dart';
import 'package:school_management_system/features/students/domain/usecases/update_student.dart';
import 'package:school_management_system/features/students/presentation/bloc/students_bloc.dart';
import 'package:school_management_system/features/students/presentation/bloc/students_event.dart';
import 'package:school_management_system/features/students/presentation/bloc/students_state.dart';

// Mock Classes
class MockGetAllStudents extends Mock implements GetAllStudents {}

class MockSearchStudents extends Mock implements SearchStudents {}

class MockCreateStudent extends Mock implements CreateStudent {}

class MockUpdateStudent extends Mock implements UpdateStudent {}

class MockDeleteStudent extends Mock implements DeleteStudent {}

void main() {
  late StudentsBloc bloc;
  late MockGetAllStudents mockGetAllStudents;
  late MockCreateStudent mockCreateStudent;
  late MockSearchStudents mockSearchStudents;
  late MockUpdateStudent mockUpdateStudent;
  late MockDeleteStudent mockDeleteStudent;

  setUp(() {
    mockGetAllStudents = MockGetAllStudents();
    mockCreateStudent = MockCreateStudent();
    mockSearchStudents = MockSearchStudents();
    mockUpdateStudent = MockUpdateStudent();
    mockDeleteStudent = MockDeleteStudent();

    bloc = StudentsBloc(
      getAllStudents: mockGetAllStudents,
      searchStudents: mockSearchStudents,
      createStudent: mockCreateStudent,
      updateStudent: mockUpdateStudent,
      deleteStudent: mockDeleteStudent,
    );
  });

  tearDown(() {
    bloc.close();
  });

  group('FetchStudents', () {
    final testStudents = [
      const StudentEntity(
        studentCode: 'STU001',
        firstName: 'أحمد',
        lastName: 'محمد',
      ),
    ];

    blocTest<StudentsBloc, StudentsState>(
      'ينتقل من Loading إلى Success عند نجاح الجلب',
      build: () => bloc,
      act: (bloc) {
        when(
          () => mockGetAllStudents.call(),
        ).thenAnswer((_) async => Right(testStudents));
        bloc.add(const FetchStudents());
      },
      expect: () => [
        isA<StudentsState>().having(
          (s) => s.studentsState,
          'state',
          isA<Loading<List<StudentEntity>>>(),
        ),
        isA<StudentsState>().having(
          (s) => s.studentsState,
          'state',
          isA<Success<List<StudentEntity>>>(),
        ),
      ],
    );
  });
}
