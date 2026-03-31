import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/job.dart';
import '../services/job_service.dart';

class JobsProvider extends ChangeNotifier {
  JobsProvider(this._jobService);

  final JobService _jobService;

  StreamSubscription<List<Job>>? _subscription;

  List<Job> _jobs = <Job>[];
  bool _isLoading = false;

  List<Job> get jobs => _jobs;
  bool get isLoading => _isLoading;

  Future<void> addJob(Job job) => _jobService.addJob(job);
  Future<void> updateJob(Job job) => _jobService.updateJob(job);
  Future<void> deleteJob(String jobId) => _jobService.deleteJob(jobId);

  Future<void> startJob(String jobId) => _jobService.markInProgress(jobId);

  Future<void> completeJob({
    required String jobId,
    required String clientSignatureBase64,
    required String completedBy,
  }) {
    return _jobService.completeJob(
      jobId: jobId,
      clientSignatureBase64: clientSignatureBase64,
      completedBy: completedBy,
    );
  }

  void start() {
    _isLoading = true;
    notifyListeners();

    _subscription?.cancel();
    _subscription = _jobService.watchJobs().listen((jobs) {
      _jobs = jobs;
      _isLoading = false;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
