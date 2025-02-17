//
//  PokemonAPI.swift
//  PokedexApp
//
//  Created by Ethan LEGROS on 2/17/25.
//

import Foundation

class PokemonAPI {
    // Singleton pour accéder au service facilement
    static let shared = PokemonAPI()

    // URL de base pour récupérer les 151 premiers Pokémon
    // URL de base pour récupérer les 151 premiers Pokémon
    private let baseURL = "https://pokeapi.co/api/v2/pokemon?limit=151"

    // Récupérer la liste des Pokémon
    func fetchPokemonList() async throws -> [Pokemon] {
        guard let url = URL(string: baseURL) else {
            throw URLError(.badURL)
        }

        // Effectuer la requête
        let (data, _) = try await URLSession.shared.data(from: url)
        
        // Décoder les résultats
        let decodedResponse = try JSONDecoder().decode(PokemonListResponse.self, from: data)
        
        var pokemonList: [Pokemon] = []
        
        // Récupérer les détails de chaque Pokémon
        for result in decodedResponse.results {
            let pokemon = try await fetchPokemonDetails(from: result.url)
            pokemonList.append(pokemon)
        }
        
        return pokemonList
    }

    // Récupérer les détails d'un Pokémon spécifique
    func fetchPokemonDetails(from url: String) async throws -> Pokemon {
        guard let url = URL(string: url) else { throw URLError(.badURL) }
        let (data, _) = try await URLSession.shared.data(from: url)
        let pokemon = try JSONDecoder().decode(Pokemon.self, from: data)
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
