import 'dart:collection';
import 'dart:convert' show json;
import 'dart:io' show File;

class Repository {
  final String name;
  final String workflow;

  Repository.from(Map<String, dynamic> data)
      : name = data['name'] as String,
        workflow = data['workflow'] as String;
}

class Category {
  final String name;
  final List<Repository> repos;

  Category.from(Map<String, dynamic> data)
      : name = data['name'] as String,
        repos = (data['repos'] as List<dynamic>).map(asRepository).toList();

  static Repository asRepository(dynamic repo) =>
      Repository.from(repo as Map<String, dynamic>);
}

class Categories extends ListBase<Category> {
  List<Category> inner = [];

  Categories(List<dynamic> data) {
    addAll(data.map((v) => Category.from(v as Map<String, dynamic>)).toList());
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

  Future<void> fromJson(String srcPath) async {
    final jsonStr = await File(srcPath).readAsString();
    final jsonList = json.decode(jsonStr) as List<dynamic>;
    categories = Categories(jsonList);
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

        if (repo.workflow.isNotEmpty) {
          details
            ..write(
                ' — <a href="https://github.com/$repoName/actions/workflows/${repo.workflow}.yml" title="GitHub Workflow Status">')
            ..write(
                '<img src="https://img.shields.io/github/workflow/status/$repoName/devel" width="52" />')
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
  await projects.fromJson('src/projects.json');
  await projects.toMarkdown('README.md');
}
