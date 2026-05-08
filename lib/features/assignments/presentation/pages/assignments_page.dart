import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../providers/assignments_provider.dart';

class AssignmentsPage extends ConsumerWidget {
  const AssignmentsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignmentsAsync = ref.watch(assignmentsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Tugas')),
      body: assignmentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (assignments) {
          final pending = assignments.where((a) => a.status == AssignmentStatus.pending).toList();
          final submitted = assignments.where((a) => a.status == AssignmentStatus.submitted).toList();
          final graded = assignments.where((a) => a.status == AssignmentStatus.graded).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stats row
                Row(children: [
                  _statChip('Belum', '${pending.length}', AppColors.warning),
                  const SizedBox(width: 8),
                  _statChip('Dikumpul', '${submitted.length}', AppColors.info),
                  const SizedBox(width: 8),
                  _statChip('Dinilai', '${graded.length}', AppColors.success),
                ]),
                if (pending.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _sectionTitle('Belum Dikerjakan', AppColors.warning),
                  const SizedBox(height: 10),
                  ...pending.map((a) => _AssignmentCard(assignment: a)),
                ],
                if (submitted.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _sectionTitle('Sudah Dikumpulkan', AppColors.info),
                  const SizedBox(height: 10),
                  ...submitted.map((a) => _AssignmentCard(assignment: a)),
                ],
                if (graded.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _sectionTitle('Sudah Dinilai', AppColors.success),
                  const SizedBox(height: 10),
                  ...graded.map((a) => _AssignmentCard(assignment: a)),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _statChip(String label, String count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
        child: Column(children: [
          Text(count, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }

  Widget _sectionTitle(String title, Color color) {
    return Row(children: [
      Container(width: 4, height: 18, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 8),
      Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
    ]);
  }
}

class _AssignmentCard extends StatelessWidget {
  final AssignmentData assignment;
  const _AssignmentCard({required this.assignment});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    switch (assignment.status) {
      case AssignmentStatus.pending: statusColor = assignment.isOverdue ? AppColors.error : AppColors.warning; break;
      case AssignmentStatus.submitted: statusColor = AppColors.info; break;
      case AssignmentStatus.graded: statusColor = AppColors.success; break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14),
        border: assignment.isOverdue ? Border.all(color: AppColors.error.withOpacity(0.3)) : null,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                child: Text(assignment.subject, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor)),
              ),
              const Spacer(),
              if (assignment.grade != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.success.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('${assignment.grade!.toInt()}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.success)),
                ),
              if (assignment.isOverdue)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                  child: Text('Terlambat!', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.error)),
                ),
            ]),
            const SizedBox(height: 10),
            Text(assignment.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(assignment.description, style: TextStyle(fontSize: 12, color: AppColors.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 10),
            Row(children: [
              Icon(Icons.person_outline, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text(assignment.teacher, style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
              const Spacer(),
              Icon(Icons.calendar_today, size: 12, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text(
                assignment.status == AssignmentStatus.pending
                  ? '${assignment.daysLeft} hari lagi'
                  : assignment.statusLabel,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: statusColor),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
