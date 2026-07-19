import 'package:bamabin_desktop/data/remote/api_service/ticket_api_service.dart';
import 'package:bamabin_desktop/data/remote/model/app/department.dart';
import 'package:bamabin_desktop/data/remote/model/user/ticket.dart';
import 'package:bamabin_desktop/data/remote/model/user/ticket_details.dart';
import 'package:bamabin_desktop/utils/data_state.dart';

class TicketRepository {
  final TicketApiService _apiService;
  TicketRepository(this._apiService);

  Future<DataState<List<Ticket>>> getTickets(String type) async {
    final response = await _apiService.getTickets(type);
    if (response.status) {
      return DataSuccess(response.data);
    } else {
      return DataError(response.message ?? 'خطایی رخ داده است');
    }
  }

  Future<DataState<List<Department>>> getDepartments(String type) async {
    final response = await _apiService.getDepartments(type);
    if (response.status) {
      return DataSuccess(response.data);
    } else {
      return DataError(response.message ?? 'خطایی رخ داده است');
    }
  }

  Future<DataState<TicketDetails>> getTicketDetails(String type, int id) async {
    final response = await _apiService.getTicketDetails(type, id);
    if (response.status) {
      return DataSuccess(response.data);
    } else {
      return DataError(response.message ?? 'خطایی رخ داده است');
    }
  }

  Future<DataState<dynamic>> createTicket(
    String title,
    int department,
    String content,
  ) async {
    final response = await _apiService.addTicket(title, department, content);
    if (response.status) {
      return DataSuccess(response.data);
    } else {
      return DataError(response.message ?? 'خطایی رخ داده است');
    }
  }

  Future<DataState<dynamic>> replyTicket(
    String type,
    int id,
    String content,
  ) async {
    final response = await _apiService.replyTicket(type, id, content);
    if (response.status) {
      return DataSuccess(response.data);
    } else {
      return DataError(response.message ?? 'خطایی رخ داده است');
    }
  }
}
