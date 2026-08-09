part of 'ticket_details_bloc.dart';

sealed class TicketDetailsState {
  const TicketDetailsState();
}

class TicketDetailsInitial extends TicketDetailsState {
  const TicketDetailsInitial();
}

class TicketDetailsLoading extends TicketDetailsState {
  const TicketDetailsLoading();
}

class TicketDetailsError extends TicketDetailsState {
  const TicketDetailsError(this.message);

  final String message;
}

class TicketDetailsLoaded extends TicketDetailsState {
  TicketDetailsLoaded({
    required this.details,
    this.isSending = false,
    this.feedbackMessage,
    this.feedbackIsError = false,
    this.clearComposer = false,
  });

  final TicketDetails details;
  final bool isSending;
  final String? feedbackMessage;
  final bool feedbackIsError;
  final bool clearComposer;

  bool get isClosed {
    final name = details.ticket.statusName.trim().toLowerCase();
    return name.contains('بسته') ||
        name.contains('close') ||
        name.contains('closed') ||
        name.contains('done');
  }

  TicketDetailsLoaded copyWith({
    TicketDetails? details,
    bool? isSending,
    String? feedbackMessage,
    bool? feedbackIsError,
    bool clearFeedback = false,
    bool? clearComposer,
  }) {
    return TicketDetailsLoaded(
      details: details ?? this.details,
      isSending: isSending ?? this.isSending,
      feedbackMessage:
          clearFeedback ? null : (feedbackMessage ?? this.feedbackMessage),
      feedbackIsError: feedbackIsError ?? this.feedbackIsError,
      clearComposer: clearComposer ?? false,
    );
  }
}
