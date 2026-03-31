import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Importy od Codexa
import 'models/app_user.dart';
import 'providers/jobs_provider.dart';
import 'services/job_service.dart';
import 'views/jobs/job_list_screen.dart';

// NASZ KLUCZOWY IMPORT (bez tego nie ruszy!)
import 'firebase_options.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Poprawna inicjalizacja Firebase z opcjami
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<JobsProvider>(
          create: (_) => JobsProvider(JobService(FirebaseFirestore.instance)),
        ),
      ],
      child: MaterialApp(
        title: 'Zlecenia Drony/Mycie',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        // Na razie zostawiamy JobListScreen jako startowy
        home: JobListScreen(
          role: UserRole.admin,
          onOpenJob: (job) {
            // Tu docelowo wejdą szczegóły zlecenia
            print("Otwieranie zlecenia: ${job.id}");
          },
        ),
      ),
    );
  }
}