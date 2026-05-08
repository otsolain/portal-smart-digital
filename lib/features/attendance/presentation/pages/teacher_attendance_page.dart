import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../students/providers/students_provider.dart';
import '../../../schedule/providers/schedule_provider.dart';
import '../../providers/absensi_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// Status absensi
enum AttendanceStatus { hadir, izin, sakit, alpha }

extension AttendanceStatusExt on AttendanceStatus {
  String get label {
    switch (this) {
      case AttendanceStatus.hadir: return 'Hadir';
      case AttendanceStatus.izin: return 'Izin';
      case AttendanceStatus.sakit: return 'Sakit';
      case AttendanceStatus.alpha: return 'Alpha';
    }
  }

  Color get color {
    switch (this) {
      case AttendanceStatus.hadir: return AppColors.success;
      case AttendanceStatus.izin: return AppColors.info;
      case AttendanceStatus.sakit: return AppColors.warning;
      case AttendanceStatus.alpha: return AppColors.error;
    }
  }

  IconData get icon {
    switch (this) {
      case AttendanceStatus.hadir: return Icons.check_circle;
      case AttendanceStatus.izin: return Icons.info;
      case AttendanceStatus.sakit: return Icons.local_hospital;
      case AttendanceStatus.alpha: return Icons.cancel;
    }
  }
}

class TeacherAttendancePage extends ConsumerStatefulWidget {
  const TeacherAttendancePage({super.key});

  @override
  ConsumerState<TeacherAttendancePage> createState() => _TeacherAttendancePageState();
}

class _TeacherAttendancePageState extends ConsumerState<TeacherAttendancePage> {
  JadwalPelajaran? _selectedJadwal; // Selected class + subject from teacher's schedule
  final Map<String, AttendanceStatus> _attendanceMap = {};
  bool _submitted = false;

  @override
  Widget build(BuildContext context) {
    final classSubjectsAsync = ref.watch(teacherClassSubjectsProvider);
    final studentsAsync = ref.watch(studentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Absensi Kelas'),
        centerTitle: true,
        elevation: 0,
      ),
      body: classSubjectsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (classSubjects) {
          if (classSubjects.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.event_busy_rounded, size: 56, color: AppColors.warning.withOpacity(0.5)),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Anda belum memiliki jadwal mengajar',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Hubungi admin untuk menambahkan jadwal mengajar Anda',
                      style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: [
              // ── Class + Subject Selector ──
              _buildClassSubjectSelector(classSubjects),

              // ── Content ──
              if (_selectedJadwal != null)
                Expanded(
                  child: studentsAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Error memuat siswa: $e')),
                    data: (allStudents) {
                      final students = allStudents
                          .where((s) => s.kelas == _selectedJadwal!.kelas)
                          .toList();
                      if (students.isEmpty) {
                        return Center(
                          child: Text('Tidak ada siswa di kelas ${_selectedJadwal!.kelas}',
                              style: TextStyle(color: AppColors.textMuted)),
                        );
                      }
                      return _buildAttendanceList(students);
                    },
                  ),
                )
              else
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.06),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.fact_check_rounded, size: 56, color: AppColors.primary.withOpacity(0.4)),
                        ),
                        const SizedBox(height: 16),
                        Text('Pilih kelas & mata pelajaran',
                            style: TextStyle(fontSize: 15, color: AppColors.textMuted, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 4),
                        Text('untuk memulai absensi',
                            style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildClassSubjectSelector(List<JadwalPelajaran> classSubjects) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Kelas & Mata Pelajaran',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          const SizedBox(height: 10),
          SizedBox(
            height: 54,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: classSubjects.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final jadwal = classSubjects[index];
                final isSelected = _selectedJadwal?.kelasMapelKey == jadwal.kelasMapelKey;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedJadwal = jadwal;
                      _attendanceMap.clear();
                      _submitted = false;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      gradient: isSelected ? AppColors.headerGradient : null,
                      color: isSelected ? null : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected ? null : Border.all(color: AppColors.divider),
                      boxShadow: isSelected
                          ? [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))]
                          : null,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            jadwal.kelas,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            jadwal.mataPelajaran,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: isSelected ? Colors.white70 : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceList(List<StudentData> students) {
    // Date header
    final now = DateTime.now();
    final days = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
    final months = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
    final dateStr = '${days[now.weekday % 7]}, ${now.day} ${months[now.month - 1]} ${now.year}';

    // Summary
    final hadirCount = _attendanceMap.values.where((v) => v == AttendanceStatus.hadir).length;
    final izinCount = _attendanceMap.values.where((v) => v == AttendanceStatus.izin).length;
    final sakitCount = _attendanceMap.values.where((v) => v == AttendanceStatus.sakit).length;
    final alphaCount = _attendanceMap.values.where((v) => v == AttendanceStatus.alpha).length;

    return Column(
      children: [
        // Date & summary bar
        Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary.withOpacity(0.06), AppColors.primary.withOpacity(0.02)],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(child: Text(dateStr, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary))),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.menu_book_rounded, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${_selectedJadwal!.mataPelajaran} — ${_selectedJadwal!.kelas}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.primary),
                    ),
                  ),
                ],
              ),
              if (_attendanceMap.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _summaryChip('Hadir', hadirCount, AppColors.success),
                    _summaryChip('Izin', izinCount, AppColors.info),
                    _summaryChip('Sakit', sakitCount, AppColors.warning),
                    _summaryChip('Alpha', alphaCount, AppColors.error),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Student list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            itemCount: students.length,
            itemBuilder: (context, index) {
              final s = students[index];
              final status = _attendanceMap[s.id];

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: status != null ? Border.all(color: status.color.withOpacity(0.3), width: 1.5) : null,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
                ),
                child: Column(
                  children: [
                    // Student info row
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.primary.withOpacity(0.08),
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.namaSiswa, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 2),
                              Text('NIS: ${s.nis}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                            ],
                          ),
                        ),
                        if (status != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: status.color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(status.icon, size: 14, color: status.color),
                                const SizedBox(width: 4),
                                Text(status.label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: status.color)),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Status buttons
                    Row(
                      children: AttendanceStatus.values.map((as_) {
                        final isActive = status == as_;
                        return Expanded(
                          child: GestureDetector(
                            onTap: _submitted ? null : () {
                              setState(() => _attendanceMap[s.id] = as_);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: EdgeInsets.only(right: as_ != AttendanceStatus.alpha ? 6 : 0),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: isActive ? as_.color : as_.color.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(10),
                                border: isActive ? null : Border.all(color: as_.color.withOpacity(0.15)),
                              ),
                              child: Center(
                                child: Text(
                                  as_.label,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: isActive ? Colors.white : as_.color,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        // Submit button
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, -4))],
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: (_submitted || _attendanceMap.length != students.length)
                    ? null
                    : () async {
                        final absensiService = ref.read(absensiServiceProvider);
                        final idSekolah = ref.read(currentIdSekolahProvider);
                        final userId = ref.read(currentUserIdProvider);

                        if (idSekolah == null || userId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Data sesi tidak lengkap. Coba login ulang.'),
                              backgroundColor: AppColors.error,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          );
                          return;
                        }

                        setState(() => _submitted = true);

                        try {
                          final statuses = _attendanceMap.map((key, value) => MapEntry(key, value.name));
                          await absensiService.submitAbsensi(
                            idSekolah: idSekolah,
                            idGuru: userId,
                            kelas: _selectedJadwal!.kelas,
                            mataPelajaran: _selectedJadwal!.mataPelajaran,
                            studentStatuses: statuses,
                            idJadwal: _selectedJadwal!.id,
                          );

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Absensi ${_selectedJadwal!.mataPelajaran} — ${_selectedJadwal!.kelas} berhasil disimpan!'),
                                backgroundColor: AppColors.success,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            );
                          }
                        } catch (e) {
                          setState(() => _submitted = false);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Gagal menyimpan: $e'),
                                backgroundColor: AppColors.error,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            );
                          }
                        }
                      },
                icon: Icon(_submitted ? Icons.check_circle : Icons.save_rounded),
                label: Text(
                  _submitted
                      ? 'Sudah Disimpan'
                      : _attendanceMap.length == students.length
                          ? 'Simpan Absensi'
                          : 'Lengkapi Absensi (${_attendanceMap.length}/${students.length})',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _submitted ? AppColors.success : AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _summaryChip(String label, int count, Color color) {
    return Column(
      children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Center(child: Text('$count', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color))),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
