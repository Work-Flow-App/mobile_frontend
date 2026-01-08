class JobWorkflowStep {
  final int id;
  final String name;
  final String description;
  final int orderIndex;
  String status;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final List<int> assignedWorkerIds;

  JobWorkflowStep({
    required this.id,
    required this.name,
    required this.description,
    required this.orderIndex,
    required this.status,
    this.startedAt,
    this.completedAt,
    required this.assignedWorkerIds,
  });
}
