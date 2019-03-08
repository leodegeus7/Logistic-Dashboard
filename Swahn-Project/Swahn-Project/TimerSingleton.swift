//
//  TimerSingleton.swift
//  Swahn-Project
//
//  Created by Leonardo Geus on 02/08/2018.
//  Copyright © 2018 Leonardo Geus. All rights reserved.
//

import UIKit

class TimerSingleton: NSObject {
    static let shared = TimerSingleton()
    
    var timer:Timer!
    var secondsCount = 0.0
    var isPaused = false
    
    func startTimer(completion: @escaping (Double) -> Void) {
        if let _ = timer {
            
        } else {
            secondsCount = 0
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { (timer) in
                if !self.isPaused {
                    self.secondsCount = self.secondsCount + 1

                    completion(self.secondsCount)
                }
            })
        }
    }
    
    func pauseTimer() {
        isPaused = true
    }
    
    func resumeTimer() {
        isPaused = false
    }
    
    func restartTimer() {
        self.secondsCount = 0
    }
    
    func stopTimer() {
        self.timer.invalidate()
        self.timer = nil
    }
}
