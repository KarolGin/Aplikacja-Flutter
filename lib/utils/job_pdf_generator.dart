import 'dart:convert';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/job.dart';

class JobPdfGenerator {
  static Future<void> generate(Job job) async {
    final doc = pw.Document();

    final String signature = job.clientSignatureBase64 ?? '';
    Uint8List? signatureBytes;
    if (signature.isNotEmpty) {
      signatureBytes = base64Decode(signature);
    }

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
              pw.Text('Tytuł: ${job.title}'),
              pw.Text('Klient: ${job.clientName}'),
              pw.Text('Adres: ${job.address}'),
              pw.Text('Opis: ${job.description}'),
              pw.Text('Kwota: ${job.price.toStringAsFixed(2)} PLN'),
              if (job.completedBy != null && job.completedBy!.isNotEmpty)
                pw.Text('Wykonał: ${job.completedBy}'),
              if (job.completedAt != null)
                pw.Text('Data zakończenia: ${job.completedAt}'),
              pw.SizedBox(height: 20),
              pw.Text('Podpis klienta:'),
              pw.SizedBox(height: 8),
              pw.Container(
                height: 120,
                width: 280,
                decoration: pw.BoxDecoration(border: pw.Border.all()),
                child: signatureBytes != null
                    ? pw.Image(
                        pw.MemoryImage(signatureBytes),
                        fit: pw.BoxFit.contain,
                      )
                    : pw.Center(child: pw.Text('Brak podpisu')),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (_) async => doc.save(),
      name: 'potwierdzenie_${job.id}.pdf',
    );
  }
}
