import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../providers/exams_provider.dart';

class ExamsPage extends ConsumerWidget {
  const ExamsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final examsAsync = ref.watch(examsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Ujian')),
      body: examsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (exams) {
          final upcoming = exams.where((e) => !e.isCompleted).toList()..sort((a, b) => a.date.compareTo(b.date));
          final completed = exams.where((e) => e.isCompleted).toList()..sort((a, b) => b.date.compareTo(a.date));

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (upcoming.isNotEmpty) ...[
                  _sectionTitle('Ujian Mendatang', Icons.event, AppColors.ujianColor),
                  const SizedBox(height: 12),
                  ...upcoming.map((e) => _ExamCard(exam: e)),
                ],
                if (completed.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _sectionTitle('Hasil Ujian', Icons.assessment, AppColors.success),
                  const SizedBox(height: 12),
                  ...completed.map((e) => _ExamCard(exam: e)),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon, Color color) {
    return Row(children: [
      Container(
        width: 32, height: 32,
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 18, color: color),
      ),
      const SizedBox(width: 10),
      Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
    ]);
  }
}

class _ExamCard extends StatelessWidget {
  final ExamData exam;
  const _ExamCard({required this.exam});

  @override
  Widget build(BuildContext context) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    final daysLeft = exam.date.difference(DateTime.now()).inDays;

    Color typeColor;
    switch (exam.type) {
      case ExamType.uts: typeColor = AppColors.ujianColor; break;
      case ExamType.uas: typeColor = AppColors.error; break;
      case ExamType.quiz: typeColor = AppColors.info; break;
      case ExamType.dailyTest: typeColor = AppColors.kehadiranColor; break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Date box
            Container(
              width: 52, height: 56,
              decoration: BoxDecoration(
                color: typeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12),
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('${exam.date.day}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: typeColor)),
                Text(months[exam.date.month - 1], style: TextStyle(fontSize: 11, color: typeColor, fontWeight: FontWeight.w500)),
              ]),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(color: typeColor.withOpacity(0.12), borderRadius: BorderRadius.circular(5)),
                    child: Text(exam.typeLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: typeColor)),
                  ),
                  const SizedBox(width: 6),
                  Text(exam.subject, style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                ]),
                const SizedBox(height: 6),
                Text(exam.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Row(children: [
                  Icon(Icons.access_time, size: 12, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text(exam.time, style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  const SizedBox(width: 10),
                  Icon(Icons.room_outlined, size: 12, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text(exam.room, style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                ]),
              ]),
            ),
            if (exam.isCompleted && exam.score != null)
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _scoreColor(exam.score!).withOpacity(0.1),
                ),
                child: Center(child: Text('${exam.score!.toInt()}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _scoreColor(exam.score!)))),
              )
            else if (!exam.isCompleted)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text('${daysLeft}h', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.warning)),
              ),
          ],
        ),
      ),
    );
  }

  Color _scoreColor(double score) {
    if (score >= 85) return AppColors.success;
    if (score >= 70) return AppColors.info;
    return AppColors.error;
  }
}
