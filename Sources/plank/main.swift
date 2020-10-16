//
//  main.swift
//  Plank
//
//  Created by Rahul Malik on 7/22/15.
//  Copyright © 2015 Rahul Malik. All rights reserved.
//

import Foundation

func handleProcess(processInfo: ProcessInfo) {
    let arguments = processInfo.arguments.dropFirst() // Drop executable name
//    let arguments = ["--objc_class_prefix=PUG", "--no_runtime", "--no_recursive", "/Users/elijah/Workspace/company/tantan/pugdatamodel/json/livePkPlayer.json"] // livePkPlayer liveModel

    handleGenerateCommand(withArguments: Array(arguments))
}

handleProcess(processInfo: ProcessInfo.processInfo)
