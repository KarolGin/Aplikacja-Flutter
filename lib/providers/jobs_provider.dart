import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
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

  Future<void> addJob(Job job) {
    return _jobService.addJob(job);
  }

  void start(UserRole role) {
    _isLoading = true;
    notifyListeners();

    _subscription?.cancel();
    _subscription = _jobService.watchJobsForRole(role).listen((jobs) {
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
