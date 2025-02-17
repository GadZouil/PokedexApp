//
//  BattleView.swift
//  PokedexApp
//
//  Created by Ethan LEGROS on 2/17/25.
//

import SwiftUI

struct BattleView: View {
    let leftPokemon: PokemonModel
    let rightPokemon: PokemonModel

    // Positions initiales sur l'écran
    @State private var leftOffset: CGFloat = -50
    @State private var rightOffset: CGFloat = 50

    // Pour l'animation finale (scale et rotation)
    @State private var leftScale: CGFloat = 1.0
    @State private var rightScale: CGFloat = 1.0
    @State private var leftRotation: Angle = .zero
    @State private var rightRotation: Angle = .zero

    // Etats du combat
    @State private var battleFinished = false
    @State private var winnerMessage: String = ""
    @State private var showConfetti = false

    // Contrôle des attaques
    @State private var turn: Int = 0    // 0 : attaque de gauche, 1 : attaque de droite
    @State private var attackCount: Int = 0
    @State private var totalAttacks: Int = 0

    // Durée du combat (en secondes) en fonction de la différence de puissance
    var fightDuration: Double {
        let leftPower = leftPokemon.attack + leftPokemon.defense + leftPokemon.speed
        let rightPower = rightPokemon.attack + rightPokemon.defense + rightPokemon.speed
        let difference = abs(leftPower - rightPower)
        if difference < 20 {
            return 5.0
        } else if difference < 50 {
            return 4.0
        } else {
            return 3.0
        }
    }

    // Détermine le vainqueur en comparant la somme des stats
    var winner: PokemonModel {
        let leftPower = leftPokemon.attack + leftPokemon.defense + leftPokemon.speed
        let rightPower = rightPokemon.attack + rightPokemon.defense + rightPokemon.speed
        return leftPower >= rightPower ? leftPokemon : rightPokemon
    }

    var body: some View {
        ZStack {
            Color.white.edgesIgnoringSafeArea(.all)

            VStack {
                // Affichage des stats de base en haut
                HStack {
                    VStack {
                        Text(leftPokemon.formattedName)
                            .font(.headline)
                        Text("Power: \(leftPokemon.attack + leftPokemon.defense + leftPokemon.speed)")
                            .font(.subheadline)
                    }
                    Spacer()
                    VStack {
                        Text(rightPokemon.formattedName)
                            .font(.headline)
                        Text("Power: \(rightPokemon.attack + rightPokemon.defense + rightPokemon.speed)")
                            .font(.subheadline)
                    }
                }
                .padding()

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

                    AsyncImage(url: URL(string: rightPokemon.sprites.frontDefault ?? "")) { phase in
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

                // Bouton pour lancer (ou relancer) le combat
                Button(action: {
                    startBattle()
                }) {
                    Text(battleFinished ? "Rejouer" : "Lancer le combat")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()

                Spacer()
            }

            if showConfetti {
                ConfettiView()
                    .transition(.opacity)
            }
        }
        .navigationBarTitle("Combat", displayMode: .inline)
    }

    // Démarre le combat en réinitialisant les états et en programmant les attaques
    func startBattle() {
        battleFinished = false
        winnerMessage = ""
        showConfetti = false
        turn = 0
        attackCount = 0
        totalAttacks = Int(fightDuration / 0.8)
        leftOffset = -50
        rightOffset = 50
        leftScale = 1.0
        rightScale = 1.0
        leftRotation = .zero
        rightRotation = .zero

        performAttack()
    }

    // Exécute une attaque selon le tour en cours
    func performAttack() {
        guard attackCount < totalAttacks else {
            endBattle()
            return
        }
        
        if turn == 0 {
            // Attaque du Pokémon de gauche : il avance puis recule
            withAnimation(.easeInOut(duration: 0.4)) {
                leftOffset = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(.easeInOut(duration: 0.4)) {
                    leftOffset = -50
                }
                attackCount += 1
                turn = 1
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    performAttack()
                }
            }
        } else {
            // Attaque du Pokémon de droite : il avance puis recule
            withAnimation(.easeInOut(duration: 0.4)) {
                rightOffset = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(.easeInOut(duration: 0.4)) {
                    rightOffset = 50
                }
                attackCount += 1
                turn = 0
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    performAttack()
                }
            }
        }
    }

    // Termine le combat : détermine le vainqueur et lance l'animation finale
    func endBattle() {
        battleFinished = true
        let winPokemon = winner
        winnerMessage = "\(winPokemon.formattedName) a gagné !"
        
        // Animation finale : le gagnant grossit et se centre, le perdant pivote à 90°
        if winPokemon.id == leftPokemon.id {
            // Le Pokémon de gauche gagne
            withAnimation(.easeInOut(duration: 0.5)) {
                leftScale = 1.5
                leftOffset = 0
            }
            withAnimation(.easeInOut(duration: 0.5)) {
                rightRotation = .degrees(90)
            }
        } else {
            // Le Pokémon de droite gagne
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
}

// Vue simple de confettis (ici des émojis 🎉)
struct ConfettiView: View {
    @State private var confettiItems: [ConfettiItem] = []

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(confettiItems) { item in
                    Text(item.emoji)
                        .font(.largeTitle)
                        .position(item.position)
                        .opacity(item.opacity)
                        .animation(.linear(duration: item.duration).repeatForever(autoreverses: false), value: item.position)
                }
            }
            .onAppear {
                confettiItems = (0..<20).map { _ in
                    ConfettiItem(
                        id: UUID(),
                        emoji: "🎉",
                        position: CGPoint(x: CGFloat.random(in: 0...geometry.size.width),
                                          y: -50),
                        opacity: 1,
                        duration: Double.random(in: 2...4)
                    )
                }
                for index in confettiItems.indices {
                    withAnimation(Animation.linear(duration: confettiItems[index].duration)) {
                        confettiItems[index].position.y = geometry.size.height + 50
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
    let emoji: String
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
        let rightStats: [PokemonStat] = [
            PokemonStat(baseStat: 52, stat: StatInfo(name: "attack")),
            PokemonStat(baseStat: 43, stat: StatInfo(name: "defense")),
            PokemonStat(baseStat: 65, stat: StatInfo(name: "speed"))
        ]
        let rightPokemon = PokemonModel(
            id: 4,
            name: "Charmander",
            sprites: PokemonSprites(frontDefault: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/4.png"),
            types: [PokemonType(type: TypeInfo(name: "fire"))],
            stats: rightStats,
            detailUrl: nil
        )
        NavigationView {
            BattleView(leftPokemon: leftPokemon, rightPokemon: rightPokemon)
        }
    }
}
#endif

// Extension pour faciliter la création d'une stat (si nécessaire)
extension PokemonStat {
    init(baseStat: Int, stat: StatInfo) {
        self.baseStat = baseStat
        self.stat = stat
    }
}
