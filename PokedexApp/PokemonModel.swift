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

    /// Propriété locale pour la gestion du favori (non issue de l'API).
    var isFavorite: Bool = false

    /// URL des détails pour recharger les images si nécessaire.
    var detailUrl: String?

    /// Nom formaté (1ère lettre majuscule).
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
    var specialAttack: Int { getStat("special-attack") }
    var specialDefense: Int { getStat("special-defense") }
    var speed: Int { getStat("speed") }

    /// Recherche la stat par nom ("attack", "defense", "speed", "hp").
    func getStat(_ statName: String) -> Int {
        stats.first { $0.stat.name == statName }?.baseStat ?? 0
    }

    /// Override du init pour gérer l'URL et ignorer la clé "isFavorite" dans le JSON.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        sprites = try container.decode(PokemonSprites.self, forKey: .sprites)
        types = try container.decode([PokemonType].self, forKey: .types)
        stats = try container.decode([PokemonStat].self, forKey: .stats)
        detailUrl = nil
        isFavorite = false
    }

    /// Initialiseur manuel pour assigner directement une URL.
    init(id: Int, name: String, sprites: PokemonSprites, types: [PokemonType], stats: [PokemonStat], detailUrl: String?) {
        self.id = id
        self.name = name
        self.sprites = sprites
        self.types = types
        self.stats = stats
        self.detailUrl = detailUrl
    }
}

/// Sprites du Pokémon (images)
struct PokemonSprites: Codable, Hashable {
    let frontDefault: String?

    enum CodingKeys: String, CodingKey {
        case frontDefault = "front_default"
    }
}

/// Représentation d'un type
struct PokemonType: Codable, Hashable {
    let type: TypeInfo
}

/// Informations sur le type (ex: "grass", "fire"...)
struct TypeInfo: Codable, Hashable {
    let name: String
}

/// Statistiques (attaque, défense, vitesse...)
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

/// Nom de la statistique
struct StatInfo: Codable, Hashable {
    let name: String
}
