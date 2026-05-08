import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../providers/attendance_provider.dart';

class AttendancePage extends ConsumerWidget {
  const AttendancePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(attendanceSummaryProvider);
    final recordsAsync = ref.watch(attendanceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Kehadiran')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.kehadiranGradient,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [BoxShadow(color: AppColors.kehadiranColor.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: Column(
                children: [
                  Text('Persentase Kehadiran', style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13)),
                  const SizedBox(height: 8),
                  Text('${summary.percentage.toStringAsFixed(1)}%',
                    style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _summaryItem('Hadir', '${summary.hadir}', AppColors.success),
                      _summaryItem('Izin', '${summary.izin}', AppColors.warning),
                      _summaryItem('Sakit', '${summary.sakit}', AppColors.info),
                      _summaryItem('Alpha', '${summary.alpha}', AppColors.error),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('Kehadiran per Mata Pelajaran', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            recordsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (subjects) {
                if (subjects.isEmpty) return const Center(child: Text('Belum ada data kehadiran'));
                return Column(
                  children: subjects.map((s) => _SubjectAttendanceCard(subject: s)).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryItem(String label, String value, Color color) {
    return Column(children: [
      Container(
        width: 40, height: 40,
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
        child: Center(child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700))),
      ),
      const SizedBox(height: 6),
      Text(label, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11)),
    ]);
  }
}

class _SubjectAttendanceCard extends StatelessWidget {
  final SubjectAttendanceSummary subject;
  const _SubjectAttendanceCard({required this.subject});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            width: 46, height: 46,
            decoration: BoxDecoration(color: AppColors.kehadiranColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.class_outlined, color: AppColors.kehadiranColor),
          ),
          title: Text(subject.subjectName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          subtitle: Text('${subject.teacherName} • Hadir: ${subject.percentage.toStringAsFixed(0)}%', 
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          childrenPadding: const EdgeInsets.only(bottom: 12),
          children: [
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            const SizedBox(height: 8),
            ...subject.meetings.map((m) => _MeetingRow(meeting: m)),
          ],
        ),
      ),
    );
  }
}

class _MeetingRow extends StatelessWidget {
  final MeetingAttendance meeting;
  const _MeetingRow({required this.meeting});

  @override
  Widget build(BuildContext context) {
    final dayNames = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];

    Color statusColor;
    IconData statusIcon;
    String statusLabel;
    switch (meeting.status) {
      case AttendanceStatus.hadir: statusColor = AppColors.success; statusIcon = Icons.check_circle; statusLabel = 'Hadir'; break;
      case AttendanceStatus.izin: statusColor = AppColors.warning; statusIcon = Icons.info; statusLabel = 'Izin'; break;
      case AttendanceStatus.sakit: statusColor = AppColors.info; statusIcon = Icons.local_hospital; statusLabel = 'Sakit'; break;
      case AttendanceStatus.alpha: statusColor = AppColors.error; statusIcon = Icons.cancel; statusLabel = 'Alpha'; break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(statusIcon, color: statusColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(meeting.meetingName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text('${dayNames[meeting.date.weekday - 1]}, ${meeting.date.day} ${monthNames[meeting.date.month - 1]}',
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                if (meeting.note != null) ...[
                  const SizedBox(height: 2),
                  Text('Catatan: ${meeting.note!}', style: TextStyle(fontSize: 11, color: AppColors.warning, fontStyle: FontStyle.italic)),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Text(statusLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor)),
          ),
        ],
      ),
    );
  }
}
