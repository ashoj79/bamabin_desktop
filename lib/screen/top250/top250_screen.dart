import 'package:bamabin_desktop/config/color.dart';
import 'package:bamabin_desktop/data/remote/model/videos/post.dart';
import 'package:bamabin_desktop/screen/top250/bloc/top250_bloc.dart';
import 'package:bamabin_desktop/screen/top250/widgets/top250_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class Top250Screen extends StatefulWidget {
  const Top250Screen({super.key, required this.type});

  final Top250Type type;

  @override
  State<Top250Screen> createState() => _Top250ScreenState();
}

class _Top250ScreenState extends State<Top250Screen> {
  @override
  void initState() {
    super.initState();
    context.read<Top250Bloc>().add(Top250LoadEvent());
  }

  String get _title => switch (widget.type) {
    Top250Type.movies => '۲۵۰ فیلم برتر',
    Top250Type.series => '۲۵۰ سریال برتر',
  };

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF0C0C14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          Text(
            _title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: BlocBuilder<Top250Bloc, Top250State>(
              builder: (context, state) {
                return switch (state) {
                  Top250Initial() || Top250Loading() =>
                    const _Top250GridShimmer(),
                  Top250Error(:final message) => Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          message,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.48),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () => context
                              .read<Top250Bloc>()
                              .add(Top250LoadEvent()),
                          child: Text(
                            'تلاش مجدد',
                            style: TextStyle(color: blueColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Top250Success(:final items) => items.isEmpty
                      ? Center(
                          child: Text(
                            'موردی یافت نشد',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.48),
                            ),
                          ),
                        )
                      : _Top250Grid(items: items),
                };
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Top250Grid extends StatelessWidget {
  const _Top250Grid({required this.items});

  final List<Post> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1400
            ? 3
            : constraints.maxWidth >= 900
                ? 2
                : 1;

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(32, 0, 32, 48),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            mainAxisExtent: 176,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) => Top250Card(
            post: items[index],
            rank: index + 1,
          ),
        );
      },
    );
  }
}

class _Top250GridShimmer extends StatelessWidget {
  const _Top250GridShimmer();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1400
            ? 3
            : constraints.maxWidth >= 900
                ? 2
                : 1;

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(32, 0, 32, 48),
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            mainAxisExtent: 176,
          ),
          itemCount: columns * 4,
          itemBuilder: (_, _) => const Top250CardShimmer(),
        );
      },
    );
  }
}
