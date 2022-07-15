import 'dart:collection';
import 'dart:convert' show json;
import 'dart:io' show File;

class Project {
  final String name;
  final List<String> repos;

  Project.from(Map<String, dynamic> data)
      : name = data['name'] as String,
        repos = (data['repos'] as List<dynamic>)
            .map((repo) => repo as String)
            .toList();
}

class Projects extends ListBase<Project> {
  List<Project> inner = [];

  Projects(List<dynamic> data) {
    addAll(data.map((v) => Project.from(v as Map<String, dynamic>)).toList());
  }

  @override
  int get length => inner.length;

  @override
  set length(int length) {
    inner.length = length;
  }

  @override
  void operator []=(int index, Project value) {
    inner[index] = value;
  }

  @override
  Project operator [](int index) => inner[index];

  @override
  void add(Project value) => inner.add(value);

  @override
  void addAll(Iterable<Project> all) => inner.addAll(all);
}

class ProjectsFile {
  List<Project> projects = [];

  ProjectsFile();

  Future<void> fromJson(String srcPath) async {
    final jsonStr = await File(srcPath).readAsString();
    final jsonList = json.decode(jsonStr) as List<dynamic>;
    projects = Projects(jsonList);
  }

  Future<void> toMarkdown(String destPath) async {
    final details = StringBuffer();

    for (final project in projects) {
      details.write('## ${project.name}\n\n');

      if (project.repos.isNotEmpty) {
        for (final repo in project.repos) {
          details.write('- $repo\n');
        }
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
