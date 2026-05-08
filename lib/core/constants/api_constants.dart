// Core constants - Supabase API configuration
// Keys can be overridden at build time via --dart-define
class ApiConstants {
  ApiConstants._();

  /// Supabase project URL
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://rljmoqijbmkppzdctvip.supabase.co',
  );

  /// Supabase REST API base URL
  static const String restBaseUrl = '$supabaseUrl/rest/v1';

  /// Supabase Auth API base URL
  static const String authBaseUrl = '$supabaseUrl/auth/v1';

  /// Supabase Publishable Key (anon — safe to embed, protected by RLS)
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_bydcfUss41iWV6zRs465cw_McFT5QR0',
  );

  /// Endpoints
  static const String loginEndpoint = '/token?grant_type=password';
  static const String signupEndpoint = '/signup';
  static const String logoutEndpoint = '/logout';
  static const String userEndpoint = '/user';

  /// REST endpoints
  static const String usersTable = '/users';
  static const String studentsTable = '/students';
  static const String parentsTable = '/parents';
  static const String teachersTable = '/teachers';
  static const String classesTable = '/classes';
  static const String subjectsTable = '/subjects';
  static const String gradesTable = '/grades';
  static const String attendanceTable = '/attendance';
  static const String announcementsTable = '/announcements';
  static const String schedulesTable = '/schedules';
  static const String assignmentsTable = '/assignments';
  static const String examsTable = '/exams';
  static const String religiousActivitiesTable = '/religious_activities';
  static const String libraryBooksTable = '/library_books';
  static const String bookLoansTable = '/book_loans';
  static const String jadwalPelajaranTable = '/jadwal_pelajaran';
  static const String absensiTable = '/absensi';
  static const String jurusanTable = '/jurusan';

  /// Timeouts
  static const int connectTimeout = 30000;
  static const int receiveTimeout = 30000;
  static const int sendTimeout = 30000;
}
