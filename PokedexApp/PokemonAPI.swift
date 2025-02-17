//
//  PokemonAPI.swift
//  PokedexApp
//
//  Created by Ethan LEGROS on 2/17/25.
//

import Foundation

/// Gestionnaire de communication avec l'API Pokémon.
class PokemonAPI {
    // Singleton
    static let shared = PokemonAPI()

    // Cache pour optimiser les appels réseau
    private let cache = NSCache<NSString, NSData>()

    /// Récupérer la liste complète des Pokémon avec un nombre configurable.
    func fetchPokemonList(limit: Int = 151) async throws -> [PokemonModel] {
        let urlString = "https://pokeapi.co/api/v2/pokemon?limit=\(limit)"
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }

        #if DEBUG
        print("[🌐 INFO] Récupération de \(limit) Pokémon depuis l'API.")
        #endif

        // Effectuer la requête principale
        let (data, _) = try await URLSession.shared.data(from: url)

        // Afficher le contenu brut pour diagnostic
        #if DEBUG
        if let jsonString = String(data: data, encoding: .utf8) {
            print("[🛠️ DEBUG] JSON reçu : \(jsonString.prefix(500))...")
        }
        #endif

        // Décoder les résultats
        let decodedResponse = try JSONDecoder().decode(PokemonListResponse.self, from: data)

        // Télécharger les détails de chaque Pokémon en parallèle
        var pokemonList: [PokemonModel] = []

        try await withThrowingTaskGroup(of: PokemonModel?.self) { group in
            for result in decodedResponse.results {
                group.addTask {
                    do {
                        return try await self.fetchPokemonDetails(from: result.url)
                    } catch {
                        print("[⚠️ ERREUR] Échec de chargement des détails pour \(result.name) : \(error)")
                        return nil
                    }
                }
            }

            for try await pokemon in group {
                if let pokemon = pokemon {
                    pokemonList.append(pokemon)
                }
            }
        }

        #if DEBUG
        print("[✅ SUCCESS] Chargement de \(pokemonList.count) Pokémon terminé.")
        #endif

        return pokemonList
    }

    /// Récupérer les détails d'un Pokémon avec gestion de cache.
    func fetchPokemonDetails(from url: String) async throws -> PokemonModel {
        guard let url = URL(string: url) else { throw URLError(.badURL) }

        let cacheKey = url.absoluteString as NSString

        // Vérification du cache
        if let cachedData = cache.object(forKey: cacheKey) {
            #if DEBUG
            print("[🛠️ CACHE] Chargé depuis le cache : \(url)")
            #endif
            let pokemon = try JSONDecoder().decode(PokemonModel.self, from: cachedData as Data)
            return pokemon
        }

        // Requête HTTP si non en cache
        let (data, _) = try await URLSession.shared.data(from: url)

        // Afficher le contenu brut pour diagnostic
        #if DEBUG
        if let jsonString = String(data: data, encoding: .utf8) {
            print("[🛠️ DEBUG] JSON détails reçu : \(jsonString.prefix(500))...")
        }
        #endif

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let pokemon = try decoder.decode(PokemonModel.self, from: data)

        // Mise en cache
        cache.setObject(data as NSData, forKey: cacheKey)

        return pokemon
    }
}

// Structure pour la réponse de la liste
struct PokemonListResponse: Codable {
    let results: [PokemonResult]
}

// Structure simplifiée pour la liste initiale
struct PokemonResult: Codable {
    let name: String
    let url: String
}
