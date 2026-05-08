import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ExamType { uts, uas, quiz, dailyTest }

class ExamData {
  final String id;
  final String title;
  final String subject;
  final ExamType type;
  final DateTime date;
  final String time;
  final String room;
  final double? score;
  final bool isCompleted;

  const ExamData({
    required this.id,
    required this.title,
    required this.subject,
    required this.type,
    required this.date,
    required this.time,
    required this.room,
    this.score,
    required this.isCompleted,
  });

  String get typeLabel {
    switch (type) {
      case ExamType.uts: return 'UTS';
      case ExamType.uas: return 'UAS';
      case ExamType.quiz: return 'Quiz';
      case ExamType.dailyTest: return 'Ulangan Harian';
    }
  }
}

final examsProvider = FutureProvider<List<ExamData>>((ref) async {
  await Future.delayed(const Duration(milliseconds: 400));
  final now = DateTime.now();
  return [
    ExamData(
      id: '1', title: 'UTS Matematika', subject: 'Matematika', type: ExamType.uts,
      date: now.add(const Duration(days: 14)), time: '07:30 - 09:30', room: 'Kelas VII-A',
      isCompleted: false,
    ),
    ExamData(
      id: '2', title: 'UTS Bahasa Inggris', subject: 'Bahasa Inggris', type: ExamType.uts,
      date: now.add(const Duration(days: 15)), time: '07:30 - 09:30', room: 'Kelas VII-A',
      isCompleted: false,
    ),
    ExamData(
      id: '3', title: 'Quiz IPA Bab 3', subject: 'IPA (Fisika)', type: ExamType.quiz,
      date: now.add(const Duration(days: 5)), time: '09:15 - 10:00', room: 'Lab IPA',
      isCompleted: false,
    ),
    ExamData(
      id: '4', title: 'Ulangan Harian B. Indonesia', subject: 'Bahasa Indonesia', type: ExamType.dailyTest,
      date: now.subtract(const Duration(days: 7)), time: '09:15 - 10:15', room: 'Kelas VII-A',
      score: 85, isCompleted: true,
    ),
    ExamData(
      id: '5', title: 'Quiz Matematika Bab 2', subject: 'Matematika', type: ExamType.quiz,
      date: now.subtract(const Duration(days: 14)), time: '07:30 - 08:15', room: 'Kelas VII-A',
      score: 90, isCompleted: true,
    ),
    ExamData(
      id: '6', title: 'Ulangan Harian IPS', subject: 'IPS', type: ExamType.dailyTest,
      date: now.subtract(const Duration(days: 10)), time: '09:15 - 10:15', room: 'Kelas VII-A',
      score: 78, isCompleted: true,
    ),
  ];
});

final upcomingExamsCountProvider = Provider<int>((ref) {
  final examsAsync = ref.watch(examsProvider);
  return examsAsync.when(
    data: (list) => list.where((e) => !e.isCompleted).length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});
