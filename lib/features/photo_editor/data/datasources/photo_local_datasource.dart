import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../domain/entities/photo_project_entity.dart';

class PhotoLocalDataSource {
  Future<File> _getFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/photo_projects_catalog.json');
  }

  Future<List<PhotoProjectEntity>> getPhotoProjects() async {
    try {
      final file = await _getFile();
      if (!await file.exists()) {
        return [];
      }
      final contents = await file.readAsString();
      if (contents.trim().isEmpty) return [];
      final List<dynamic> jsonList = jsonDecode(contents);
      return jsonList
          .map((j) => PhotoProjectEntity.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> savePhotoProject(PhotoProjectEntity project) async {
    final list = await getPhotoProjects();
    final index = list.indexWhere((p) => p.id == project.id);
    if (index >= 0) {
      list[index] = project;
    } else {
      list.insert(0, project);
    }
    await _saveList(list);
  }

  Future<void> deletePhotoProject(String id) async {
    final list = await getPhotoProjects();
    list.removeWhere((p) => p.id == id);
    await _saveList(list);
  }

  Future<void> _saveList(List<PhotoProjectEntity> list) async {
    final file = await _getFile();
    final raw = jsonEncode(list.map((p) => p.toJson()).toList());
    await file.writeAsString(raw);
  }
}
