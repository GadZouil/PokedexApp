//
//  ContentView.swift
//  PokedexApp
//
//  Created by Ethan LEGROS on 2/17/25.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @State private var pokemons: [Pokemon] = []
    @State private var isLoading = true
    
    var body: some View {
        NavigationView {
            List(pokemons) { pokemon in
                HStack {
                    // Affiche l'image du Pokémon
                    AsyncImage(url: URL(string: pokemon.sprites.front_default)) { image in
                        image.resizable()
                            .frame(width: 60, height: 60)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.red, lineWidth: 2))
                    } placeholder: {
                        ProgressView()
                    }
                    Text(pokemon.name.capitalized)
                        .fontWeight(.bold)
                }
            }
            .navigationTitle("Pokédex")
            .onAppear {
                // Récupérer les Pokémon au lancement
                Task {
                    do {
                        pokemons = try await PokemonAPI.shared.fetchPokemonList()
                        isLoading = false
                    } catch {
                        print("Erreur lors du chargement des Pokémon : \(error)")
                        isLoading = false
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
