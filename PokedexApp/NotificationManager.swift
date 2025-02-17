//
//  NotificationManager.swift
//  PokedexApp
//
//  Created by Ethan LEGROS on 2/17/25.
//

import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()

    // Demander la permission pour les notifications
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("✅ Notifications autorisées")
            } else {
                print("⚠️ Notifications refusées : \(error?.localizedDescription ?? "Inconnu")")
            }
        }
    }

    // Planifier une notification quotidienne
    func scheduleDailyPokemonNotification() {
        let content = UNMutableNotificationContent()
        content.title = "🎯 Pokémon du Jour !"
        content.body = getRandomPokemonMessage()
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = 10  // Notification à 10h chaque jour

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "dailyPokemonNotification", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Erreur lors de la planification de la notification : \(error)")
            } else {
                print("✅ Notification quotidienne programmée !")
            }
        }
    }

    // Simuler une notification lorsque le type d'un favori change
    func simulateFavoriteTypeChangeNotification(pokemonName: String, oldType: String, newType: String) {
        let content = UNMutableNotificationContent()
        content.title = "⚠️ Changement de Type !"
        content.body = "\(pokemonName) a changé de type : de \(oldType.capitalized) à \(newType.capitalized) !"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)

        let request = UNNotificationRequest(identifier: "favoriteTypeChangeNotification", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Erreur lors de la notification : \(error)")
            } else {
                print("✅ Notification de changement de type envoyée !")
            }
        }
    }

    // Générer un message aléatoire avec un Pokémon
    private func getRandomPokemonMessage() -> String {
        let pokemons = ["Pikachu", "Bulbizarre", "Salamèche", "Carapuce", "Evoli", "Dracaufeu", "Rondoudou", "Goupix", "Magicarpe", "Mewtwo"]
        let pokemon = pokemons.randomElement() ?? "Pikachu"
        return "Aujourd'hui, découvrez \(pokemon) ! 🔍"
    }
}
