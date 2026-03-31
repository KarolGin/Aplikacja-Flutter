import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/app_user.dart';
import '../../models/job.dart';
import '../../providers/jobs_provider.dart';
import '../../services/auth_service.dart';
import 'add_job_screen.dart';
import 'job_execution_screen.dart';

class JobListScreen extends StatefulWidget {
  const JobListScreen({
    super.key,
    required this.appUser,
  });

  final AppUser appUser;

  @override
  State<JobListScreen> createState() => _JobListScreenState();
}

class _JobListScreenState extends State<JobListScreen>
    with SingleTickerProviderStateMixin {
  final DateFormat _dateFormat = DateFormat('dd.MM.yyyy HH:mm');

  late final TabController _tabController = TabController(length: 2, vsync: this);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<JobsProvider>().start();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _openAddJobScreen() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const AddJobScreen(),
      ),
    );
  }

  List<Job> _filteredJobs(List<Job> jobs) {
    if (_tabController.index == 1) {
      return jobs.where((job) => job.status == JobStatus.completed).toList();
    }

    return jobs.where((job) => job.status != JobStatus.completed).toList();
  }

  Future<void> _onTapJob(Job job) async {
    if (job.status == JobStatus.inProgress) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => JobExecutionScreen(job: job),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista zleceń'),
        actions: [
          IconButton(
            onPressed: () => context.read<AuthService>().signOut(),
            icon: const Icon(Icons.logout),
            tooltip: 'Wyloguj',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          onTap: (_) => setState(() {}),
          tabs: const [
            Tab(text: 'Do zrobienia'),
            Tab(text: 'Zakończone'),
          ],
        ),
      ),
      floatingActionButton: widget.appUser.isAdmin
          ? FloatingActionButton(
              onPressed: _openAddJobScreen,
              child: const Icon(Icons.add),
            )
          : null,
      body: Consumer<JobsProvider>(
        builder: (context, jobsProvider, _) {
          if (jobsProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final visibleJobs = _filteredJobs(jobsProvider.jobs);
          if (visibleJobs.isEmpty) {
            return const Center(child: Text('Brak zleceń do wyświetlenia.'));
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= 900;
              final crossAxisCount = isDesktop ? 2 : 1;

              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: isDesktop ? 3.7 : 2.9,
                ),
                itemCount: visibleJobs.length,
                itemBuilder: (context, index) {
                  final job = visibleJobs[index];
                  return _JobCard(
                    job: job,
                    formattedDate: _dateFormat.format(job.scheduledAt),
                    onTap: () => _onTapJob(job),
                    onStart: job.status == JobStatus.pending
                        ? () => context.read<JobsProvider>().startJob(job.id)
                        : null,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  const _JobCard({
    required this.job,
    required this.formattedDate,
    required this.onTap,
    this.onStart,
  });

  final Job job;
  final String formattedDate;
  final VoidCallback onTap;
  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context) {
    final (statusText, statusColor) = switch (job.status) {
      JobStatus.pending => ('Oczekujące', Colors.orange),
      JobStatus.inProgress => ('W trakcie', Colors.blue),
      JobStatus.completed => ('Zakończone', Colors.green),
    };

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                job.title,
                style: Theme.of(context).textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                job.description.isEmpty ? 'Brak opisu' : job.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const Spacer(),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(label: Text(formattedDate)),
                  Chip(label: Text('${job.price.toStringAsFixed(2)} PLN')),
                  Chip(
                    label: Text(statusText),
                    backgroundColor: statusColor.withValues(alpha: 0.18),
                  ),
                ],
              ),
              if (onStart != null) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: onStart,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Rozpocznij zlecenie'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
