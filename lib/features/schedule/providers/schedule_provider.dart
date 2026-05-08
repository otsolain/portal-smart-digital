import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/presentation/providers/auth_provider.dart';

/// Model for jadwal_pelajaran table
class JadwalPelajaran {
  final String id;
  final String idSekolah;
  final String kelas;
  final String mataPelajaran;
  final String hari;
  final String jamMulai;
  final String jamSelesai;
  final String guru;
  final String ruangan;

  JadwalPelajaran({
    required this.id,
    required this.idSekolah,
    required this.kelas,
    required this.mataPelajaran,
    required this.hari,
    required this.jamMulai,
    required this.jamSelesai,
    required this.guru,
    required this.ruangan,
  });

  factory JadwalPelajaran.fromJson(Map<String, dynamic> json) {
    return JadwalPelajaran(
      id: json['id']?.toString() ?? '',
      idSekolah: json['id_sekolah']?.toString() ?? '',
      kelas: json['kelas']?.toString() ?? '',
      mataPelajaran: json['mata_pelajaran']?.toString() ?? '',
      hari: json['hari']?.toString() ?? '',
      jamMulai: json['jam_mulai']?.toString() ?? '',
      jamSelesai: json['jam_selesai']?.toString() ?? '',
      guru: json['guru']?.toString() ?? '',
      ruangan: json['ruangan']?.toString() ?? '',
    );
  }

  String get jamRange => '$jamMulai - $jamSelesai';

  /// Unique key for class + subject combo (for attendance dropdown)
  String get kelasMapelKey => '$kelas|$mataPelajaran';

  Color get color {
    final hash = mataPelajaran.hashCode;
    final colors = [
      AppColors.pelajaranColor,
      AppColors.kehadiranColor,
      AppColors.tugasColor,
      AppColors.ujianColor,
      AppColors.perpustakaanColor,
      AppColors.info,
      AppColors.secondary,
    ];
    return colors[hash.abs() % colors.length];
  }
}

/// Grouped schedule by day
class DaySchedule {
  final String hari;
  final List<JadwalPelajaran> jadwalList;

  DaySchedule({required this.hari, required this.jadwalList});
}

/// Day order for sorting
const _dayOrder = {
  'senin': 0, 'selasa': 1, 'rabu': 2, 'kamis': 3, 'jumat': 4, 'sabtu': 5, 'minggu': 6,
};

String _getTodayName() {
  final now = DateTime.now();
  const days = ['minggu', 'senin', 'selasa', 'rabu', 'kamis', 'jumat', 'sabtu'];
  return days[now.weekday % 7];
}

// ═══════════════════════════════════════════════════
// All jadwal for the school (unfiltered)
// ═══════════════════════════════════════════════════

final allJadwalProvider = FutureProvider<List<JadwalPelajaran>>((ref) async {
  final idSekolah = ref.watch(currentIdSekolahProvider);
  if (idSekolah == null) return [];

  try {
    final dioClient = ref.watch(dioClientProvider);
    final response = await dioClient.get(
      ApiConstants.jadwalPelajaranTable,
      queryParameters: {
        'id_sekolah': 'eq.$idSekolah',
        'select': '*',
        'order': 'jam_mulai.asc',
      },
    );

    final List data = response.data is List ? response.data : [];
    return data.map((json) => JadwalPelajaran.fromJson(json as Map<String, dynamic>)).toList();
  } on DioException catch (e) {
    if (e.response?.statusCode == 404) return [];
    throw Exception('Gagal memuat jadwal: ${e.message}');
  }
});

// ═══════════════════════════════════════════════════
// Teacher-specific: only jadwal where guru == user name
// ═══════════════════════════════════════════════════

/// Jadwal milik guru yang sedang login
final myJadwalProvider = Provider<AsyncValue<List<JadwalPelajaran>>>((ref) {
  final allJadwal = ref.watch(allJadwalProvider);
  final userName = ref.watch(authProvider).user?.name;

  if (userName == null) return const AsyncValue.data([]);

  return allJadwal.whenData((list) {
    return list.where((j) => j.guru.toLowerCase() == userName.toLowerCase()).toList();
  });
});

/// Kelas-kelas yang diajar oleh guru ini (unique, sorted)
final teacherClassesProvider = Provider<AsyncValue<List<String>>>((ref) {
  return ref.watch(myJadwalProvider).whenData((jadwalList) {
    final classes = jadwalList.map((j) => j.kelas).toSet().toList()..sort();
    return classes;
  });
});

/// Unique class + subject combos for attendance dropdown
/// Returns list of JadwalPelajaran with distinct kelas+mataPelajaran
final teacherClassSubjectsProvider = Provider<AsyncValue<List<JadwalPelajaran>>>((ref) {
  return ref.watch(myJadwalProvider).whenData((jadwalList) {
    final seen = <String>{};
    final unique = <JadwalPelajaran>[];
    for (final j in jadwalList) {
      if (seen.add(j.kelasMapelKey)) {
        unique.add(j);
      }
    }
    // Sort by kelas then mataPelajaran
    unique.sort((a, b) {
      final c = a.kelas.compareTo(b.kelas);
      return c != 0 ? c : a.mataPelajaran.compareTo(b.mataPelajaran);
    });
    return unique;
  });
});

// ═══════════════════════════════════════════════════
// Today & Weekly — teacher-specific
// ═══════════════════════════════════════════════════

/// Today's schedule for this teacher only
final todayScheduleProvider = Provider<AsyncValue<List<JadwalPelajaran>>>((ref) {
  final today = _getTodayName();
  return ref.watch(myJadwalProvider).whenData((list) {
    return list.where((j) => j.hari.toLowerCase() == today).toList();
  });
});

/// Weekly schedule grouped by day for this teacher
final weeklyScheduleProvider = Provider<AsyncValue<List<DaySchedule>>>((ref) {
  return ref.watch(myJadwalProvider).whenData((list) {
    final Map<String, List<JadwalPelajaran>> grouped = {};
    for (final j in list) {
      grouped.putIfAbsent(j.hari, () => []).add(j);
    }

    final days = grouped.entries.map((e) => DaySchedule(hari: e.key, jadwalList: e.value)).toList();
    days.sort((a, b) {
      final aOrder = _dayOrder[a.hari.toLowerCase()] ?? 99;
      final bOrder = _dayOrder[b.hari.toLowerCase()] ?? 99;
      return aOrder.compareTo(bOrder);
    });

    return days;
  });
});
