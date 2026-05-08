import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../providers/library_provider.dart';

class LibraryPage extends ConsumerStatefulWidget {
  const LibraryPage({super.key});

  @override
  ConsumerState<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends ConsumerState<LibraryPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // To prevent multiple navigations during a single swipe overscroll
  bool _isNavigating = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perpustakaan'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Katalog Buku'),
            Tab(text: 'Pinjaman Saya'),
          ],
        ),
      ),
      body: NotificationListener<OverscrollNotification>(
        onNotification: (notification) {
          if (_isNavigating) return false;

          // Drag left (swipe to go right) -> overscroll > 0 -> next main tab (Profile)
          if (notification.overscroll > 10 && _tabController.index == 1) {
            _isNavigating = true;
            context.go('/profile');
            return true;
          }
          // Drag right (swipe to go left) -> overscroll < -10 -> prev main tab (Jadwal/Siswa)
          else if (notification.overscroll < -10 && _tabController.index == 0) {
            _isNavigating = true;
            // Assuming this is murid. If it's guru/orangtua, prev tab might be different.
            // But we can just use go_router context to pop or go to specific route.
            // We'll just pop history or go to dashboard to be safe, or /subjects for murid.
            context.go('/subjects');
            return true;
          }
          return false;
        },
        child: TabBarView(
          controller: _tabController,
          children: const [
            _CatalogTab(),
            _LoansTab(),
          ],
        ),
      ),
    );
  }
}

class _CatalogTab extends ConsumerStatefulWidget {
  const _CatalogTab();

  @override
  ConsumerState<_CatalogTab> createState() => _CatalogTabState();
}

class _CatalogTabState extends ConsumerState<_CatalogTab> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final booksAsync = ref.watch(libraryBooksProvider);

    return Column(
      children: [
        // Search Bar
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          color: Colors.white,
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Cari judul buku atau penulis...',
              prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: AppColors.textMuted),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppColors.scaffoldBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
            onChanged: (val) {
              setState(() {
                _searchQuery = val;
              });
            },
          ),
        ),
        // Book List
        Expanded(
          child: booksAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (books) {
              final filteredBooks = books.where((b) {
                final query = _searchQuery.toLowerCase();
                return b.title.toLowerCase().contains(query) ||
                       b.author.toLowerCase().contains(query) ||
                       b.category.toLowerCase().contains(query);
              }).toList();

              if (filteredBooks.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off_rounded, size: 64, color: AppColors.textMuted.withOpacity(0.5)),
                      const SizedBox(height: 16),
                      const Text('Buku tidak ditemukan', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(libraryBooksProvider);
                  await Future.delayed(const Duration(milliseconds: 500));
                },
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredBooks.length,
                  itemBuilder: (_, i) => _BookCard(book: filteredBooks[i]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _LoansTab extends ConsumerWidget {
  const _LoansTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loansAsync = ref.watch(myLoansProvider);
    return loansAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (loans) {
        if (loans.isEmpty) {
          return const Center(child: Text('Belum ada buku yang dipinjam'));
        }
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(myLoansProvider);
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: loans.length,
            itemBuilder: (_, i) => _LoanCard(loan: loans[i]),
          ),
        );
      },
    );
  }
}

class _BookCard extends StatelessWidget {
  final BookData book;
  const _BookCard({required this.book});

  @override
  Widget build(BuildContext context) {
    final isAvailable = book.status == BookStatus.available && book.availableCopies > 0;

    return GestureDetector(
      onTap: () => _showBookDetailsBottomSheet(context, book, isAvailable),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(
              width: 52, height: 68,
              decoration: BoxDecoration(
                color: AppColors.perpustakaanColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                image: book.coverUrl != null 
                    ? DecorationImage(
                        image: NetworkImage(book.coverUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: book.coverUrl == null ? const Icon(Icons.menu_book_rounded, color: AppColors.perpustakaanColor, size: 26) : null,
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(book.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 3),
              Text(book.author, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 6),
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.info.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                  child: Text(book.category, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.info)),
                ),
                const SizedBox(width: 8),
                Text('Tersedia: ${book.availableCopies}/${book.totalCopies}', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
              ]),
            ])),
            if (isAvailable)
              ElevatedButton(
                onPressed: () => _showBorrowDialog(context, book),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  textStyle: const TextStyle(fontSize: 12),
                ),
                child: const Text('Pinjam'),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: AppColors.textMuted.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text('Kosong', style: TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w500)),
              ),
          ]),
        ),
      ),
    );
  }
}

void _showBorrowDialog(BuildContext context, BookData book) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Pinjam Buku'),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Apakah Anda ingin meminjam buku ini?'),
        const SizedBox(height: 12),
        Text(book.title, style: const TextStyle(fontWeight: FontWeight.w600)),
        Text('Oleh: ${book.author}', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        const SizedBox(height: 8),
        const Text('Durasi peminjaman: 14 hari', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Buku "${book.title}" berhasil dipinjam!'), backgroundColor: AppColors.success),
            );
          },
          child: const Text('Pinjam'),
        ),
      ],
    ),
  );
}

void _showBookDetailsBottomSheet(BuildContext context, BookData book, bool isAvailable) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(color: AppColors.textMuted.withOpacity(0.3), borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 100, height: 140,
                    decoration: BoxDecoration(
                      color: AppColors.perpustakaanColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))],
                      image: book.coverUrl != null
                          ? DecorationImage(image: NetworkImage(book.coverUrl!), fit: BoxFit.cover)
                          : null,
                    ),
                    child: book.coverUrl == null ? const Icon(Icons.menu_book_rounded, color: AppColors.perpustakaanColor, size: 40) : null,
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: AppColors.info.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                          child: Text(book.category, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.info)),
                        ),
                        const SizedBox(height: 12),
                        Text(book.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, height: 1.2)),
                        const SizedBox(height: 6),
                        Text(book.author, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 12),
                        Row(children: [
                          const Icon(Icons.inventory_2_outlined, size: 14, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Text('Tersedia: ${book.availableCopies} dari ${book.totalCopies}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        ]),
                        const SizedBox(height: 4),
                        Row(children: [
                          const Icon(Icons.qr_code, size: 14, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Text('ISBN: ${book.isbn}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        ]),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text('Sinopsis', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              Text(book.synopsis, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5)),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isAvailable 
                    ? () {
                        Navigator.pop(context);
                        _showBorrowDialog(context, book);
                      }
                    : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isAvailable ? AppColors.primary : AppColors.textMuted.withOpacity(0.3),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    isAvailable ? 'Pinjam Buku Ini' : 'Buku Sedang Kosong',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isAvailable ? Colors.white : AppColors.textMuted),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _LoanCard extends ConsumerWidget {
  final BookLoan loan;
  const _LoanCard({required this.loan});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    Color statusColor = loan.isReturned ? AppColors.success : (loan.isOverdue ? AppColors.error : AppColors.info);
    String statusText = loan.isReturned ? 'Dikembalikan' : (loan.isOverdue ? 'Terlambat!' : '${loan.daysLeft} hari lagi');

    // Fetch BookData to get the cover image
    final booksAsync = ref.watch(libraryBooksProvider);
    BookData? book;
    if (booksAsync.hasValue) {
      book = booksAsync.value!.cast<BookData?>().firstWhere(
        (b) => b?.id == loan.bookId,
        orElse: () => null,
      );
    }

    return GestureDetector(
      onTap: () async {
        if (book != null) {
          final isAvailable = book.status == BookStatus.available && book.availableCopies > 0;
          _showBookDetailsBottomSheet(context, book, isAvailable);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(14),
          border: loan.isOverdue ? Border.all(color: AppColors.error.withOpacity(0.3)) : null,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(
              width: 48, height: 64,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1), 
                borderRadius: BorderRadius.circular(10),
                image: book?.coverUrl != null
                  ? DecorationImage(image: NetworkImage(book!.coverUrl!), fit: BoxFit.cover)
                  : null,
              ),
              child: book?.coverUrl == null ? Icon(loan.isReturned ? Icons.check_circle : Icons.book_outlined, color: statusColor, size: 22) : null,
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(loan.bookTitle, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text('Pinjam: ${loan.borrowDate.day} ${months[loan.borrowDate.month - 1]}  •  Kembali: ${loan.dueDate.day} ${months[loan.dueDate.month - 1]}',
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Text(statusText, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor)),
            ),
          ]),
        ),
      ),
    );
  }
}
