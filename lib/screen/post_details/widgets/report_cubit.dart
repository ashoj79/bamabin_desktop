import 'package:bamabin_desktop/data/local/temp_db.dart';
import 'package:bamabin_desktop/data/remote/model/app/department.dart';
import 'package:bamabin_desktop/repository/app_repository.dart';
import 'package:bamabin_desktop/utils/data_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ReportCubit extends Cubit<ReportState> {
  ReportCubit(this._appRepository, this.postId) : super(const ReportState()) {
    loadDepartments();
  }

  final AppRepository _appRepository;
  final int postId;

  Future<void> loadDepartments() async {
    if (TempDb.departments.isNotEmpty) {
      emit(
        state.copyWith(
          departments: List<Department>.from(TempDb.departments),
          isLoadingDepartments: false,
          clearDepartmentsError: true,
        ),
      );
      return;
    }

    emit(state.copyWith(isLoadingDepartments: true, clearDepartmentsError: true));

    final result = await _appRepository.getDepartments('report');
    if (result is DataSuccess<List<Department>>) {
      final departments = result.data ?? const <Department>[];
      TempDb.departments = departments;
      emit(
        state.copyWith(
          departments: departments,
          isLoadingDepartments: false,
          clearDepartmentsError: true,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        isLoadingDepartments: false,
        departmentsError: result.errorMessage,
      ),
    );
  }

  void selectDepartment(int? departmentId) {
    emit(
      state.copyWith(
        selectedDepartmentId: departmentId,
        clearSelectedDepartment: departmentId == null,
        clearFeedback: true,
      ),
    );
  }

  Future<void> submit(String content) async {
    final departmentId = state.selectedDepartmentId;
    final trimmed = content.trim();

    if (departmentId == null) {
      emit(
        state.copyWith(
          feedbackMessage: 'موضوع گزارش را انتخاب کنید',
          feedbackIsError: true,
        ),
      );
      return;
    }
    if (trimmed.isEmpty) {
      emit(
        state.copyWith(
          feedbackMessage: 'توضیحات گزارش را وارد کنید',
          feedbackIsError: true,
        ),
      );
      return;
    }

    emit(state.copyWith(isSubmitting: true, clearFeedback: true));

    final result = await _appRepository.saveReport(
      departmentId,
      trimmed,
      postId,
    );

    if (result is DataError) {
      emit(
        state.copyWith(
          isSubmitting: false,
          feedbackMessage: result.errorMessage,
          feedbackIsError: true,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        isSubmitting: false,
        submitted: true,
        feedbackMessage: 'گزارش با موفقیت ارسال شد',
        feedbackIsError: false,
      ),
    );
  }

  void clearFeedback() {
    emit(state.copyWith(clearFeedback: true));
  }
}

class ReportState {
  const ReportState({
    this.departments = const [],
    this.selectedDepartmentId,
    this.isLoadingDepartments = true,
    this.departmentsError,
    this.isSubmitting = false,
    this.feedbackMessage,
    this.feedbackIsError = false,
    this.submitted = false,
  });

  final List<Department> departments;
  final int? selectedDepartmentId;
  final bool isLoadingDepartments;
  final String? departmentsError;
  final bool isSubmitting;
  final String? feedbackMessage;
  final bool feedbackIsError;
  final bool submitted;

  ReportState copyWith({
    List<Department>? departments,
    int? selectedDepartmentId,
    bool clearSelectedDepartment = false,
    bool? isLoadingDepartments,
    String? departmentsError,
    bool clearDepartmentsError = false,
    bool? isSubmitting,
    String? feedbackMessage,
    bool? feedbackIsError,
    bool clearFeedback = false,
    bool? submitted,
  }) {
    return ReportState(
      departments: departments ?? this.departments,
      selectedDepartmentId: clearSelectedDepartment
          ? null
          : (selectedDepartmentId ?? this.selectedDepartmentId),
      isLoadingDepartments: isLoadingDepartments ?? this.isLoadingDepartments,
      departmentsError: clearDepartmentsError
          ? null
          : (departmentsError ?? this.departmentsError),
      isSubmitting: isSubmitting ?? this.isSubmitting,
      feedbackMessage:
          clearFeedback ? null : (feedbackMessage ?? this.feedbackMessage),
      feedbackIsError: feedbackIsError ?? this.feedbackIsError,
      submitted: submitted ?? this.submitted,
    );
  }
}
