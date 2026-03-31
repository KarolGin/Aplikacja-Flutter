import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/job.dart';
import '../../utils/job_pdf_generator.dart';

class JobHistoryScreen extends StatelessWidget {
  const JobHistoryScreen({
    super.key,
    required this.job,
  });

  final Job job;

  @override
  Widget build(BuildContext context) {
    final completedAtText = job.completedAt == null
        ? 'Brak danych'
        : DateFormat('dd.MM.yyyy HH:mm').format(job.completedAt!);

    return Scaffold(
      appBar: AppBar(title: const Text('Archiwum zlecenia')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(job.title, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text('Klient: ${job.clientName}'),
                  Text('Adres: ${job.address}'),
                  Text('Opis: ${job.description}'),
                  Text('Kwota: ${job.price.toStringAsFixed(2)} PLN'),
                  Text('Data zakończenia: $completedAtText'),
                  const SizedBox(height: 8),
                  Text(
                    'Zlecenie wykonał: ${job.completedBy ?? 'brak danych'}, Data: $completedAtText',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Podpis klienta (miniatura)'),
                  const SizedBox(height: 8),
                  Container(
                    height: 120,
                    width: 260,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: _buildSignaturePreview(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => JobPdfGenerator.generate(job),
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Generuj / Pobierz PDF'),
          ),
        ],
      ),
    );
  }

  Widget _buildSignaturePreview() {
    final signature = job.clientSignatureBase64;
    if (signature == null || signature.isEmpty) {
      return const Center(child: Text('Brak podpisu'));
    }

    try {
      final bytes = base64Decode(signature);
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.memory(bytes, fit: BoxFit.contain),
      );
    } catch (_) {
      return const Center(child: Text('Nieprawidłowy podpis'));
    }
  }
}
