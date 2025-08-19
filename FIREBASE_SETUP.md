# 🔥 Configuration Firebase pour Ilium

## Problème d'inscription Firebase

Si vous rencontrez une erreur lors de l'inscription, c'est probablement parce que l'authentification email/password n'est pas activée dans Firebase Console.

## ✅ Solution rapide

1. **Ouvrez Firebase Console :**
   - Allez sur https://console.firebase.google.com
   - Sélectionnez le projet `ilium-4d0ab`

2. **Activez l'authentification Email/Password :**
   - Dans le menu de gauche, cliquez sur **Authentication**
   - Allez dans l'onglet **Sign-in method**
   - Trouvez **Email/Password** dans la liste
   - Cliquez sur **Email/Password**
   - Activez l'option **Enable**
   - Cliquez sur **Save**

3. **Vérifiez la configuration :**
   - L'option **Email/Password** doit maintenant être **Enabled**
   - Vous pouvez tester l'inscription dans l'app

## 🔍 Test dans l'app

En mode debug, un bouton **🔍 Tester Firebase** apparaît sur l'écran d'inscription pour diagnostiquer les problèmes.

## 📋 Informations du projet

- **Project ID :** ilium-4d0ab
- **Auth Domain :** ilium-4d0ab.firebaseapp.com
- **Lien direct :** https://console.firebase.google.com/project/ilium-4d0ab/authentication/providers

## 🚨 Erreurs communes

### `operation-not-allowed`
**Cause :** L'authentification email/password n'est pas activée  
**Solution :** Suivez les étapes ci-dessus

### `network-request-failed`
**Cause :** Problème de connexion ou configuration Firebase incorrecte  
**Solution :** Vérifiez votre connexion internet et la configuration Firebase

### `invalid-email`
**Cause :** Format d'email invalide  
**Solution :** Vérifiez le format de l'email

### `weak-password`
**Cause :** Mot de passe trop faible (moins de 6 caractères)  
**Solution :** Utilisez un mot de passe d'au moins 6 caractères

## 📞 Support

Si le problème persiste après avoir activé l'authentification, vérifiez :
1. Que vous êtes connecté à internet
2. Que la configuration Firebase dans `firebase_options.dart` est correcte
3. Que le projet Firebase existe et est accessible