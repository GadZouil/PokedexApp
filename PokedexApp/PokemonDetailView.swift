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
    
    var body: some View {
        VStack(spacing: 20) {
            // Image principale
            AsyncImage(url: URL(string: pokemon.sprites.front_default)) { image in
                image.resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(radius: 10)
            } placeholder: {
                ProgressView()
            }
            
            // Nom et types
            Text(pokemon.name.capitalized)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.blue)
            
            // Afficher les types
            HStack {
                ForEach(pokemon.types, id: \.type.name) { pokeType in
                    Text(pokeType.type.name.capitalized)
                        .padding(10)
                        .background(Color.green.opacity(0.2))
                        .clipShape(Capsule())
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
                }
            }
            .padding()
            
            // Bouton Favori
            Button(action: {
                if favoriteManager.isFavorite(id: pokemon.id) {
                    favoriteManager.removeFavorite(id: pokemon.id)
                } else {
                    favoriteManager.addFavorite(pokemon: pokemon)
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
            
            Spacer()
        }
        .padding()
        .background(LinearGradient(colors: [.white, .blue.opacity(0.2)], startPoint: .top, endPoint: .bottom))
        .cornerRadius(15)
        .shadow(radius: 5)
        .navigationBarTitleDisplayMode(.inline)
    }
}
