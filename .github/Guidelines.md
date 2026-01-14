# Commit Message Guidelines

Questo progetto utilizza lo standard **Conventional Commits**.

## Formato
<type>(scope): <description>

## Tipi consentiti
- feat: nuova funzionalità
- fix: bug fix
- refactor: refactoring senza cambiamenti funzionali
- perf: miglioramento delle performance
- docs: documentazione
- test: test
- build: build system / dipendenze
- ci: pipeline CI/CD
- chore: manutenzione

## Esempi
feat(core): add player cache system
fix(db): prevent SQL injection in query builder
refactor(lua): simplify event handler logic
security(auth): harden permission checks

## Breaking Changes
Usa `!` oppure il footer `BREAKING CHANGE:`.

feat(api)!: change authentication flow

- Compatibilità Lua 5.3 obbligatoria
- Niente globali non dichiarate
- Usare `local` ovunque possibile
- Validare sempre input lato server
- Separare logica client/server
- Nessun uso di funzioni deprecate
- Protezione eventi server (`source`, ACL)

- Strict mode abilitato
- No eval / no dynamic require
- Validazione input (OWASP)
- Sanitizzazione output
- Gestione errori centralizzata
- Async/await preferito
- Protezione rate-limit / anti-DDoS

- strict_types=1 obbligatorio
- PDO con prepared statements
- Nessuna query concatenata
- Escape output (XSS)
- CSRF protection
- Password hashing (bcrypt/argon2)
- Config separata dal codice

- OWASP Top 10 compliance
- Least Privilege Principle
- No secrets nel codice
- Logging sicuro (no dati sensibili)
- Aggiornamento dipendenze
