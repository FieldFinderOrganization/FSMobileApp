import 'package:flutter/material.dart';
import '../cubit/home_state.dart';
import 'fade_in_section.dart';
import 'pitch_card.dart';
import 'section_header.dart';
import 'shimmer_card.dart';

class FeaturedPitchesSection extends StatelessWidget {
  final HomeState state;

  const FeaturedPitchesSection({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final isLoading =
        state.pitchesStatus == LoadStatus.loading ||
        state.pitchesStatus == LoadStatus.initial;

    return FadeInSection(
      delay: const Duration(milliseconds: 150),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: 'Sân nổi bật', onSeeAll: () {}),
          SizedBox(
            height: 200,
            child: isLoading
                ? _buildShimmer()
                : state.pitches.isEmpty
                ? _buildEmpty()
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(right: 16),
                    itemCount: state.pitches.length,
                    itemBuilder: (_, i) => SizedBox(
                          height: 200,
                          child: PitchCard(pitch: state.pitches[i]),
                        ),
                  ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(right: 16),
      itemCount: 3,
      itemBuilder: (_, _) => Padding(
        padding: const EdgeInsets.only(left: 16),
        child: ShimmerCard(
          width: 200,
          height: 200,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(child: Text('Chưa có sân nào.'));
  }
}
