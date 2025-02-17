//
//  BattleView.swift
//  PokedexApp
//
//  Created by Ethan LEGROS on 2/17/25.
//

import SwiftUI

struct BattleView: View {
    let leftPokemon: PokemonModel
    let availableOpponents: [PokemonModel]
    
    @State private var opponent: PokemonModel
    @State private var arenaURL: String = ""
    
    // Positions initiales (plus centrées)
    @State private var leftOffset: CGFloat = -40
    @State private var rightOffset: CGFloat = 40

    // Pour les animations finales (scale et rotation)
    @State private var leftScale: CGFloat = 1.0
    @State private var rightScale: CGFloat = 1.0
    @State private var leftRotation: Angle = .zero
    @State private var rightRotation: Angle = .zero

    // États du combat
    @State private var battleFinished = false
    @State private var winnerMessage: String = ""
    @State private var showConfetti = false

    // Contrôle des attaques (alternance)
    @State private var turn: Int = 0    // 0: attaque de gauche, 1: attaque de l'adversaire
    @State private var attackCount: Int = 0
    @State private var totalAttacks: Int = 0

    // Effet flash pendant une attaque
    @State private var attackFlash: Bool = false

    // Durée du combat en fonction de la différence de puissance
    var fightDuration: Double {
        let leftPower = leftPokemon.attack + leftPokemon.defense + leftPokemon.speed
        let rightPower = opponent.attack + opponent.defense + opponent.speed
        let difference = abs(leftPower - rightPower)
        if difference < 20 {
            return 5.0
        } else if difference < 50 {
            return 4.0
        } else {
            return 3.0
        }
    }
    
    // Détermine le vainqueur selon la somme des stats
    var winner: PokemonModel {
        let leftPower = leftPokemon.attack + leftPokemon.defense + leftPokemon.speed
        let rightPower = opponent.attack + opponent.defense + opponent.speed
        return leftPower >= rightPower ? leftPokemon : opponent
    }
    
    // MARK: - Initialisation
    init(leftPokemon: PokemonModel, initialOpponent: PokemonModel, availableOpponents: [PokemonModel]) {
        self.leftPokemon = leftPokemon
        self.availableOpponents = availableOpponents
        _opponent = State(initialValue: initialOpponent)
    }
    
    var body: some View {
        ZStack {
            // Fond d'arène stable et recadré
            AsyncImage(url: URL(string: arenaURL)) { phase in
                if let image = phase.image {
                    image.resizable()
                         .aspectRatio(contentMode: .fill)
                         .frame(maxWidth: .infinity, maxHeight: .infinity)
                         .clipped()
                         .ignoresSafeArea()
                } else if phase.error != nil {
                    Color.gray.ignoresSafeArea()
                } else {
                    ProgressView().ignoresSafeArea()
                }
            }
            
            // Effet flash lors d'une attaque
            if attackFlash {
                Color.white
                    .opacity(0.3)
                    .blendMode(.plusLighter)
                    .ignoresSafeArea()
            }
            
            // Contenu principal du combat
            VStack {
                // Bandeau avec noms et stats
                HStack {
                    VStack {
                        Text(leftPokemon.formattedName)
                            .font(.headline)
                        Text("Power: \(leftPokemon.attack + leftPokemon.defense + leftPokemon.speed)")
                            .font(.subheadline)
                    }
                    Spacer()
                    VStack {
                        Text(opponent.formattedName)
                            .font(.headline)
                        Text("Power: \(opponent.attack + opponent.defense + opponent.speed)")
                            .font(.subheadline)
                    }
                }
                .padding()
                .background(Color.white.opacity(0.7))
                .cornerRadius(10)
                
                Spacer()
                
                // Zone de combat avec les images des Pokémon
                HStack {
                    AsyncImage(url: URL(string: leftPokemon.sprites.frontDefault ?? "")) { phase in
                        if let image = phase.image {
                            image.resizable().scaledToFit()
                        } else if phase.error != nil {
                            Color.red
                        } else {
                            ProgressView()
                        }
                    }
                    .frame(width: 150, height: 150)
                    .offset(x: leftOffset)
                    .scaleEffect(leftScale)
                    .rotationEffect(leftRotation)
                    .animation(.easeInOut(duration: 0.3), value: leftOffset)
                    .animation(.easeInOut(duration: 0.3), value: leftScale)
                    .animation(.easeInOut(duration: 0.3), value: leftRotation)
                    
                    Spacer()
                    
                    AsyncImage(url: URL(string: opponent.sprites.frontDefault ?? "")) { phase in
                        if let image = phase.image {
                            image.resizable().scaledToFit()
                        } else if phase.error != nil {
                            Color.red
                        } else {
                            ProgressView()
                        }
                    }
                    .frame(width: 150, height: 150)
                    .offset(x: rightOffset)
                    .scaleEffect(rightScale)
                    .rotationEffect(rightRotation)
                    .animation(.easeInOut(duration: 0.3), value: rightOffset)
                    .animation(.easeInOut(duration: 0.3), value: rightScale)
                    .animation(.easeInOut(duration: 0.3), value: rightRotation)
                }
                .padding()
                
                Spacer()
                
                if battleFinished {
                    Text(winnerMessage)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                        .padding()
                }
                
                // Boutons de contrôle du combat
                if battleFinished {
                    HStack {
                        Button(action: {
                            startBattle()
                        }) {
                            Text("Rejouer")
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        Button(action: {
                            changeOpponent()
                        }) {
                            Text("Changer d'adversaire")
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                    .padding()
                } else {
                    Button(action: {
                        startBattle()
                    }) {
                        Text("Lancer le combat")
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding()
                }
                
                Spacer()
            }
            .padding()
            .background(Color.white.opacity(0.7))
            .cornerRadius(15)
            .padding()
            
            if showConfetti {
                ConfettiView()
                    .transition(.opacity)
            }
        }
        .navigationBarTitle("Combat", displayMode: .inline)
        .onAppear {
            if arenaURL.isEmpty {
                arenaURL = randomArenaURL()
            }
        }
    }
    
    // Lancement du combat (avec nouvelle arène)
    func startBattle() {
        arenaURL = randomArenaURL()  // Nouvelle arène pour chaque nouveau combat
        battleFinished = false
        winnerMessage = ""
        showConfetti = false
        turn = 0
        attackCount = 0
        totalAttacks = Int(fightDuration / 0.8)
        leftOffset = -40
        rightOffset = 40
        leftScale = 1.0
        rightScale = 1.0
        leftRotation = .zero
        rightRotation = .zero
        
        performAttack()
    }
    
    // Simulation des attaques en alternance
    func performAttack() {
        guard attackCount < totalAttacks else {
            endBattle()
            return
        }
        
        if turn == 0 {
            withAnimation(.easeInOut(duration: 0.4)) {
                leftOffset = 20
                attackFlash = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                attackFlash = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(.easeInOut(duration: 0.4)) {
                    leftOffset = -40
                }
                attackCount += 1
                turn = 1
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    performAttack()
                }
            }
        } else {
            withAnimation(.easeInOut(duration: 0.4)) {
                rightOffset = -20
                attackFlash = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                attackFlash = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(.easeInOut(duration: 0.4)) {
                    rightOffset = 40
                }
                attackCount += 1
                turn = 0
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    performAttack()
                }
            }
        }
    }
    
    // Fin du combat et animation finale
    func endBattle() {
        battleFinished = true
        let winPokemon = winner
        winnerMessage = "\(winPokemon.formattedName) a gagné !"
        
        if winPokemon.id == leftPokemon.id {
            withAnimation(.easeInOut(duration: 0.5)) {
                leftScale = 1.5
                leftOffset = 0
            }
            withAnimation(.easeInOut(duration: 0.5)) {
                rightRotation = .degrees(90)
            }
        } else {
            withAnimation(.easeInOut(duration: 0.5)) {
                rightScale = 1.5
                rightOffset = 0
            }
            withAnimation(.easeInOut(duration: 0.5)) {
                leftRotation = .degrees(90)
            }
        }
        withAnimation(Animation.easeInOut(duration: 1).delay(0.5)) {
            showConfetti = true
        }
    }
    
    // Changer d'adversaire en sélectionnant un Pokémon aléatoire dans la liste (différent du leftPokemon)
    func changeOpponent() {
        let possibles = availableOpponents.filter { $0.id != leftPokemon.id }
        if let newOpponent = possibles.randomElement() {
            opponent = newOpponent
        }
        startBattle()
    }
    
    // Retourne une URL d'image d'arène aléatoire
    func randomArenaURL() -> String {
        let urls = [
            "https://i.pinimg.com/736x/0a/d7/40/0ad740bdde2d5ed0f5a641ebefaff38b.jpg",
            "https://pokemonblog.com/wp-content/uploads/2020/05/pokemon_sword_and_shield_poke_ball_wallpaper.jpg?w=584",
            "https://www.pokemon.com/static-assets/content-assets/cms2/img/misc/virtual-backgrounds/sword-shield/dynamax-battle.png"
        ]
        return urls.randomElement()!
    }
}

struct ConfettiView: View {
    @State private var confettiItems: [ConfettiItem] = []
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(confettiItems) { item in
                    Circle()
                        .fill(item.color)
                        .frame(width: item.size, height: item.size)
                        .position(item.position)
                        .opacity(item.opacity)
                        .animation(Animation.linear(duration: item.duration).repeatForever(autoreverses: false), value: item.position)
                }
            }
            .onAppear {
                confettiItems = (0..<50).map { _ in
                    ConfettiItem(
                        id: UUID(),
                        color: Color(hue: Double.random(in: 0...1), saturation: 0.8, brightness: 0.9),
                        size: CGFloat.random(in: 5...10),
                        position: CGPoint(x: CGFloat.random(in: 0...geometry.size.width), y: -10),
                        opacity: 1,
                        duration: Double.random(in: 2...4)
                    )
                }
                for index in confettiItems.indices {
                    withAnimation(Animation.linear(duration: confettiItems[index].duration)) {
                        confettiItems[index].position.y = geometry.size.height + 10
                        confettiItems[index].opacity = 0
                    }
                }
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
}

struct ConfettiItem: Identifiable {
    let id: UUID
    let color: Color
    let size: CGFloat
    var position: CGPoint
    var opacity: Double
    let duration: Double
}

#if DEBUG
struct BattleView_Previews: PreviewProvider {
    static var previews: some View {
        let leftStats: [PokemonStat] = [
            PokemonStat(baseStat: 49, stat: StatInfo(name: "attack")),
            PokemonStat(baseStat: 49, stat: StatInfo(name: "defense")),
            PokemonStat(baseStat: 45, stat: StatInfo(name: "speed"))
        ]
        let leftPokemon = PokemonModel(
            id: 1,
            name: "Bulbasaur",
            sprites: PokemonSprites(frontDefault: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/1.png"),
            types: [PokemonType(type: TypeInfo(name: "grass"))],
            stats: leftStats,
            detailUrl: nil
        )
        let sampleOpponents: [PokemonModel] = [
            PokemonModel(
                id: 25,
                name: "Pikachu",
                sprites: PokemonSprites(frontDefault: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/25.png"),
                types: [PokemonType(type: TypeInfo(name: "electric"))],
                stats: [
                    PokemonStat(baseStat: 55, stat: StatInfo(name: "attack")),
                    PokemonStat(baseStat: 40, stat: StatInfo(name: "defense")),
                    PokemonStat(baseStat: 90, stat: StatInfo(name: "speed"))
                ],
                detailUrl: nil
            ),
            PokemonModel(
                id: 4,
                name: "Charmander",
                sprites: PokemonSprites(frontDefault: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/4.png"),
                types: [PokemonType(type: TypeInfo(name: "fire"))],
                stats: [
                    PokemonStat(baseStat: 52, stat: StatInfo(name: "attack")),
                    PokemonStat(baseStat: 43, stat: StatInfo(name: "defense")),
                    PokemonStat(baseStat: 65, stat: StatInfo(name: "speed"))
                ],
                detailUrl: nil
            ),
            PokemonModel(
                id: 7,
                name: "Squirtle",
                sprites: PokemonSprites(frontDefault: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/7.png"),
                types: [PokemonType(type: TypeInfo(name: "water"))],
                stats: [
                    PokemonStat(baseStat: 48, stat: StatInfo(name: "attack")),
                    PokemonStat(baseStat: 65, stat: StatInfo(name: "defense")),
                    PokemonStat(baseStat: 43, stat: StatInfo(name: "speed"))
                ],
                detailUrl: nil
            )
        ]
        NavigationView {
            BattleView(leftPokemon: leftPokemon, initialOpponent: sampleOpponents[0], availableOpponents: sampleOpponents)
        }
    }
}
#endif

extension PokemonStat {
    init(baseStat: Int, stat: StatInfo) {
        self.baseStat = baseStat
        self.stat = stat
    }
}
