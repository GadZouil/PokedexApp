//
//  FavoriteManager.swift
//  PokedexApp
//
//  Created by Ethan LEGROS on 2/17/25.
//

import Foundation
import CoreData
import SwiftUI

class FavoriteManager: ObservableObject {
    static let shared = FavoriteManager()
    
    private let container: NSPersistentContainer
    @Published var favorites: [FavoritePokemon] = []
    
    private init() {
        container = NSPersistentContainer(name: "PokedexApp")
        container.loadPersistentStores { _, error in
            if let error = error {
                print("Erreur lors du chargement de CoreData : \(error)")
            }
        }
        fetchFavorites()
    }
    
    // Récupérer les favoris
    func fetchFavorites() {
        let request: NSFetchRequest<FavoritePokemon> = FavoritePokemon.fetchRequest()
        do {
            favorites = try container.viewContext.fetch(request)
        } catch {
            print("Erreur lors de la récupération des favoris : \(error)")
        }
    }
    
    // Vérifier si un Pokémon est en favori
    func isFavorite(id: Int) -> Bool {
        favorites.contains { $0.id == id }
    }
    
    // Ajouter un Pokémon en favori
    func addFavorite(pokemon: Pokemon) {
        let newFavorite = FavoritePokemon(context: container.viewContext)
        newFavorite.id = Int64(pokemon.id)
        newFavorite.name = pokemon.name
        newFavorite.imageURL = pokemon.sprites.front_default
        save()
    }
    
    // Supprimer un Pokémon des favoris
    func removeFavorite(id: Int) {
        if let favorite = favorites.first(where: { $0.id == id }) {
            container.viewContext.delete(favorite)
            save()
        }
    }
    
    // Sauvegarder les modifications
    private func save() {
        do {
            try container.viewContext.save()
            fetchFavorites()
        } catch {
            print("Erreur lors de la sauvegarde : \(error)")
        }
    }
}
