//
//  MemoryGameView.swift
//  PokedexApp
//
//  Created by Ethan LEGROS on 2/24/25.
//

import SwiftUI
import Combine

struct MemoryGameView: View {
    let pokemons: [PokemonModel]
    let selectedPokemon: PokemonModel  // Le Pokémon sur lequel l'utilisateur a cliqué

    // Niveaux de difficulté
    let difficulties = ["Facile", "Moyen", "Difficile"]
    @State private var selectedDifficulty: String = "Facile"
    
    // Paramètres de jeu qui dépendent de la difficulté
    @State private var pairsCount: Int = 4
    @State private var maxMoves: Int = 20
    
    // Durée du jeu en secondes (déclarée une seule fois)
    let gameDuration: TimeInterval = 15
    @State private var timeRemaining: TimeInterval = 15
    @State private var score: Int = 0
    
    // Définition d'une carte pour le jeu
    struct Card: Identifiable {
        let id = UUID()
        let content: String  // URL de l'image du Pokémon
        var isFaceUp = false
        var isMatched = false
        let isBonus: Bool    // Vrai pour la carte bonus (celle du Pokémon sélectionné)
    }
    
    @State private var cards: [Card] = []
    @State private var firstSelectedIndex: Int? = nil
    @State private var moves: Int = 0
    @State private var gameOver: Bool = false
    @State private var victory: Bool = false
    
    // Disposition en grille (3 colonnes)
    let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
    
    // Pour animer la carte bonus qui s'envole
    @State private var bonusOffset: CGFloat = 0
    @State private var bonusOpacity: Double = 1.0
    
    // Pour le contrôle des taps afin d'éviter les doubles clics rapides
    @State private var isProcessingTap = false
    
    // Pour le timer du jeu
    @State private var timerCancellable: AnyCancellable?
    
    // Dimensions de la zone de jeu
    @State private var gameAreaSize: CGSize = .zero
    
    // Pour positionner la carte normale
    @State private var currentPosition: CGPoint = .zero
    @State private var currentPokemonURL: String = ""
    @State private var animatePokemon = false
    
    var body: some View {
        VStack(spacing: 8) {
            // Titre et Picker de difficulté
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
                .onChange(of: selectedDifficulty) { oldValue, newValue in
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
                        .offset(y: cards[index].isBonus ? bonusOffset : 0)
                        .opacity(cards[index].isBonus ? bonusOpacity : 1)
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
                resetGame()
            }
            .padding(8)
        }
        .navigationTitle("Jeu de Mémoire")
        .onAppear {
            setupGame()
            startGameTimer()
        }
    }
    
    // Configuration du jeu
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
            pairsCount = 8
            maxMoves = 30
        default:
            pairsCount = 4
            maxMoves = 20
        }
        moves = 0
        gameOver = false
        victory = false
        bonusOffset = 0
        bonusOpacity = 1.0
        
        // Sélectionner aléatoirement 'pairsCount' Pokémon pour créer des paires
        let selected = pokemons.shuffled().prefix(pairsCount)
        var newCards: [Card] = []
        for pokemon in selected {
            let imageURL = pokemon.sprites.frontDefault ?? ""
            newCards.append(Card(content: imageURL, isBonus: false))
            newCards.append(Card(content: imageURL, isBonus: false))
        }
        // Ajout de la carte bonus correspondant au Pokémon sélectionné
        if let bonusURL = selectedPokemon.sprites.frontDefault {
            newCards.append(Card(content: bonusURL, isBonus: true))
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
        
        // Si c'est la carte bonus, déclencher l'animation spéciale
        if cards[index].isBonus {
            bonusTapped(at: index)
            return
        }		
        
        if let firstIndex = firstSelectedIndex {
            moves += 1
            if cards[index].content == cards[firstIndex].content {
                // Appariement trouvé
                cards[index].isMatched = true
                cards[firstIndex].isMatched = true
                if cards.allSatisfy({ $0.isMatched || $0.isBonus }) {
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
        
        if moves >= maxMoves && !cards.allSatisfy({ $0.isMatched || $0.isBonus }) {
            gameOver = true
        }
    }
    
    // Action spéciale pour la carte bonus
    func bonusTapped(at index: Int) {
        guard !isProcessingTap else { return }
        isProcessingTap = true
        score += 2  // Bonus de score
        // Attendre 0.3 seconde avant d'animer l'envol pour laisser le temps de se retourner
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeInOut(duration: 0.5)) {
                bonusOffset = -100  // La carte s'envole vers le haut
                bonusOpacity = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                if let idx = cards.firstIndex(where: { $0.isBonus }) {
                    cards.remove(at: idx)
                }
                isProcessingTap = false
            }
        }
    }

    
    func resetGame() {
        timeRemaining = gameDuration
        score = 0
        moves = 0
        gameOver = false
        victory = false
        startGameTimer()
        setupGame()
    }
    
    // Démarrer le timer du jeu
    func startGameTimer() {
        timerCancellable?.cancel()
        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                if timeRemaining > 0 {
                    timeRemaining -= 1
                } else {
                    timerCancellable?.cancel()
                }
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
        MemoryGameView(pokemons: Array(repeating: dummyPokemon, count: 10), selectedPokemon: dummyPokemon)
    }
}
