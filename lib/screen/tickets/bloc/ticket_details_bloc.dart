import 'package:bamabin_desktop/data/remote/model/user/ticket_details.dart';
import 'package:bamabin_desktop/repository/ticket_repository.dart';
import 'package:bamabin_desktop/utils/data_state.dart';
import 'package:bloc/bloc.dart';

part 'ticket_details_event.dart';
part 'ticket_details_state.dart';

class TicketDetailsBloc extends Bloc<TicketDetailsEvent, TicketDetailsState> {
  TicketDetailsBloc(this._ticketRepository) : super(TicketDetailsInitial()) {
    on<TicketDetailsLoadEvent>(_onLoad);
    on<TicketDetailsReplyEvent>(_onReply);
    on<TicketDetailsClearFeedbackEvent>(_onClearFeedback);
  }

  final TicketRepository _ticketRepository;

  String _type = 'ticket';

  Future<void> _onLoad(
    TicketDetailsLoadEvent event,
    Emitter<TicketDetailsState> emit,
  ) async {
    _type = event.type;
    emit(TicketDetailsLoading());

    final result =
        await _ticketRepository.getTicketDetails(_type, event.ticketId);
    if (result is DataError) {
      emit(TicketDetailsError(result.errorMessage));
      return;
    }

    final details = result.data;
    if (details == null) {
      emit(const TicketDetailsError('جزئیات تیکت یافت نشد'));
      return;
    }

    emit(TicketDetailsLoaded(details: details));
  }

  Future<void> _onReply(
    TicketDetailsReplyEvent event,
    Emitter<TicketDetailsState> emit,
  ) async {
    final current = state;
    if (current is! TicketDetailsLoaded) return;
    if (current.isClosed) return;

    final content = event.content.trim();
    if (content.isEmpty) {
      emit(
        current.copyWith(
          feedbackMessage: 'متن پیام را وارد کنید',
          feedbackIsError: true,
        ),
      );
      return;
    }

    emit(current.copyWith(isSending: true, clearFeedback: true));

    final ticketId = current.details.ticket.id;
    final result = await _ticketRepository.replyTicket(_type, ticketId, content);

    if (result is DataError) {
      emit(
        current.copyWith(
          isSending: false,
          feedbackMessage: result.errorMessage,
          feedbackIsError: true,
        ),
      );
      return;
    }

    final refreshed = await _ticketRepository.getTicketDetails(_type, ticketId);
    if (refreshed is DataSuccess && refreshed.data != null) {
      emit(
        TicketDetailsLoaded(
          details: refreshed.data!,
          clearComposer: true,
        ),
      );
      return;
    }

    emit(current.copyWith(isSending: false));
  }

  void _onClearFeedback(
    TicketDetailsClearFeedbackEvent event,
    Emitter<TicketDetailsState> emit,
  ) {
    final current = state;
    if (current is! TicketDetailsLoaded) return;
    emit(current.copyWith(clearFeedback: true));
  }
}
