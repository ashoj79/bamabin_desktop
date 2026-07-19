import 'package:bamabin_desktop/data/remote/api_service/base_api_service.dart';
import 'package:bamabin_desktop/data/remote/model/api_response.dart';
import 'package:bamabin_desktop/data/remote/model/app/department.dart';
import 'package:bamabin_desktop/data/remote/model/user/ticket.dart';
import 'package:bamabin_desktop/data/remote/model/user/ticket_details.dart';

class TicketApiService extends BaseApiService {
  TicketApiService(super.dioHelper);

  Future<ApiResponse<List<Ticket>>> getTickets(String type) async {
    return await get(
      '/$type/list',
      (json) => List.generate(json.length, (i) => Ticket.fromJson(json[i])),
    );
  }

  Future<ApiResponse<List<Department>>> getDepartments(String type) async {
    return await get(
      '/$type/departments',
      (json) => List.generate(json.length, (i) => Department.fromJson(json[i])),
    );
  }

  Future<ApiResponse<dynamic>> addTicket(
    String title,
    int department,
    String content,
  ) async {
    return await post(
      '/ticket/create',
      (json) => null,
      data: {'title': title, 'department': department, 'content': content},
    );
  }

  Future<ApiResponse<TicketDetails>> getTicketDetails(
    String type,
    int id,
  ) async {
    return await get('/$type/$id', (json) => TicketDetails.fromJson(json));
  }

  Future<ApiResponse<dynamic>> replyTicket(
    String type,
    int id,
    String content,
  ) async {
    return await post(
      '/$type/$id/reply',
      (json) => null,
      data: {'content': content},
    );
  }
}
