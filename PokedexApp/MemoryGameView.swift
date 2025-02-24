//
//  MemoryGameView.swift
//  PokedexApp
//
//  Created by Ethan LEGROS on 2/24/25.
//

import SwiftUI

struct MemoryGameView: View {
    let pokemons: [PokemonModel]
    
    // Niveaux de difficulté
    let difficulties = ["Facile", "Moyen", "Difficile"]
    @State private var selectedDifficulty: String = "Facile"
    
    // Paramètres de jeu qui dépendent de la difficulté
    @State private var pairsCount: Int = 4
    @State private var maxMoves: Int = 20
    
    // Définition d'une carte pour le jeu
    struct Card: Identifiable {
        let id = UUID()
        let content: String // URL de l'image du Pokémon
        var isFaceUp = false
        var isMatched = false
    }
    
    @State private var cards: [Card] = []
    @State private var firstSelectedIndex: Int? = nil
    @State private var moves: Int = 0
    @State private var gameOver: Bool = false
    @State private var victory: Bool = false
    
    // Disposition en grille (3 colonnes)
    let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Jeu de Mémoire")
                    .font(.title)
                    .padding(.leading, 8)
                Spacer()
                Picker("Difficulté", selection: $selectedDifficulty) {
                    ForEach(difficulties, id: \.self) { diff in
                        Text(diff)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding(.trailing, 8)
                .onChange(of: selectedDifficulty) { _ in
                    setupGame()
                }
            }
            
            Text("Coups: \(moves) / \(maxMoves)")
                .font(.subheadline)
            
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(cards.indices, id: \.self) { index in
                    CardView(card: cards[index])
                        .onTapGesture {
                            cardTapped(at: index)
                        }
                }
            }
            .padding(8)
            
            if gameOver {
                Text("Défaite !")
                    .font(.largeTitle)
                    .foregroundColor(.red)
                    .padding(4)
            } else if victory {
                Text("Victoire !")
                    .font(.largeTitle)
                    .foregroundColor(.green)
                    .padding(4)
            }
            
            Button("Recommencer") {
                setupGame()
            }
            .padding(8)
        }
        .navigationTitle("Jeu de Mémoire")
        .onAppear {
            setupGame()
        }
    }
    
    func setupGame() {
        // Ajuster le nombre de paires et le nombre maximum de coups selon la difficulté
        switch selectedDifficulty {
        case "Facile":
            pairsCount = 4
            maxMoves = 20
        case "Moyen":
            pairsCount = 6
            maxMoves = 25
        case "Difficile":
            pairsCount = 7
            maxMoves = 25
        default:
            pairsCount = 4
            maxMoves = 20
        }
        moves = 0
        gameOver = false
        victory = false
        
        // Sélectionnez aléatoirement 'pairsCount' Pokémon
        let selected = pokemons.shuffled().prefix(pairsCount)
        var newCards: [Card] = []
        for pokemon in selected {
            let imageURL = pokemon.sprites.frontDefault ?? ""
            newCards.append(Card(content: imageURL))
            newCards.append(Card(content: imageURL))
        }
        cards = newCards.shuffled()
        firstSelectedIndex = nil
    }
    
    func cardTapped(at index: Int) {
        // Ne rien faire si le jeu est terminé ou si la carte est déjà révélée/appairée
        guard !gameOver, !cards[index].isFaceUp, !cards[index].isMatched else { return }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            cards[index].isFaceUp = true
        }
        
        if let firstIndex = firstSelectedIndex {
            moves += 1
            if cards[index].content == cards[firstIndex].content {
                // Appariement trouvé
                cards[index].isMatched = true
                cards[firstIndex].isMatched = true
                if cards.allSatisfy({ $0.isMatched }) {
                    victory = true
                }
            } else {
                // Pas d'appariement, masquer après 1 seconde
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        cards[index].isFaceUp = false
                        cards[firstIndex].isFaceUp = false
                    }
                }
            }
            firstSelectedIndex = nil
        } else {
            firstSelectedIndex = index
        }
        
        if moves >= maxMoves && !cards.allSatisfy({ $0.isMatched }) {
            gameOver = true
        }
    }
}

struct CardView: View {
    let card: MemoryGameView.Card
    
    var body: some View {
        ZStack {
            if card.isFaceUp || card.isMatched {
                AsyncImage(url: URL(string: card.content)) { phase in
                    if let image = phase.image {
                        image.resizable().scaledToFit()
                    } else if phase.error != nil {
                        Color.red
                    } else {
                        ProgressView()
                    }
                }
                .frame(width: 100, height: 100)
                .cornerRadius(8)
            } else {
                Rectangle()
                    .foregroundColor(.blue)
                    .frame(width: 100, height: 100)
                    .cornerRadius(8)
            }
        }
        // Animation de flip 3D
        .rotation3DEffect(
            .degrees(card.isFaceUp || card.isMatched ? 0 : 180),
            axis: (x: 0, y: 1, z: 0)
        )
        .animation(.easeInOut(duration: 0.3), value: card.isFaceUp)
    }
}

struct MemoryGameView_Previews: PreviewProvider {
    static var previews: some View {
        let dummyPokemon = PokemonModel(
            id: 1,
            name: "Bulbasaur",
            sprites: PokemonSprites(frontDefault: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/1.png"),
            types: [PokemonType(type: TypeInfo(name: "grass"))],
            stats: [],
            detailUrl: nil
        )
        MemoryGameView(pokemons: Array(repeating: dummyPokemon, count: 10))
    }
}
