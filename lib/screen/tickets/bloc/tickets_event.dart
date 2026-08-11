part of 'tickets_bloc.dart';

sealed class TicketsEvent {}

class TicketsLoadEvent extends TicketsEvent {}

class TicketsSelectListTypeEvent extends TicketsEvent {
  TicketsSelectListTypeEvent(this.listType);

  final TicketsListType listType;
}

class TicketsSelectDepartmentEvent extends TicketsEvent {
  TicketsSelectDepartmentEvent(this.departmentId);

  final int? departmentId;
}

class TicketsCreateEvent extends TicketsEvent {
  TicketsCreateEvent({
    required this.title,
    required this.content,
  });

  final String title;
  final String content;
}

class TicketsClearFeedbackEvent extends TicketsEvent {}

class TicketsClearNavigationEvent extends TicketsEvent {}
