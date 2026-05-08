import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../auth/presentation/providers/auth_provider.dart';

/// Submit attendance records to Supabase `absensi` table
class AbsensiService {
  final DioClient _dioClient;

  AbsensiService(this._dioClient);

  Future<void> submitAbsensi({
    required String idSekolah,
    required String idGuru,
    required String kelas,
    required String mataPelajaran,
    required Map<String, String> studentStatuses, // studentId -> status
    String? idJadwal,
  }) async {
    final now = DateTime.now();
    final tanggal = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final jam = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

    final records = studentStatuses.entries.map((entry) => {
      'id_jadwal': idJadwal,
      'id_siswa': entry.key,
      'id_guru': idGuru,
      'id_sekolah': idSekolah,
      'kelas': kelas,
      'mata_pelajaran': mataPelajaran,
      'tanggal_absensi': tanggal,
      'status_absensi': entry.value, // hadir, izin, sakit, alpha
      'keterangan': null,
      'jam_absensi': jam,
      'tipe_absensi': 'harian',
      'metode_absensi': 'manual',
    }).toList();

    try {
      await _dioClient.post(
        ApiConstants.absensiTable,
        data: records,
      );
    } on DioException catch (e) {
      throw Exception('Gagal menyimpan absensi: ${e.message}');
    }
  }
}

final absensiServiceProvider = Provider<AbsensiService>((ref) {
  return AbsensiService(ref.watch(dioClientProvider));
});

/// Provides current teacher's user ID for id_guru field
final currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(authProvider).user?.id;
});
