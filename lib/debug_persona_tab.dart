// Test file to debug the Personas tab issues
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PersonaTabDebugger {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Test database connectivity and profiles table access
  static Future<Map<String, dynamic>> testDatabaseConnection() async {
    final result = <String, dynamic>{
      'connected': false,
      'authenticated': false,
      'profilesAccessible': false,
      'friendsTableAccessible': false,
      'errors': <String>[],
      'profilesCount': 0,
      'sampleUsers': <Map<String, dynamic>>[],
    };

    try {
      // Check authentication
      final user = _supabase.auth.currentUser;
      if (user != null) {
        result['authenticated'] = true;
        result['userId'] = user.id;
      } else {
        result['errors'].add('User not authenticated');
        return result;
      }      // Test profiles table access
      try {
        final profilesResponse = await _supabase
            .from('profiles')
            .select('id, username, avatar_url, position')
            .limit(5);
        
        result['profilesAccessible'] = true;
        result['profilesCount'] = profilesResponse.length;
        result['sampleUsers'] = List<Map<String, dynamic>>.from(profilesResponse);
      } catch (e) {
        result['errors'].add('Profiles table error: $e');
      }

      // Test friends table access
      try {
        final friendsResponse = await _supabase
            .from('friends')
            .select('id, user_id_1, user_id_2, status')
            .limit(1);
        
        result['friendsTableAccessible'] = true;
      } catch (e) {
        result['errors'].add('Friends table error: $e');
      }

      result['connected'] = true;
    } catch (e) {
      result['errors'].add('General connection error: $e');
    }

    return result;
  }

  /// Test search functionality
  static Future<Map<String, dynamic>> testSearchFunctionality(String searchQuery) async {
    final result = <String, dynamic>{
      'success': false,
      'searchQuery': searchQuery,
      'resultsCount': 0,
      'results': <Map<String, dynamic>>[],
      'errors': <String>[],
    };

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        result['errors'].add('User not authenticated');
        return result;
      }      var query = _supabase
          .from('profiles')
          .select('id, username, avatar_url, position')
          .neq('id', user.id);

      if (searchQuery.isNotEmpty) {
        query = query.ilike('username', '%$searchQuery%');
      }

      final response = await query.limit(10);
      
      result['success'] = true;
      result['resultsCount'] = response.length;
      result['results'] = List<Map<String, dynamic>>.from(response);
    } catch (e) {
      result['errors'].add('Search error: $e');
    }

    return result;
  }

  /// Test friend request functionality
  static Future<Map<String, dynamic>> testFriendRequestFlow(String targetUserId) async {
    final result = <String, dynamic>{
      'success': false,
      'targetUserId': targetUserId,
      'errors': <String>[],
      'steps': <String>[],
    };

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        result['errors'].add('User not authenticated');
        return result;
      }

      // Step 1: Check if target user exists
      result['steps'].add('Checking if target user exists...');
      final targetUser = await _supabase
          .from('profiles')
          .select('id, username')
          .eq('id', targetUserId)
          .maybeSingle();

      if (targetUser == null) {
        result['errors'].add('Target user does not exist');
        return result;
      }
      result['steps'].add('Target user found: ${targetUser['username']}');

      // Step 2: Check if friendship already exists
      result['steps'].add('Checking existing friendship status...');
      final existingFriendship = await _supabase
          .from('friends')
          .select('id, status')
          .or('user_id_1.eq.$targetUserId,user_id_2.eq.$targetUserId')
          .or('user_id_1.eq.${user.id},user_id_2.eq.${user.id}')
          .maybeSingle();

      if (existingFriendship != null) {
        result['errors'].add('Friendship already exists with status: ${existingFriendship['status']}');
        return result;
      }
      result['steps'].add('No existing friendship found');

      result['success'] = true;
      result['steps'].add('Friend request flow validation completed successfully');
    } catch (e) {
      result['errors'].add('Friend request flow error: $e');
    }

    return result;
  }

  /// Print debug information to console
  static Future<void> runFullDiagnostic() async {
    print('=== PERSONA TAB DIAGNOSTIC ===');
    
    // Test database connection
    print('\n1. Testing database connection...');
    final connectionResult = await testDatabaseConnection();
    print('Connection result: $connectionResult');

    // Test search functionality
    print('\n2. Testing search functionality...');
    final searchResult = await testSearchFunctionality('test');
    print('Search result: $searchResult');

    // Test with empty search
    print('\n3. Testing empty search...');
    final emptySearchResult = await testSearchFunctionality('');
    print('Empty search result: $emptySearchResult');

    print('\n=== DIAGNOSTIC COMPLETE ===');
  }
}
