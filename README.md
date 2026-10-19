# Foundit

Lost something? Find your way back to it.

Foundit is a campus-first lost-and-found app for Android and iOS. People post lost and found reports, an AI agent matches reports that describe the same item in different words (English and Roman Urdu), and a private claim process confirms the owner before handover at the campus desk.

Individual semester project by Basit Ul Ebad (FA23-BSE-026). Domain: mobile application, agentic AI and NLP.

## Status

UI stage. The clickable prototype and the Flutter screens (sample data) are in place. Firebase and the backend are not started yet.

## Folders

| Folder | What it holds |
| --- | --- |
| `design/` | Clickable UI prototype (open `foundit-prototype.html` in a browser) |
| `docs/` | Proposal, requirements, tools and technology (added as they are finalised) |
| `app/` | Flutter app (Android and iOS), UI screens on sample data |
| `backend/` | Python FastAPI backend, planned |

## Planned stack

Flutter and Dart, Firebase (Authentication, Firestore, Cloud Messaging), Python FastAPI, an open-source LLM (Llama 3.1 8B via Groq) and an open-source sentence-embedding model.

## Notes

All names, items and match scores in the prototype are sample data. Scoring weights and thresholds are starting values to test, not validated results. Foundit is not claimed to be unique; similar lost-and-found apps exist.
