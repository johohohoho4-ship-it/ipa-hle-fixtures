//
//  AppDelegate.swift
//  SwiftUITodo
//
//  Created by Suyeol Jeon on 03/06/2019.
//  Copyright © 2019 Suyeol Jeon. All rights reserved.
//
//  Corpus fixture: `@UIApplicationMain` became `@main`, and the global scene
//  delegate from 2019 was replaced by the window setup in `didFinishLaunching`.
//  The root is still `UIHostingController(rootView: NavigationView { TaskListView() })`.
//

import UIKit
import SwiftUI

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    let window = UIWindow(frame: UIScreen.main.bounds)
    window.rootViewController = UIHostingController(rootView: NavigationView {
      TaskListView().environmentObject(UserData())
    })
    window.makeKeyAndVisible()
    self.window = window
    return true
  }

  func applicationWillTerminate(_ application: UIApplication) {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
  }
}
