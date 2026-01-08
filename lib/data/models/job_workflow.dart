import 'job_workflow_step.dart';

class JobWorkflow {
  final int id;
  final int jobId;
  String status;
  final List<JobWorkflowStep> steps;

  JobWorkflow({
    required this.id,
    required this.jobId,
    required this.status,
    required this.steps,
  });
}
