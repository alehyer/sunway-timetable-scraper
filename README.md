# SunwayTimeTabler

SunwayTimeTabler is a full-stack project for retrieving a Sunway student timetable from Sunway iZone, displaying it in a Flutter app, and exporting it to a calendar or generating AI-assisted study recommendations.

The repository is split into two main parts:

- `backend/` – Java + Spring Boot service that scrapes the timetable and exposes REST endpoints
- `frontend/` – Flutter mobile/web client that presents the timetable and integrates calendar export features

## Features

- Extract timetable data from Sunway iZone using Selenium and HTML parsing
- Expose timetable and AI endpoints through a Spring Boot API
- Display the timetable in a Flutter interface
- Export timetable entries to the device calendar
- Generate study recommendations using a local Ollama model

## Project structure

```text
SunwayTimeTabler/
├── backend/
│   ├── src/
│   ├── pom.xml
│   └── mvnw
├── frontend/
│   ├── lib/
│   ├── assets/
│   ├── pubspec.yaml
│   └── README.md
├── .gitignore
└── README.md
```

## Requirements

Before running the project, make sure you have:

- Java 17+
- Maven or the included `backend/mvnw`
- Flutter SDK
- Chrome/Chromium installed and available to Selenium
- Ollama installed and running locally
- A model such as `llama3.2` pulled in Ollama

## Backend setup

From the repository root:

```bash
cd backend
./mvnw spring-boot:run
```

The app listens on:

- `http://localhost:8020`

The backend configuration is defined in:

- `backend/src/main/resources/application.yaml`

It expects Ollama at:

- `http://localhost:11434`

and uses the model:

- `llama3.2`

## API endpoints

The backend exposes timetable-related endpoints under `/api/timetable`.

### Scrape timetable

```http
POST /api/timetable/scrape
```

Request body includes the Sunway iZone student credentials and returns the scraped timetable data.

### AI recommendations

```http
POST /api/timetable/ai
```

Request body includes the timetable data and an intensity level. The backend uses Ollama to generate study recommendations.

## Frontend setup

From the repository root:

```bash
cd frontend
flutter pub get
flutter run
```

## Typical development flow

1. Start the backend API.
2. Run the Flutter app.
3. Sign in with Sunway iZone credentials.
4. View the timetable.
5. Export to the device calendar or generate AI study suggestions.

## Notes

- This project is still a development prototype and may contain test/debug code.
- The Flutter app currently clears cached preferences on startup in `frontend/lib/main.dart`, which is useful for testing but should be removed before production deployment.
- The backend depends on a working local Ollama service for AI features.

## License

This project does not currently declare a license in the repository, so treat it as project-local code for internal or academic use unless otherwise specified by the project owner.
