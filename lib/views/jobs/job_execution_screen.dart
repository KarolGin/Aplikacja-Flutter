import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:signature/signature.dart';
import 'package:url_launcher/url_launcher.dart';

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

  Future<void> _openNavigation() async {
    final query = Uri.encodeComponent(widget.job.address);
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nie udało się otworzyć Google Maps.')),
      );
    }
  }

  Future<void> _generatePdfConfirmation(String signatureBase64) async {
    final doc = pw.Document();
    final Uint8List signatureBytes = base64Decode(signatureBase64);

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Twoja Firma Sp. z o.o.',
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text('Potwierdzenie realizacji zlecenia'),
              pw.SizedBox(height: 12),
              pw.Text('Tytuł: ${widget.job.title}'),
              pw.Text('Adres: ${widget.job.address}'),
              pw.Text('Kwota: ${widget.job.price.toStringAsFixed(2)} PLN'),
              pw.SizedBox(height: 20),
              pw.Text('Podpis klienta:'),
              pw.SizedBox(height: 8),
              pw.Container(
                height: 120,
                width: 280,
                decoration: pw.BoxDecoration(border: pw.Border.all()),
                child: pw.Image(pw.MemoryImage(signatureBytes), fit: pw.BoxFit.contain),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (_) async => doc.save(),
      name: 'potwierdzenie_${widget.job.id}.pdf',
    );
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
      await _generatePdfConfirmation(signatureBase64);

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
      appBar: AppBar(
        title: Text('Realizacja: ${widget.job.title}'),
        actions: [
          TextButton.icon(
            onPressed: _openNavigation,
            icon: const Icon(Icons.navigation),
            label: const Text('Nawiguj'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cena: ${widget.job.price.toStringAsFixed(2)} PLN'),
            const SizedBox(height: 4),
            Text('Adres: ${widget.job.address}'),
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
