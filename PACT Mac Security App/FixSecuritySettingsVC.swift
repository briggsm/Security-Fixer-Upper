//
//  FixSecuritySettingsVC.swift
//  PACT Mac Security App
//
//  Created by Mark Briggs on 11/14/16.
//  Copyright © 2016 Mark Briggs. All rights reserved.
//

import Cocoa

class FixSecuritySettingsVC: NSViewController {

    let settingsToQuery = ["screensaver5sec.sh", "screensaver10min.sh"]
    
    @IBOutlet weak var settingsStackView: NSStackView!
    @IBOutlet weak var fixAllBtn: NSButton!
    
    override func viewDidAppear() {
        // Add (Version Number) to title of Main GUI's Window
        let appName = Bundle.main.infoDictionary![kCFBundleNameKey as String] as! String
        let appVersion = Bundle.main.infoDictionary![kCFBundleVersionKey as String] as! String
        self.view.window?.title = "\(appName) (v\(appVersion))"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Build the list of Security Settings for the Main GUI
        for settingToQuery in settingsToQuery {
            
            let aTaskOutput = runTask(taskFilename: settingToQuery, arguments: ["-a"])  // -a => Applicable given user's OS Version.
            if aTaskOutput == "true" {

                // Setup Status Image
                let statusImgView = NSImageView(image: NSImage(named: "greyQM")!)
                statusImgView.identifier = settingToQuery
                
                // Setup Setting Description Label
                let dTaskOutput = runTask(taskFilename: settingToQuery, arguments: ["-d"])  // -d => Get Description
                let settingDescLabel = NSTextField(labelWithString: dTaskOutput)

                // Setup FixIt Button
                let fixItBtn = NSButton(title: "Fix It!", target: self, action: #selector(fixItBtnClicked))
                fixItBtn.identifier = settingToQuery
                
                // Create StackView
                let entryStackView = NSStackView()  // Default is Horizontal
                entryStackView.alignment = .centerY
                entryStackView.spacing = 10
                entryStackView.distribution = .gravityAreas

                // Add Image, Label, and Button to StackView
                entryStackView.addView(statusImgView, in: .leading)
                entryStackView.addView(settingDescLabel, in: .leading)
                entryStackView.addView(fixItBtn, in: .leading)
                
                // Add our entryStackView to the settingsStackView
                settingsStackView.addView(entryStackView, in: NSStackViewGravity.top)
            }
        }
        
        // Update all Status Images & FixIt Button visibilities.
        updateAllStatusImagesAndFixItBtns()
    }
    
    func getImgNameFor(pfString: String) -> String {
        if pfString == "pass" {
            return "greenCheck"
        } else if pfString == "fail" {
            return "redX"
        } else {
            // Uh oh, unknow state. Shouldn't get here.
            return "greyQM"
        }
    }
    
    func runTask(taskFilename: String, arguments: [String]) -> String {
        // Note: Running in Main thread because it's not going take long at all (if it does, something is majorly wrong).
        
        print("runTask: \(taskFilename) \(arguments[0]) ", terminator: "")  // Finish this print statement at end of runTask() function

        // Make sure we can find the script file. Return if not.
        let settingNameArr = taskFilename.components(separatedBy: ".")
        guard let path = Bundle.main.path(forResource: settingNameArr[0], ofType:settingNameArr[1]) else {
            print("\n  Unable to locate: \(taskFilename)!")
            return "Unable to locate: \(taskFilename)!"
        }
        
        // Init outputPipe
        let outputPipe = Pipe()
        
        // Setup & Launch our process
        let ps: Process = Process()
        ps.launchPath = path
        ps.arguments = arguments
        ps.standardOutput = outputPipe
        ps.launch()
        ps.waitUntilExit()

        // Read everything the outputPipe captured from stdout
        let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
        var outputString = String(data: data, encoding: String.Encoding.utf8) ?? ""
        outputString = outputString.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Return the output
        print("[output: \(outputString)]")
        return outputString
    }
    
    func fixItBtnClicked(btn: NSButton) {
        let settingToQuery = btn.identifier ?? ""
        if !settingToQuery.isEmpty {
            _ = runTask(taskFilename: settingToQuery, arguments: ["-w"])  // -w => Write Setting
            updateAllStatusImagesAndFixItBtns()
        }
    }

    @IBAction func fixAllBtnClicked(_ sender: NSButton) {
        for settingToQuery in settingsToQuery {
            let aTaskOutput = runTask(taskFilename: settingToQuery, arguments: ["-a"])  // -a => Applicable given user's OS Version.
            if aTaskOutput == "true" {
                let pfTaskOutput = runTask(taskFilename: settingToQuery, arguments: ["-pf"])  // -pf => Return "pass" or "fail" security test
                if pfTaskOutput != "pass" {
                    _ = runTask(taskFilename: settingToQuery, arguments: ["-w"])  // -w => Write Setting
                }
            }
        }
        
        updateAllStatusImagesAndFixItBtns()
    }
    
    func updateAllStatusImagesAndFixItBtns() {
        var allSettingsFixed = true
        
        // Iterate through all our entryStackViews, finding the image views and buttons.
        for entryStackView in settingsStackView.views as! [NSStackView] {
            if let statusImgView = entryStackView.views.first as! NSImageView? , let fixItBtn = entryStackView.views.last as! NSButton? {
                let settingToQuery = statusImgView.identifier ?? ""
                if !settingToQuery.isEmpty {
                    let pfTaskOutput = runTask(taskFilename: settingToQuery, arguments: ["-pf"])  // -pf => Return "pass" or "fail" security test
                    
                    // Update statusImageView & fixItBtn
                    statusImgView.image = NSImage(named: getImgNameFor(pfString: pfTaskOutput))
                    fixItBtn.isHidden = pfTaskOutput == "pass"
                    
                    if pfTaskOutput != "pass" {
                        allSettingsFixed = false
                    }
                }
            }
        }
        
        // If all settings are fixed, disable the "Fix All" button
        if allSettingsFixed {
            fixAllBtn.isEnabled = false
        }
    }
}
