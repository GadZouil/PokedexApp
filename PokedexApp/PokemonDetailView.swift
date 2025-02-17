//
//  PokemonDetailView.swift
//  PokedexApp
//
//  Created by Ethan LEGROS on 2/17/25.
//

import SwiftUI

struct PokemonDetailView: View {
    var pokemon: PokemonModel
    @ObservedObject var favoriteManager = FavoriteManager.shared
    @State private var showAlert = false
    @State private var combatMessage = ""

    var body: some View {
        VStack(spacing: 20) {
            // 🖼️ Image principale
            if let imageUrl = pokemon.sprites.frontDefault, let url = URL(string: imageUrl) {
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
                        placeholderImage()
                    case .empty:
                        ProgressView()
                    @unknown default:
                        ProgressView()
                    }
                }
            } else {
                placeholderImage()
            }

            // 🏷️ Nom et types
            Text(pokemon.formattedName)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.blue)
                .transition(.opacity)

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
                        .transition(.scale)
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
                    .transition(.slide)
                }
            }
            .padding()

            // ⭐ Bouton Favori
            Button(action: {
                toggleFavorite()
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
            .transition(.opacity)

            // 🔔 Simuler un changement de type
            Button(action: {
                NotificationManager.shared.simulateFavoriteTypeChangeNotification(
                    pokemonName: pokemon.name,
                    oldType: "electric",
                    newType: "psychic"
                )
            }) {
                HStack {
                    Image(systemName: "bell.fill")
                    Text("🔔 Simuler Changement de Type")
                }
                .foregroundColor(.white)
                .padding()
                .background(Color.orange)
                .cornerRadius(12)
            }

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

    // 🌟 **Basculer le favori**
    private func toggleFavorite() {
        if let entity = PokemonDataManager.shared.fetchPokemonEntity(by: pokemon.id) {
            withAnimation {
                favoriteManager.toggleFavorite(for: entity)
            }
        } else {
            print("[⚠️ ERREUR] Impossible de trouver l'entité pour le Pokémon ID \(pokemon.id)")
        }
    }

    // ⚔️ **Simuler un combat aléatoire**
    private func simulateCombat(pokemon: PokemonModel) {
        let opponentID = Int.random(in: 1...151)
        let opponentURL = "https://pokeapi.co/api/v2/pokemon/\(opponentID)"

        Task {
            do {
                let opponent = try await PokemonAPI.shared.fetchPokemonDetails(from: opponentURL)
                determineWinner(pokemon1: pokemon, pokemon2: opponent)
            } catch {
                print("[⚠️ ERREUR] Échec de récupération de l'adversaire : \(error)")
            }
        }
    }

    // 🥊 **Déterminer le vainqueur du combat**
    private func determineWinner(pokemon1: PokemonModel, pokemon2: PokemonModel) {
        let statsToCompare = ["attack", "defense", "speed"]

        let score1 = statsToCompare.reduce(0) { score, statName in
            let stat1 = pokemon1.stats.first(where: { $0.stat.name == statName })?.baseStat ?? 0
            let stat2 = pokemon2.stats.first(where: { $0.stat.name == statName })?.baseStat ?? 0
            return score + (stat1 > stat2 ? 1 : 0)
        }

        let score2 = statsToCompare.count - score1
        let winner = score1 > score2 ? pokemon1.name.capitalized : (score2 > score1 ? pokemon2.name.capitalized : "Match nul")

        // 🎯 Affichage détaillé des résultats
        DispatchQueue.main.async {
            let result = """
            ⚔️ Combat ⚔️

            🟦 \(pokemon1.name.capitalized)
            - 🛡️ Attaque : \(pokemon1.getStat("attack"))
            - 🛡️ Défense : \(pokemon1.getStat("defense"))
            - ⚡ Vitesse : \(pokemon1.getStat("speed"))

            🆚

            🟥 \(pokemon2.name.capitalized)
            - 🛡️ Attaque : \(pokemon2.getStat("attack"))
            - 🛡️ Défense : \(pokemon2.getStat("defense"))
            - ⚡ Vitesse : \(pokemon2.getStat("speed"))

            🎯 **Gagnant** : \(winner)
            """
            withAnimation {
                self.combatMessage = result
                self.showAlert = true
            }
        }
    }

    // 🖼️ Image de placeholder en cas d'erreur
    private func placeholderImage() -> some View {
        Image(systemName: "photo")
            .resizable()
            .scaledToFit()
            .frame(width: 200, height: 200)
            .foregroundColor(.gray)
    }
}
