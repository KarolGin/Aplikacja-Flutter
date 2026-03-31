import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/app_user.dart';
import '../../models/job.dart';
import '../../providers/jobs_provider.dart';
import '../../services/auth_service.dart';
import 'add_job_screen.dart';
import 'job_execution_screen.dart';
import 'job_history_screen.dart';

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
  final TextEditingController _searchController = TextEditingController();

  late final TabController _tabController =
      TabController(length: 2, vsync: this);

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
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openAddJobScreen([Job? job]) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AddJobScreen(initialJob: job),
      ),
    );
  }

  List<Job> _filterCompletedJobsByRole(List<Job> jobs) {
    if (widget.appUser.isAdmin) return jobs;

    return jobs
        .where((job) => (job.completedBy ?? '').toLowerCase() == widget.appUser.email.toLowerCase())
        .toList();
  }

  List<Job> _filteredJobs(List<Job> jobs) {
    if (_tabController.index == 1) {
      final completedJobs = jobs.where((job) => job.status == JobStatus.completed).toList();
      final roleFiltered = _filterCompletedJobsByRole(completedJobs);

      final query = _searchController.text.trim().toLowerCase();
      if (query.isEmpty) return roleFiltered;

      return roleFiltered
          .where(
            (job) =>
                job.address.toLowerCase().contains(query) ||
                job.clientName.toLowerCase().contains(query),
          )
          .toList();
    }

    return jobs.where((job) => job.status != JobStatus.completed).toList();
  }

  double _completedRevenue(List<Job> jobs) {
    return jobs
        .where((job) => job.status == JobStatus.completed)
        .fold<double>(0, (sum, job) => sum + job.price);
  }

  Future<void> _onTapJob(Job job) async {
    if (job.status == JobStatus.inProgress) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => JobExecutionScreen(job: job),
        ),
      );
      return;
    }

    if (job.status == JobStatus.completed) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => JobHistoryScreen(job: job),
        ),
      );
    }
  }

  Future<void> _deleteJob(Job job) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Usuń zlecenie'),
          content: Text('Czy na pewno chcesz usunąć: ${job.title}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Anuluj'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Usuń'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true && mounted) {
      await context.read<JobsProvider>().deleteJob(job.id);
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
          final revenue = _completedRevenue(jobsProvider.jobs);

          return Column(
            children: [
              if (widget.appUser.isAdmin)
                _RevenueSummaryPanel(totalRevenue: revenue),
              if (_tabController.index == 1)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Szukaj po adresie lub nazwie klienta',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              Expanded(
                child: visibleJobs.isEmpty
                    ? const Center(child: Text('Brak zleceń do wyświetlenia.'))
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final isDesktop = constraints.maxWidth >= 900;
                          final crossAxisCount = isDesktop ? 2 : 1;

                          return GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: isDesktop ? 3.7 : 2.9,
                            ),
                            itemCount: visibleJobs.length,
                            itemBuilder: (context, index) {
                              final job = visibleJobs[index];
                              return _JobCard(
                                key: ValueKey(job.id),
                                job: job,
                                isAdmin: widget.appUser.isAdmin,
                                formattedDate: _dateFormat.format(job.scheduledAt),
                                onTap: () => _onTapJob(job),
                                onStart: job.status == JobStatus.pending
                                    ? () => context
                                        .read<JobsProvider>()
                                        .startJob(job.id)
                                    : null,
                                onEdit: widget.appUser.isAdmin
                                    ? () => _openAddJobScreen(job)
                                    : null,
                                onDelete: widget.appUser.isAdmin
                                    ? () => _deleteJob(job)
                                    : null,
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RevenueSummaryPanel extends StatelessWidget {
  const _RevenueSummaryPanel({required this.totalRevenue});

  final double totalRevenue;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade600, Colors.green.shade400],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dashboard finansowy',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 6),
            Text(
              '${totalRevenue.toStringAsFixed(2)} PLN',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              'Suma zleceń zakończonych',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  const _JobCard({
    super.key,
    required this.job,
    required this.formattedDate,
    required this.onTap,
    required this.isAdmin,
    this.onStart,
    this.onEdit,
    this.onDelete,
  });

  final Job job;
  final bool isAdmin;
  final String formattedDate;
  final VoidCallback onTap;
  final VoidCallback? onStart;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final (statusText, statusColor, statusIcon) = switch (job.status) {
      JobStatus.pending => ('Oczekujące', Colors.orange, '🕒'),
      JobStatus.inProgress => ('W trakcie', Colors.blue, '🚀'),
      JobStatus.completed => ('Zakończone', Colors.green, '✅'),
    };

    return Card(
      elevation: 2,
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      job.title,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isAdmin) ...[
                    IconButton(
                      onPressed: onEdit,
                      tooltip: 'Edytuj',
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    IconButton(
                      onPressed: onDelete,
                      tooltip: 'Usuń',
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              Text(
                job.clientName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                job.description.isEmpty ? 'Brak opisu' : job.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                job.address,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const Spacer(),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(label: Text(formattedDate)),
                  Chip(label: Text('${job.price.toStringAsFixed(2)} PLN')),
                  Chip(
                    label: Text('$statusIcon $statusText'),
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
