// lib/providers/marketing_target_provider.dart
import 'package:flutter/foundation.dart';
import 'package:mega_pro/models/mar_manager_model.dart';
import 'package:mega_pro/services/mar_target_assigning_services.dart';


class MarketingTargetProvider with ChangeNotifier {
  final MarketingTargetService _service = MarketingTargetService();
  
  List<MarketingManager> _managers = [];
  List<MarketingTarget> _assignedTargets = [];
  List<String> _branches = ['All Branches'];
  bool _isLoading = false;
  String? _error;

  List<MarketingManager> get managers => _managers;
  List<MarketingTarget> get assignedTargets => _assignedTargets;
  List<String> get branches => _branches;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Initialize data
  Future<void> initialize() async {
    await loadBranches();
    await loadManagers();
    await loadAssignedTargets();
  }

  // Load branches from Marketing Managers
  Future<void> loadBranches() async {
    try {
      _branches = await _service.getBranches();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Load Marketing Managers
  Future<void> loadManagers({String? branch}) async {
    try {
      _isLoading = true;
      notifyListeners();

      _managers = await _service.getMarketingManagers(branch: branch);
      
      _isLoading = false;
      _error = null;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  // Load assigned targets
  Future<void> loadAssignedTargets({String? branch, DateTime? month}) async {
    try {
      _isLoading = true;
      notifyListeners();

      _assignedTargets = await _service.getAssignedTargets(
        branch: branch,
        month: month,
      );
      
      _isLoading = false;
      _error = null;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  // Assign targets to Marketing Managers
  Future<bool> assignTargets({
    required List<String> managerIds,
    required String branch,
    required DateTime targetMonth,
    required int revenueTarget,
    required int orderTarget,
    String? remarks,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final success = await _service.assignTargets(
        managerIds: managerIds,
        branch: branch,
        targetMonth: targetMonth,
        revenueTarget: revenueTarget,
        orderTarget: orderTarget,
        remarks: remarks,
      );

      if (success) {
        await loadAssignedTargets();
        _isLoading = false;
        _error = null;
        notifyListeners();
        return true;
      } else {
        _isLoading = false;
        _error = 'Failed to assign targets';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Delete target
  Future<bool> deleteTarget(String targetId) async {
    try {
      final success = await _service.deleteTarget(targetId);
      if (success) {
        _assignedTargets.removeWhere((target) => target.id == targetId);
        notifyListeners();
      }
      return success;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Refresh all data
  Future<void> refresh() async {
    await initialize();
  }
}