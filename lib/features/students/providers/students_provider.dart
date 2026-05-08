import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../schedule/providers/schedule_provider.dart';

/// Model for student data from Supabase
class StudentData {
  final String id;
  final String nis;
  final String nisn;
  final String namaSiswa;
  final String jenisKelamin;
  final String alamat;
  final String tempatLahir;
  final String tanggalLahir;
  final String? namaOrangTua;
  final String? noTelpOrangTua;
  final String kelas;

  StudentData({
    required this.id,
    required this.nis,
    required this.nisn,
    required this.namaSiswa,
    required this.jenisKelamin,
    required this.alamat,
    required this.tempatLahir,
    required this.tanggalLahir,
    this.namaOrangTua,
    this.noTelpOrangTua,
    required this.kelas,
  });

  factory StudentData.fromJson(Map<String, dynamic> json) {
    return StudentData(
      id: json['id']?.toString() ?? '',
      nis: json['nis']?.toString() ?? '',
      nisn: json['nisn']?.toString() ?? '',
      namaSiswa: json['nama_siswa']?.toString() ?? '',
      jenisKelamin: json['jenis_kelamin']?.toString() ?? '',
      alamat: json['alamat']?.toString() ?? '-',
      tempatLahir: json['tempat_lahir']?.toString() ?? '-',
      tanggalLahir: json['tanggal_lahir']?.toString() ?? '-',
      namaOrangTua: json['nama_orang_tua']?.toString(),
      noTelpOrangTua: json['no_telp_orang_tua']?.toString(),
      kelas: json['kelas']?.toString() ?? '-',
    );
  }
}

/// Toggle: set to true for mock data during development
const bool _useMockStudents = false;

/// Provider that fetches ALL students from Supabase
final studentsProvider = FutureProvider<List<StudentData>>((ref) async {
  if (_useMockStudents) {
    return _getMockStudents();
  }

  try {
    final dioClient = ref.watch(dioClientProvider);
    final response = await dioClient.get(
      ApiConstants.studentsTable,
      queryParameters: {
        'select': '*',
        'order': 'nama_siswa.asc',
      },
    );

    if (response.data == null) {
      return [];
    }

    final List data = response.data is List ? response.data : [];
    return data
        .map((json) => StudentData.fromJson(json as Map<String, dynamic>))
        .toList();
  } on DioException catch (e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      throw Exception('Koneksi timeout. Periksa jaringan Anda.');
    }
    if (e.response?.statusCode == 404) {
      throw Exception('Tabel siswa belum tersedia di database.');
    }
    if (e.response?.statusCode == 401) {
      throw Exception('Sesi telah berakhir. Silakan login kembali.');
    }
    throw Exception(
      'Gagal memuat data siswa: ${e.message ?? 'Kesalahan server'}',
    );
  } catch (e) {
    throw Exception('Terjadi kesalahan: $e');
  }
});

/// Provider that returns ONLY students from classes the teacher teaches
/// Uses jadwal_pelajaran to determine which classes belong to this teacher
final myStudentsProvider = Provider<AsyncValue<List<StudentData>>>((ref) {
  final allStudents = ref.watch(studentsProvider);
  final teacherClasses = ref.watch(teacherClassesProvider);

  // Combine both async values
  return teacherClasses.when(
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
    data: (classes) {
      if (classes.isEmpty) {
        return const AsyncValue.data([]);
      }
      return allStudents.whenData((students) {
        final classSet = classes.toSet();
        return students.where((s) => classSet.contains(s.kelas)).toList();
      });
    },
  );
});

/// Mock student data for development/demo
List<StudentData> _getMockStudents() {
  return [
    StudentData(
      id: '1', nis: '2024001', nisn: '0012345601',
      namaSiswa: 'Ahmad Fauzi Rahman', jenisKelamin: 'Laki-laki',
      alamat: 'Jl. Sudirman No. 45, Jakarta Selatan',
      tempatLahir: 'Jakarta', tanggalLahir: '2010-03-15',
      namaOrangTua: 'Budi Rahman', noTelpOrangTua: '081234567890',
      kelas: 'VII-A',
    ),
    StudentData(
      id: '2', nis: '2024002', nisn: '0012345602',
      namaSiswa: 'Siti Aisyah Putri', jenisKelamin: 'Perempuan',
      alamat: 'Jl. Gatot Subroto No. 12, Jakarta Pusat',
      tempatLahir: 'Bandung', tanggalLahir: '2010-07-22',
      namaOrangTua: 'Hendra Wijaya', noTelpOrangTua: '081234567891',
      kelas: 'VII-A',
    ),
    StudentData(
      id: '3', nis: '2024003', nisn: '0012345603',
      namaSiswa: 'Muhammad Rizki Pratama', jenisKelamin: 'Laki-laki',
      alamat: 'Jl. Thamrin No. 88, Jakarta Pusat',
      tempatLahir: 'Surabaya', tanggalLahir: '2010-01-10',
      namaOrangTua: 'Agus Pratama', noTelpOrangTua: '081234567892',
      kelas: 'VII-B',
    ),
    StudentData(
      id: '4', nis: '2024004', nisn: '0012345604',
      namaSiswa: 'Fatimah Azzahra', jenisKelamin: 'Perempuan',
      alamat: 'Jl. Kuningan No. 33, Jakarta Selatan',
      tempatLahir: 'Yogyakarta', tanggalLahir: '2010-11-05',
      namaOrangTua: 'Ahmad Faisal', noTelpOrangTua: '081234567893',
      kelas: 'VII-B',
    ),
    StudentData(
      id: '5', nis: '2024005', nisn: '0012345605',
      namaSiswa: 'Dimas Arya Putra', jenisKelamin: 'Laki-laki',
      alamat: 'Jl. Rasuna Said No. 7, Jakarta Selatan',
      tempatLahir: 'Semarang', tanggalLahir: '2010-05-28',
      namaOrangTua: 'Wahyu Putra', noTelpOrangTua: '081234567894',
      kelas: 'VII-A',
    ),
    StudentData(
      id: '6', nis: '2024006', nisn: '0012345606',
      namaSiswa: 'Nur Hidayah', jenisKelamin: 'Perempuan',
      alamat: 'Jl. Casablanca No. 55, Jakarta Selatan',
      tempatLahir: 'Medan', tanggalLahir: '2010-09-14',
      namaOrangTua: 'Irwan Hidayat', noTelpOrangTua: '081234567895',
      kelas: 'VII-C',
    ),
    StudentData(
      id: '7', nis: '2024007', nisn: '0012345607',
      namaSiswa: 'Rafi Aditya Nugraha', jenisKelamin: 'Laki-laki',
      alamat: 'Jl. Kemang Raya No. 21, Jakarta Selatan',
      tempatLahir: 'Jakarta', tanggalLahir: '2010-12-01',
      namaOrangTua: 'Deni Nugraha', noTelpOrangTua: '081234567896',
      kelas: 'VII-C',
    ),
    StudentData(
      id: '8', nis: '2024008', nisn: '0012345608',
      namaSiswa: 'Zahra Amelia Putri', jenisKelamin: 'Perempuan',
      alamat: 'Jl. Senayan No. 9, Jakarta Selatan',
      tempatLahir: 'Bogor', tanggalLahir: '2010-04-18',
      namaOrangTua: 'Rizal Amelia', noTelpOrangTua: '081234567897',
      kelas: 'VII-A',
    ),
  ];
}
