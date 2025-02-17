//
//  PokemonDetailView.swift
//  PokedexApp
//
//  Created by Ethan LEGROS on 2/17/25.
//

import SwiftUI

struct PokemonDetailView: View {
    let pokemon: PokemonModel
    @ObservedObject var favoriteManager = FavoriteManager.shared

    @State private var showAlert = false
    @State private var combatMessage = ""
    
    // Fonction pour retourner une couleur selon le type
    func colorForType(_ type: String) -> Color {
        switch type.lowercased() {
        case "fire":      return .red
        case "water":     return .blue
        case "grass":     return .green
        case "electric":  return .yellow
        case "rock":      return .gray
        case "ground":    return .brown
        case "psychic":   return .purple
        case "bug":       return Color.green.opacity(0.7)
        case "ghost":     return .indigo
        case "dragon":    return .indigo
        case "dark":      return .black
        case "steel":     return .gray
        case "fairy":     return .pink
        case "flying":    return Color.blue.opacity(0.5)
        case "ice":       return .cyan
        case "normal":    return Color.gray.opacity(0.5)
        default:          return .gray
        }
    }

    // Calculer si le Pokémon est favori
    private var isPokemonFavorite: Bool {
        favoriteManager.favorites.contains(pokemon.id)
    }

    var body: some View {
        VStack(spacing: 20) {
            // Image principale
            if let imageUrl = pokemon.sprites.frontDefault,
               let url = URL(string: imageUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable()
                            .scaledToFit()
                            .frame(width: 200, height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .shadow(radius: 10)
                            .scaleEffect(1.2)
                            .animation(.easeInOut(duration: 1), value: pokemon.id)
                    case .failure:
                        placeholderImage
                    case .empty:
                        ProgressView()
                    @unknown default:
                        placeholderImage
                    }
                }
            } else {
                placeholderImage
            }
            
            // Nom et types
            Text(pokemon.formattedName)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.blue)
            
            // Étiquettes de type colorées
            HStack {
                ForEach(pokemon.types, id: \.type.name) { pokeType in
                    Text(pokeType.type.name.capitalized)
                        .padding(10)
                        .background(colorForType(pokeType.type.name).opacity(0.2))
                        .clipShape(Capsule())
                        .overlay(
                            Capsule().stroke(colorForType(pokeType.type.name), lineWidth: 2)
                        )
                }
            }
            
            // Statistiques principales
            VStack(alignment: .leading, spacing: 10) {
                Text("📈 Statistiques :")
                    .font(.headline)
                ForEach(pokemon.stats, id: \.stat.name) { stat in
                    HStack {
                        Text(stat.stat.name.capitalized)
                        Spacer()
                        Text("\(stat.baseStat)")
                    }
                    .padding(.horizontal)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                }
            }
            .padding()
            
            // Bouton Favori
            Button(action: {
                toggleFavorite()
            }) {
                HStack {
                    Image(systemName: isPokemonFavorite ? "star.fill" : "star")
                    Text(isPokemonFavorite ? "Retirer des favoris" : "Ajouter aux favoris")
                }
                .foregroundColor(.white)
                .padding()
                .background(isPokemonFavorite ? Color.red : Color.blue)
                .cornerRadius(12)
            }
            
            // Bouton Combat qui ouvre la vue BattleView
            NavigationLink(destination: BattleView(
                leftPokemon: pokemon,
                initialOpponent: randomOpponent(),
                availableOpponents: sampleOpponents()
            )) {
                HStack {
                    Image(systemName: "bolt.fill")
                    Text("Combattre")
                }
                .foregroundColor(.white)
                .padding()
                .background(Color.purple)
                .cornerRadius(12)
            }
            
            Spacer()
        }
        .padding()
        .background(
            LinearGradient(colors: [.white, .blue.opacity(0.2)],
                           startPoint: .top,
                           endPoint: .bottom)
        )
        .cornerRadius(15)
        .shadow(radius: 5)
        .navigationBarTitleDisplayMode(.inline)
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Résultat du Combat"),
                  message: Text(combatMessage),
                  dismissButton: .default(Text("OK")))
        }
    }
    
    // Bascule le statut favori
    private func toggleFavorite() {
        withAnimation {
            if isPokemonFavorite {
                favoriteManager.removeFromFavorites(pokemon.id)
            } else {
                favoriteManager.addToFavorites(pokemon)
            }
        }
    }
    
    // Retourne un tableau d'adversaires d'exemple
    private func sampleOpponents() -> [PokemonModel] {
        return [
            PokemonModel(
                id: 25,
                name: "Pikachu",
                sprites: PokemonSprites(frontDefault: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/25.png"),
                types: [PokemonType(type: TypeInfo(name: "electric"))],
                stats: [
                    PokemonStat(baseStat: 55, stat: StatInfo(name: "attack")),
                    PokemonStat(baseStat: 40, stat: StatInfo(name: "defense")),
                    PokemonStat(baseStat: 90, stat: StatInfo(name: "speed"))
                ],
                detailUrl: nil
            ),
            PokemonModel(
                id: 4,
                name: "Charmander",
                sprites: PokemonSprites(frontDefault: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/4.png"),
                types: [PokemonType(type: TypeInfo(name: "fire"))],
                stats: [
                    PokemonStat(baseStat: 52, stat: StatInfo(name: "attack")),
                    PokemonStat(baseStat: 43, stat: StatInfo(name: "defense")),
                    PokemonStat(baseStat: 65, stat: StatInfo(name: "speed"))
                ],
                detailUrl: nil
            ),
            PokemonModel(
                id: 7,
                name: "Squirtle",
                sprites: PokemonSprites(frontDefault: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/7.png"),
                types: [PokemonType(type: TypeInfo(name: "water"))],
                stats: [
                    PokemonStat(baseStat: 48, stat: StatInfo(name: "attack")),
                    PokemonStat(baseStat: 65, stat: StatInfo(name: "defense")),
                    PokemonStat(baseStat: 43, stat: StatInfo(name: "speed"))
                ],
                detailUrl: nil
            )
        ]
    }
    
    // Retourne un adversaire random parmi sampleOpponents, différent du Pokémon affiché
    private func randomOpponent() -> PokemonModel {
        let opponents = sampleOpponents().filter { $0.id != pokemon.id }
        return opponents.randomElement() ?? sampleOpponents()[0]
    }
    
    // Vue placeholder pour l'image
    private var placeholderImage: some View {
        Image(systemName: "photo")
            .resizable()
            .scaledToFit()
            .frame(width: 200, height: 200)
            .foregroundColor(.gray)
    }
}

struct PokemonDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let bulbasaurStats: [PokemonStat] = [
            PokemonStat(baseStat: 49, stat: StatInfo(name: "attack")),
            PokemonStat(baseStat: 49, stat: StatInfo(name: "defense")),
            PokemonStat(baseStat: 45, stat: StatInfo(name: "speed"))
        ]
        let bulbasaur = PokemonModel(
            id: 1,
            name: "Bulbasaur",
            sprites: PokemonSprites(frontDefault: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/1.png"),
            types: [PokemonType(type: TypeInfo(name: "grass"))],
            stats: bulbasaurStats,
            detailUrl: nil
        )
        NavigationView {
            PokemonDetailView(pokemon: bulbasaur)
        }
    }
}
