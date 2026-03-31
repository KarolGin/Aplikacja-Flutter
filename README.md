# Aplikacja Flutter: Zarządzanie zleceniami (Drony / Mycie)

## Proponowana struktura folderów

```text
lib/
  main.dart
  models/
    app_user.dart
    job.dart
  providers/
    jobs_provider.dart
  services/
    job_service.dart
  views/
    auth/
      login_screen.dart
    dashboard/
      admin_dashboard.dart
      drones_dashboard.dart
      wash_dashboard.dart
    jobs/
      job_list_screen.dart
      add_job_screen.dart
    job_details/
      job_details_screen.dart
  widgets/
    app_drawer.dart
    responsive_scaffold.dart
```

## Co już zostało przygotowane

- Model danych `AppUser` (rola + mapowanie Firestore).
- Model danych `Job` (dział, status, cena, termin, podpisy).
- Serwis `JobService` do pobierania zleceń zależnie od roli.
- Provider `JobsProvider` do zarządzania stanem listy zleceń.
- Responsywny ekran `JobListScreen` (mobile + desktop) z kartami zleceń.
- Minimalny `main.dart` z integracją `Firebase.initializeApp()` i `Provider`.
