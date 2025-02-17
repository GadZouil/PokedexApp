//
//  ContentView.swift
//  PokedexApp
//
//  Created by Ethan LEGROS on 2/17/25.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @State private var pokemons: [PokemonModel] = []
    @State private var isLoading = true
    @State private var searchText = ""
    @State private var selectedType: String = "Tous"
    @State private var selectedSortOption = "Nom"
    @State private var isDarkMode = false
    @ObservedObject var favoriteManager = FavoriteManager.shared
    @Environment(\.colorScheme) var colorScheme

    let sortOptions = ["Nom", "Attaque"]
    let types = [
        "Tous", "fire", "water", "grass", "electric", "rock", "ground", "flying",
        "psychic", "bug", "ghost", "dragon", "dark", "steel", "fairy", "normal",
        "poison", "fighting", "ice"
    ]

    var body: some View {
        NavigationView {
            VStack {
                // 🔍 Recherche et Filtres
                searchAndFilterSection()

                // 🕐 Chargement
                if isLoading {
                    ProgressView("Chargement des Pokémon...").padding()
                }

                // 🎯 Liste filtrée et triée
                let filteredPokemons = filterAndSortPokemons()

                // 📜 Affichage de la liste
                ScrollView {
                    LazyVStack {
                        ForEach(filteredPokemons) { pokemon in
                            NavigationLink(destination: PokemonDetailView(pokemon: pokemon)) {
                                pokemonRow(for: pokemon)
                            }
                        }
                    }
                }
                .background(
                    LinearGradient(colors: [.blue.opacity(0.2), .purple.opacity(0.2)], startPoint: .top, endPoint: .bottom)
                        .edgesIgnoringSafeArea(.all)
                )
                .navigationTitle("Pokédex")
                .onAppear { loadPokemons() }
                .toolbar { darkModeToggle() }
            }
        }
    }

    // 🧠 Barre de recherche et filtres
    private func searchAndFilterSection() -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("🔍 Recherche et Filtres")
                .font(.headline)
                .padding(.horizontal)

            TextField("Rechercher un Pokémon...", text: $searchText)
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding(.horizontal)

            HStack {
                Text("Type :")
                Picker("Type", selection: $selectedType) {
                    ForEach(types, id: \.self) { type in
                        Text(type.capitalized)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
            .padding(.horizontal)

            Picker("Trier par", selection: $selectedSortOption) {
                ForEach(sortOptions, id: \.self) { option in
                    Text(option)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
        }
        .padding(.bottom, 10)
    }

    // ⚙️ Filtrage et tri
    private func filterAndSortPokemons() -> [PokemonModel] {
        pokemons.filter { pokemon in
            let matchesName = searchText.isEmpty || pokemon.name.localizedCaseInsensitiveContains(searchText)
            let matchesType = selectedType == "Tous" || pokemon.primaryType.lowercased() == selectedType.lowercased()
            return matchesName && matchesType
        }
        .sorted {
            if selectedSortOption == "Nom" {
                return $0.formattedName < $1.formattedName
            } else {
                return $0.getStat("attack") > $1.getStat("attack")
            }
        }
    }

    // 🌗 Basculer le mode sombre
    private func darkModeToggle() -> some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button(action: { withAnimation { isDarkMode.toggle() } }) {
                Image(systemName: isDarkMode ? "moon.fill" : "sun.max.fill")
                    .foregroundColor(.primary)
                    .font(.title2)
                    .padding(6)
                    .background(Color(.systemGray5))
                    .clipShape(Circle())
            }
            .accessibilityLabel("Basculer le mode sombre")
            .onChange(of: isDarkMode) { _, newValue in
                UIApplication.shared.connectedScenes
                    .compactMap { $0 as? UIWindowScene }
                    .first?.windows.first?.overrideUserInterfaceStyle = newValue ? .dark : .light
            }
        }
    }

    // 📦 Chargement des Pokémon
    private func loadPokemons() {
        isLoading = true
        Task {
            do {
                pokemons = try await PokemonAPI.shared.fetchPokemonList(limit: 10)
                isLoading = false
            } catch {
                #if DEBUG
                print("[⚠️ ERREUR] Échec de chargement des Pokémon : \(error.localizedDescription)")
                #endif
                isLoading = false
            }
        }
    }

    // 🔹 Affichage d'un Pokémon
    private func pokemonRow(for pokemon: PokemonModel) -> some View {
        HStack {
            // Chargement d'image
            if let imageUrl = pokemon.sprites.frontDefault, let url = URL(string: imageUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable()
                            .frame(width: 60, height: 60)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.red, lineWidth: 2))
                            .transition(.scale)
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

            // Nom et Favori
            Text(pokemon.formattedName)
                .fontWeight(.bold)
                .transition(.opacity)
                .animation(.easeInOut, value: searchText)

            Spacer()

            if favoriteManager.isFavorite(id: pokemon.id) {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                    .transition(.opacity)
                    .animation(.easeInOut, value: pokemon.id)
            }
        }
        .padding(.vertical, 5)
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .shadow(radius: 3)
    }

    // 📷 Image placeholder
    private func placeholderImage() -> some View {
        Image(systemName: "photo")
            .resizable()
            .frame(width: 60, height: 60)
            .foregroundColor(.gray)
    }
}

#Preview {
    ContentView()
}
