import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AssignmentStatus { pending, submitted, graded }

class AssignmentData {
  final String id;
  final String title;
  final String subject;
  final String description;
  final DateTime deadline;
  final AssignmentStatus status;
  final double? grade;
  final String teacher;

  const AssignmentData({
    required this.id,
    required this.title,
    required this.subject,
    required this.description,
    required this.deadline,
    required this.status,
    this.grade,
    required this.teacher,
  });

  String get statusLabel {
    switch (status) {
      case AssignmentStatus.pending: return 'Belum Dikerjakan';
      case AssignmentStatus.submitted: return 'Sudah Dikumpulkan';
      case AssignmentStatus.graded: return 'Sudah Dinilai';
    }
  }

  bool get isOverdue => status == AssignmentStatus.pending && DateTime.now().isAfter(deadline);

  int get daysLeft => deadline.difference(DateTime.now()).inDays;
}

final assignmentsProvider = FutureProvider<List<AssignmentData>>((ref) async {
  await Future.delayed(const Duration(milliseconds: 400));
  final now = DateTime.now();
  return [
    AssignmentData(
      id: '1', title: 'Latihan Soal Persamaan Linear', subject: 'Matematika',
      description: 'Kerjakan halaman 45 nomor 1-20', deadline: now.add(const Duration(days: 3)),
      status: AssignmentStatus.pending, teacher: 'Bu Sari Dewi',
    ),
    AssignmentData(
      id: '2', title: 'Essay Teks Narasi', subject: 'Bahasa Indonesia',
      description: 'Tulis essay minimal 500 kata tentang pengalaman liburan', deadline: now.add(const Duration(days: 5)),
      status: AssignmentStatus.pending, teacher: 'Pak Hendra',
    ),
    AssignmentData(
      id: '3', title: 'Lab Report: Fotosintesis', subject: 'IPA (Biologi)',
      description: 'Buat laporan praktikum fotosintesis', deadline: now.subtract(const Duration(days: 1)),
      status: AssignmentStatus.submitted, teacher: 'Bu Rina',
    ),
    AssignmentData(
      id: '4', title: 'English Presentation', subject: 'Bahasa Inggris',
      description: 'Present about your favorite hobby (3-5 minutes)', deadline: now.subtract(const Duration(days: 5)),
      status: AssignmentStatus.graded, grade: 88, teacher: 'Mrs. Sarah Johnson',
    ),
    AssignmentData(
      id: '5', title: 'Peta Konsep Sejarah', subject: 'IPS',
      description: 'Buat peta konsep tentang kerajaan Majapahit', deadline: now.subtract(const Duration(days: 3)),
      status: AssignmentStatus.graded, grade: 92, teacher: 'Pak Dimas',
    ),
    AssignmentData(
      id: '6', title: 'Program Kalkulator Sederhana', subject: 'Informatika',
      description: 'Buat program kalkulator menggunakan Python', deadline: now.add(const Duration(days: 7)),
      status: AssignmentStatus.pending, teacher: 'Pak Rizki',
    ),
  ];
});

final pendingAssignmentsCountProvider = Provider<int>((ref) {
  final assignmentsAsync = ref.watch(assignmentsProvider);
  return assignmentsAsync.when(
    data: (list) => list.where((a) => a.status == AssignmentStatus.pending).length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});
