import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/valuer_profile.dart';
import '../../models/valuation_project.dart';

class StorageService {
  static const String _keyProfile = 'val_user_profile';
  static const String _keyProjects = 'val_projects_list';
  static const String _keyActiveProjectId = 'val_active_project_id';

  // Profile Persistence
  static Future<void> saveProfile(ValuerProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyProfile, jsonEncode(profile.toJson()));
  }

  static Future<ValuerProfile> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyProfile);
    if (raw == null || raw.isEmpty) return ValuerProfile();
    try {
      return ValuerProfile.fromJson(jsonDecode(raw));
    } catch (_) {
      return ValuerProfile();
    }
  }

  // Projects Persistence
  static Future<void> saveProjects(List<ValuationProject> projects) async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = projects.map((p) => p.toJson()).toList();
    await prefs.setString(_keyProjects, jsonEncode(rawList));
  }

  static Future<List<ValuationProject>> loadProjects() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyProjects);
    if (raw == null || raw.isEmpty) return [];
    try {
      final List decoded = jsonDecode(raw);
      return decoded.map((item) => ValuationProject.fromJson(item)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveActiveProject(ValuationProject project) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyActiveProjectId, project.id);

    final projects = await loadProjects();
    final index = projects.indexWhere((p) => p.id == project.id);
    if (index >= 0) {
      projects[index] = project;
    } else {
      projects.insert(0, project);
    }
    await saveProjects(projects);
  }

  static Future<ValuationProject?> loadActiveProject() async {
    final prefs = await SharedPreferences.getInstance();
    final activeId = prefs.getString(_keyActiveProjectId);
    if (activeId == null) return null;
    final projects = await loadProjects();
    final match = projects.where((p) => p.id == activeId);
    return match.isNotEmpty ? match.first : null;
  }

  static Future<void> deleteProject(String projectId) async {
    final projects = await loadProjects();
    projects.removeWhere((p) => p.id == projectId);
    await saveProjects(projects);
  }
}
