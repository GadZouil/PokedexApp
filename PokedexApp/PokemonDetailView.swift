//
//  PokemonDetailView.swift
//  PokedexApp
//
//  Created by Ethan LEGROS on 2/17/25.
//

import SwiftUI

struct PokemonDetailView: View {
    let pokemon: PokemonModel                 // Utilisé en "let" pour afficher ses infos de base
    @ObservedObject var favoriteManager = FavoriteManager.shared

    @State private var showAlert = false
    @State private var combatMessage = ""

    // Calculer si le Pokémon est favori en se basant sur favoriteManager.favorites
    private var isPokemonFavorite: Bool {
        favoriteManager.favorites.contains(pokemon.id)
    }

    var body: some View {
        VStack(spacing: 20) {
            // 🖼️ Image principale
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

            // 🏷️ Nom et types
            Text(pokemon.formattedName)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.blue)

            // 🌀 Types
            HStack {
                ForEach(pokemon.types, id: \.type.name) { pokeType in
                    Text(pokeType.type.name.capitalized)
                        .padding(10)
                        .background(Color.green.opacity(0.2))
                        .clipShape(Capsule())
                        .overlay(
                            Capsule().stroke(Color.green, lineWidth: 2)
                        )
                }
            }

            // 📊 Statistiques principales
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

            // ⭐ Bouton Favori
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

            // ⚔️ Bouton Combat
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

    // ⚙️ Basculer l'état favori du Pokémon
    private func toggleFavorite() {
        withAnimation {
            if isPokemonFavorite {
                favoriteManager.removeFromFavorites(pokemon.id)
            } else {
                favoriteManager.addToFavorites(pokemon)
            }
        }
    }

    // 🥊 Simuler un combat
    private func simulateCombat(pokemon: PokemonModel) {
        let opponentID = Int.random(in: 1...151)
        let opponentURL = "https://pokeapi.co/api/v2/pokemon/\(opponentID)"

        Task {
            do {
                // On veut un détail complet !
                let opponent = try await PokemonAPI.shared.fetchPokemonDetails(from: opponentURL)
                determineWinner(pokemon1: pokemon, pokemon2: opponent)
            } catch {
                print("[⚠️ ERREUR] Échec de récupération de l'adversaire : \(error)")
            }
        }
    }


    // 🏆 Déterminer le vainqueur du combat
    private func determineWinner(pokemon1: PokemonModel, pokemon2: PokemonModel) {
        let statsToCompare = ["attack", "defense", "speed"]

        let score1 = statsToCompare.reduce(0) { partialResult, statName in
            partialResult + (pokemon1.getStat(statName) > pokemon2.getStat(statName) ? 1 : 0)
        }
        let score2 = statsToCompare.count - score1

        let winner: String
        if score1 > score2 { winner = pokemon1.name.capitalized }
        else if score2 > score1 { winner = pokemon2.name.capitalized }
        else { winner = "Match nul" }

        // 🛠️ Afficher les stats
        combatMessage = """
        ⚔️ Combat ⚔️

        🟦 \(pokemon1.name.capitalized)
        - Attaque : \(pokemon1.attack)
        - Défense : \(pokemon1.defense)
        - Vitesse : \(pokemon1.speed)

        🆚

        🟥 \(pokemon2.name.capitalized)
        - Attaque : \(pokemon2.attack)
        - Défense : \(pokemon2.defense)
        - Vitesse : \(pokemon2.speed)

        🎯 Gagnant : \(winner)
        """
        showAlert = true
    }


    // 🏞️ Image placeholder
    private var placeholderImage: some View {
        Image(systemName: "photo")
            .resizable()
            .scaledToFit()
            .frame(width: 200, height: 200)
            .foregroundColor(.gray)
    }
}
