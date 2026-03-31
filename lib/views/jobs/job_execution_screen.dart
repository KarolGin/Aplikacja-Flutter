import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:signature/signature.dart';

import '../../models/job.dart';
import '../../providers/jobs_provider.dart';

class JobExecutionScreen extends StatefulWidget {
  const JobExecutionScreen({
    super.key,
    required this.job,
  });

  final Job job;

  @override
  State<JobExecutionScreen> createState() => _JobExecutionScreenState();
}

class _JobExecutionScreenState extends State<JobExecutionScreen> {
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 2,
    penColor: Colors.black,
  );

  bool _isSaving = false;

  @override
  void dispose() {
    _signatureController.dispose();
    super.dispose();
  }

  Future<void> _completeJob() async {
    if (_signatureController.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Podpis klienta jest wymagany.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final Uint8List? bytes = await _signatureController.toPngBytes();
      if (bytes == null || bytes.isEmpty) {
        throw Exception('Brak podpisu');
      }

      final signatureBase64 = base64Encode(bytes);
      await context.read<JobsProvider>().completeJob(
            jobId: widget.job.id,
            clientSignatureBase64: signatureBase64,
          );

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nie udało się zakończyć zlecenia.')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Realizacja: ${widget.job.title}')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cena: ${widget.job.price.toStringAsFixed(2)} PLN'),
            const SizedBox(height: 12),
            const Text('Podpis klienta'),
            const SizedBox(height: 8),
            Container(
              height: 220,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Signature(
                controller: _signatureController,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _signatureController.clear,
                  icon: const Icon(Icons.clear),
                  label: const Text('Wyczyść'),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: _isSaving ? null : _completeJob,
                  icon: const Icon(Icons.check_circle),
                  label: Text(
                    _isSaving ? 'Zapisywanie...' : 'Zakończ zlecenie',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
