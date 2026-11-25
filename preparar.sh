#!/usr/bin/env bash
# Gera as pastas nativas, baixa dependências e roda os testes.
set -e
cd "$(dirname "$0")"
flutter create . --project-name cofrinho --org br.edu.cofrinho --platforms=android,ios
flutter pub get
flutter test
echo ""
echo "Pronto! Agora rode: flutter run"
