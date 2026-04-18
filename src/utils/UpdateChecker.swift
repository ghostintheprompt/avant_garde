import Foundation
import SwiftUI
import AppKit

class UpdateChecker: ObservableObject {
    static let shared = UpdateChecker()
    
    private let repoOwner = "ghostintheprompt"
    private let repoName = "avant_garde"
    
    @Published var isChecking = false
    @Published var latestVersion: String?
    @Published var updateURL: URL?
    @Published var updateAvailable = false
    
    private let currentVersion = "1.0.1"
    
    func checkForUpdates(isAutoCheck: Bool = false) {
        guard !isChecking else { return }
        isChecking = true
        
        let urlString = "https://api.github.com/repos/\(repoOwner)/\(repoName)/releases/latest"
        guard let url = URL(string: urlString) else {
            isChecking = false
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.setValue("AvantGarde-UpdateChecker", forHTTPHeaderField: "User-Agent")
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isChecking = false
                
                guard let data = data, error == nil else {
                    if !isAutoCheck { self?.showErrorAlert() }
                    return
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let tagName = json["tag_name"] as? String,
                       let htmlUrl = json["html_url"] as? String {
                        
                        let cleanTagName = tagName.replacingOccurrences(of: "v", with: "")
                        
                        // Precise version check: only update if remote > current
                        let comparison = self?.currentVersion.compare(cleanTagName, options: .numeric)
                        
                        if comparison == .orderedAscending {
                            self?.latestVersion = tagName
                            self?.updateURL = URL(string: htmlUrl)
                            self?.updateAvailable = true
                            self?.showUpdateAlert(version: tagName, url: htmlUrl)
                        } else {
                            self?.updateAvailable = false
                            if !isAutoCheck {
                                self?.showUpToDateAlert()
                            }
                        }
                    }
                } catch {
                    if !isAutoCheck { self?.showErrorAlert() }
                }
            }
        }.resume()
    }
    
    private func showUpdateAlert(version: String, url: String) {
        let alert = NSAlert()
        alert.messageText = "Update Available"
        alert.informativeText = "A new version of Avant Garde (\(version)) is available. Would you like to download it now?"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Download")
        alert.addButton(withTitle: "Later")
        
        if alert.runModal() == .alertFirstButtonReturn {
            if let downloadURL = URL(string: url) {
                NSWorkspace.shared.open(downloadURL)
            }
        }
    }
    
    private func showUpToDateAlert() {
        let alert = NSAlert()
        alert.messageText = "Up to Date"
        alert.informativeText = "Avant Garde \(currentVersion) is the latest version."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    private func showErrorAlert() {
        let alert = NSAlert()
        alert.messageText = "Update Check Failed"
        alert.informativeText = "Could not connect to GitHub to check for updates. Please try again later."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
