import 'package:bamabin_desktop/data/remote/model/user/vip_info.dart';
import 'package:bamabin_desktop/data/remote/model/videos/home_sections.dart';
import 'package:bamabin_desktop/data/remote/model/videos/genre.dart';
import 'package:bamabin_desktop/data/remote/model/videos/post.dart';
import 'package:bamabin_desktop/data/remote/model/app/department.dart';
import 'package:bamabin_desktop/data/remote/model/app/about_us.dart';
import 'package:bamabin_desktop/data/remote/model/videos/taxonomy.dart';
import 'package:flutter/material.dart';

class TempDb {
  static var homeSections = ValueNotifier<List<HomeSection>>([]);
  static var isLoggedIn = ValueNotifier<bool>(false);
  static var vipInfo = ValueNotifier<VipInfo>(VipInfo(isVip: false, days: 0));
  static var haveUnreadNotif = ValueNotifier<bool>(false);

  static late AboutUs aboutUs;
  static List<Genre> genres = [];
  static List<Department> departments = [];
  static List<Post> promotions = [];
  static String apiKey = '';
  static String avatar = '';
  static String username = '';
  static String supportLink = '';
  static List<Taxonomy> contries = [];
  static List<Taxonomy> languages = [];
  static List<Taxonomy> ageRates = [];
  static List<Taxonomy> networks = [];
}
