//
//  PokemonDataManager.swift
//  PokedexApp
//
//  Created by Ethan LEGROS on 2/17/25.
//

import Foundation
import CoreData

/// Gestionnaire de persistance pour les Pokémon avec Core Data.
class PokemonDataManager {
    // Singleton global
    static let shared = PokemonDataManager()

    // Persistent container pour Core Data
    let persistentContainer: NSPersistentContainer

    // Contexte principal
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }

    // Initialisation et chargement du store
    private init() {
        persistentContainer = NSPersistentContainer(name: "PokedexApp")
        persistentContainer.loadPersistentStores { _, error in
            if let error = error {
                fatalError("[❌ ERREUR] Échec du chargement de Core Data : \(error.localizedDescription)")
            } else {
                #if DEBUG
                print("[✅ SUCCESS] Core Data chargé avec succès.")
                #endif
            }
        }
    }

    // 💾 Sauvegarder un Pokémon dans Core Data
    func savePokemon(_ pokemon: PokemonModel) {
        let request: NSFetchRequest<PokemonEntity> = PokemonEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %d", pokemon.id)

        // Vérifier si le Pokémon existe déjà
        do {
            let results = try context.fetch(request)
            if results.isEmpty {
                let newPokemon = PokemonEntity(context: context)
                newPokemon.id = Int64(pokemon.id)
                newPokemon.name = pokemon.name
                newPokemon.imageURL = pokemon.sprites.frontDefault
                newPokemon.primaryType = pokemon.primaryType
                newPokemon.hp = Int64(pokemon.hp)
                newPokemon.attack = Int64(pokemon.attack)
                newPokemon.defense = Int64(pokemon.defense)
                newPokemon.speed = Int64(pokemon.speed)

                saveContext()
                #if DEBUG
                print("[⭐ AJOUTÉ] Pokémon \(pokemon.name) enregistré dans Core Data.")
                #endif
            } else {
                #if DEBUG
                print("[ℹ️ INFO] Pokémon \(pokemon.name) déjà existant.")
                #endif
            }
        } catch {
            print("[⚠️ ERREUR] Échec de la vérification/sauvegarde de \(pokemon.name) : \(error)")
        }
    }

    // 📦 Récupérer tous les Pokémon
    func fetchAllPokemons() -> [PokemonEntity] {
        let request: NSFetchRequest<PokemonEntity> = PokemonEntity.fetchRequest()
        do {
            return try context.fetch(request)
        } catch {
            print("[⚠️ ERREUR] Échec de récupération des Pokémon : \(error.localizedDescription)")
            return []
        }
    }

    // 🚮 Supprimer un Pokémon
    func deletePokemon(_ pokemon: PokemonEntity) {
        context.delete(pokemon)
        saveContext()
    }

    // 💾 Enregistrer les modifications
    func saveContext() {
        if context.hasChanges {
            do {
                try context.save()
                #if DEBUG
                print("[✅ SUCCESS] Modifications Core Data enregistrées.")
                #endif
            } catch {
                print("[⚠️ ERREUR] Échec de la sauvegarde de Core Data : \(error.localizedDescription)")
            }
        }
    }
}
