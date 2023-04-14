import 'dart:collection';
import 'dart:io' show File;

import 'package:yaml/yaml.dart';

class Repository {
  final String name;
  final String workflow;
  final String ci;

  Repository.from(YamlMap data)
      : name = data['name'] as String,
        ci = data['ci'] as String,
        workflow = data['workflow'] as String;
}

class Category {
  final String name;
  final List<Repository> repos;

  Category.from(YamlMap data)
      : name = data['name'] as String,
        repos = (data['repos'] as List<dynamic>).map(asRepository).toList();

  static Repository asRepository(dynamic repo) =>
      Repository.from(repo as YamlMap);
}

class Categories extends ListBase<Category> {
  List<Category> inner = [];

  Categories(YamlList data) {
    addAll(data.map((v) => Category.from(v as YamlMap)).toList());
  }

  @override
  int get length => inner.length;

  @override
  set length(int length) {
    inner.length = length;
  }

  @override
  void operator []=(int index, Category value) {
    inner[index] = value;
  }

  @override
  Category operator [](int index) => inner[index];

  @override
  void add(Category value) => inner.add(value);

  @override
  void addAll(Iterable<Category> all) => inner.addAll(all);
}

class ProjectsFile {
  List<Category> categories = [];

  ProjectsFile();

  Future<void> fromYaml(String srcPath) async {
    final yamlStr = await File(srcPath).readAsString();
    final yamlList = loadYaml(yamlStr) as YamlList;
    categories = Categories(yamlList);
  }

  Future<void> toMarkdown(String destPath) async {
    final details = StringBuffer();

    for (final category in categories) {
      details.write('## ${category.name}\n\n');

      if (category.repos.isEmpty) {
        continue;
      }

      for (final repo in category.repos) {
        final repoName = repo.name;
        details.write('- <a href="https://github.com/$repoName">$repoName</a>');

        if (repo.ci == 'github' && repo.workflow.isNotEmpty) {
          details
            ..write(
                ' — <a href="https://github.com/$repoName/actions/workflows/${repo.workflow}.yml" title="GitHub Workflow Status">')
            ..write(
                '<img src="https://github.com/$repoName/actions/workflows/${repo.workflow}.yml/badge.svg?branch=master" width="64" />')
            ..write('</a>');
        }
        if (repo.ci == 'cirrus' && repo.workflow.isNotEmpty) {
          details
            ..write(
                ' — <a href="https://cirrus-ci.com/github/$repoName" title="Cirrus CI Status">')
            ..write(
                '<img src="https://api.cirrus-ci.com/github/$repoName.svg" width="64" />')
            ..write('</a>');
        }

        details.write('\n');
      }

      details.write('\n');
    }

    final tmpl = (await File('src/projects.md').readAsString())
        .replaceAll('{{TABLE}}', details.toString());

    await File(destPath).writeAsString(tmpl);
  }
}

Future<void> main() async {
  final projects = ProjectsFile();
  await projects.fromYaml('src/projects.yml');
  await projects.toMarkdown('README.md');
}
