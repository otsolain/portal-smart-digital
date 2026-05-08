import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/students_provider.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../auth/domain/entities/user_entity.dart';
import '../../schedule/providers/schedule_provider.dart';

class StudentsListPage extends ConsumerStatefulWidget {
  const StudentsListPage({super.key});

  @override
  ConsumerState<StudentsListPage> createState() => _StudentsListPageState();
}

class _StudentsListPageState extends ConsumerState<StudentsListPage> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(currentUserRoleProvider);
    // Guru only sees their own classes; others see all students
    final studentsAsync = role == UserRole.guru
        ? ref.watch(myStudentsProvider)
        : ref.watch(studentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Siswa'),
      ),
      body: studentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                const SizedBox(height: 16),
                Text('Gagal memuat data', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(error.toString(), style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => ref.invalidate(studentsProvider),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ),
        data: (students) {
          if (students.isEmpty) {
            return const Center(child: Text('Belum ada data siswa'));
          }

          // Filter by search query
          final filteredStudents = students.where((s) {
            final query = _searchQuery.toLowerCase();
            return s.namaSiswa.toLowerCase().contains(query) ||
                   s.nis.toLowerCase().contains(query) ||
                   s.kelas.toLowerCase().contains(query);
          }).toList();

          // Group students by kelas — only show classes that have students
          final Map<String, List<StudentData>> grouped = {};
          for (final s in filteredStudents) {
            grouped.putIfAbsent(s.kelas, () => []).add(s);
          }

          // Sort class names naturally
          final sortedClasses = grouped.keys.toList()..sort();

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(studentsProvider);
              ref.invalidate(allJadwalProvider);
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: Column(
            children: [
              // Search Bar
              Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                color: Colors.white,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari nama, NIS, atau kelas...',
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
              // Count header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary.withOpacity(0.08), AppColors.primary.withOpacity(0.02)],
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.people_alt_rounded, size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      '${filteredStudents.length} siswa  •  ${sortedClasses.length} kelas',
                      style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              // Expandable class list
              Expanded(
                child: filteredStudents.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off_rounded, size: 64, color: AppColors.textMuted.withOpacity(0.5)),
                            const SizedBox(height: 16),
                            Text('Siswa tidak ditemukan', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: sortedClasses.length,
                        itemBuilder: (context, index) {
                          final kelas = sortedClasses[index];
                          final classStudents = grouped[kelas]!;
                          return _ClassExpansionCard(
                            kelas: kelas,
                            students: classStudents,
                            isExpanded: _searchQuery.isNotEmpty, // Auto expand if searching
                            onStudentTap: (s) => _showStudentDetail(context, s),
                          );
                        },
                      ),
              ),
            ],
            ),
          );
        },
      ),
    );
  }

  void _showStudentDetail(BuildContext context, StudentData s) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        maxChildSize: 0.85,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: CircleAvatar(
                  radius: 36,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: Text(
                    s.namaSiswa.isNotEmpty ? s.namaSiswa[0] : '?',
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(child: Text(s.namaSiswa, style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center)),
              Center(child: Text(s.kelas, style: Theme.of(context).textTheme.bodyMedium)),
              const SizedBox(height: 24),
              _detailRow('NIS', s.nis),
              _detailRow('NISN', s.nisn),
              _detailRow('Jenis Kelamin', s.jenisKelamin),
              _detailRow('Tempat Lahir', s.tempatLahir),
              _detailRow('Tanggal Lahir', s.tanggalLahir),
              _detailRow('Alamat', s.alamat),
              _detailRow('Orang Tua', s.namaOrangTua ?? '-'),
              _detailRow('No. Telp Ortu', s.noTelpOrangTua ?? '-'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

/// A premium-looking expansion card for each class
class _ClassExpansionCard extends StatelessWidget {
  final String kelas;
  final List<StudentData> students;
  final bool isExpanded;
  final void Function(StudentData) onStudentTap;

  const _ClassExpansionCard({
    required this.kelas,
    required this.students,
    this.isExpanded = false,
    required this.onStudentTap,
  });

  @override
  Widget build(BuildContext context) {
    final maleCount = students.where((s) => s.jenisKelamin == 'Laki-laki').length;
    final femaleCount = students.length - maleCount;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: isExpanded,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.only(bottom: 8),
          leading: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              gradient: AppColors.headerGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(child: Icon(Icons.class_rounded, color: Colors.white, size: 22)),
          ),
          title: Text(
            'Kelas $kelas',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                _miniChip(Icons.people, '${students.length}', AppColors.primary),
                const SizedBox(width: 8),
                _miniChip(Icons.male, '$maleCount', AppColors.siswaColor),
                const SizedBox(width: 8),
                _miniChip(Icons.female, '$femaleCount', AppColors.orangtuaColor),
              ],
            ),
          ),
          children: students.map((s) {
            return InkWell(
              onTap: () => onStudentTap(s),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: s.jenisKelamin == 'Laki-laki'
                          ? AppColors.siswaColor.withOpacity(0.1)
                          : AppColors.orangtuaColor.withOpacity(0.1),
                      child: Text(
                        s.namaSiswa.isNotEmpty ? s.namaSiswa[0] : '?',
                        style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 13,
                          color: s.jenisKelamin == 'Laki-laki' ? AppColors.siswaColor : AppColors.orangtuaColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.namaSiswa, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text('NIS: ${s.nis}', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                    Icon(
                      s.jenisKelamin == 'Laki-laki' ? Icons.male : Icons.female,
                      size: 18, color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _miniChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}
