//
//  FavoriteManager.swift
//  PokedexApp
//
//  Created by Ethan LEGROS on 2/17/25.
//

import Foundation
import CoreData

class FavoriteManager: ObservableObject {
    static let shared = FavoriteManager()
    private let container: NSPersistentContainer

    @Published var favorites: [Int] = []

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

        do {
            let results = try container.viewContext.fetch(request)
            favorites = results.map { Int($0.id) }
            print("[✅ SUCCESS] \(favorites.count) favoris chargés.")
        } catch {
            print("[⚠️ ERREUR] Récupération favoris : \(error.localizedDescription)")
        }
    }

    // ➕ Ajouter un Pokémon en favori
    func addToFavorites(_ pokemon: PokemonModel) {
        DispatchQueue.main.async {
            let request: NSFetchRequest<PokemonEntity> = PokemonEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %d", pokemon.id)
            
            do {
                let results = try self.container.viewContext.fetch(request)
                if let existing = results.first {
                    // Déjà en base. On ne fait que mettre isFavorite = true
                    existing.isFavorite = true
                    existing.name = pokemon.name
                    existing.imageURL = pokemon.sprites.frontDefault ?? ""
                    // etc. Màj possible
                } else {
                    // On crée l'entité
                    let entity = PokemonEntity(context: self.container.viewContext)
                    entity.id = Int64(pokemon.id)
                    entity.name = pokemon.name
                    entity.isFavorite = true
                    entity.imageURL = pokemon.sprites.frontDefault ?? ""
                }
                self.saveChanges()
            } catch {
                print("[⚠️ ERREUR] addToFavorites : \(error)")
            }
        }
    }


    // ➖ Supprimer un Pokémon des favoris
    func removeFromFavorites(_ id: Int) {
        print("[DBG] removeFromFavorites(\(id))")
        DispatchQueue.main.async {
            let request: NSFetchRequest<PokemonEntity> = PokemonEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %d", id)
            do {
                let results = try self.container.viewContext.fetch(request)
                print("[DBG] Nombre entités fetch : \(results.count)")
                if let entity = results.first {
                    entity.isFavorite = false
                    self.saveChanges()
                    print("[DBG] Favori supprimé pour \(entity.name ?? "??")")
                } else {
                    print("[DBG] Aucune entité pour ID \(id)")
                }
            } catch {
                print("[⚠️ ERREUR] Supprimer favori ID \(id) : \(error)")
            }
        }
    }

    func resetFavorites() {
        let request: NSFetchRequest<PokemonEntity> = PokemonEntity.fetchRequest()
        request.predicate = NSPredicate(format: "isFavorite == true")
        
        do {
            let results = try container.viewContext.fetch(request)
            for entity in results {
                entity.isFavorite = false
            }
            saveChanges()
            print("[✅ SUCCESS] Tous les favoris ont été réinitialisés.")
        } catch {
            print("[⚠️ ERREUR] Réinitialisation des favoris : \(error)")
        }
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
