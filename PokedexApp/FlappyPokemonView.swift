//
//  FlappyPokemonView.swift
//  PokedexApp
//
//  Created by Ethan LEGROS on 2/24/25.
//

import SwiftUI
import Combine

struct FlappyPokemonView: View {
    let selectedPokemon: PokemonModel  // Le Pokémon sélectionné dans le détail

    // Constants du jeu
    let gravity: Double = 0.1          // Vitesse de gravité réduite
    let flapStrength: Double = -4
    let gameTimerInterval: TimeInterval = 0.02
    let obstacleSpeed: CGFloat = 2.0
    let obstacleWidth: CGFloat = 60
    let gapHeight: CGFloat = 180       // Gap agrandi pour faciliter le passage

    // États du joueur et du jeu
    @State private var playerY: CGFloat = 0
    @State private var playerVelocity: Double = 0
    @State private var obstacles: [Obstacle] = []
    @State private var score: Int = 0
    @State private var isGameOver = false
    @State private var gameTimer: AnyCancellable?

    // Dimensions d'écran
    var screenHeight: CGFloat { UIScreen.main.bounds.height }
    var screenWidth: CGFloat { UIScreen.main.bounds.width }
    
    // Structure pour les obstacles
    struct Obstacle: Identifiable {
        let id = UUID()
        var x: CGFloat
        let gapY: CGFloat  // Position verticale du centre du gap
    }
    
    var body: some View {
        ZStack {
            // Fond statique
            LinearGradient(gradient: Gradient(colors: [.blue, .cyan]),
                           startPoint: .top,
                           endPoint: .bottom)
                .ignoresSafeArea()
            
            // Obstacles
            ForEach(obstacles) { obstacle in
                // Obstacle supérieur
                Rectangle()
                    .foregroundColor(.green)
                    .frame(width: obstacleWidth, height: obstacle.gapY - gapHeight/2)
                    .position(x: obstacle.x, y: (obstacle.gapY - gapHeight/2) / 2)
                // Obstacle inférieur
                Rectangle()
                    .foregroundColor(.green)
                    .frame(width: obstacleWidth, height: screenHeight - (obstacle.gapY + gapHeight/2))
                    .position(x: obstacle.x, y: obstacle.gapY + gapHeight/2 + (screenHeight - (obstacle.gapY + gapHeight/2))/2)
            }
            
            // Le joueur (affichage de l'image du Pokémon sélectionné)
            if let playerURL = selectedPokemon.sprites.frontDefault,
               let url = URL(string: playerURL) {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image.resizable().scaledToFit()
                    } else {
                        Color.red
                    }
                }
                .frame(width: 60, height: 60)
                .position(x: screenWidth * 0.3, y: playerY)
            }
            
            // Score affiché en haut
            VStack {
                HStack {
                    Text("Score: \(score)")
                        .font(.title)
                        .padding()
                    Spacer()
                }
                Spacer()
            }
            
            // Menu de fin de jeu
            if isGameOver {
                VStack(spacing: 16) {
                    Text("Game Over")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Button("Recommencer") {
                        restartGame()
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(8)
                }
            }
        }
        .onTapGesture {
            if !isGameOver { flap() }
        }
        .onAppear { startGame() }
    }
    
    // Démarrer le jeu
    func startGame() {
        playerY = screenHeight / 2
        playerVelocity = 0
        score = 0
        isGameOver = false
        obstacles = []
        spawnObstacle()
        // Démarrer le timer du jeu
        gameTimer = Timer.publish(every: gameTimerInterval, on: .main, in: .common)
            .autoconnect()
            .sink { _ in updateGame() }
    }
    
    // Mettre à jour la physique du joueur et le mouvement des obstacles
    func updateGame() {
        guard !isGameOver else { return }
        playerVelocity += gravity
        playerY += CGFloat(playerVelocity)
        
        // Collision avec les bords
        if playerY < 0 || playerY > screenHeight {
            gameOver()
        }
        
        // Déplacer les obstacles
        for i in obstacles.indices {
            obstacles[i].x -= obstacleSpeed
        }
        obstacles.removeAll { $0.x < -obstacleWidth }
        
        // Ajouter un nouvel obstacle si nécessaire
        if let last = obstacles.last, last.x < screenWidth - 200 {
            spawnObstacle()
        }
        
        checkCollisions()
        
        score += 1
    }
    
    func flap() {
        playerVelocity = flapStrength
    }
    
    func spawnObstacle() {
        let gapY = CGFloat.random(in: gapHeight...(screenHeight - gapHeight))
        let newObstacle = Obstacle(x: screenWidth + obstacleWidth, gapY: gapY)
        obstacles.append(newObstacle)
    }
    
    func checkCollisions() {
        let playerX = screenWidth * 0.3
        let playerFrame = CGRect(x: playerX - 30, y: playerY - 30, width: 60, height: 60)
        
        for obstacle in obstacles {
            let topFrame = CGRect(x: obstacle.x - obstacleWidth/2, y: 0, width: obstacleWidth, height: obstacle.gapY - gapHeight/2)
            let bottomFrame = CGRect(x: obstacle.x - obstacleWidth/2, y: obstacle.gapY + gapHeight/2, width: obstacleWidth, height: screenHeight - (obstacle.gapY + gapHeight/2))
            if playerFrame.intersects(topFrame) || playerFrame.intersects(bottomFrame) {
                gameOver()
                break
            }
        }
    }
    
    func gameOver() {
        isGameOver = true
        gameTimer?.cancel()
    }
    
    func restartGame() {
        isGameOver = false
        gameTimer?.cancel()
        startGame()
    }
}

struct FlappyPokemonView_Previews: PreviewProvider {
    static var previews: some View {
        let dummyPokemon = PokemonModel(
            id: 1,
            name: "Bulbasaur",
            sprites: PokemonSprites(frontDefault: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/1.png"),
            types: [PokemonType(type: TypeInfo(name: "grass"))],
            stats: [],
            detailUrl: nil
        )
        FlappyPokemonView(selectedPokemon: dummyPokemon)
    }
}
