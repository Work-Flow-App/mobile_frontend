import 'package:flutter/material.dart';

/// ----------------------------
/// DUMMY MODELS
/// ----------------------------
class DemoWorkflow {
  final int id;
  String status;
  final List<DemoWorkflowStep> steps;

  DemoWorkflow({
    required this.id,
    required this.status,
    required this.steps,
  });
}

class DemoWorkflowStep {
  final int id;
  final String name;
  String status;
  final int? assignedWorkerId;

  DemoWorkflowStep({
    required this.id,
    required this.name,
    required this.status,
    this.assignedWorkerId,
  });
}

class DemoComment {
  final String author;
  String body;

  DemoComment(this.author, this.body);
}

/// ----------------------------
/// DUMMY DATA
/// ----------------------------
final List<DemoWorkflow> demoWorkflows = [
  DemoWorkflow(
    id: 1,
    status: 'ONGOING',
    steps: [
      DemoWorkflowStep(
        id: 1,
        name: 'Inspection',
        status: 'COMPLETED',
        assignedWorkerId: 1,
      ),
      DemoWorkflowStep(
        id: 2,
        name: 'Repair Work',
        status: 'STARTED',
        assignedWorkerId: 1,
      ),
      DemoWorkflowStep(
        id: 3,
        name: 'Final Inspection',
        status: 'INITIATED',
      ),
    ],
  ),
  DemoWorkflow(
    id: 2,
    status: 'INITIATED',
    steps: [
      DemoWorkflowStep(id: 4, name: 'Inspection', status: 'INITIATED'),
      DemoWorkflowStep(id: 5, name: 'Repair Work', status: 'INITIATED'),
    ],
  ),
];

/// ----------------------------
/// DEMO COLORS & THEME (UNIQUE)
/// ----------------------------
class DemoColors {
  static const black = Colors.black;
  static const white = Colors.white;
  static const grey = Colors.grey;
  static const green = Colors.green;
}

class DemoAppTheme {
  static ThemeData light = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: DemoColors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: DemoColors.white,
      foregroundColor: DemoColors.black,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: DemoColors.black,
        foregroundColor: DemoColors.white,
      ),
    ),
  );

  static ThemeData dark = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: DemoColors.black,
    appBarTheme: const AppBarTheme(
      backgroundColor: DemoColors.black,
      foregroundColor: DemoColors.white,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: DemoColors.white,
        foregroundColor: DemoColors.black,
      ),
    ),
  );
}

/// ----------------------------
/// DEMO HOME SCREEN
/// ----------------------------
class DemoHomeScreen extends StatefulWidget {
  const DemoHomeScreen({super.key});

  @override
  State<DemoHomeScreen> createState() => _DemoHomeScreenState();
}

class _DemoHomeScreenState extends State<DemoHomeScreen> {
  bool isDark = true;
  String selectedStatus = 'ALL';
  int selectedWorkflowIndex = 0;

  static const int currentWorkerId = 1;

  final List<DemoComment> comments = [
    DemoComment('worker1', 'Inspection started.'),
    DemoComment('worker1', 'Waiting for parts.'),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: DemoAppTheme.light,
      darkTheme: DemoAppTheme.dark,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Workfloow'),
          actions: [
            IconButton(
              icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
              onPressed: () => setState(() => isDark = !isDark),
            ),
          ],
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final isTablet = constraints.maxWidth > 700;

            return Padding(
              padding: const EdgeInsets.all(12),
              child: isTablet
                  ? Row(
                      children: [
                        Expanded(flex: 2, child: _workflowList()),
                        const VerticalDivider(width: 1),
                        Expanded(flex: 3, child: _workflowDetails()),
                      ],
                    )
                  : Column(
                      children: [
                        Expanded(child: _workflowList()),
                        const Divider(),
                        Expanded(child: _workflowDetails()),
                      ],
                    ),
            );
          },
        ),
      ),
    );
  }

  /// ----------------------------
  /// WORKFLOW LIST + FILTER
  /// ----------------------------
  Widget _workflowList() {
    final workflows = selectedStatus == 'ALL'
        ? demoWorkflows
        : demoWorkflows.where((w) => w.status == selectedStatus).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _statusFilter(),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            itemCount: workflows.length,
            itemBuilder: (context, index) {
              final wf = workflows[index];
              return Card(
                child: ListTile(
                  title: Text('Workflow #${wf.id}'),
                  subtitle: Text(wf.status),
                  selected: selectedWorkflowIndex == index,
                  onTap: () => setState(() => selectedWorkflowIndex = index),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _statusFilter() {
    const statuses = ['ALL', 'INITIATED', 'ONGOING', 'COMPLETED'];
    return Wrap(
      spacing: 6,
      children: statuses.map((s) {
        return ChoiceChip(
          label: Text(s),
          selected: selectedStatus == s,
          onSelected: (_) => setState(() => selectedStatus = s),
        );
      }).toList(),
    );
  }

  /// ----------------------------
  /// WORKFLOW DETAILS
  /// ----------------------------
  Widget _workflowDetails() {
    final workflow = demoWorkflows[selectedWorkflowIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Workflow Pipeline',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Expanded(child: _pipeline(workflow)),
        const Divider(),
        Text(
          'Comments',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        _commentsSection(),
      ],
    );
  }

  Widget _pipeline(DemoWorkflow workflow) {
    return ListView(
      children: workflow.steps.map((step) {
        final isAssigned = step.assignedWorkerId == currentWorkerId;
        final isCompleted = step.status == 'COMPLETED';

        return Card(
          color: isCompleted ? DemoColors.green.withOpacity(0.15) : null,
          child: ListTile(
            title: Text(step.name),
            subtitle: Text(step.status),
            trailing: isAssigned && !isCompleted
                ? TextButton(
                    child: const Text('MARK DONE'),
                    onPressed: () {
                      setState(() {
                        step.status = 'COMPLETED';
                        workflow.status = 'ONGOING';
                      });
                    },
                  )
                : null,
          ),
        );
      }).toList(),
    );
  }

  /// ----------------------------
  /// COMMENTS (CRUD-READY UI)
  /// ----------------------------
  Widget _commentsSection() {
    final controller = TextEditingController();

    return Column(
      children: [
        ...comments.map(
          (c) => ListTile(
            title: Text(c.author),
            subtitle: Text(c.body),
            trailing: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {},
            ),
          ),
        ),
        TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Add a comment...',
          ),
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              setState(() {
                comments.add(DemoComment('worker1', value));
              });
              controller.clear();
            }
          },
        ),
      ],
    );
  }
}
