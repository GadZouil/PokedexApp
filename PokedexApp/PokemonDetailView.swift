//
//  PokemonDetailView.swift
//  PokedexApp
//
//  Created by Ethan LEGROS on 2/17/25.
//

import SwiftUI

struct PokemonDetailView: View {
    var pokemon: Pokemon
    @ObservedObject var favoriteManager = FavoriteManager.shared
    @State private var showAlert = false
    @State private var combatMessage = ""

    var body: some View {
        VStack(spacing: 20) {
            // Image principale
            AsyncImage(url: URL(string: pokemon.sprites.front_default)) { image in
                image.resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(radius: 10)
                    .scaleEffect(1.2)
                    .animation(.easeInOut(duration: 1), value: pokemon.id)
            } placeholder: {
                ProgressView()
            }
            
            // Nom et types
            Text(pokemon.name.capitalized)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.blue)
                .transition(.opacity)
            
            // Afficher les types
            HStack {
                ForEach(pokemon.types, id: \.type.name) { pokeType in
                    Text(pokeType.type.name.capitalized)
                        .padding(10)
                        .background(Color.green.opacity(0.2))
                        .clipShape(Capsule())
                        .transition(.scale)
                }
            }
            
            // Statistiques principales
            VStack(alignment: .leading, spacing: 10) {
                Text("Statistiques :")
                    .font(.headline)
                ForEach(pokemon.stats, id: \.stat.name) { stat in
                    HStack {
                        Text(stat.stat.name.capitalized)
                        Spacer()
                        Text("\(stat.base_stat)")
                    }
                    .padding(.horizontal)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                    .transition(.slide)
                }
            }
            .padding()
            
            // Bouton Favori
            Button(action: {
                withAnimation {
                    if favoriteManager.isFavorite(id: pokemon.id) {
                        favoriteManager.removeFavorite(id: pokemon.id)
                    } else {
                        favoriteManager.addFavorite(pokemon: pokemon)
                    }
                }
            }) {
                HStack {
                    Image(systemName: favoriteManager.isFavorite(id: pokemon.id) ? "star.fill" : "star")
                    Text(favoriteManager.isFavorite(id: pokemon.id) ? "Retirer des favoris" : "Ajouter aux favoris")
                }
                .foregroundColor(.white)
                .padding()
                .background(favoriteManager.isFavorite(id: pokemon.id) ? Color.red : Color.blue)
                .cornerRadius(12)
            }
            .transition(.scale)

            // Bouton Combat
            Button(action: {
                simulateCombat(pokemon: pokemon)
            }) {
                HStack {
                    Image(systemName: "bolt.fill")
                    Text("Combattre un Pokémon aléatoire")
                }
                .foregroundColor(.white)
                .padding()
                .background(Color.purple)
                .cornerRadius(12)
            }
            .transition(.opacity)
            
            Spacer()
        }
        .padding()
        .background(LinearGradient(colors: [.white, .blue.opacity(0.2)], startPoint: .top, endPoint: .bottom))
        .cornerRadius(15)
        .shadow(radius: 5)
        .navigationBarTitleDisplayMode(.inline)
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Résultat du Combat"), message: Text(combatMessage), dismissButton: .default(Text("OK")))
        }
    }

    // Simuler un combat aléatoire
    func simulateCombat(pokemon: Pokemon) {
        let opponentID = Int.random(in: 1...151)
        let opponentURL = "https://pokeapi.co/api/v2/pokemon/\(opponentID)"
        
        Task {
            do {
                let opponent = try await PokemonAPI.shared.fetchPokemonDetails(from: opponentURL)
                determineWinner(pokemon1: pokemon, pokemon2: opponent)
            } catch {
                print("Erreur lors de la récupération de l'adversaire : \(error)")
            }
        }
    }

    // Comparer les stats et afficher le gagnant
    func determineWinner(pokemon1: Pokemon, pokemon2: Pokemon) {
        let statsToCompare = ["attack", "defense", "speed"]
        
        let score1 = statsToCompare.reduce(0) { score, statName in
            let stat1 = pokemon1.stats.first(where: { $0.stat.name == statName })?.base_stat ?? 0
            let stat2 = pokemon2.stats.first(where: { $0.stat.name == statName })?.base_stat ?? 0
            return score + (stat1 > stat2 ? 1 : 0)
        }

        let score2 = 3 - score1
        
        let winner = score1 > score2 ? pokemon1.name.capitalized : (score2 > score1 ? pokemon2.name.capitalized : "Match nul")
        
        // Affichage détaillé des statistiques dans l'alerte
        DispatchQueue.main.async {
            let result = """
            ⚔️ Combat ⚔️

            🔵 \(pokemon1.name.capitalized)
            - Attaque : \(pokemon1.stats.first(where: { $0.stat.name == "attack" })?.base_stat ?? 0)
            - Défense : \(pokemon1.stats.first(where: { $0.stat.name == "defense" })?.base_stat ?? 0)
            - Vitesse : \(pokemon1.stats.first(where: { $0.stat.name == "speed" })?.base_stat ?? 0)

            🆚

            🔴 \(pokemon2.name.capitalized)
            - Attaque : \(pokemon2.stats.first(where: { $0.stat.name == "attack" })?.base_stat ?? 0)
            - Défense : \(pokemon2.stats.first(where: { $0.stat.name == "defense" })?.base_stat ?? 0)
            - Vitesse : \(pokemon2.stats.first(where: { $0.stat.name == "speed" })?.base_stat ?? 0)

            🎯 Gagnant : \(winner)
            """
            withAnimation {
                self.combatMessage = result
                self.showAlert = true
            }
        }
    }
}
