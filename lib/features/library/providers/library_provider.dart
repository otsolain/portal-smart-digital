import 'package:flutter_riverpod/flutter_riverpod.dart';

enum BookStatus { available, borrowed, reserved }

class BookData {
  final String id;
  final String title;
  final String author;
  final String category;
  final String isbn;
  final BookStatus status;
  final String? coverUrl;
  final String synopsis;
  final int totalCopies;
  final int availableCopies;

  const BookData({
    required this.id, required this.title, required this.author,
    required this.category, required this.isbn, required this.status,
    this.coverUrl, required this.synopsis, required this.totalCopies, required this.availableCopies,
  });
}

class BookLoan {
  final String id;
  final String bookId;
  final String bookTitle;
  final DateTime borrowDate;
  final DateTime dueDate;
  final DateTime? returnDate;
  final bool isReturned;

  const BookLoan({
    required this.id, required this.bookId, required this.bookTitle,
    required this.borrowDate, required this.dueDate, this.returnDate,
    required this.isReturned,
  });

  bool get isOverdue => !isReturned && DateTime.now().isAfter(dueDate);
  int get daysLeft => dueDate.difference(DateTime.now()).inDays;
}

final libraryBooksProvider = FutureProvider<List<BookData>>((ref) async {
  await Future.delayed(const Duration(milliseconds: 400));
  return const [
    BookData(id: '1', title: 'Laskar Pelangi', author: 'Andrea Hirata',
      category: 'Fiksi', isbn: '978-602-291-001-0', status: BookStatus.available,
      synopsis: 'Kisah 10 anak Belitung yang berjuang menempuh pendidikan di sekolah Muhammadiyah yang nyaris ditutup. Sebuah cerita tentang persahabatan, mimpi, dan semangat belajar di tengah keterbatasan.',
      coverUrl: 'https://picsum.photos/seed/laskar/300/450',
      totalCopies: 5, availableCopies: 3),
    BookData(id: '2', title: 'Bumi Manusia', author: 'Pramoedya Ananta Toer',
      category: 'Fiksi', isbn: '978-602-291-002-0', status: BookStatus.available,
      synopsis: 'Menceritakan perjalanan hidup Minke, seorang pribumi yang bersekolah di HBS, sekolah khusus anak-anak Eropa. Kisah cinta, perlawanan, dan pencarian identitas di masa kolonial Hindia Belanda.',
      coverUrl: 'https://picsum.photos/seed/bumi/300/450',
      totalCopies: 3, availableCopies: 1),
    BookData(id: '3', title: 'Fisika SMP Kelas VII', author: 'Erlangga',
      category: 'Textbook', isbn: '978-602-291-003-0', status: BookStatus.available,
      synopsis: 'Buku teks pelajaran Fisika untuk siswa SMP Kelas VII. Berisi materi dasar tentang besaran, satuan, mekanika, dan suhu yang disesuaikan dengan kurikulum nasional terbaru.',
      coverUrl: 'https://picsum.photos/seed/fisika/300/450',
      totalCopies: 20, availableCopies: 12),
    BookData(id: '4', title: 'English Grammar in Use', author: 'Raymond Murphy',
      category: 'Reference', isbn: '978-602-291-004-0', status: BookStatus.available,
      synopsis: 'Buku referensi grammar bahasa Inggris terlengkap yang digunakan di seluruh dunia. Berisi penjelasan tata bahasa beserta latihan praktis untuk meningkatkan kemampuan berbahasa Inggris.',
      coverUrl: 'https://picsum.photos/seed/grammar/300/450',
      totalCopies: 10, availableCopies: 6),
    BookData(id: '5', title: 'Sejarah Indonesia Modern', author: 'M.C. Ricklefs',
      category: 'Non-Fiksi', isbn: '978-602-291-005-0', status: BookStatus.borrowed,
      synopsis: 'Buku sejarah komprehensif yang membahas perjalanan bangsa Indonesia dari masa masuknya Islam hingga era modernisasi dan kemerdekaan. Ditulis dengan riset mendalam oleh sejarawan terkemuka.',
      coverUrl: 'https://picsum.photos/seed/sejarah/300/450',
      totalCopies: 2, availableCopies: 0),
    BookData(id: '6', title: 'Al-Quran dan Terjemahan', author: 'Kemenag RI',
      category: 'Agama', isbn: '978-602-291-006-0', status: BookStatus.available,
      synopsis: 'Kitab suci Al-Quran lengkap 30 juz beserta terjemahan bahasa Indonesia resmi dari Kementerian Agama Republik Indonesia. Dilengkapi dengan asbabun nuzul singkat.',
      coverUrl: 'https://picsum.photos/seed/quran/300/450',
      totalCopies: 30, availableCopies: 25),
  ];
});

final myLoansProvider = FutureProvider<List<BookLoan>>((ref) async {
  await Future.delayed(const Duration(milliseconds: 300));
  final now = DateTime.now();
  return [
    BookLoan(id: 'l1', bookId: '1', bookTitle: 'Laskar Pelangi',
      borrowDate: now.subtract(const Duration(days: 5)),
      dueDate: now.add(const Duration(days: 9)), isReturned: false),
    BookLoan(id: 'l2', bookId: '3', bookTitle: 'Fisika SMP Kelas VII',
      borrowDate: now.subtract(const Duration(days: 20)),
      dueDate: now.subtract(const Duration(days: 6)),
      returnDate: now.subtract(const Duration(days: 7)), isReturned: true),
  ];
});

final activeLoanCountProvider = Provider<int>((ref) {
  final l = ref.watch(myLoansProvider);
  return l.when(data: (x) => x.where((b) => !b.isReturned).length, loading: () => 0, error: (_, __) => 0);
});
