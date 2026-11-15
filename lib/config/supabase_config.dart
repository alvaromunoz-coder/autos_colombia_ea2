import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String url = 'https://postcemttosohvvghbhv.supabase.co';
  static const String publishableKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBvc3RjZW10dG9zb2h2dmdoYmh2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTI4ODEyMzAsImV4cCI6MjEwODQ1NzIzMH0.BtqAhNJ8XuU6ZspkpKyO7XqeDRhucDyanpVwQLYXrUM';

  static Future<void> init() async {
    await Supabase.initialize(url: url, publishableKey: publishableKey);
  }

  static SupabaseClient get client => Supabase.instance.client;
}
