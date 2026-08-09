part of 'ticket_details_bloc.dart';

sealed class TicketDetailsEvent {}

class TicketDetailsLoadEvent extends TicketDetailsEvent {
  TicketDetailsLoadEvent(this.ticketId);

  final int ticketId;
}

class TicketDetailsReplyEvent extends TicketDetailsEvent {
  TicketDetailsReplyEvent(this.content);

  final String content;
}

class TicketDetailsClearFeedbackEvent extends TicketDetailsEvent {}
