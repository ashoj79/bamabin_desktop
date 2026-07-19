import 'ticket.dart';
import 'ticket_reply.dart';

class TicketDetails {
  final Ticket ticket;
  final List<TicketReply> replies;

  TicketDetails({required this.ticket, required this.replies});

  factory TicketDetails.fromJson(Map<String, dynamic> json) => TicketDetails(
    ticket: Ticket.fromJson(json['ticket'] ?? {}),
    replies: (json['replies'] as List?)
            ?.map((e) => TicketReply.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
  );
}
