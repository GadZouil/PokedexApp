//
//  Pokemon.swift
//  PokedexApp
//
//  Created by Ethan LEGROS on 2/17/25.
//

import Foundation

// Modèle principal pour représenter un Pokémon
struct Pokemon: Codable, Identifiable {
    var id: Int
    var name: String
    var sprites: Sprites
    var types: [PokemonType]
    var stats: [PokemonStat]
}

// Structure pour les images (on récupère uniquement l'image de face)
struct Sprites: Codable {
    var front_default: String
}

// Structure pour les types (ex : Eau, Feu, Plante)
struct PokemonType: Codable {
    var type: TypeInfo
}

struct TypeInfo: Codable {
    var name: String
}

// Structure pour les statistiques (attaque, défense, etc.)
struct PokemonStat: Codable {
    var base_stat: Int
    var stat: StatInfo
}

struct StatInfo: Codable {
    var name: String
}
