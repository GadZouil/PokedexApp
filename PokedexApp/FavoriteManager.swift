//
//  FavoriteManager.swift
//  PokedexApp
//
//  Created by Ethan LEGROS on 2/17/25.
//

import Foundation
import CoreData

extension PokemonDataManager {
    func fetchPokemonEntity(by id: Int) -> PokemonEntity? {
        let request: NSFetchRequest<PokemonEntity> = PokemonEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %d", id)
        do {
            return try persistentContainer.viewContext.fetch(request).first
        } catch {
            print("[⚠️ ERREUR] Impossible de récupérer l'entité Pokémon : \(error)")
            return nil
        }
    }
}

/// Gestionnaire des Pokémon favoris basé directement sur `PokemonEntity`.
class FavoriteManager: ObservableObject {
    static let shared = FavoriteManager()
    private let container: NSPersistentContainer
    @Published var favorites: [PokemonEntity] = []

    private init() {
        container = NSPersistentContainer(name: "PokedexApp")
        container.loadPersistentStores { _, error in
            if let error = error {
                print("[❌ ERREUR] Core Data : \(error)")
            }
        }
        fetchFavorites()
    }

    // 🛠️ Récupérer les favoris
    func fetchFavorites() {
        let request: NSFetchRequest<PokemonEntity> = PokemonEntity.fetchRequest()
        request.predicate = NSPredicate(format: "isFavorite == true")
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]

        do {
            favorites = try container.viewContext.fetch(request)
            print("[✅ SUCCESS] \(favorites.count) favoris chargés.")
        } catch {
            print("[⚠️ ERREUR] Récupération favoris : \(error.localizedDescription)")
        }
    }

    // 🔍 Vérifier si un Pokémon est en favori
    func isFavorite(id: Int) -> Bool {
        favorites.contains { Int($0.id) == id }
    }

    // ➕ Basculer l'état favori
    func toggleFavorite(for pokemon: PokemonEntity) {
        pokemon.isFavorite.toggle()
        saveChanges()
    }

    // 💾 Sauvegarder les changements
    private func saveChanges() {
        do {
            try container.viewContext.save()
            fetchFavorites()
        } catch {
            print("[⚠️ ERREUR] Échec de la sauvegarde : \(error)")
        }
    }
}
