//
//  ProspectsView.swift
//  HotProspects
//
//  Created by Jan Andrzejewski on 23/07/2022.
//

import SwiftUI
import CodeScanner
import UserNotifications

struct ProspectsView: View {
    @State private var isShowingScanner = false
    
    @EnvironmentObject var prospects: Prospects
    enum FilterType {
        case none, contacted, uncontacted
    }
    
    let filter: FilterType
    
    var title: String {
        switch filter {
        case .none:
            return "Everyone"
        case .contacted:
            return "Contected people"
        case .uncontacted:
            return "Uncontacted people"
        }
    }
    
    var filteredProspects: [Prospect] {
        switch filter {
        case .none:
            return prospects.people
        case .contacted:
            return prospects.people.filter { $0.isContacted }
        case .uncontacted:
            return prospects.people.filter { !$0.isContacted }
        }
    }
    
    enum SortType {
        case recent, name
    }
    
    @State private var sort: SortType = .recent
    
    var fileteredAndSortedProspects: [Prospect] {
        switch sort {
        case .recent:
            return prospects.people
        case .name:
            let preSortedProspects = prospects.people.sorted { $0.name > $1.name }
            return preSortedProspects
        }
    }
    
    @State private var showingConfirmationDialog = false
    var body: some View {
        NavigationView {
            List {
                ForEach(filteredProspects) { prospect in
                    VStack(alignment: .leading) {
                        HStack {
                            Image(systemName: prospect.isContacted == true ? "person.fill.checkmark" : "person.fill.xmark")
                                .foregroundColor(prospect.isContacted == true ? .green : .red)
                            Text(prospect.name)
                                .font(.headline)
                        }
                        Text(prospect.emailAddress)
                            .foregroundColor(.secondary)
                    }
                    .swipeActions {
                        if prospect.isContacted {
                            Button {
                                prospects.toggle(prospect)
                            } label: {
                                Label("Mark Uncontacted",systemImage: "person.crop.circle.badge.xmark")
                            }
                            .tint(.red)
                        } else {
                            Button {
                                prospects.toggle(prospect)
                            } label: {
                                Label("Mark Contacted", systemImage: "person.crop.circle.fill.badge.checkmark")
                            }
                            .tint(.green)
                            
                            Button {
                                addNotification(for: prospect)
                            } label: {
                                Label("Remind Me", systemImage: "bell")
                            }
                            .tint(.blue)
                        }
                    }
                }
            }
                .navigationTitle(title)
                .toolbar {
                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                        Button {
                            isShowingScanner = true
                        } label: {
                            Label("Scam", systemImage: "qrcode.viewfinder")
                        }
                        Button {
                            showingConfirmationDialog = true
                        } label: {
                            Label("Change sorting", systemImage: "arrow.up.arrow.down")
                        }

                    }

                }
                    .sheet(isPresented: $isShowingScanner) {
                    CodeScannerView(codeTypes: [.qr], simulatedData: "Paul Hudson\npaul@hackingwithswift.com", completion: handleScan)
                }
                .confirmationDialog("Sort prospects by", isPresented: $showingConfirmationDialog) {
                    Button("Most Recent") {
                        sort = SortType.recent
                    }
                    Button("Name") {
                        sort = SortType.name
                    }
                }
        }
    }
    
    func handleScan(result: Result<ScanResult, ScanError>) {
        isShowingScanner = false
        
        switch result {
        case .success(let result):
            let details = result.string.components(separatedBy: "\n")
            guard details.count == 2 else { return }
            
            let person = Prospect()
            person.name = details[0]
            person.emailAddress = details[1]
            
            prospects.add(person)
            
        case .failure(let error):
            print("Scanning failed: \(error.localizedDescription)")
        }
    }
    
    func addNotification( for prospect: Prospect) {
        let center = UNUserNotificationCenter.current()
        
        let addRequest = {
            let content = UNMutableNotificationContent()
            content.title = "Contact \(prospect.name)"
            content.subtitle = prospect.emailAddress
            content.sound = UNNotificationSound.default
            
            var dateComponents = DateComponents()
            dateComponents.hour = 9
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
            
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
            center.add(request)
        }
        
        center.getNotificationSettings() { settings in
            if settings.authorizationStatus == .authorized {
                addRequest()
            } else {
                center.requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
                    if success {
                        addRequest()
                    } else {
                        print("Notification permission not allowed.")
                    }
                }
            }
        }
    }
}

struct ProspectsView_Previews: PreviewProvider {
    static var previews: some View {
        ProspectsView(filter: .none)
    }
}
