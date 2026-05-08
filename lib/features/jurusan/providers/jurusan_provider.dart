import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../auth/presentation/providers/auth_provider.dart';

/// Model for jurusan table
class Jurusan {
  final String id;
  final String idSekolah;
  final String namaJurusan;
  final String kodeJurusan;
  final String? deskripsi;
  final String? kepalaJurusan;

  Jurusan({
    required this.id,
    required this.idSekolah,
    required this.namaJurusan,
    required this.kodeJurusan,
    this.deskripsi,
    this.kepalaJurusan,
  });

  factory Jurusan.fromJson(Map<String, dynamic> json) {
    return Jurusan(
      id: json['id']?.toString() ?? '',
      idSekolah: json['id_sekolah']?.toString() ?? '',
      namaJurusan: json['nama_jurusan']?.toString() ?? '',
      kodeJurusan: json['kode_jurusan']?.toString() ?? '',
      deskripsi: json['deskripsi']?.toString(),
      kepalaJurusan: json['kepala_jurusan']?.toString(),
    );
  }
}

/// Fetch all jurusan for the school
final jurusanProvider = FutureProvider<List<Jurusan>>((ref) async {
  final idSekolah = ref.watch(currentIdSekolahProvider);
  if (idSekolah == null) return [];

  try {
    final dioClient = ref.watch(dioClientProvider);
    final response = await dioClient.get(
      ApiConstants.jurusanTable,
      queryParameters: {
        'id_sekolah': 'eq.$idSekolah',
        'select': '*',
        'order': 'nama_jurusan.asc',
      },
    );

    final List data = response.data is List ? response.data : [];
    return data.map((json) => Jurusan.fromJson(json as Map<String, dynamic>)).toList();
  } on DioException catch (e) {
    if (e.response?.statusCode == 404) return [];
    throw Exception('Gagal memuat data jurusan: ${e.message}');
  }
});
