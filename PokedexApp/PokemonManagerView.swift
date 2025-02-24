//
//  PokemonManagerView.swift
//  PokedexApp
//
//  Created by Ethan LEGROS on 2/24/25.
//

import SwiftUI
import Combine

struct PokemonManagerView: View {
    let selectedPokemon: PokemonModel

    // Ressources initiales
    @State private var gold: Int = 100
    @State private var energy: Int = 50
    
    // Timer de production de ressources
    @State private var timer: AnyCancellable?
    
    // Gestion du Pokémon pour son upgrade (taille)
    @State private var pokemonScale: CGFloat = 1.0
    @State private var energyCostForUpgrade: Int = 20   // Coût initial pour grossir le Pokémon

    // Options d'achat d'énergie en plus grande quantité
    @State private var energyPackCost: Int = 30
    @State private var energyPackAmount: Int = 50
    
    // Bâtiments déjà achetés
    struct Building: Identifiable {
        let id = UUID()
        var name: String
        var level: Int
        var baseCost: Int
        var baseProduction: Int
        var imageName: String
        
        // Coût d'upgrade évolutif
        var currentCost: Int {
            return baseCost * level * level
        }
        // Production actuelle
        var productionRate: Int {
            return baseProduction * level
        }
    }
    
    @State private var buildings: [Building] = []
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Section Pokémon Upgrade
                VStack(spacing: 8) {
                    Text("\(selectedPokemon.formattedName)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    
                    // Image du Pokémon en dessous du nom, évoluant en taille
                    if let imageUrl = selectedPokemon.sprites.frontDefault, let url = URL(string: imageUrl) {
                        AsyncImage(url: url) { phase in
                            if let image = phase.image {
                                image.resizable()
                                    .scaledToFit()
                                    .frame(width: 100 * pokemonScale, height: 100 * pokemonScale)
                                    .clipShape(Circle())
                                    .shadow(radius: 5)
                            } else if phase.error != nil {
                                Color.red.frame(width: 100 * pokemonScale, height: 100 * pokemonScale)
                            } else {
                                ProgressView()
                            }
                        }
                    }
                    
                    // Boutons pour upgrader le Pokémon et acheter de l'énergie
                    HStack(spacing: 8) {
                        Button("Grossir (\(energyCostForUpgrade) énergie)") {
                            if energy >= energyCostForUpgrade {
                                energy -= energyCostForUpgrade
                                withAnimation(.spring()) {
                                    pokemonScale += 0.1
                                }
                                energyCostForUpgrade = Int(Double(energyCostForUpgrade) * 1.5)
                            }
                        }
                        .padding(8)
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        
                        Button("Acheter +\(energyPackAmount) énergie (\(energyPackCost) gold)") {
                            if gold >= energyPackCost {
                                gold -= energyPackCost
                                energy += energyPackAmount
                            }
                        }
                        .padding(8)
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }
                .padding()
                .background(Color.white.opacity(0.8))
                .cornerRadius(12)
                .shadow(radius: 5)
                
                // Ressources
                HStack(spacing: 32) {
                    VStack {
                        Text("Gold")
                        Text("\(gold)")
                            .font(.title2)
                    }
                    VStack {
                        Text("Énergie")
                        Text("\(energy)")
                            .font(.title2)
                    }
                }
                .padding()
                
                Divider()
                
                // Section Bâtiments possédés
                VStack(alignment: .leading, spacing: 8) {
                    Text("Mes Bâtiments")
                        .font(.headline)
                    if buildings.isEmpty {
                        Text("Aucun bâtiment. Achetez-en un ci-dessous !")
                            .font(.caption)
                            .foregroundColor(.gray)
                    } else {
                        ForEach(buildings) { building in
                            HStack {
                                Image(systemName: building.imageName)
                                    .resizable()
                                    .frame(width: 40, height: 40)
                                VStack(alignment: .leading) {
                                    Text("\(building.name) (Niveau \(building.level))")
                                        .font(.headline)
                                    Text("Production: \(building.productionRate) gold/s")
                                        .font(.caption)
                                    Text("Upgrade: +\(building.baseProduction) gold/s")
                                        .font(.caption2)
                                    Text("Coût upgrade: \(building.currentCost) gold")
                                        .font(.caption2)
                                }
                                Spacer()
                                Button("Améliorer") {
                                    upgrade(building: building)
                                }
                                .disabled(gold < building.currentCost)
                            }
                            .padding()
                            .background(Color.white.opacity(0.7))
                            .cornerRadius(10)
                            .shadow(radius: 3)
                            .padding(.horizontal)
                        }
                    }
                }
                
                Divider()
                
                // Section pour acheter de nouveaux bâtiments
                VStack(spacing: 8) {
                    Text("Acheter un nouveau bâtiment")
                        .font(.headline)
                    HStack(spacing: 12) {
                        BuildingOptionView(building: Building(name: "Centre d'entraînement", level: 1, baseCost: 50, baseProduction: 5, imageName: "figure.walk"), gold: $gold)
                        BuildingOptionView(building: Building(name: "Laboratoire", level: 1, baseCost: 100, baseProduction: 8, imageName: "flame.fill"), gold: $gold)
                        BuildingOptionView(building: Building(name: "Poke-Centre", level: 1, baseCost: 80, baseProduction: 6, imageName: "cross.case.fill"), gold: $gold)
                        BuildingOptionView(building: Building(name: "Usine", level: 1, baseCost: 150, baseProduction: 12, imageName: "gear"), gold: $gold)
                        BuildingOptionView(building: Building(name: "Centre Commercial", level: 1, baseCost: 120, baseProduction: 10, imageName: "cart.fill"), gold: $gold)
                        BuildingOptionView(building: Building(name: "Centre de Recherche", level: 1, baseCost: 200, baseProduction: 15, imageName: "lightbulb.fill"), gold: $gold)
                    }
                }
                .padding()
                
                Divider()
                
                Spacer()
            }
            .padding()
        }
        .onAppear {
            startResourceTimer()
        }
        // Écoute des notifications pour ajouter un nouveau bâtiment
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("NewBuildingPurchased"))) { notification in
            if let newBuilding = notification.object as? Building {
                buildings.append(newBuilding)
            }
        }
        .navigationTitle("Gestion Pokémon")
    }
    
    // Timer pour ajouter des ressources chaque seconde
    func startResourceTimer() {
        timer?.cancel()
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                let production = buildings.reduce(0) { $0 + $1.productionRate }
                gold += production
            }
    }
    
    // Améliorer un bâtiment existant
    func upgrade(building: Building) {
        if let index = buildings.firstIndex(where: { $0.id == building.id }) {
            let cost = buildings[index].currentCost
            if gold >= cost {
                gold -= cost
                withAnimation(.spring()) {
                    buildings[index].level += 1
                }
            }
        }
    }
}

struct BuildingOptionView: View {
    let building: PokemonManagerView.Building
    @Binding var gold: Int
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: building.imageName)
                .resizable()
                .frame(width: 40, height: 40)
                .padding(4)
            Text(building.name)
                .font(.caption)
            Text("Coût: \(building.baseCost) gold")
                .font(.caption2)
                .foregroundColor(.gray)
            Button("Acheter") {
                if gold >= building.baseCost {
                    gold -= building.baseCost
                    // Notifier l'achat du bâtiment
                    NotificationCenter.default.post(name: Notification.Name("NewBuildingPurchased"), object: building)
                }
            }
            .padding(4)
            .background(gold >= building.baseCost ? Color.blue : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(8)
            .font(.caption2)
        }
        .padding(4)
        .background(Color.white.opacity(0.8))
        .cornerRadius(8)
        .shadow(radius: 2)
    }
}

struct PokemonManagerView_Previews: PreviewProvider {
    static var previews: some View {
        let dummyPokemon = PokemonModel(
            id: 1,
            name: "Bulbasaur",
            sprites: PokemonSprites(frontDefault: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/1.png"),
            types: [PokemonType(type: TypeInfo(name: "grass"))],
            stats: [],
            detailUrl: nil
        )
        NavigationView {
            PokemonManagerView(selectedPokemon: dummyPokemon)
        }
    }
}
