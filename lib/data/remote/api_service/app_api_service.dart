import 'package:bamabin_desktop/data/remote/api_service/base_api_service.dart';
import 'package:bamabin_desktop/data/remote/model/app/department.dart';
import 'package:bamabin_desktop/data/remote/model/app/gateway.dart';
import 'package:bamabin_desktop/data/remote/model/app/notification.dart';
import 'package:bamabin_desktop/data/remote/model/app/plan.dart';
import 'package:bamabin_desktop/data/remote/model/app/plan_discount_price.dart';
import 'package:bamabin_desktop/data/remote/model/app/startup_data.dart';
import 'package:bamabin_desktop/data/remote/model/api_response.dart';
import 'package:bamabin_desktop/data/remote/model/videos/search_taxonomies.dart';

class AppApiService extends BaseApiService {
  AppApiService(super.dioHelper);

  Future<ApiResponse<StartupData>> getStartupData() async {
    return await get(
      '/startup',
      (json) => StartupData.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<dynamic>> saveReport(
    int department,
    String content,
    int postId,
  ) async {
    return await post(
      '/report/create',
      (json) => null,
      data: {'department': department, 'content': content, 'title': postId},
    );
  }

  Future<ApiResponse<List<Department>>> getDepartments(String type) async {
    return await get(
      '/$type/departments',
      (json) => List<Department>.generate(
        json.length,
        (index) => Department.fromJson(json[index] as Map<String, dynamic>),
      ),
    );
  }

  Future<ApiResponse<SearchTaxonomies>> getSearchTaxonomies() async {
    return await get(
      '/search_taxonomies',
      (json) => SearchTaxonomies.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<List<Plan>>> getPlans() async {
    return await get(
      '/subscription/plans',
      (json) => List<Plan>.generate(
        json.length,
        (index) => Plan.fromJson(json[index] as Map<String, dynamic>),
      ),
    );
  }

  Future<ApiResponse<List<Gateway>>> getGateways() async {
    return await get(
      '/subscription/gateways',
      (json) => List<Gateway>.generate(
        json.length,
        (index) => Gateway.fromJson(json[index] as Map<String, dynamic>),
      ),
    );
  }

  Future<ApiResponse<List<PlanDiscountPrice>>> verifyDiscountForAllPlans(
    String code,
  ) async {
    return await get(
      '/subscription/discount_for_all_plans',
      (json) => List<PlanDiscountPrice>.generate(
        (json as List).length,
        (index) => PlanDiscountPrice.fromJson(
          json[index] as Map<String, dynamic>,
        ),
      ),
      queryParameters: {'discount_code': code},
    );
  }

  Future<ApiResponse<String>> buy(
    int planId,
    String gateway,
    String code,
  ) async {
    return await post(
      '/subscription/create_payment',
      (json) => json['url'],
      data: {'plan_id': planId, 'discount_code': code, 'gateway': gateway},
    );
  }

  Future<ApiResponse<List<Notification>>> getAllNotifications(int page) async {
    return await get(
      '/notification',
      (json) => List<Notification>.generate(
        json.length,
        (index) => Notification.fromJson(json[index] as Map<String, dynamic>),
      ),
      queryParameters: {'page': page},
    );
  }

  Future<ApiResponse<dynamic>> deleteAllNotifications(int id) async {
    return await delete('/notification', (json) => null, data: {'id': id});
  }

  Future<ApiResponse<String>> getTelegramToken() async {
    return await get('/telegram_token', (json) => json['token'] as String);
  }
}
