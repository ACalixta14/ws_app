class SupabaseConfig {
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://aabpypgubwhemjxqssmn.supabase.co',
  );

  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_DNIFXAU7SrKLGAwV3dtXEg_qPOPM66C',
  );
}