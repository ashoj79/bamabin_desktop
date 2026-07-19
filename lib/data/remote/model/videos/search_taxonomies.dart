import 'taxonomy.dart';

class SearchTaxonomies {
  final List<Taxonomy> countries;
  final List<Taxonomy> languages;
  final List<Taxonomy> ageRates;
  final List<Taxonomy> networks;

  SearchTaxonomies({
    required this.countries,
    required this.languages,
    required this.ageRates,
    required this.networks,
  });

  factory SearchTaxonomies.fromJson(Map<String, dynamic> json) =>
      SearchTaxonomies(
        countries: (json['countries'] as List?)
                ?.map((e) => Taxonomy.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        languages: (json['languages'] as List?)
                ?.map((e) => Taxonomy.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        ageRates: (json['age_rates'] as List?)
                ?.map((e) => Taxonomy.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        networks: (json['networks'] as List?)
                ?.map((e) => Taxonomy.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}
