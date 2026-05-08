import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Subject/Mata Pelajaran model
class SubjectData {
  final String id;
  final String name;
  final String teacher;
  final String day;
  final String time;
  final String room;
  final Color color;

  const SubjectData({
    required this.id,
    required this.name,
    required this.teacher,
    required this.day,
    required this.time,
    required this.room,
    required this.color,
  });
}

/// Provider for subjects
final subjectsProvider = FutureProvider<List<SubjectData>>((ref) async {
  await Future.delayed(const Duration(milliseconds: 400));
  return [
    SubjectData(id: '1', name: 'Matematika', teacher: 'Bu Sari Dewi, M.Pd', day: 'Senin', time: '07:30 - 09:00', room: 'Kelas VII-A', color: const Color(0xFF5C6BC0)),
    SubjectData(id: '2', name: 'Bahasa Indonesia', teacher: 'Pak Hendra, S.Pd', day: 'Senin', time: '09:15 - 10:45', room: 'Kelas VII-A', color: const Color(0xFF26A69A)),
    SubjectData(id: '3', name: 'Bahasa Inggris', teacher: 'Mrs. Sarah Johnson, M.A', day: 'Selasa', time: '07:30 - 09:00', room: 'Lab Bahasa', color: const Color(0xFF42A5F5)),
    SubjectData(id: '4', name: 'IPA (Fisika)', teacher: 'Pak Andi, M.Si', day: 'Selasa', time: '09:15 - 10:45', room: 'Lab IPA', color: const Color(0xFFFF7043)),
    SubjectData(id: '5', name: 'IPA (Biologi)', teacher: 'Bu Rina, M.Si', day: 'Rabu', time: '07:30 - 09:00', room: 'Lab IPA', color: const Color(0xFF66BB6A)),
    SubjectData(id: '6', name: 'IPS', teacher: 'Pak Dimas, S.Pd', day: 'Rabu', time: '09:15 - 10:45', room: 'Kelas VII-A', color: const Color(0xFFAB47BC)),
    SubjectData(id: '7', name: 'Pendidikan Agama Islam', teacher: 'Ustadz Ahmad, Lc', day: 'Kamis', time: '07:30 - 09:00', room: 'Musholla', color: const Color(0xFF8D6E63)),
    SubjectData(id: '8', name: 'Seni Budaya', teacher: 'Bu Maya, S.Sn', day: 'Kamis', time: '09:15 - 10:45', room: 'Ruang Seni', color: const Color(0xFFEC407A)),
    SubjectData(id: '9', name: 'PJOK', teacher: 'Pak Budi, S.Pd', day: 'Jumat', time: '07:30 - 09:00', room: 'Lapangan', color: const Color(0xFFFFA726)),
    SubjectData(id: '10', name: 'Informatika', teacher: 'Pak Rizki, S.Kom', day: 'Jumat', time: '09:15 - 10:45', room: 'Lab Komputer', color: const Color(0xFF29B6F6)),
  ];
});

/// Today's schedule
final todayScheduleProvider = Provider<List<SubjectData>>((ref) {
  final dayNames = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
  final now = DateTime.now();
  final todayName = dayNames[now.weekday - 1];

  final subjectsAsync = ref.watch(subjectsProvider);
  return subjectsAsync.when(
    data: (subjects) => subjects.where((s) => s.day == todayName).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});
