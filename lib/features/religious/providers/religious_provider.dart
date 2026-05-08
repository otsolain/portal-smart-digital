import 'package:flutter_riverpod/flutter_riverpod.dart';

class ReligiousActivity {
  final String id;
  final String title;
  final String description;
  final String day;
  final String time;
  final String location;
  final String category;
  final bool isMandatory;

  const ReligiousActivity({
    required this.id,
    required this.title,
    required this.description,
    required this.day,
    required this.time,
    required this.location,
    required this.category,
    required this.isMandatory,
  });
}

final religiousActivitiesProvider = FutureProvider<List<ReligiousActivity>>((ref) async {
  await Future.delayed(const Duration(milliseconds: 400));
  return const [
    ReligiousActivity(
      id: '1', title: 'Shalat Dhuha Berjamaah', description: 'Shalat Dhuha bersama di Musholla sekolah',
      day: 'Setiap Hari', time: '09:00 - 09:15', location: 'Musholla Al-Hikmah',
      category: 'Ibadah', isMandatory: true,
    ),
    ReligiousActivity(
      id: '2', title: 'Shalat Dzuhur Berjamaah', description: 'Shalat Dzuhur berjamaah wajib untuk seluruh siswa',
      day: 'Setiap Hari', time: '12:00 - 12:30', location: 'Musholla Al-Hikmah',
      category: 'Ibadah', isMandatory: true,
    ),
    ReligiousActivity(
      id: '3', title: 'Kajian Jumat', description: 'Kajian Islam mingguan dengan tema akhlak mulia',
      day: 'Jumat', time: '11:00 - 11:45', location: 'Aula Sekolah',
      category: 'Kajian', isMandatory: true,
    ),
    ReligiousActivity(
      id: '4', title: 'Tahfidz Al-Quran', description: 'Program hafalan Al-Quran Juz 30',
      day: 'Senin, Rabu', time: '06:30 - 07:15', location: 'Musholla Al-Hikmah',
      category: 'Tahfidz', isMandatory: false,
    ),
    ReligiousActivity(
      id: '5', title: 'Mentoring Keislaman', description: 'Mentoring kelompok kecil tentang fiqih dan akidah',
      day: 'Selasa', time: '15:00 - 16:00', location: 'Ruang Kelas',
      category: 'Mentoring', isMandatory: false,
    ),
    ReligiousActivity(
      id: '6', title: 'Baca Tulis Al-Quran (BTQ)', description: 'Bimbingan membaca dan menulis Al-Quran',
      day: 'Kamis', time: '15:00 - 16:00', location: 'Musholla Al-Hikmah',
      category: 'BTQ', isMandatory: true,
    ),
    ReligiousActivity(
      id: '7', title: 'Infaq Jumat', description: 'Program infaq mingguan untuk kegiatan sosial',
      day: 'Jumat', time: '07:15 - 07:30', location: 'Kelas Masing-masing',
      category: 'Sosial', isMandatory: false,
    ),
  ];
});
