# README - Pokédex SwiftUI

### Ce projet est un Pokédex réalisé en SwiftUI, utilisant l’API PokéAPI pour récupérer les informations des Pokémon et proposant plusieurs fonctionnalités et mini-jeux originaux. Il s’agit d’un projet noté dont les objectifs et les compétences visées sont listés ci-dessous.

## 1. Objectifs du TP

- Créer un Pokédex complet en SwiftUI.
- Exploiter l’API PokéAPI (récupération + affichage des Pokémon).
- Mettre en œuvre :
- La navigation en SwiftUI
- La modélisation des données Pokémon
- La recherche et le filtrage dynamique
- Les animations et les interactions avancées
- La persistance avec CoreData (favoris)
- Les notifications push locales (découverte de Pokémon, changement de type favori)
- En bonus, plusieurs mini-jeux ont été ajoutés (Memory, Catch, Flappy, etc.) pour illustrer la notion de “fonctionnalité originale” et approfondir l’aspect ludique.

## 2. Choix Techniques & Architecture

### 2.1. Récupération des données (API PokéAPI)
PokemonAPI.swift :
- Fournit la fonction fetchPokemonList() qui télécharge la liste initiale (jusqu’à 1025 Pokémon).
- Utilise withThrowingTaskGroup pour lancer des requêtes asynchrones en parallèle et récupérer les détails de chaque Pokémon (images, stats, types...).
- Stocke la réponse JSON dans un cache local (NSCache) pour optimiser les prochains accès.
- La fonction fetchPokemonDetails() effectue un appel direct pour un Pokémon précis (mode combat, etc.).
### 2.2. Modélisation des données
PokemonModel.swift :
- Définit la structure codable PokemonModel (id, name, sprites, stats, etc.).
- Possède une propriété detailUrl pour relancer un fetch si l’image est nil.
- Dispose de méthodes d’accès rapides aux stats (attack, defense, speed).
CoreData :
- Une entité PokemonEntity sert à stocker l’ID, le nom, et un booléen isFavorite.
- FavoriteManager gère l’enregistrement et la suppression de favoris.
### 2.3. Navigation & Interface Principale
ContentView.swift :
- Liste des Pokémon avec ScrollView et LazyVStack.
- Recherche, filtrage par type, et tri (nom, attaque, défense, vitesse).
- Switch pour afficher uniquement les favoris ou non.
- Mode sombre activable depuis la barre de navigation.
PokemonDetailView.swift :
- Affiche les détails du Pokémon sélectionné (type, stats, image).
- Permet l’ajout/retrait en favoris (CoreData).
- Inclus un bouton de combat menant à BattleView.
### 2.4. Favoris & CoreData
FavoriteManager.swift :
- Singleton gérant la liste des favoris dans une simple liste favorites: [Int] (IDs).
- Synchronise avec CoreData (entité PokemonEntity) pour conserver isFavorite.
Sauvegarde :
- Toute modification (ajout/suppression) est suivie d’un saveChanges() et d’un fetchFavorites() pour rafraîchir la liste.
### 2.5. Animations & Interactions Avancées
- Effet de zoom sur l’image principale dans la vue détail.
- Transition .spring ou .easeInOut lors de l’ajout/suppression en favoris.
- BattleView : animation de combat Pokémon vs Pokémon (offset, rotation, confettis).
### 2.6. Gestion locale et Notifications
NotificationManager.swift :
- Planifie une notification quotidienne (Pokémon aléatoire)
- Simule une notification si le type d’un favori change.
UserNotifications :
- L’utilisateur accepte ou refuse les notifications au lancement.
- Les notifications s’affichent même si l’app est en arrière-plan.
### 2.7. Mini-Jeux Originaux
MemoryGameView :
- Jeu de mémoire (paires d’images Pokémon + 1 carte bonus “selectedPokemon”).
CatchGameView :
- Tap sur un Pokémon apparaissant aléatoirement à l’écran pendant X secondes.
FlappyPokemonView :
- Variation de Flappy Bird avec le sprite du Pokémon sélectionné.
PokemonManagerView :
- Gestion/upgrade de ressources, achetées via du “gold” et “énergie”.
PokemonVsZombiesVerticalView :
- Inspiré de “Plants vs Zombies” : on place des tours (Pokémon) dans des lanes pour stopper les ennemis.
Ces mini-jeux démontrent l’utilisation de SwiftUI, la gestion d’état via @State et @Binding, et diverses animations (translation, rotation, échelle).

## 3. Améliorations Apportées

- Effet visuel (fond d’arène) dans la BattleView, commenté temporairement pour éviter un bug d’affichage.
- Recherche plus poussée (barre + filtre type + tri multiples stats).
- Corrections pour forcer le chargement des images (si nil, on relance un fetch).
- Barre favoris dans ContentView : mode “showFavoritesOnly”.
- Plusieurs mini-jeux insérés dans la vue détail pour enrichir l’expérience.
## 4. Conclusion

Cette application Pokédex en SwiftUI met en avant :

- L’utilisation d’API asynchrone (PokeAPI).
- L’intégration de CoreData pour gérer les favoris.
- La navigation SwiftUI + fiches détaillées.
- Des animations (zoom, transitions, mini-jeux).
- Des notifications locales quotidiennes et contextuelles.
Le projet illustre ainsi la maîtrise de SwiftUI, la consommation d’API, la persistance et la ludification avec des mini-jeux originaux.
