// lib/services/marketing_target_service.dart
import 'package:flutter/material.dart';
import 'package:mega_pro/models/mar_manager_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MarketingTargetService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ===================== GET MARKETING MANAGERS =====================
  Future<List<MarketingManager>> getMarketingManagers({String? branch}) async {
    try {
      // Build query with method chaining (no reassignment needed)
      final data = await _supabase
          .from('emp_profile')
          .select('id, emp_id, full_name, email, phone, position, branch, district, status, role')
          .eq('role', 'Marketing Manager')
          .eq('status', 'Active')
          .order('full_name');
      
      return (data as List<dynamic>)
          .map((e) => MarketingManager.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error fetching marketing managers: $e');
      return [];
    }
  }

  // ===================== GET BRANCHES =====================
  Future<List<String>> getBranches() async {
    try {
      final data = await _supabase
          .from('emp_profile')
          .select('branch')
          .eq('role', 'Marketing Manager')
          .eq('status', 'Active');

      final branches = (data as List<dynamic>)
          .map((e) => e['branch'] as String?)
          .where((branch) => branch != null && branch.isNotEmpty)
          .map((branch) => branch!)
          .toSet()
          .toList();
      
      branches.sort();
      return ['All Branches', ...branches];
    } catch (e) {
      debugPrint('Error fetching branches: $e');
      return ['All Branches'];
    }
  }

  // ===================== GET ASSIGNED TARGETS =====================
  Future<List<MarketingTarget>> getAssignedTargets({
    String? branch,
    DateTime? month,
  }) async {
    try {
      // Start building the query
      var queryBuilder = _supabase
          .from('own_marketing_targets')
          .select('''
            *,
            manager:emp_profile!inner(
              id, emp_id, full_name, email, phone, position, branch, district, status, role
            )
          ''');

      // Apply filters
      if (branch != null && branch != 'All Branches') {
        queryBuilder = queryBuilder.eq('branch', branch);
      }

      if (month != null) {
        final monthStr = '${month.year}-${month.month.toString().padLeft(2, '0')}-01';
        queryBuilder = queryBuilder.eq('target_month', monthStr);
      }

      // Execute the query with ordering - call order() directly on the chain
      final data = await queryBuilder.order('target_month', ascending: false).order('branch');
      
      return (data as List<dynamic>)
          .map((e) => MarketingTarget.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error fetching assigned targets: $e');
      return [];
    }
  }

  // ===================== GET TARGET FOR MARKETING MANAGER =====================
  Future<MarketingTarget?> getManagerTarget({
    required String managerId,
    required DateTime month,
  }) async {
    try {
      final monthStr = '${month.year}-${month.month.toString().padLeft(2, '0')}-01';
      
      final data = await _supabase
          .from('own_marketing_targets')
          .select('''
            *,
            manager:emp_profile!inner(
              id, emp_id, full_name, email, phone, position, branch, district, status, role
            )
          ''')
          .eq('manager_id', managerId)
          .eq('target_month', monthStr)
          .maybeSingle();

      if (data == null) return null;
      return MarketingTarget.fromJson(data);
    } catch (e) {
      debugPrint('Error fetching manager target: $e');
      return null;
    }
  }

  // ===================== ASSIGN TARGETS =====================
  Future<bool> assignTargets({
    required List<String> managerIds,
    required String branch,
    required DateTime targetMonth,
    required int revenueTarget,
    required int orderTarget,
    String? remarks,
  }) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      final targets = managerIds.map((managerId) {
        return {
          'manager_id': managerId,
          'branch': branch,
          'target_month': '${targetMonth.year}-${targetMonth.month.toString().padLeft(2, '0')}-01',
          'revenue_target': revenueTarget,
          'order_target': orderTarget,
          'remarks': remarks,
          'assigned_by': currentUser?.id,
        };
      }).toList();

      await _supabase.from('own_marketing_targets').upsert(
        targets,
        onConflict: 'manager_id, target_month',
      );

      return true;
    } catch (e) {
      debugPrint('Error assigning targets: $e');
      return false;
    }
  }

  // ===================== UPDATE TARGET PROGRESS =====================
  Future<bool> updateTargetProgress({
    required String targetId,
    required int revenueAchieved,
    required int ordersAchieved,
  }) async {
    try {
      // Update target achieved values
      await _supabase
          .from('own_marketing_targets')
          .update({
            'achieved_revenue': revenueAchieved,
            'achieved_orders': ordersAchieved,
          })
          .eq('id', targetId);

      // Add daily progress record
      await _supabase.from('own_target_progress').insert({
        'target_id': targetId,
        'progress_date': DateTime.now().toIso8601String().split('T')[0],
        'revenue_achieved': revenueAchieved,
        'orders_achieved': ordersAchieved,
      });

      return true;
    } catch (e) {
      debugPrint('Error updating target progress: $e');
      return false;
    }
  }

  // ===================== DELETE TARGET =====================
  Future<bool> deleteTarget(String targetId) async {
    try {
      await _supabase
          .from('own_marketing_targets')
          .delete()
          .eq('id', targetId);
      return true;
    } catch (e) {
      debugPrint('Error deleting target: $e');
      return false;
    }
  }
}