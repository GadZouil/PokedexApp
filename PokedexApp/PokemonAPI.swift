//
//  PokemonAPI.swift
//  PokedexApp
//
//  Created by Ethan LEGROS on ...
//

import Foundation

struct PokemonListResponse: Codable {
    let results: [PokemonResult]
}

struct PokemonResult: Codable {
    let name: String
    let url: String
}

class PokemonAPI {
    static let shared = PokemonAPI()
    
    private let cache = NSCache<NSString, NSData>()

    /// Récupère la liste COMPLETE des Pokémon avec toutes leurs stats et sprites.
    func fetchPokemonList(limit: Int = 151) async throws -> [PokemonModel] {
        let urlString = "https://pokeapi.co/api/v2/pokemon?limit=\(limit)"
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }

        print("[🌐 INFO] Récupération de \(limit) Pokémon depuis l'API.")

        let (data, _) = try await URLSession.shared.data(from: url)
        let decodedResponse = try JSONDecoder().decode(PokemonListResponse.self, from: data)

        var pokemonList: [PokemonModel] = []

        try await withThrowingTaskGroup(of: PokemonModel?.self) { group in
            for result in decodedResponse.results {
                group.addTask {
                    do {
                        var pokemon = try await self.fetchPokemonDetails(from: result.url)
                        // Ici, on affecte l'URL de détail, afin de pouvoir relancer un fetch si besoin
                        pokemon.detailUrl = result.url
                        return pokemon
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

        print("[✅ SUCCESS] Chargement de \(pokemonList.count) Pokémon terminé.")
        return pokemonList
    }


    /// Récupère les détails COMPLETS d’un Pokémon (sprites, stats...) avec cache.
    func fetchPokemonDetails(from urlString: String) async throws -> PokemonModel {
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        let cacheKey = urlString as NSString

        // Vérifie le cache d'abord
        if let cachedData = cache.object(forKey: cacheKey) {
            // Décodage direct depuis le cache
            return try JSONDecoder().decode(PokemonModel.self, from: cachedData as Data)
        }

        // Téléchargement si pas en cache
        let (data, _) = try await URLSession.shared.data(from: url)
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let pokemon = try decoder.decode(PokemonModel.self, from: data)

        // Mise en cache
        cache.setObject(data as NSData, forKey: cacheKey)
        
        return pokemon
    }
}
