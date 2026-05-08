import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../providers/religious_provider.dart';

class ReligiousActivitiesPage extends ConsumerWidget {
  const ReligiousActivitiesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activitiesAsync = ref.watch(religiousActivitiesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Kegiatan Keagamaan')),
      body: activitiesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (activities) {
          final grouped = <String, List<ReligiousActivity>>{};
          for (final a in activities) {
            grouped.putIfAbsent(a.category, () => []).add(a);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: AppColors.keagamaanGradient,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [BoxShadow(color: AppColors.keagamaanColor.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: Row(children: [
                    Container(
                      width: 50, height: 50,
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(14)),
                      child: const Icon(Icons.mosque_rounded, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Program Keagamaan', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text('${activities.length} kegiatan terjadwal', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
                    ])),
                  ]),
                ),
                const SizedBox(height: 24),
                ...grouped.entries.map((entry) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(width: 4, height: 18, decoration: BoxDecoration(color: AppColors.keagamaanColor, borderRadius: BorderRadius.circular(2))),
                      const SizedBox(width: 8),
                      Text(entry.key, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    ]),
                    const SizedBox(height: 10),
                    ...entry.value.map((a) => _ActivityCard(activity: a)),
                    const SizedBox(height: 16),
                  ],
                )),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final ReligiousActivity activity;
  const _ActivityCard({required this.activity});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(color: AppColors.keagamaanColor.withOpacity(0.1), borderRadius: BorderRadius.circular(11)),
            child: Icon(
              activity.isMandatory ? Icons.star_rounded : Icons.star_border_rounded,
              color: AppColors.keagamaanColor, size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(activity.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
              if (activity.isMandatory)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                  child: Text('Wajib', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.error)),
                ),
            ]),
            const SizedBox(height: 4),
            Row(children: [
              Icon(Icons.schedule, size: 12, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text('${activity.day} • ${activity.time}', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
            ]),
            const SizedBox(height: 2),
            Row(children: [
              Icon(Icons.location_on_outlined, size: 12, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text(activity.location, style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
            ]),
          ])),
        ]),
      ),
    );
  }
}
