//
//  PokemonModel.swift
//  PokedexApp
//
//  Created by Ethan LEGROS on 2/17/25.
//

import Foundation

/// Modèle principal pour représenter un Pokémon.
struct PokemonModel: Codable, Identifiable, Equatable, Hashable {
    let id: Int
    let name: String
    let sprites: PokemonSprites
    let types: [PokemonType]
    let stats: [PokemonStat]

    /// Nom formaté avec majuscule.
    var formattedName: String {
        name.capitalized
    }

    /// Type principal.
    var primaryType: String {
        types.first?.type.name ?? "Unknown"
    }

    /// Accès direct aux statistiques principales.
    var hp: Int { getStat("hp") }
    var attack: Int { getStat("attack") }
    var defense: Int { getStat("defense") }
    var speed: Int { getStat("speed") }

    /// Récupérer une statistique par son nom.
    func getStat(_ statName: String) -> Int {
        stats.first { $0.stat.name == statName }?.baseStat ?? 0
    }
}

// 🖼️ Images (sprites) - on ne prend que l'image principale
struct PokemonSprites: Codable, Hashable {
    let frontDefault: String?
    
    enum CodingKeys: String, CodingKey {
        case frontDefault = "front_default"
    }
}

// 🛠️ Type d’un Pokémon
struct PokemonType: Codable, Hashable {
    let type: TypeInfo
}

// 🔍 Informations de type
struct TypeInfo: Codable, Hashable {
    let name: String
}

// 📊 Statistiques d’un Pokémon
struct PokemonStat: Codable, Hashable {
    let baseStat: Int
    let stat: StatInfo

    enum CodingKeys: String, CodingKey {
        case baseStat = "base_stat"
        case stat
    }

    // Décodage sécurisé
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        baseStat = try container.decodeIfPresent(Int.self, forKey: .baseStat) ?? 0
        stat = try container.decode(StatInfo.self, forKey: .stat)
    }
}

// 🔍 Informations de statistiques
struct StatInfo: Codable, Hashable {
    let name: String
}
