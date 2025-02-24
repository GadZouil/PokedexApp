//
//  TowerUpgradeView.swift .swift
//  PokedexApp
//
//  Created by Ethan LEGROS on 2/24/25.
//

import SwiftUI

struct TowerUpgradeView: View {
    @Binding var tower: Tower
    
    var body: some View {
        VStack(spacing: 16) {
            if let url = URL(string: tower.pokemon.sprites.frontDefault ?? "") {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image.resizable().scaledToFit()
                    } else {
                        Color.gray
                    }
                }
                .frame(width: 100, height: 100)
                .clipShape(Circle())
                .shadow(radius: 5)
            }
            Text(tower.pokemon.name)
                .font(.title)
                .fontWeight(.bold)
            Text("Type: \(tower.pokemon.types.first?.type.name.capitalized ?? "N/A")")
            Text("Dégâts: \(tower.damage)")
            Button("Améliorer (+5 dégâts)") {
                tower.damage += 5
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
            Spacer()
        }
        .padding()
        .navigationTitle("Améliorer la Tour")
    }
}

struct TowerUpgradeView_Previews: PreviewProvider {
    @State static var tower = Tower(pokemon: PokemonModel(id: 1, name: "Bulbasaur", sprites: PokemonSprites(frontDefault: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/1.png"), types: [PokemonType(type: TypeInfo(name: "grass"))], stats: [], detailUrl: nil), lane: 0, order: 0, damage: 10)
    static var previews: some View {
        NavigationView {
            TowerUpgradeView(tower: $tower)
        }
    }
}
