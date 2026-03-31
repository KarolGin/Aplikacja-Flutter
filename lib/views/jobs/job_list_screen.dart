import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/app_user.dart';
import '../../models/job.dart';
import '../../providers/jobs_provider.dart';

class JobListScreen extends StatefulWidget {
  const JobListScreen({
    super.key,
    required this.role,
    required this.onOpenJob,
  });

  final UserRole role;
  final ValueChanged<Job> onOpenJob;

  @override
  State<JobListScreen> createState() => _JobListScreenState();
}

class _JobListScreenState extends State<JobListScreen> {
  final DateFormat _dateFormat = DateFormat('dd.MM.yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<JobsProvider>().start(widget.role);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<JobsProvider>(
      builder: (context, jobsProvider, _) {
        if (jobsProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (jobsProvider.jobs.isEmpty) {
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
                childAspectRatio: isDesktop ? 3.6 : 2.8,
              ),
              itemCount: jobsProvider.jobs.length,
              itemBuilder: (context, index) {
                final job = jobsProvider.jobs[index];
                return _JobCard(
                  job: job,
                  formattedDate: _dateFormat.format(job.scheduledAt),
                  onTap: () => widget.onOpenJob(job),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _JobCard extends StatelessWidget {
  const _JobCard({
    required this.job,
    required this.formattedDate,
    required this.onTap,
  });

  final Job job;
  final String formattedDate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor =
        job.status == JobStatus.completed ? Colors.green : Colors.orange;

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
                job.description,
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
                    label: Text(
                      job.status == JobStatus.completed
                          ? 'Zakończone'
                          : 'Oczekujące',
                    ),
                    backgroundColor: statusColor.withValues(alpha: 0.18),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
