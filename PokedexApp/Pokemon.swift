//
//  Pokemon.swift
//  PokedexApp
//
//  Created by Ethan LEGROS on 2/17/25.
//

import Foundation

/// Modèle principal pour représenter un Pokémon.
struct Pokemon: Codable, Identifiable, Equatable, Hashable {
    let id: Int
    let name: String
    let sprites: Sprites
    let types: [PokemonType]
    let stats: [PokemonStat]

    /// Nom formaté avec première lettre en majuscule.
    var formattedName: String {
        name.prefix(1).uppercased() + name.dropFirst()
    }

    /// Type principal du Pokémon (le premier type s'il y en a plusieurs).
    var primaryType: String {
        types.first?.type.name ?? "Unknown"
    }

    /// Récupère la statistique d'un Pokémon par son nom (ex : "attack", "speed").
    func getStat(_ statName: String) -> Int {
        return stats.first(where: { $0.stat.name == statName })?.base_stat ?? 0
    }
}

/// Structure pour les images (on récupère uniquement l'image de face).
struct Sprites: Codable, Hashable {
    let front_default: String
}

/// Structure pour les types (ex : Eau, Feu, Plante).
struct PokemonType: Codable, Hashable {
    let type: TypeInfo
}

struct TypeInfo: Codable, Hashable {
    let name: String
}

/// Structure pour les statistiques (attaque, défense, etc.).
struct PokemonStat: Codable, Hashable {
    let base_stat: Int
    let stat: StatInfo
}

struct StatInfo: Codable, Hashable {
    let name: String
}
