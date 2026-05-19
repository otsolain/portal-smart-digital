import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/providers/guru_staff_provider.dart';
import '../../../schedule/providers/schedule_provider.dart';
import '../data/models/class_attendance_models.dart';
import '../data/repositories/absensi_repository.dart';
import '../data/repositories/student_resolver.dart';

/// Simplified state — no more selectJadwal/selectTipe phases.
/// Jadwal is auto-detected, tipe is controlled by tab.
class SimpleAttendanceState {
  final TipeAbsensi tipe;
  final MetodeAbsensi metode;
  final JadwalPelajaran? detectedJadwal;
  final List<AbsensiRecord> todayHistory;
  final bool isSubmitting;
  final StudentLite? lastScannedStudent;
  final AttendanceException? lastError;
  final bool isLoadingHistory;

  const SimpleAttendanceState({
    this.tipe = TipeAbsensi.masuk,
    this.metode = MetodeAbsensi.rfid,
    this.detectedJadwal,
    this.todayHistory = const [],
    this.isSubmitting = false,
    this.lastScannedStudent,
    this.lastError,
    this.isLoadingHistory = false,
  });

  SimpleAttendanceState copyWith({
    TipeAbsensi? tipe,
    MetodeAbsensi? metode,
    JadwalPelajaran? detectedJadwal,
    List<AbsensiRecord>? todayHistory,
    bool? isSubmitting,
    StudentLite? lastScannedStudent,
    AttendanceException? lastError,
    bool? isLoadingHistory,
    bool clearError = false,
    bool clearLastStudent = false,
    bool clearJadwal = false,
  }) {
    return SimpleAttendanceState(
      tipe: tipe ?? this.tipe,
      metode: metode ?? this.metode,
      detectedJadwal:
          clearJadwal ? null : (detectedJadwal ?? this.detectedJadwal),
      todayHistory: todayHistory ?? this.todayHistory,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      lastScannedStudent: clearLastStudent
          ? null
          : (lastScannedStudent ?? this.lastScannedStudent),
      lastError: clearError ? null : (lastError ?? this.lastError),
      isLoadingHistory: isLoadingHistory ?? this.isLoadingHistory,
    );
  }

  int get totalTercatat => todayHistory.length;
  Set<String> get studentIdsTercatat =>
      todayHistory.map((r) => r.idSiswa).toSet();
}

class SimpleAttendanceNotifier extends StateNotifier<SimpleAttendanceState> {
  SimpleAttendanceNotifier({
    required this.ref,
    required this.repository,
    required this.resolver,
  }) : super(const SimpleAttendanceState()) {
    _autoDetectJadwal();
  }

  final Ref ref;
  final AbsensiRepository repository;
  final StudentResolver resolver;

  /// Auto-detect jadwal based on current time.
  void _autoDetectJadwal() {
    final myJadwalAsync = ref.read(myJadwalForAttendanceProvider);
    myJadwalAsync.whenData((jadwalList) {
      final detected = _findCurrentJadwal(jadwalList);
      state = state.copyWith(detectedJadwal: detected, clearJadwal: detected == null);
      _loadHistory();
    });
  }

  /// Find jadwal that matches current day and time.
  /// Priority: exact time match > closest jadwal today > null.
  JadwalPelajaran? _findCurrentJadwal(List<JadwalPelajaran> jadwalList) {
    final now = DateTime.now();
    final todayName = _getDayName(now.weekday);

    // Filter by today
    final todayJadwal =
        jadwalList.where((j) => j.hari.toLowerCase() == todayName).toList();
    if (todayJadwal.isEmpty) return null;

    // Find the one where current time is between jamMulai and jamSelesai
    final currentMinutes = now.hour * 60 + now.minute;
    for (final j in todayJadwal) {
      final mulai = _parseTimeToMinutes(j.jamMulai);
      final selesai = _parseTimeToMinutes(j.jamSelesai);
      if (mulai != null && selesai != null) {
        if (currentMinutes >= mulai && currentMinutes <= selesai) {
          return j;
        }
      }
    }

    // Fallback: find the closest jadwal (smallest absolute distance)
    JadwalPelajaran? closest;
    int closestDist = 999999;
    for (final j in todayJadwal) {
      final mulai = _parseTimeToMinutes(j.jamMulai);
      final selesai = _parseTimeToMinutes(j.jamSelesai);
      if (mulai == null || selesai == null) continue;
      final distToMulai = (currentMinutes - mulai).abs();
      final distToSelesai = (currentMinutes - selesai).abs();
      final dist = distToMulai < distToSelesai ? distToMulai : distToSelesai;
      if (dist < closestDist) {
        closestDist = dist;
        closest = j;
      }
    }
    return closest;
  }

  String _getDayName(int weekday) {
    const days = [
      'senin',
      'selasa',
      'rabu',
      'kamis',
      'jumat',
      'sabtu',
      'minggu'
    ];
    return days[(weekday - 1) % 7];
  }

  int? _parseTimeToMinutes(String time) {
    // Supports "HH:mm" or "HH:mm:ss"
    final parts = time.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return hour * 60 + minute;
  }

  /// Refresh jadwal detection (e.g. when provider data arrives later).
  void refreshJadwal() {
    _autoDetectJadwal();
  }

  /// Switch tipe (masuk/pulang) — triggered by tab change.
  void setTipe(TipeAbsensi tipe) {
    if (tipe == state.tipe) return;
    state = state.copyWith(
      tipe: tipe,
      todayHistory: const [],
      clearError: true,
      clearLastStudent: true,
    );
    _loadHistory();
  }

  /// Switch scan method.
  void setMetode(MetodeAbsensi metode) {
    state = state.copyWith(metode: metode, clearError: true);
  }

  /// Clear the last scanned student (dismiss flash card).
  void clearLastStudent() {
    state = state.copyWith(clearLastStudent: true);
  }

  /// Load today's history for current jadwal + tipe.
  /// If no jadwal detected, load all records for today (no jadwal filter).
  Future<void> _loadHistory() async {
    final jadwal = state.detectedJadwal;
    final idSekolah = ref.read(currentIdSekolahProvider);
    if (idSekolah == null) return;

    state = state.copyWith(isLoadingHistory: true);
    try {
      final records = await repository.getSessionRecords(
        idSekolah: idSekolah,
        idJadwal: jadwal?.id ?? '',
        tanggal: _today(),
        tipe: state.tipe,
      );
      state = state.copyWith(todayHistory: records, isLoadingHistory: false);
    } on AttendanceException catch (e) {
      state = state.copyWith(
        todayHistory: const [],
        isLoadingHistory: false,
        lastError: e,
      );
    }
  }

  /// Record a scan — resolve identity, validate, save, update history.
  /// Validation:
  /// - Student must exist in DB
  /// - Student must be from same school
  /// - If jadwal detected: student must be from that jadwal's class
  /// - If no jadwal detected: student must be from one of the teacher's
  ///   taught classes (otherwise teacher is scanning students they don't teach)
  /// If no jadwal detected, record with empty id_jadwal.
  Future<AbsensiRecord> recordScan({
    required ScanInput input,
    required StatusAbsensi status,
    String? keterangan,
  }) async {
    final jadwal = state.detectedJadwal;
    final tipe = state.tipe;
    final userId = ref.read(authProvider).user?.id;
    final idSekolah = ref.read(currentIdSekolahProvider);
    // Coba fetch guruStaffId. Kalau null, retry sekali dengan invalidate
    // (kemungkinan cache stale atau network glitch).
    var guruStaffId = await ref.read(currentGuruStaffIdProvider.future);
    if (guruStaffId == null) {
      ref.invalidate(currentGuruStaffIdProvider);
      try {
        guruStaffId = await ref.read(currentGuruStaffIdProvider.future);
      } catch (_) {
        // ignore — guruStaffId tetap null, error spesifik di bawah.
      }
    }

    if (userId == null || idSekolah == null) {
      throw const AttendanceException(
        AttendanceErrorCode.notAuthorized,
        'Sesi login tidak valid. Silakan login ulang.',
      );
    }
    if (guruStaffId == null) {
      throw const AttendanceException(
        AttendanceErrorCode.notAuthorized,
        'Akun guru belum terhubung ke data guru_staff. '
        'Hubungi admin sekolah.',
      );
    }

    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      // 1. Resolve to StudentLite
      final student = await input.resolve(resolver, idSekolah);

      // 2. Validate school
      if (student.idSekolah != idSekolah) {
        throw const AttendanceException(
          AttendanceErrorCode.studentWrongSchool,
          'Siswa bukan dari sekolah Anda.',
        );
      }

      // 3. Validate class — guru hanya boleh absen siswa dari kelas yang
      //    dia ajar.
      if (jadwal != null) {
        // Kalau ada jadwal terdeteksi: siswa harus dari kelas itu.
        if (_normalizeKelas(student.kelas) !=
            _normalizeKelas(jadwal.kelas)) {
          throw AttendanceException(
            AttendanceErrorCode.studentWrongClass,
            '${student.namaSiswa} dari kelas ${student.kelas}, '
            'sedang absensi kelas ${jadwal.kelas}.',
          );
        }
      } else {
        // Kalau tidak ada jadwal terdeteksi: siswa harus dari salah satu
        // kelas yang guru ajar (dari teacherClassesProvider).
        final taught = ref.read(teacherClassesProvider).maybeWhen(
              data: (list) => list,
              orElse: () => const <String>[],
            );
        final taughtNorm = taught.map(_normalizeKelas).toSet();
        if (taughtNorm.isNotEmpty &&
            !taughtNorm.contains(_normalizeKelas(student.kelas))) {
          throw AttendanceException(
            AttendanceErrorCode.studentWrongClass,
            '${student.namaSiswa} dari kelas ${student.kelas} — '
            'Anda tidak mengajar kelas tersebut.',
          );
        }
      }

      // 4. Check local duplicate
      if (state.studentIdsTercatat.contains(student.id)) {
        throw AttendanceException(
          AttendanceErrorCode.duplicate,
          '${student.namaSiswa} sudah diabsen pada sesi ini.',
        );
      }

      // 5. Build record + insert
      final now = DateTime.now();
      final record = AbsensiRecord(
        idJadwal: jadwal?.id ?? '',
        idSiswa: student.id,
        idGuru: guruStaffId,
        idSekolah: idSekolah,
        kelas: jadwal?.kelas ?? student.kelas,
        mataPelajaran: jadwal?.mataPelajaran ?? '',
        tanggalAbsensi: _formatDate(now),
        jamAbsensi: _formatTime(now),
        tipeAbsensi: tipe,
        metodeAbsensi: state.metode,
        statusAbsensi: status,
        keterangan: keterangan,
        rfidCode: input.rfidCodeForRecord,
        qrcodeData: input.qrcodeDataForRecord,
        namaSiswa: student.namaSiswa,
        nisSiswa: student.nis,
      );

      final saved = await repository.createRecord(record);
      state = state.copyWith(
        todayHistory: [saved, ...state.todayHistory],
        isSubmitting: false,
        lastScannedStudent: student,
        clearError: true,
      );
      return saved;
    } on AttendanceException catch (e) {
      state = state.copyWith(isSubmitting: false, lastError: e);
      rethrow;
    } catch (e) {
      final err = AttendanceException(
        AttendanceErrorCode.unknown,
        e.toString(),
      );
      state = state.copyWith(isSubmitting: false, lastError: err);
      throw err;
    }
  }

  /// Normalize nama kelas untuk matching tahan terhadap variasi
  /// spasi/dash/case. "XI DKV" vs "XI-DKV" vs "xi dkv" → "XIDKV".
  String _normalizeKelas(String s) =>
      s.toUpperCase().replaceAll(RegExp(r'[\s\-_/.]+'), '');

  /// Undo a record (swipe-to-dismiss).
  Future<void> undoRecord(AbsensiRecord record) async {
    final idSekolah = ref.read(currentIdSekolahProvider);
    if (idSekolah == null || record.id == null) return;
    try {
      await repository.deleteRecord(id: record.id!, idSekolah: idSekolah);
      state = state.copyWith(
        todayHistory:
            state.todayHistory.where((r) => r.id != record.id).toList(),
      );
    } on AttendanceException catch (e) {
      state = state.copyWith(lastError: e);
    }
  }

  /// Go back — reset state.
  void back() {
    state = const SimpleAttendanceState();
    _autoDetectJadwal();
  }

  /// Full reset.
  void reset() {
    state = const SimpleAttendanceState();
    _autoDetectJadwal();
  }

  String _today() {
    final now = DateTime.now();
    return _formatDate(now);
  }

  String _formatDate(DateTime d) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }

  String _formatTime(DateTime d) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(d.hour)}:${two(d.minute)}:${two(d.second)}';
  }
}

/// Input yang dikirim UI ke notifier setiap kali scan berhasil.
abstract class ScanInput {
  Future<StudentLite> resolve(StudentResolver resolver, String idSekolah);
  String? get rfidCodeForRecord => null;
  String? get qrcodeDataForRecord => null;
}

class QrScanInput extends ScanInput {
  QrScanInput(this.payload);
  final String payload;

  @override
  Future<StudentLite> resolve(StudentResolver resolver, String idSekolah) {
    return resolver.resolveQr(payload: payload, idSekolah: idSekolah);
  }

  @override
  String? get qrcodeDataForRecord => payload;
}

class RfidScanInput extends ScanInput {
  RfidScanInput(this.code);
  final String code;

  @override
  Future<StudentLite> resolve(StudentResolver resolver, String idSekolah) {
    return resolver.resolveRfid(rfidCode: code, idSekolah: idSekolah);
  }

  @override
  String? get rfidCodeForRecord => code;
}

class ManualScanInput extends ScanInput {
  ManualScanInput(this.nis);
  final String nis;

  @override
  Future<StudentLite> resolve(StudentResolver resolver, String idSekolah) {
    return resolver.resolveNis(nis: nis, idSekolah: idSekolah);
  }
}

final classAttendanceSessionProvider = StateNotifierProvider.autoDispose<
    SimpleAttendanceNotifier, SimpleAttendanceState>((ref) {
  return SimpleAttendanceNotifier(
    ref: ref,
    repository: ref.watch(absensiRepositoryProvider),
    resolver: ref.watch(studentResolverProvider),
  );
});
