import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AttendanceStatus { hadir, izin, sakit, alpha }

class MeetingAttendance {
  final String id;
  final String meetingName;
  final DateTime date;
  final AttendanceStatus status;
  final String? note;

  const MeetingAttendance({
    required this.id,
    required this.meetingName,
    required this.date,
    required this.status,
    this.note,
  });
}

class SubjectAttendanceSummary {
  final String subjectId;
  final String subjectName;
  final String teacherName;
  final List<MeetingAttendance> meetings;

  const SubjectAttendanceSummary({
    required this.subjectId,
    required this.subjectName,
    required this.teacherName,
    required this.meetings,
  });

  int get hadirCount => meetings.where((m) => m.status == AttendanceStatus.hadir).length;
  int get izinCount => meetings.where((m) => m.status == AttendanceStatus.izin).length;
  int get sakitCount => meetings.where((m) => m.status == AttendanceStatus.sakit).length;
  int get alphaCount => meetings.where((m) => m.status == AttendanceStatus.alpha).length;
  
  double get percentage => meetings.isEmpty ? 0 : (hadirCount / meetings.length) * 100;
}

class OverallAttendanceSummary {
  final int totalMeetings;
  final int hadir;
  final int izin;
  final int sakit;
  final int alpha;

  const OverallAttendanceSummary({
    required this.totalMeetings,
    required this.hadir,
    required this.izin,
    required this.sakit,
    required this.alpha,
  });

  double get percentage => totalMeetings > 0 ? (hadir / totalMeetings) * 100 : 0;
}

const bool _useMockAttendance = true; // Wajib true karena database belum support skema ini

final attendanceProvider = FutureProvider<List<SubjectAttendanceSummary>>((ref) async {
  if (_useMockAttendance) {
    return _getMockAttendance();
  }
  // Implementasi API Supabase nanti saat tabel sudah diupdate
  return [];
});

List<SubjectAttendanceSummary> _getMockAttendance() {
  final now = DateTime.now();
  
  return [
    SubjectAttendanceSummary(
      subjectId: 's1',
      subjectName: 'Matematika',
      teacherName: 'Budi Santoso, S.Pd',
      meetings: [
        MeetingAttendance(id: 'm1_1', meetingName: 'Pertemuan 1', date: now.subtract(const Duration(days: 30)), status: AttendanceStatus.hadir),
        MeetingAttendance(id: 'm1_2', meetingName: 'Pertemuan 2', date: now.subtract(const Duration(days: 23)), status: AttendanceStatus.hadir),
        MeetingAttendance(id: 'm1_3', meetingName: 'Pertemuan 3', date: now.subtract(const Duration(days: 16)), status: AttendanceStatus.sakit, note: 'Demam'),
        MeetingAttendance(id: 'm1_4', meetingName: 'UTS', date: now.subtract(const Duration(days: 9)), status: AttendanceStatus.hadir),
      ],
    ),
    SubjectAttendanceSummary(
      subjectId: 's2',
      subjectName: 'Bahasa Indonesia',
      teacherName: 'Siti Aminah, M.Pd',
      meetings: [
        MeetingAttendance(id: 'm2_1', meetingName: 'Pertemuan 1', date: now.subtract(const Duration(days: 28)), status: AttendanceStatus.hadir),
        MeetingAttendance(id: 'm2_2', meetingName: 'Pertemuan 2', date: now.subtract(const Duration(days: 21)), status: AttendanceStatus.izin, note: 'Acara Keluarga'),
        MeetingAttendance(id: 'm2_3', meetingName: 'Pertemuan 3', date: now.subtract(const Duration(days: 14)), status: AttendanceStatus.hadir),
        MeetingAttendance(id: 'm2_4', meetingName: 'Pertemuan Akhir', date: now.subtract(const Duration(days: 7)), status: AttendanceStatus.hadir),
      ],
    ),
    SubjectAttendanceSummary(
      subjectId: 's3',
      subjectName: 'Bahasa Inggris',
      teacherName: 'John Doe, S.S',
      meetings: [
        MeetingAttendance(id: 'm3_1', meetingName: 'Pertemuan 1', date: now.subtract(const Duration(days: 25)), status: AttendanceStatus.hadir),
        MeetingAttendance(id: 'm3_2', meetingName: 'Pertemuan 2', date: now.subtract(const Duration(days: 18)), status: AttendanceStatus.hadir),
        MeetingAttendance(id: 'm3_3', meetingName: 'Pertemuan 3', date: now.subtract(const Duration(days: 11)), status: AttendanceStatus.alpha),
      ],
    ),
    SubjectAttendanceSummary(
      subjectId: 's4',
      subjectName: 'Ilmu Pengetahuan Alam',
      teacherName: 'Dewi Lestari, S.Si',
      meetings: [
        MeetingAttendance(id: 'm4_1', meetingName: 'Pertemuan 1', date: now.subtract(const Duration(days: 20)), status: AttendanceStatus.hadir),
        MeetingAttendance(id: 'm4_2', meetingName: 'Praktikum 1', date: now.subtract(const Duration(days: 13)), status: AttendanceStatus.hadir),
        MeetingAttendance(id: 'm4_3', meetingName: 'UTS', date: now.subtract(const Duration(days: 6)), status: AttendanceStatus.hadir),
      ],
    ),
  ];
}

final attendanceSummaryProvider = Provider<OverallAttendanceSummary>((ref) {
  final recordsAsync = ref.watch(attendanceProvider);
  return recordsAsync.when(
    data: (subjects) {
      int h = 0, i = 0, s = 0, a = 0;
      int total = 0;
      for (final subj in subjects) {
        total += subj.meetings.length;
        h += subj.hadirCount;
        i += subj.izinCount;
        s += subj.sakitCount;
        a += subj.alphaCount;
      }
      return OverallAttendanceSummary(totalMeetings: total, hadir: h, izin: i, sakit: s, alpha: a);
    },
    loading: () => const OverallAttendanceSummary(totalMeetings: 0, hadir: 0, izin: 0, sakit: 0, alpha: 0),
    error: (_, __) => const OverallAttendanceSummary(totalMeetings: 0, hadir: 0, izin: 0, sakit: 0, alpha: 0),
  );
});
