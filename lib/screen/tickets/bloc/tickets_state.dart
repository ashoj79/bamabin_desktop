part of 'tickets_bloc.dart';

sealed class TicketsState {}

class TicketsInitial extends TicketsState {}

class TicketsLoading extends TicketsState {}

class TicketsError extends TicketsState {
  TicketsError(this.message);

  final String message;
}

class TicketsLoaded extends TicketsState {
  TicketsLoaded({
    required this.tickets,
    required this.departments,
    this.selectedDepartmentId,
    this.isSubmitting = false,
    this.feedbackMessage,
    this.feedbackIsError = false,
    this.navigateToTicketId,
  });

  final List<Ticket> tickets;
  final List<Department> departments;
  final int? selectedDepartmentId;
  final bool isSubmitting;
  final String? feedbackMessage;
  final bool feedbackIsError;
  final int? navigateToTicketId;

  Department? get selectedDepartment {
    final id = selectedDepartmentId;
    if (id == null) return null;
    for (final d in departments) {
      if (d.id == id) return d;
    }
    return null;
  }

  TicketsLoaded copyWith({
    List<Ticket>? tickets,
    List<Department>? departments,
    int? selectedDepartmentId,
    bool clearSelectedDepartment = false,
    bool? isSubmitting,
    String? feedbackMessage,
    bool? feedbackIsError,
    bool clearFeedback = false,
    int? navigateToTicketId,
    bool clearNavigation = false,
  }) {
    return TicketsLoaded(
      tickets: tickets ?? this.tickets,
      departments: departments ?? this.departments,
      selectedDepartmentId: clearSelectedDepartment
          ? null
          : (selectedDepartmentId ?? this.selectedDepartmentId),
      isSubmitting: isSubmitting ?? this.isSubmitting,
      feedbackMessage:
          clearFeedback ? null : (feedbackMessage ?? this.feedbackMessage),
      feedbackIsError: feedbackIsError ?? this.feedbackIsError,
      navigateToTicketId: clearNavigation
          ? null
          : (navigateToTicketId ?? this.navigateToTicketId),
    );
  }
}
