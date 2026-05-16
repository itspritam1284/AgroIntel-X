import 'gemini_service.dart';
import 'database_helper.dart';

class PlanStorageService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<void> savePlan(FarmingPlan plan) async {
    await _dbHelper.insertPlan(plan);
  }

  Future<List<FarmingPlan>> getAllPlans() async {
    return await _dbHelper.getAllPlans();
  }

  Future<FarmingPlan?> getLatestPlan() async {
    return await _dbHelper.getLatestPlan();
  }

  Future<FarmingPlan?> getPlanById(String planId) async {
    return await _dbHelper.getPlanById(planId);
  }

  Future<void> deletePlan(String planId) async {
    await _dbHelper.deletePlan(planId);
  }

  Future<void> clearAllPlans() async {
    await _dbHelper.deleteAllPlans();
  }
}
