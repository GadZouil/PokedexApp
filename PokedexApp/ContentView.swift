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
    @State private var searchText = ""
    @State private var selectedType: String = "Tous"
    @State private var selectedSortOption = "Nom"
    @ObservedObject var favoriteManager = FavoriteManager.shared
    
    let sortOptions = ["Nom", "Attaque"]
    let types = [
        "Tous", "fire", "water", "grass", "electric", "rock", "ground", "flying",
        "psychic", "bug", "ghost", "dragon", "dark", "steel", "fairy", "normal",
        "poison", "fighting", "ice"
    ]

    var body: some View {
        NavigationView {
            VStack {
                // Filtres et Recherche
                VStack(alignment: .leading, spacing: 10) {
                    Text("🔍 Recherche et Filtres")
                        .font(.headline)
                        .padding(.horizontal)

                    // Barre de recherche
                    TextField("Rechercher un Pokémon...", text: $searchText)
                        .padding(10)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .padding(.horizontal)

                    // Filtre par type
                    HStack {
                        Text("Type :")
                        Picker("Type", selection: $selectedType) {
                            ForEach(types, id: \.self) { type in
                                Text(type)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                    .padding(.horizontal)

                    // Tri par nom ou attaque
                    Picker("Trier par", selection: $selectedSortOption) {
                        ForEach(sortOptions, id: \.self) { option in
                            Text(option)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                }
                .padding(.bottom, 10)

                // Liste filtrée et triée
                let filteredPokemons = pokemons.filter { pokemon in
                    // Filtrage par nom
                    let matchesName = searchText.isEmpty || pokemon.name.localizedCaseInsensitiveContains(searchText)
                    
                    // Filtrage par type (correction en lowercase)
                    let matchesType = selectedType == "Tous" || pokemon.types.contains { $0.type.name.lowercased() == selectedType.lowercased() }
                    
                    return matchesName && matchesType
                }
                .sorted {
                    if selectedSortOption == "Nom" {
                        return $0.name < $1.name
                    } else {
                        let statA = $0.stats.first(where: { $0.stat.name == "attack" })?.base_stat ?? 0
                        let statB = $1.stats.first(where: { $0.stat.name == "attack" })?.base_stat ?? 0
                        return statA > statB
                    }
                }


                List(filteredPokemons) { pokemon in
                    NavigationLink(destination: PokemonDetailView(pokemon: pokemon)) {
                        HStack {
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

                            Spacer()

                            if favoriteManager.isFavorite(id: pokemon.id) {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                            }
                        }
                    }
                }
                .navigationTitle("Pokédex")
                .onAppear {
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
}

#Preview {
    ContentView()
}
