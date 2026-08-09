import 'package:bamabin_desktop/data/remote/model/app/department.dart';
import 'package:bamabin_desktop/data/remote/model/user/ticket.dart';
import 'package:bamabin_desktop/repository/ticket_repository.dart';
import 'package:bamabin_desktop/utils/data_state.dart';
import 'package:bloc/bloc.dart';

part 'tickets_event.dart';
part 'tickets_state.dart';

class TicketsBloc extends Bloc<TicketsEvent, TicketsState> {
  TicketsBloc(this._ticketRepository) : super(TicketsInitial()) {
    on<TicketsLoadEvent>(_onLoad);
    on<TicketsSelectDepartmentEvent>(_onSelectDepartment);
    on<TicketsCreateEvent>(_onCreate);
    on<TicketsClearFeedbackEvent>(_onClearFeedback);
    on<TicketsClearNavigationEvent>(_onClearNavigation);
  }

  final TicketRepository _ticketRepository;

  static const _type = 'ticket';

  Future<void> _onLoad(
    TicketsLoadEvent event,
    Emitter<TicketsState> emit,
  ) async {
    emit(TicketsLoading());

    final departmentsResult = await _ticketRepository.getDepartments(_type);
    if (departmentsResult is DataError) {
      emit(TicketsError(departmentsResult.errorMessage));
      return;
    }

    final ticketsResult = await _ticketRepository.getTickets(_type);
    if (ticketsResult is DataError) {
      emit(TicketsError(ticketsResult.errorMessage));
      return;
    }

    emit(
      TicketsLoaded(
        tickets: ticketsResult.data ?? const [],
        departments: departmentsResult.data ?? const [],
      ),
    );
  }

  void _onSelectDepartment(
    TicketsSelectDepartmentEvent event,
    Emitter<TicketsState> emit,
  ) {
    final current = state;
    if (current is! TicketsLoaded) return;
    emit(
      current.copyWith(
        selectedDepartmentId: event.departmentId,
        clearSelectedDepartment: event.departmentId == null,
        clearFeedback: true,
      ),
    );
  }

  Future<void> _onCreate(
    TicketsCreateEvent event,
    Emitter<TicketsState> emit,
  ) async {
    final current = state;
    if (current is! TicketsLoaded) return;

    final departmentId = current.selectedDepartmentId;
    final title = event.title.trim();
    final content = event.content.trim();

    if (departmentId == null) {
      emit(
        current.copyWith(
          feedbackMessage: 'موضوع تیکت را انتخاب کنید',
          feedbackIsError: true,
        ),
      );
      return;
    }
    if (title.isEmpty) {
      emit(
        current.copyWith(
          feedbackMessage: 'عنوان تیکت را وارد کنید',
          feedbackIsError: true,
        ),
      );
      return;
    }
    if (content.isEmpty) {
      emit(
        current.copyWith(
          feedbackMessage: 'توضیحات تیکت را وارد کنید',
          feedbackIsError: true,
        ),
      );
      return;
    }

    emit(
      current.copyWith(
        isSubmitting: true,
        clearFeedback: true,
        clearNavigation: true,
      ),
    );

    final result = await _ticketRepository.createTicket(
      title,
      departmentId,
      content,
    );

    if (result is DataError) {
      emit(
        current.copyWith(
          isSubmitting: false,
          feedbackMessage: result.errorMessage,
          feedbackIsError: true,
        ),
      );
      return;
    }

    final ticketsResult = await _ticketRepository.getTickets(_type);
    final tickets = ticketsResult is DataSuccess
        ? (ticketsResult.data ?? current.tickets)
        : current.tickets;

    final createdId = result.data ?? _findCreatedTicketId(tickets, title);

    emit(
      current.copyWith(
        tickets: tickets,
        isSubmitting: false,
        clearSelectedDepartment: true,
        feedbackMessage: 'تیکت با موفقیت ارسال شد',
        feedbackIsError: false,
        navigateToTicketId: createdId,
      ),
    );
  }

  int? _findCreatedTicketId(List<Ticket> tickets, String title) {
    Ticket? best;
    for (final ticket in tickets) {
      if (ticket.title?.trim() != title) continue;
      if (best == null || ticket.id > best.id) best = ticket;
    }
    return best?.id;
  }

  void _onClearFeedback(
    TicketsClearFeedbackEvent event,
    Emitter<TicketsState> emit,
  ) {
    final current = state;
    if (current is! TicketsLoaded) return;
    emit(current.copyWith(clearFeedback: true));
  }

  void _onClearNavigation(
    TicketsClearNavigationEvent event,
    Emitter<TicketsState> emit,
  ) {
    final current = state;
    if (current is! TicketsLoaded) return;
    emit(current.copyWith(clearNavigation: true));
  }
}
