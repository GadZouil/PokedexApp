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

    let sortOptions = ["Nom", "Attaque", "Défense", "Vitesse"]
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
                
                //Button("Reset Favoris") {
                //    FavoriteManager.shared.resetFavorites()
                //}
                //.padding()
                //.background(Color.red)
                //.foregroundColor(.white)
                //.cornerRadius(8)

                // 🕐 Chargement
                if isLoading {
                    ProgressView("Chargement des Pokémon...").padding()
                } else {
                    let filteredPokemons = filterAndSortPokemons()
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(filteredPokemons) { pokemon in
                                NavigationLink(destination: PokemonDetailView(pokemon: pokemon)) {
                                    pokemonRow(for: pokemon)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .background(
                        LinearGradient(colors: [.blue.opacity(0.2), .purple.opacity(0.2)],
                                       startPoint: .top,
                                       endPoint: .bottom)
                        .edgesIgnoringSafeArea(.all)
                    )
                }
            }
            .navigationTitle("Pokédex")
            .onAppear(perform: loadPokemons)
            .toolbar { darkModeToggle() }
        }
    }

    // MARK: - Barre de recherche et filtres
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

    // MARK: - Chargement des Pokémon
    private func loadPokemons() {
        isLoading = true
        Task {
            do {
                pokemons = try await PokemonAPI.shared.fetchPokemonList(limit: 151)

                // 🔍 Vérification des images manquantes et second fetch
                var updatedPokemons = pokemons
                for index in updatedPokemons.indices {
                    if updatedPokemons[index].sprites.frontDefault == nil, let url = updatedPokemons[index].detailUrl {
                        let fullDetails = try await PokemonAPI.shared.fetchPokemonDetails(from: url)
                        updatedPokemons[index] = fullDetails
                    }
                }

                pokemons = updatedPokemons

                // Affiche les résultats dans la console
                for pokemon in pokemons {
                    print("[🔍 IMAGE CHECK] \(pokemon.name): \(pokemon.sprites.frontDefault ?? "❌ Aucune image")")
                }

                isLoading = false
            } catch {
                print("[⚠️ ERREUR] Échec de chargement : \(error.localizedDescription)")
                isLoading = false
            }
        }
    }



    // MARK: - Filtrage et tri
    private func filterAndSortPokemons() -> [PokemonModel] {
        pokemons
            .filter { pokemon in
                let matchesName = searchText.isEmpty || pokemon.name.localizedCaseInsensitiveContains(searchText)
                let matchesType = (selectedType == "Tous") || (pokemon.primaryType.lowercased() == selectedType.lowercased())
                return matchesName && matchesType
            }
            .sorted {
                switch selectedSortOption {
                case "Nom":      return $0.formattedName < $1.formattedName
                case "Attaque":  return $0.attack > $1.attack
                case "Défense":  return $0.defense > $1.defense
                case "Vitesse":  return $0.speed > $1.speed
                default:         return $0.formattedName < $1.formattedName
                }
            }
    }

    // MARK: - Mode Sombre
    private func darkModeToggle() -> some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                withAnimation {
                    isDarkMode.toggle()
                }
            } label: {
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

    // MARK: - Affichage d'un Pokémon (Row)
    // Ajoutez cette fonction utilitaire (vous pouvez la placer dans ContentView ou dans une extension commune)
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

    private func pokemonRow(for pokemon: PokemonModel) -> some View {
        HStack {
            // Image du Pokémon
            if let frontURL = pokemon.sprites.frontDefault,
               let url = URL(string: frontURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable()
                            .frame(width: 60, height: 60)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.red, lineWidth: 2))
                    case .failure:
                        placeholderImage()
                    case .empty:
                        ProgressView()
                    @unknown default:
                        placeholderImage()
                    }
                }
            } else {
                placeholderImage()
                    .task {
                        if let detailUrl = pokemon.detailUrl {
                            do {
                                let updatedPokemon = try await PokemonAPI.shared.fetchPokemonDetails(from: detailUrl)
                                if let index = pokemons.firstIndex(where: { $0.id == pokemon.id }) {
                                    pokemons[index] = updatedPokemon
                                }
                            } catch {
                                print("[⚠️ ERREUR] Impossible de récupérer l'image pour \(pokemon.name) : \(error)")
                            }
                        }
                    }
            }
            
            // Infos (nom et type)
            VStack(alignment: .leading) {
                Text(pokemon.formattedName)
                    .fontWeight(.bold)
                    .transition(.opacity)
                Text("Type : \(pokemon.primaryType.capitalized)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .animation(.easeInOut, value: searchText)
            
            Spacer()
            
            // Bouton favori
            Button {
                toggleFavorite(pokemon: pokemon)
            } label: {
                if isPokemonFavorite(pokemon) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                } else {
                    Image(systemName: "star")
                        .foregroundColor(.gray)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 5)
        .padding(.horizontal)
        // Le bandeau a pour fond la couleur du type principal, en légère transparence
        .background(colorForType(pokemon.primaryType).opacity(0.3))
        .cornerRadius(10)
        .shadow(radius: 3)
    }



    // MARK: - Placeholder Image
    private func placeholderImage() -> some View {
        Image(systemName: "photo")
            .resizable()
            .frame(width: 60, height: 60)
            .foregroundColor(.gray)
    }

    // MARK: - Gestion des Favoris
    private func toggleFavorite(pokemon: PokemonModel) {
        if favoriteManager.favorites.contains(pokemon.id) {
            favoriteManager.removeFromFavorites(pokemon.id)
        } else {
            favoriteManager.addToFavorites(pokemon)
        }
    }
    // MARK: - Vérifier si un Pokémon est favori
    private func isPokemonFavorite(_ pokemon: PokemonModel) -> Bool {
        return favoriteManager.favorites.contains(pokemon.id)
    }
}

// MARK: - Gestion fiable des images
struct ImageView: View {
    @StateObject private var loader = ImageLoader()
    let url: String?

    var body: some View {
        Group {
            if let image = loader.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                placeholder
                    .onAppear { loader.load(from: url) }
            }
        }
    }

    private var placeholder: some View {
        Image(systemName: "photo")
            .resizable()
            .scaledToFit()
            .foregroundColor(.gray)
            .frame(width: 60, height: 60)
    }
}
