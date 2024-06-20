import 'dart:io';

import 'package:change_case/change_case.dart';
import 'package:glob/glob.dart';
import 'package:glob/list_local_fs.dart';
import 'package:path/path.dart';

void findUnusedGen() {
  final root = Directory.current.path;
  final rootPosix = root.replaceAll("\\", "/");

  final assets = getAssets(rootPosix);
  final dartFiles = getDartFiles(rootPosix);
  final unusedAssets = findUnusedAssets(assets, dartFiles);
  for (final asset in unusedAssets) {
    print(asset);
  }
}

Set<String> getAssets(String path) {
  final assetsGlob = Glob('$path/lib/**.gen.dart');

  final assets = <String>{};
  for (var entity in assetsGlob.listSync(followLinks: false)) {
    assets.add(entity.path);
  }

  final properties = <String>{};
  final regExp = RegExp(r'''(["'])(?:\\.|(?!\1).)*\1''');

  for (final file in assets) {
    final fileContent = File(file).readAsStringSync();
    final matches = regExp.allMatches(fileContent);

    for (final match in matches) {
      final matchString = match.group(0);
      if (matchString != null) {
        final assetPath = withoutExtension(matchString);
        final asset = assetPath.split('/').map((s) => s.toCamelCase()).join('.');
        properties.add(asset.toUpperFirstCase());
      }
    }
  }

  return properties;
}

List<String> getDartFiles(String path) {
  final dartFilesGlob = Glob('$path/lib/**.dart');
  final dartFilesExcludeGlob = Glob('$path/lib/generated/**.dart');

  final dartFilesExclude = <String>[];
  for (var entity in dartFilesExcludeGlob.listSync(followLinks: false)) {
    dartFilesExclude.add(entity.path);
  }

  final dartFiles = <String>[];
  for (var entity in dartFilesGlob.listSync(followLinks: false)) {
    if (!dartFilesExclude.contains(entity.path)) {
      dartFiles.add(entity.path);
    }
  }

  return dartFiles;
}

Set<String> findUnusedAssets(Set<String> assets, List<String> files) {
  final usedAssets = <String>{};
  for (final file in files) {
    final content = File(file).readAsStringSync();
    for (final asset in assets) {
      if (content.contains(asset)) {
        usedAssets.add(asset);
      }
    }
  }

  final unusedAssets = <String>{};
  for (final asset in assets) {
    if (!usedAssets.contains(asset)) {
      unusedAssets.add(asset);
    }
  }

  return unusedAssets;
}
