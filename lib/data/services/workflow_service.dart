import 'package:mobile_frontend/data/models/workflow.dart';
import 'package:mobile_frontend/data/models/workflow_step.dart';

class WorkflowService {
  Future<List<Workflow>> fetchWorkflows() async {
    await Future.delayed(const Duration(milliseconds: 500));

    return [
      Workflow(
        id: 1,
        jobId: 1,
        workflowId: 1,
        status: 'NOT_STARTED',
        workerIds: [1],
        steps: [
          WorkflowStep(
            id: 1,
            name: 'Inspection',
            status: 'INITIATED',
            assignedWorkerIds: [1],
          ),
          WorkflowStep(
            id: 2,
            name: 'Repair Work',
            status: 'INITIATED',
            assignedWorkerIds: [],
          ),
          WorkflowStep(
            id: 3,
            name: 'Final Inspection',
            status: 'INITIATED',
            assignedWorkerIds: [],
          ),
        ],
      ),
    ];
  }
}
