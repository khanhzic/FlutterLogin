import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/master_data.dart';
import 'api_common.dart';
import 'package:flutter/widgets.dart'; // Added for BuildContext

class MasterDataService {
  static const String _masterDataKey = 'master_data';
  static const String _masterDataTimestampKey = 'master_data_timestamp';
  static const int _cacheDurationDays = 7; // 1 week

  static Future<MasterData?> getMasterData(BuildContext context, {bool forceRefresh = false}) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Check if we should use cached data
    if (!forceRefresh) {
      final cachedData = _getCachedMasterData(prefs);
      if (cachedData != null) {
        return cachedData;
      }
    }

    // Fetch fresh data from API
    try {
      final response = await ApiCommon.getMasterData(context);
      if (response != null && response['status'] == 'success') {
        final masterData = MasterData.fromJson(response);
        
        // Cache the data
        await _cacheMasterData(prefs, masterData);
        
        return masterData;
      }
    } catch (e) {
      print('Error fetching master data: $e');
    }

    // If API fails, try to return cached data even if expired
    return _getCachedMasterData(prefs, ignoreExpiry: true);
  }

  static MasterData? _getCachedMasterData(SharedPreferences prefs, {bool ignoreExpiry = false}) {
    try {
      final timestamp = prefs.getInt(_masterDataTimestampKey);
      final dataString = prefs.getString(_masterDataKey);
      
      if (timestamp == null || dataString == null) {
        return null;
      }

      final now = DateTime.now();
      final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final daysSinceCache = now.difference(cacheTime).inDays;

      // Check if cache is still valid (within 7 days)
      if (!ignoreExpiry && daysSinceCache >= _cacheDurationDays) {
        return null;
      }

      final data = jsonDecode(dataString);
      return MasterData.fromJson(data);
    } catch (e) {
      print('Error reading cached master data: $e');
      return null;
    }
  }

  static Future<void> _cacheMasterData(SharedPreferences prefs, MasterData masterData) async {
    try {
      final dataString = jsonEncode(masterData.toJson());
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      
      await prefs.setString(_masterDataKey, dataString);
      await prefs.setInt(_masterDataTimestampKey, timestamp);
    } catch (e) {
      print('Error caching master data: $e');
    }
  }

  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_masterDataKey);
    await prefs.remove(_masterDataTimestampKey);
  }

  static Future<bool> isCacheExpired() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_masterDataTimestampKey);
    
    if (timestamp == null) {
      return true;
    }

    final now = DateTime.now();
    final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final daysSinceCache = now.difference(cacheTime).inDays;

    return daysSinceCache >= _cacheDurationDays;
  }
} 