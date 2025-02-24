//
//  PokemonVsZombiesVerticalView.swift
//  PokedexApp
//
//  Created by Ethan LEGROS on [Date]
//

import SwiftUI
import Combine

struct PokemonVsZombiesVerticalView: View {
    let allPokemons: [PokemonModel]     // Liste complète des Pokémon
    let selectedPokemon: PokemonModel   // Le Pokémon sélectionné dans le détail

    let laneCount = 5               // Nombre de lanes
    let topMargin: CGFloat = 80     // Espace réservé en haut pour la barre d'icônes

    // Pas de décalage vertical pour un alignement parfait
    let verticalOffset: CGFloat = 0

    // États du jeu
    @State private var towers: [Tower] = []
    @State private var zombies: [Zombie] = []
    @State private var projectiles: [Projectile] = []
    
    // Pour contrôler le tir continu de chaque tour
    @State private var towerShotTimers: [UUID: Double] = [:]
    @State private var shootingStates: [UUID: Bool] = [:]
    
    @State private var gameTimer: AnyCancellable?
    @State private var gameOver = false
    @State private var score = 0
    
    // Pour ajouter une tour via la barre supérieure
    @State private var showLaneSelection: Bool = false
    @State private var selectedForAdding: PokemonModel? = nil

    var body: some View {
        GeometryReader { geo in
            let screenWidth = geo.size.width
            let screenHeight = geo.size.height
            let effectiveHeight = screenHeight - topMargin
            let laneHeight = effectiveHeight / CGFloat(laneCount)
            
            ZStack {
                // Fond d'écran
                LinearGradient(gradient: Gradient(colors: [.black, .gray]),
                               startPoint: .top,
                               endPoint: .bottom)
                    .ignoresSafeArea()
                
                VStack(spacing: 4) {
                    // Barre supérieure : affichage unique d'une tour par lane
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(uniqueTowers(), id: \.id) { tower in
                                if let url = URL(string: tower.pokemon.sprites.frontDefault ?? "") {
                                    AsyncImage(url: url) { phase in
                                        if let image = phase.image {
                                            image.resizable().scaledToFit()
                                        } else {
                                            Color.gray
                                        }
                                    }
                                    .frame(width: 40, height: 40)
                                    .clipShape(Circle())
                                    .onTapGesture {
                                        // On choisit ce Pokémon pour ajouter une nouvelle tour
                                        selectedForAdding = tower.pokemon
                                        showLaneSelection = true
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 8)
                    }
                    .padding(.top, 8)
                    
                    // Zone de jeu (lanes et éléments)
                    ZStack {
                        // Lignes de lanes avec tap pour ajouter une tour dans la lane
                        ForEach(0..<laneCount, id: \.self) { lane in
                            let laneCenter = getLaneCenter(for: lane, laneHeight: laneHeight)
                            Path { path in
                                path.move(to: CGPoint(x: 0, y: laneCenter))
                                path.addLine(to: CGPoint(x: screenWidth, y: laneCenter))
                            }
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if towers.filter({ $0.lane == lane }).count < 3, let pokemon = selectedForAdding {
                                    addTower(newPokemon: pokemon, toLane: lane)
                                }
                            }
                        }
                        
                        // Affichage des tours dans chaque lane, avec menu contextuel pour améliorations
                        ForEach(0..<laneCount, id: \.self) { lane in
                            let towersInLane = towers.filter { $0.lane == lane }.sorted { $0.order < $1.order }
                            ForEach(Array(towersInLane.enumerated()), id: \.element.id) { (index, tower) in
                                TowerView(tower: tower,
                                          xPosition: 50 + CGFloat(index) * 80,
                                          laneCenter: getLaneCenter(for: lane, laneHeight: laneHeight))
                                .contextMenu {
                                    Button("Augmenter dégâts (+5)") {
                                        increaseDamage(for: tower)
                                    }
                                    Button("Tir plus rapide (-0.1s)") {
                                        increaseFireRate(for: tower)
                                    }
                                }
                            }
                        }

                        
                        // Zombies, alignés au centre de leur lane
                        ForEach(zombies) { zombie in
                            ZombieView(zombie: zombie)
                        }
                        
                        // Projectiles, alignés au centre de leur lane
                        ForEach(projectiles) { projectile in
                            ProjectileView(projectile: projectile)
                        }
                    }
                }
                
                // Score affiché en haut à droite
                VStack {
                    HStack {
                        Spacer()
                        Text("Score: \(score)")
                            .font(.title)
                            .foregroundColor(.white)
                            .padding()
                    }
                    Spacer()
                }
                
                // Game Over overlay
                if gameOver {
                    VStack(spacing: 16) {
                        Text("Game Over")
                            .font(.largeTitle)
                            .foregroundColor(.red)
                        Button("Recommencer") {
                            resetGame(screenWidth: screenWidth, screenHeight: screenHeight, laneHeight: laneHeight)
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(8)
                    }
                }
            }
            .onAppear {
                resetGame(screenWidth: screenWidth, screenHeight: screenHeight, laneHeight: laneHeight)
                startGame(screenWidth: screenWidth, screenHeight: screenHeight, laneHeight: laneHeight)
            }
            // Confirmation dialog pour choisir la lane lors de l'ajout d'une tour
            .confirmationDialog("Choisissez la lane", isPresented: $showLaneSelection, titleVisibility: .visible) {
                ForEach(0..<laneCount, id: \.self) { lane in
                    Button("Lane \(lane + 1)") {
                        if towers.filter({ $0.lane == lane }).count < 3, let pokemon = selectedForAdding {
                            addTower(newPokemon: pokemon, toLane: lane)
                        }
                    }
                }
                Button("Annuler", role: .cancel) { }
            }
        }
    }
    
    func increaseDamage(for tower: Tower) {
        if let i = towers.firstIndex(where: { $0.id == tower.id }) {
            towers[i].damage += 5
        }
    }

    func increaseFireRate(for tower: Tower) {
        if let i = towers.firstIndex(where: { $0.id == tower.id }) {
            towers[i].fireRate = max(towers[i].fireRate - 0.1, 0.2)
        }
    }

    // Retourne le centre vertical d'une lane
    func getLaneCenter(for lane: Int, laneHeight: CGFloat) -> CGFloat {
        return topMargin + laneHeight * CGFloat(lane) + laneHeight / 2
    }
    
    // Retourne une tour par lane (une icône par lane)
    func uniqueTowers() -> [Tower] {
        var result: [Tower] = []
        for lane in 0..<laneCount {
            let towersInLane = towers.filter { $0.lane == lane }.sorted { $0.order < $1.order }
            if let first = towersInLane.first {
                result.append(first)
            }
        }
        return result
    }
    
    // Ajoute une tour dans la lane donnée
    func addTower(newPokemon: PokemonModel, toLane lane: Int) {
        let order = (towers.filter { $0.lane == lane }.map { $0.order }.max() ?? 0) + 1
        towers.append(Tower(pokemon: newPokemon, lane: lane, order: order, damage: 10, fireRate: 0.5))
    }
    
    // Crée les tours initiales : le selectedPokemon dans la première lane, les 4 autres aléatoires
    func createInitialTowers() -> [Tower] {
        var ts: [Tower] = []
        ts.append(Tower(pokemon: selectedPokemon, lane: 0, order: 0, damage: 10, fireRate: 0.5))
        let available = allPokemons.filter { $0.id != selectedPokemon.id }
        for lane in 1..<laneCount {
            if let random = available.randomElement() {
                ts.append(Tower(pokemon: random, lane: lane, order: 0, damage: 10, fireRate: 0.5))
            }
        }
        return ts
    }
    
    func resetGame(screenWidth: CGFloat, screenHeight: CGFloat, laneHeight: CGFloat) {
        gameOver = false
        score = 0
        zombies = []
        projectiles = []
        towerShotTimers = [:]
        shootingStates = [:]
        towers = createInitialTowers()
        spawnZombie(screenWidth: screenWidth, laneHeight: laneHeight)
    }
    
    func startGame(screenWidth: CGFloat, screenHeight: CGFloat, laneHeight: CGFloat) {
        resetGame(screenWidth: screenWidth, screenHeight: screenHeight, laneHeight: laneHeight)
        gameTimer = Timer.publish(every: 0.03, on: .main, in: .common)
            .autoconnect()
            .sink { _ in updateGame(screenWidth: screenWidth, laneHeight: laneHeight) }
    }
    
    func updateGame(screenWidth: CGFloat, laneHeight: CGFloat) {
        guard !gameOver else {
            gameTimer?.cancel()
            return
        }
        
        // Chaque tour tire si un zombie est dans sa lane
        for tower in towers {
            let zombiesInLane = zombies.filter { $0.lane == tower.lane }
            if !zombiesInLane.isEmpty {
                towerShotTimers[tower.id, default: 0] += 0.03
                if towerShotTimers[tower.id, default: 0] >= tower.fireRate {
                    shoot(from: tower, laneHeight: laneHeight)
                    towerShotTimers[tower.id] = 0
                }
            } else {
                towerShotTimers[tower.id] = 0
            }
        }
        
        // Déplacer zombies
        for index in zombies.indices {
            zombies[index].position.x -= zombies[index].speed
        }
        zombies.removeAll { $0.position.x < -50 }
        if let zombie = zombies.first, zombie.position.x < 50 {
            gameOver = true
        }
        
        // Déplacer projectiles
        for index in projectiles.indices {
            projectiles[index].position.x += projectiles[index].speed
        }
        projectiles.removeAll { $0.position.x > screenWidth }
        
        // Collisions (dans la même lane)
        for proj in projectiles {
            for i in zombies.indices {
                if zombies[i].lane == proj.lane && distance(proj.position, zombies[i].position) < 30 {
                    let multiplier = damageMultiplier(projectileType: proj.type, zombieType: zombies[i].type)
                    let damage = Int(CGFloat(proj.damage) * multiplier)
                    zombies[i].health -= damage
                    if zombies[i].health <= 0 {
                        zombies.remove(at: i)
                        score += 10
                    }
                    if let projIndex = projectiles.firstIndex(where: { $0.id == proj.id }) {
                        projectiles.remove(at: projIndex)
                    }
                    break
                }
            }
        }
        
        // Spawner de nouveaux zombies aléatoirement
        if Int.random(in: 0...100) < 2 {
            spawnZombie(screenWidth: screenWidth, laneHeight: laneHeight)
        }
        
        score += 1
    }
    
    func shoot(from tower: Tower, laneHeight: CGFloat) {
        shootingStates[tower.id] = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            shootingStates[tower.id] = false
        }
        
        let towersInLane = towers.filter { $0.lane == tower.lane }.sorted { $0.order < $1.order }
        let index = towersInLane.firstIndex(where: { $0.id == tower.id }) ?? 0
        let xPos = 50 + CGFloat(index) * 80
        
        let proj = Projectile(
            type: tower.pokemon.types.first?.type.name ?? "normal",
            lane: tower.lane,
            position: CGPoint(x: xPos + 40, y: getLaneCenter(for: tower.lane, laneHeight: laneHeight)),
            speed: 4,
            damage: tower.damage
        )
        projectiles.append(proj)
    }
    
    func spawnZombie(screenWidth: CGFloat, laneHeight: CGFloat) {
        let lane = Int.random(in: 0..<laneCount)
        let yPos = getLaneCenter(for: lane, laneHeight: laneHeight)
        let baseHealth: Int = 30
        let extraHealth = Int(CGFloat(score) / 150.0)  // Augmentation progressive
        let zombie = Zombie(
            lane: lane,
            position: CGPoint(x: screenWidth + 50, y: yPos),
            speed: CGFloat.random(in: 1...2),
            health: baseHealth + extraHealth,
            type: getRandomZombieType()
        )
        zombies.append(zombie)
    }
    
    func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        return sqrt(pow(a.x - b.x, 2) + pow(a.y - b.y, 2))
    }
    
    func damageMultiplier(projectileType: String, zombieType: String) -> CGFloat {
        let pt = projectileType.lowercased()
        let zt = zombieType.lowercased()
        if pt == "fire" && zt == "grass" {
            return 1.5
        } else if pt == "fire" && zt == "water" {
            return 0.5
        } else if pt == "water" && zt == "fire" {
            return 1.5
        } else if pt == "water" && zt == "electric" {
            return 0.5
        } else if pt == "grass" && zt == "water" {
            return 1.5
        } else if pt == "grass" && zt == "fire" {
            return 0.5
        } else if pt == "electric" && zt == "water" {
            return 1.5
        } else if pt == "electric" && zt == "grass" {
            return 0.5
        } else {
            return 1.0
        }
    }
    
    func getRandomPokemon() -> PokemonModel {
        let options: [PokemonModel] = [
            PokemonModel(id: 1, name: "Bulbasaur", sprites: PokemonSprites(frontDefault: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/1.png"), types: [PokemonType(type: TypeInfo(name: "grass"))], stats: [], detailUrl: nil),
            PokemonModel(id: 4, name: "Charmander", sprites: PokemonSprites(frontDefault: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/4.png"), types: [PokemonType(type: TypeInfo(name: "fire"))], stats: [], detailUrl: nil),
            PokemonModel(id: 7, name: "Squirtle", sprites: PokemonSprites(frontDefault: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/7.png"), types: [PokemonType(type: TypeInfo(name: "water"))], stats: [], detailUrl: nil),
            PokemonModel(id: 25, name: "Pikachu", sprites: PokemonSprites(frontDefault: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/25.png"), types: [PokemonType(type: TypeInfo(name: "electric"))], stats: [], detailUrl: nil),
            PokemonModel(id: 39, name: "Jigglypuff", sprites: PokemonSprites(frontDefault: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/39.png"), types: [PokemonType(type: TypeInfo(name: "normal"))], stats: [], detailUrl: nil)
        ]
        return options.randomElement()!
    }
    
    func getRandomZombieType() -> String {
        let types = ["grass", "fire", "water", "electric", "normal"]
        return types.randomElement()!
    }
}

struct Tower: Identifiable {
    let id = UUID()
    var pokemon: PokemonModel
    var lane: Int
    var order: Int   // Pour position horizontale
    var damage: Int  // Dégâts de la tour
    var fireRate: Double  // Intervalle de tir
}

struct Zombie: Identifiable {
    let id = UUID()
    var lane: Int
    var position: CGPoint
    var speed: CGFloat
    var health: Int
    var type: String
}

struct Projectile: Identifiable {
    let id = UUID()
    let type: String
    var lane: Int
    var position: CGPoint
    var speed: CGFloat
    let damage: Int
}

struct TowerView: View {
    let tower: Tower
    let xPosition: CGFloat
    let laneCenter: CGFloat
    
    var body: some View {
        if let url = URL(string: tower.pokemon.sprites.frontDefault ?? "") {
            AsyncImage(url: url) { phase in
                if let image = phase.image {
                    image.resizable()
                        .scaledToFit()
                        .offset(x: 0)
                        .animation(.easeInOut(duration: 0.1), value: 0)
                } else {
                    Color.gray
                }
            }
            .frame(width: 60, height: 60)
            .position(x: xPosition, y: laneCenter)
        }
    }
}

struct ZombieView: View {
    let zombie: Zombie
    
    var body: some View {
        let color: Color
        switch zombie.type.lowercased() {
        case "fire": color = .red
        case "water": color = .blue
        case "grass": color = .green
        case "electric": color = .yellow
        default: color = .gray
        }
        return Circle()
            .fill(color)
            .frame(width: 50, height: 50)
            .overlay(Text("\(zombie.health)").foregroundColor(.white))
            .position(zombie.position)
    }
}

struct ProjectileView: View {
    let projectile: Projectile
    
    var body: some View {
        let color: Color
        switch projectile.type.lowercased() {
        case "fire": color = .red
        case "water": color = .blue
        case "grass": color = .green
        case "electric": color = .yellow
        default: color = .white
        }
        return Circle()
            .fill(color)
            .frame(width: 20, height: 20)
            .position(projectile.position)
    }
}

struct PokemonVsZombiesVerticalView_Previews: PreviewProvider {
    static var previews: some View {
        let dummyList: [PokemonModel] = [
            PokemonModel(id: 1, name: "Bulbasaur", sprites: PokemonSprites(frontDefault: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/1.png"), types: [PokemonType(type: TypeInfo(name: "grass"))], stats: [], detailUrl: nil),
            PokemonModel(id: 4, name: "Charmander", sprites: PokemonSprites(frontDefault: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/4.png"), types: [PokemonType(type: TypeInfo(name: "fire"))], stats: [], detailUrl: nil),
            PokemonModel(id: 7, name: "Squirtle", sprites: PokemonSprites(frontDefault: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/7.png"), types: [PokemonType(type: TypeInfo(name: "water"))], stats: [], detailUrl: nil),
            PokemonModel(id: 25, name: "Pikachu", sprites: PokemonSprites(frontDefault: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/25.png"), types: [PokemonType(type: TypeInfo(name: "electric"))], stats: [], detailUrl: nil),
            PokemonModel(id: 39, name: "Jigglypuff", sprites: PokemonSprites(frontDefault: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/39.png"), types: [PokemonType(type: TypeInfo(name: "normal"))], stats: [], detailUrl: nil)
        ]
        PokemonVsZombiesVerticalView(allPokemons: dummyList, selectedPokemon: dummyList[0])
    }
}
