//
//  CatchGameView.swift
//  PokedexApp
//
//  Created by Ethan LEGROS on [Date].
//

import SwiftUI
import Combine

struct CatchGameView: View {
    let pokemons: [PokemonModel] // Liste complète des Pokémon pour choisir les sprites
    
    // Durée du jeu en secondes
    let gameDuration: TimeInterval = 15
    
    @State private var isLoading = true
    @State private var timeRemaining: TimeInterval = 15
    @State private var score: Int = 0
    
    // Les coordonnées de l'image actuelle dans le jeu
    @State private var currentPosition: CGPoint = .zero
    @State private var currentPokemonURL: String = ""
    @State private var animatePokemon = false
    
    // Pour le contrôle des taps afin d'éviter les doubles clics rapides
    @State private var isProcessingTap = false
    
    // Pour le timer du jeu
    @State private var timerCancellable: AnyCancellable?
    
    // Dimensions de la zone de jeu
    @State private var gameAreaSize: CGSize = .zero
    
    var body: some View {
        ZStack {
            // Fond de jeu (personnalisable)
            Color.green.opacity(0.1)
                .ignoresSafeArea()
            
            if isLoading {
                // Mini cinématique de chargement
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(2)
                    Text("Chargement du mini jeu...")
                        .font(.headline)
                }
                .transition(.opacity)
            } else if timeRemaining > 0 {
                // Zone de jeu
                GeometryReader { geo in
                    ZStack {
                        Color.clear
                            .onAppear {
                                gameAreaSize = geo.size
                                spawnNewPokemon()
                            }
                        
                        if !currentPokemonURL.isEmpty {
                            AsyncImage(url: URL(string: currentPokemonURL)) { phase in
                                if let image = phase.image {
                                    image.resizable()
                                        .scaledToFit()
                                } else if phase.error != nil {
                                    Color.red
                                } else {
                                    ProgressView()
                                }
                            }
                            .frame(width: 80, height: 80)
                            .position(currentPosition)
                            .scaleEffect(animatePokemon ? 1.2 : 1.0)
                            .animation(.easeInOut(duration: 0.3), value: animatePokemon)
                            .onTapGesture {
                                catchPokemon()
                            }
                        }
                    }
                }
            } else {
                // Fin du jeu : afficher le score
                VStack(spacing: 16) {
                    Text("Temps écoulé")
                        .font(.title)
                    Text("Score : \(score)")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Button("Recommencer") {
                        resetGame()
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .transition(.scale)
            }
            
            // Affichage du timer et du score en haut
            VStack {
                HStack {
                    Text("Temps: \(Int(timeRemaining)) s")
                        .font(.headline)
                    Spacer()
                    Text("Score: \(score)")
                        .font(.headline)
                }
                .padding()
                Spacer()
            }
        }
        .onAppear {
            startLoading()
        }
    }
    
    // Cinématique de chargement
    func startLoading() {
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isLoading = false
            timeRemaining = gameDuration
            score = 0
            startGameTimer()
        }
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
    
    // Choisit un nouveau Pokémon et positionne l'image aléatoirement
    func spawnNewPokemon() {
        guard gameAreaSize != .zero else { return }
        if let randomPokemon = pokemons.randomElement() {
            currentPokemonURL = randomPokemon.sprites.frontDefault ?? ""
        } else {
            currentPokemonURL = ""
        }
        let margin: CGFloat = 50
        let x = CGFloat.random(in: margin...(gameAreaSize.width - margin))
        let y = CGFloat.random(in: margin...(gameAreaSize.height - margin))
        currentPosition = CGPoint(x: x, y: y)
        animatePokemon.toggle()
    }
    
    // Action lors du tap sur le Pokémon (empêche les doubles taps rapides)
    func catchPokemon() {
        guard !isProcessingTap else { return }
        isProcessingTap = true
        score += 1
        withAnimation(.easeInOut(duration: 0.2)) {
            animatePokemon = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            animatePokemon = false
            spawnNewPokemon()
            isProcessingTap = false
        }
    }
    
    func resetGame() {
        timeRemaining = gameDuration
        score = 0
        startGameTimer()
        spawnNewPokemon()
    }
}

struct CatchGameView_Previews: PreviewProvider {
    static var previews: some View {
        let dummyPokemon = PokemonModel(
            id: 1,
            name: "Bulbasaur",
            sprites: PokemonSprites(frontDefault: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/1.png"),
            types: [PokemonType(type: TypeInfo(name: "grass"))],
            stats: [],
            detailUrl: nil
        )
        CatchGameView(pokemons: Array(repeating: dummyPokemon, count: 20))
    }
}
