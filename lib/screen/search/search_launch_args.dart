import 'package:bamabin_desktop/screen/search/bloc/search_bloc.dart';

class SearchLaunchArgs {
  const SearchLaunchArgs({
    required this.title,
    this.filters = const SearchFilters(),
  });

  final String title;
  final SearchFilters filters;
}
