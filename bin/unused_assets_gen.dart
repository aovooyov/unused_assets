import 'dart:io';

import 'package:glob/glob.dart';
import 'package:glob/list_local_fs.dart';

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
  for (final file in assets) {
    final content = File(file).readAsStringSync();
    final lines = content.split('\n');
    for (final line in lines) {
      if (line.contains(' get ')) {
        final property = line.trim().split(' ')[2].split(' ')[0];
        properties.add(property);
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
