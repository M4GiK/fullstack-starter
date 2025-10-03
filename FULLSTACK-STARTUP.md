# 🚀 Fullstack Starter - Quick Startup Guide

## Jedno-klikowe uruchomienie całego środowiska programistycznego!

### Co uruchamiają skrypty?

Skrypty `start-fullstack.*` automatycznie uruchamiają wszystkie komponenty projektu:

1. **🗄️ Baza danych** - PostgreSQL + LocalStack (AWS mock) + **Backend Extended (Java)** - wszystko w Dockerze
2. **🔧 Backend (Node.js)** - API RESTowe z Fastify (lokalnie)
3. **🌐 Frontend (React)** - Interfejs użytkownika (lokalnie)

## Wymagania wstępne

- ✅ **Docker & Docker Compose** - wymagane (dla bazy danych, LocalStack i backend-extended)
- ✅ **Node.js & npm** - wymagane dla backend/frontend (uruchamiane lokalnie)

## 🚀 Szybkie uruchomienie

### Windows
```cmd
start-fullstack.bat
```

### macOS/Linux
```bash
./start-fullstack.sh
```

## Co się dzieje krok po kroku?

### 1. Uruchamianie usług Docker (baza danych + backend-extended)
```
Starting database and backend-extended services...
Building backend-extended image... (pierwsze uruchomienie)
Waiting for PostgreSQL to be ready on localhost:5432...
[OK] PostgreSQL is ready!
Waiting for Backend Extended to be ready on localhost:8081...
[OK] Backend Extended is ready!
```

### 2. Uruchamianie backend (Node.js)
```
Starting backend (Node.js)...
Installing backend dependencies... (jeśli potrzeba)
Waiting for Backend to be ready on localhost:3001...
[OK] Backend is ready!
```

### 3. Uruchamianie frontend (React)
```
Starting frontend (React)...
Installing frontend dependencies... (jeśli potrzeba)
Waiting for Frontend to be ready on localhost:5173...
[OK] Frontend is ready!
```

### 5. Gotowe! 🎉
```
All services are running!

Service URLs:
  Frontend:     http://localhost:5173
  Backend:      http://localhost:3001
  Backend Ext:  http://localhost:8081
  Database:     localhost:5432
  LocalStack:   http://localhost:4566

Press Ctrl+C to stop all services
```

## 🛑 Zatrzymywanie usług

- **Windows/macOS/Linux**: Naciśnij `Ctrl+C` w terminalu gdzie uruchomiony jest skrypt
- Wszystkie usługi zostaną automatycznie zatrzymane

## 🔧 Architektura

- **Usługi Docker**: PostgreSQL, LocalStack, Backend Extended (Java) - wszystkie w kontenerach
- **Aplikacje lokalne**: Backend (Node.js), Frontend (React) - uruchamiane natywnie
- **Automatyczne wykrywanie**: Skrypty czekają aż każda usługa będzie gotowa przed przejściem dalej

## 🔍 Rozwiązywanie problemów

### Problem: "Docker Compose is required"
**Rozwiązanie**: Zainstaluj Docker Desktop

### Problem: "Node.js is required"
**Rozwiązanie**: Pobierz z https://nodejs.org/

### Problem: "Failed to download Java 21"
**Rozwiązanie**:
- Sprawdź połączenie internetowe
- Na Windows: upewnij się, że PowerShell ma uprawnienia do pobierania

### Problem: Port już jest zajęty
**Rozwiązanie**:
```bash
# Znajdź proces używający portu
lsof -i :5432  # Linux/macOS
netstat -ano | findstr :5432  # Windows

# Zatrzymaj proces lub zmień port w konfiguracji
```

### Problem: Maven wrapper nie działa
**Rozwiązanie**:
```bash
cd apps/backend_extended
mvn wrapper:wrapper  # Przegeneruj wrapper
```

## 🎯 Dla kogo to jest?

- **Nowi developerzy** - nie musisz znać wszystkich technologii
- **DoS Development** - szybkie uruchamianie środowiska
- **CI/CD** - łatwe testowanie lokalne
- **Demos/Prezentacje** - "jedno-klikowe" uruchamianie

## 📋 Ręczne uruchamianie (alternatywa)

Jeśli wolisz uruchamiać usługi osobno:

```bash
# 1. Baza danych
docker-compose up -d database-postgres localstack

# 2. Backend (nowy terminal)
cd apps/backend && npm run dev

# 3. Backend Extended (nowy terminal)
cd apps/backend_extended && ./mvnw spring-boot:run

# 4. Frontend (nowy terminal)
cd apps/frontend && npm run dev
```

## 🔄 Aktualizacje

Po pobraniu nowych zmian z repo:

```bash
# Wyczyść lokalne narzędzia jeśli są problemy
rm -rf tools/

# Uruchom ponownie
./start-fullstack.sh
```

---

**🎉 Gotowe! Twoje pełne środowisko developerskie uruchamia się jednym poleceniem!**
