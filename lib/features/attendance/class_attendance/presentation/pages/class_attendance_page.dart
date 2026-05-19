import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../schedule/providers/schedule_provider.dart';
import '../../data/models/class_attendance_models.dart';
import '../../providers/class_attendance_session.dart';
import '../design/attendance_tokens.dart';
import '../widgets/manual_scanner_panel.dart';
import '../widgets/metode_tabs.dart';
import '../widgets/qr_scanner_panel.dart';
import '../widgets/result_flash_overlay.dart';
import '../widgets/rfid_scanner_panel.dart';
import '../widgets/session_history_list.dart';

class ClassAttendancePage extends ConsumerStatefulWidget {
  const ClassAttendancePage({super.key});

  @override
  ConsumerState<ClassAttendancePage> createState() =>
      _ClassAttendancePageState();
}

class _ClassAttendancePageState extends ConsumerState<ClassAttendancePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _cooldown = false;
  Timer? _flashTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) return;
    final tipe =
        _tabController.index == 0 ? TipeAbsensi.masuk : TipeAbsensi.pulang;
    ref.read(classAttendanceSessionProvider.notifier).setTipe(tipe);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _flashTimer?.cancel();
    super.dispose();
  }

  Future<void> _handleScan(ScanInput input) async {
    if (_cooldown) return;
    _cooldown = true;
    try {
      final saved = await ref
          .read(classAttendanceSessionProvider.notifier)
          .recordScan(input: input, status: StatusAbsensi.hadir);

      if (!mounted) return;
      final lastStudent =
          ref.read(classAttendanceSessionProvider).lastScannedStudent;

      await ResultFlash.show(
        context,
        success: true,
        title: saved.namaSiswa ?? 'Tersimpan',
        subtitle: 'NIS ${saved.nisSiswa ?? '-'} • ${saved.statusAbsensi.label}',
        photoUrl: lastStudent?.fotoProfile,
      );
      _flashTimer?.cancel();
      _flashTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) {
          ref.read(classAttendanceSessionProvider.notifier).clearLastStudent();
        }
      });
    } on AttendanceException catch (e) {
      if (!mounted) return;
      await ResultFlash.show(
        context,
        success: false,
        title: _titleFor(e.code),
        subtitle: e.message,
      );
    } finally {
      await Future.delayed(const Duration(milliseconds: 500));
      _cooldown = false;
    }
  }

  String _titleFor(AttendanceErrorCode code) {
    switch (code) {
      case AttendanceErrorCode.duplicate:
        return 'Sudah Diabsen';
      case AttendanceErrorCode.studentNotFound:
        return 'Siswa Tidak Ditemukan';
      case AttendanceErrorCode.studentWrongClass:
        return 'Beda Kelas';
      case AttendanceErrorCode.studentWrongSchool:
        return 'Bukan dari Sekolah Anda';
      case AttendanceErrorCode.rfidNotRegistered:
        return 'RFID Tidak Terdaftar';
      case AttendanceErrorCode.qrInvalidFormat:
        return 'QR Tidak Dikenali';
      case AttendanceErrorCode.nisInvalid:
        return 'NIS Tidak Valid';
      case AttendanceErrorCode.notAuthorized:
        return 'Tidak Diizinkan';
      case AttendanceErrorCode.network:
        return 'Jaringan Bermasalah';
      case AttendanceErrorCode.unknown:
        return 'Gagal';
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(classAttendanceSessionProvider);
    final notifier = ref.read(classAttendanceSessionProvider.notifier);

    ref.listen(myJadwalForAttendanceProvider, (_, next) {
      next.whenData((_) {
        ref.read(classAttendanceSessionProvider.notifier).refreshJadwal();
      });
    });

    return PopScope(
      canPop: true,
      child: Scaffold(
        // false: Scaffold tidak resize saat keyboard naik. Manual panel
        // handle viewInsets-nya sendiri lewat AnimatedPadding. Ini cegah
        // rebuild storm saat keyboard animasi.
        resizeToAvoidBottomInset: false,
        backgroundColor: AppColors.scaffoldBg,
        appBar: AppBar(
          title: const Text('Absensi Siswa'),
          scrolledUnderElevation: 0,
        ),
        body: Column(
          children: [
            // Tab Masuk/Pulang
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                indicatorWeight: 3,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
                tabs: const [
                  Tab(text: 'Masuk'),
                  Tab(text: 'Pulang'),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.divider),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: MetodeTabs(
                active: state.metode,
                onChanged: notifier.setMetode,
              ),
            ),
            // Scanner area: 60% dari sisa space.
            // Flash card di-overlay di atas scanner pakai Stack supaya
            // tidak push layout & cegah bottom overflow saat muncul.
            Expanded(
              flex: 6,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: _ScannerSurface(
                        metode: state.metode,
                        enabled: !state.isSubmitting,
                        onScan: _handleScan,
                      ),
                    ),
                    if (state.lastScannedStudent != null)
                      Positioned(
                        left: 8,
                        right: 8,
                        bottom: 8,
                        child: _StudentFlashCard(
                          student: state.lastScannedStudent!,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // History area: 40% dari sisa space
            Expanded(
              flex: 4,
              child: _HistorySheetInline(
                records: state.todayHistory,
                isLoading: state.isLoadingHistory,
                onUndo: notifier.undoRecord,
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

/// Flash card showing last scanned student info.
class _StudentFlashCard extends StatelessWidget {
  const _StudentFlashCard({required this.student});
  final StudentLite student;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        // Solid background supaya tidak transparan menutupi scanner.
        color: Colors.white,
        borderRadius: BorderRadius.circular(AttendanceTokens.cornerRadius),
        border: Border.all(
          color: AppColors.success.withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.success.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildAvatar(),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  student.namaSiswa,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  'Kelas ${student.kelas} • NIS ${student.nis}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.check_circle_rounded,
            color: AppColors.success,
            size: 22,
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    if (student.fotoProfile != null && student.fotoProfile!.isNotEmpty) {
      return CircleAvatar(
        radius: 18,
        backgroundColor: AppColors.success.withValues(alpha: 0.15),
        backgroundImage: NetworkImage(student.fotoProfile!),
        onBackgroundImageError: (_, __) {},
      );
    }
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.success.withValues(alpha: 0.15),
      ),
      child: const Icon(
        Icons.person_rounded,
        color: AppColors.success,
        size: 20,
      ),
    );
  }
}

/// Scanner surface with animated switching between methods.
class _ScannerSurface extends StatelessWidget {
  const _ScannerSurface({
    required this.metode,
    required this.enabled,
    required this.onScan,
  });
  final MetodeAbsensi metode;
  final bool enabled;
  final Future<void> Function(ScanInput) onScan;

  @override
  Widget build(BuildContext context) {
    final child = switch (metode) {
      MetodeAbsensi.qr => QrScannerPanel(
          enabled: enabled,
          onScan: (p) => onScan(QrScanInput(p)),
        ),
      MetodeAbsensi.rfid => RfidScannerPanel(
          enabled: enabled,
          onScan: (c) => onScan(RfidScanInput(c)),
        ),
      MetodeAbsensi.manual => ManualScannerPanel(
          enabled: enabled,
          onSubmit: (n) => onScan(ManualScanInput(n)),
        ),
    };

    return ClipRRect(
      borderRadius: BorderRadius.circular(AttendanceTokens.cornerRadius),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AttendanceTokens.cornerRadius),
          border: Border.all(color: AppColors.divider),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: AnimatedSwitcher(
          duration: AttendanceTokens.dNormal,
          transitionBuilder: (c, a) => FadeTransition(opacity: a, child: c),
          child: SizedBox(
            key: ValueKey(metode),
            width: double.infinity,
            height: double.infinity,
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Inline history list — porsi bawah halaman.
class _HistorySheetInline extends StatelessWidget {
  const _HistorySheetInline({
    required this.records,
    required this.isLoading,
    required this.onUndo,
  });
  final List<AbsensiRecord> records;
  final bool isLoading;
  final Future<void> Function(AbsensiRecord) onUndo;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(AttendanceTokens.cornerRadius),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
            child: Row(
              children: [
                const Icon(
                  Icons.history_rounded,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Riwayat Hari Ini',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                if (isLoading)
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${records.length}',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          Expanded(
            child: SessionHistoryList(
              records: records,
              onUndo: onUndo,
            ),
          ),
        ],
      ),
    );
  }
}
