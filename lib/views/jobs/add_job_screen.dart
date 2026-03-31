import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/job.dart';
import '../../providers/jobs_provider.dart';

class AddJobScreen extends StatefulWidget {
  const AddJobScreen({
    super.key,
    this.initialJob,
  });

  final Job? initialJob;

  bool get isEditMode => initialJob != null;

  @override
  State<AddJobScreen> createState() => _AddJobScreenState();
}

class _AddJobScreenState extends State<AddJobScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _clientNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  JobDepartment _selectedDepartment = JobDepartment.wash;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialJob;
    if (initial != null) {
      _titleController.text = initial.title;
      _clientNameController.text = initial.clientName;
      _descriptionController.text = initial.description;
      _addressController.text = initial.address;
      _priceController.text = initial.price.toStringAsFixed(2);
      _selectedDepartment = initial.department;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _clientNameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final price = double.tryParse(_priceController.text.replaceAll(',', '.'));
    if (price == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Podaj poprawną cenę.')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final initial = widget.initialJob;
    final job = Job(
      id: initial?.id ?? '',
      title: _titleController.text.trim(),
      clientName: _clientNameController.text.trim(),
      description: _descriptionController.text.trim(),
      address: _addressController.text.trim(),
      department: _selectedDepartment,
      status: initial?.status ?? JobStatus.pending,
      price: price,
      scheduledAt: initial?.scheduledAt ?? DateTime.now(),
      clientSignatureBase64: initial?.clientSignatureBase64,
      clientSignatureUrl: initial?.clientSignatureUrl,
      workerSignatureUrl: initial?.workerSignatureUrl,
      assignedToUserId: initial?.assignedToUserId,
    );

    try {
      final jobsProvider = context.read<JobsProvider>();
      if (widget.isEditMode) {
        await jobsProvider.updateJob(job);
      } else {
        await jobsProvider.addJob(job);
      }

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEditMode
                ? 'Nie udało się zapisać zmian.'
                : 'Nie udało się dodać zlecenia.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isEditMode ? 'Edytuj zlecenie' : 'Nowe zlecenie';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: ListView(
                shrinkWrap: true,
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Tytuł'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Tytuł jest wymagany';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _clientNameController,
                    decoration: const InputDecoration(labelText: 'Nazwa klienta'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Nazwa klienta jest wymagana';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descriptionController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(labelText: 'Opis'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(labelText: 'Adres'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Adres jest wymagany';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _priceController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Cena'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Cena jest wymagana';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<JobDepartment>(
                    value: _selectedDepartment,
                    decoration: const InputDecoration(labelText: 'Kategoria'),
                    items: const [
                      DropdownMenuItem(
                        value: JobDepartment.wash,
                        child: Text('Mycie'),
                      ),
                      DropdownMenuItem(
                        value: JobDepartment.drones,
                        child: Text('Dron'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedDepartment = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _isSaving ? null : _submit,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save),
                      label: Text(
                        _isSaving
                            ? 'Zapisywanie...'
                            : widget.isEditMode
                                ? 'Zapisz zmiany'
                                : 'Dodaj zlecenie',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
