//
//  AppDelegate.swift
//  RealmSample
//
//  Created by Administrator on 01/03/24.
//

import UIKit
import RealmSwift

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    // Initialize Realm app
        let app = App(id: loadAppConfig().appId, configuration: AppConfiguration(baseURL: loadAppConfig().baseUrl, transport: nil))
        
        // Initialize error handler
        var errorHandler: ErrorHandler?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        errorHandler = ErrorHandler(app: app)
        if let atlasUrl = loadAppConfig().atlasUrl {
            print("To view your data in Atlas, go to this link: " + atlasUrl)
            
        }
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

// Define the error handler class
final class ErrorHandler {
    var error: Swift.Error?

    // Initialize with app instance
    init(app: RealmSwift.App) {
        app.syncManager.errorHandler = { syncError, syncSession in
            self.error = syncError
        }
    }
}
