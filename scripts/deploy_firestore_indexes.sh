#!/bin/bash

# Script pour déployer les index Firestore
echo "🔥 Déploiement des index Firestore..."

# Vérifier que Firebase CLI est installé
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI n'est pas installé. Installez-le avec:"
    echo "npm install -g firebase-tools"
    exit 1
fi

# Se connecter à Firebase si nécessaire
echo "🔐 Vérification de l'authentification Firebase..."
firebase login --reauth

# Déployer les index
echo "📊 Déploiement des index Firestore..."
firebase deploy --only firestore:indexes --project ilium-4d0ab

echo "✅ Index Firestore déployés avec succès!"
echo ""
echo "📋 Index créés :"
echo "  1. course_status: userId + lastAccessedAt"
echo "  2. course_status: userId + status + lastAccessedAt"
echo ""
echo "⏱️  Les index peuvent prendre quelques minutes à être disponibles."