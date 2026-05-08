import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AnnouncementCategory { important, event, info }

class AnnouncementData {
  final String id;
  final String title;
  final String content;
  final String author;
  final DateTime date;
  final AnnouncementCategory category;
  final bool isRead;

  const AnnouncementData({
    required this.id, required this.title, required this.content,
    required this.author, required this.date, required this.category,
    this.isRead = false,
  });

  String get categoryLabel {
    switch (category) {
      case AnnouncementCategory.important: return 'Penting';
      case AnnouncementCategory.event: return 'Acara';
      case AnnouncementCategory.info: return 'Info';
    }
  }

  String get timeAgo {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    return '${(diff.inDays / 7).floor()} minggu lalu';
  }
}

final announcementsProvider = FutureProvider<List<AnnouncementData>>((ref) async {
  await Future.delayed(const Duration(milliseconds: 400));
  final now = DateTime.now();
  return [
    AnnouncementData(id: '1', title: 'Jadwal UTS Semester Genap 2025/2026',
      content: 'UTS dilaksanakan tanggal 19-23 Mei 2026. Siswa diharapkan mempersiapkan diri.',
      author: 'Kepala Sekolah', date: now.subtract(const Duration(hours: 2)),
      category: AnnouncementCategory.important),
    AnnouncementData(id: '2', title: 'Peringatan Isra Miraj 1447 H',
      content: 'Sekolah mengadakan acara peringatan. Seluruh siswa wajib hadir dengan seragam putih.',
      author: 'Bagian Kesiswaan', date: now.subtract(const Duration(hours: 8)),
      category: AnnouncementCategory.event),
    AnnouncementData(id: '3', title: 'Perpanjangan Pembayaran SPP',
      content: 'Batas waktu pembayaran SPP diperpanjang hingga tanggal 15 Mei 2026.',
      author: 'Bagian Keuangan', date: now.subtract(const Duration(days: 1)),
      category: AnnouncementCategory.info),
    AnnouncementData(id: '4', title: 'Lomba Cerdas Cermat Antar Kelas',
      content: 'Pendaftaran dibuka, setiap kelas mengirimkan 3 perwakilan.',
      author: 'OSIS', date: now.subtract(const Duration(days: 2)),
      category: AnnouncementCategory.event),
    AnnouncementData(id: '5', title: 'Libur Hari Raya Waisak',
      content: 'KBM diliburkan 12 Mei 2026. Kembali normal 13 Mei 2026.',
      author: 'Tata Usaha', date: now.subtract(const Duration(days: 3)),
      category: AnnouncementCategory.info),
  ];
});

final unreadAnnouncementsCountProvider = Provider<int>((ref) {
  final a = ref.watch(announcementsProvider);
  return a.when(data: (l) => l.where((x) => !x.isRead).length, loading: () => 0, error: (_, __) => 0);
});
