#!/bin/bash

echo "🔥 Déploiement des règles Firestore..."

# Vérifier si Firebase CLI est installé
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI n'est pas installé"
    echo "💡 Installez-le avec: npm install -g firebase-tools"
    exit 1
fi

# Vérifier la connexion Firebase
echo "🔍 Vérification de l'authentification Firebase..."
if ! firebase projects:list &> /dev/null; then
    echo "❌ Vous n'êtes pas connecté à Firebase"
    echo "💡 Connectez-vous avec: firebase login"
    exit 1
fi

# Déployer les règles
echo "📤 Déploiement des règles Firestore vers le projet ilium-4d0ab..."
firebase deploy --only firestore:rules --project ilium-4d0ab

if [ $? -eq 0 ]; then
    echo "✅ Règles Firestore déployées avec succès!"
    echo "🎉 Les utilisateurs peuvent maintenant accéder à leurs données"
else
    echo "❌ Erreur lors du déploiement des règles"
    echo "💡 Vérifiez votre projet Firebase et vos permissions"
    exit 1
fi