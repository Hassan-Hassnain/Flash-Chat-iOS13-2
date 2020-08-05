//
//  ChatViewController.swift
//  Flash Chat iOS13
//
//  Created by Angela Yu on 21/10/2019.
//  Copyright © 2019 Angela Yu. All rights reserved.
//

import UIKit
import Firebase

class ChatViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var messageTextfield: UITextField!
    
    let db = Firestore.firestore()
    
    var messages: [Message] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadMessage()
        tableView.dataSource = self
        title = "⚡️FlashChat"
        navigationItem.hidesBackButton = true
        
        //Nib is old name of xib file
        tableView.register(UINib(nibName: K.cellNibName, bundle: nil), forCellReuseIdentifier: K.cellIdentifier)
        
        loadMessage()
    }
    // Retrive messages from firebase
    func loadMessage(){
        
        db.collection(K.FStore.collectionName).order(by: K.FStore.dateField).addSnapshotListener {(querySnapShot, error) in
            self.messages = []
            if let e = error {
                print("Error in getting data from server \(e)")
            } else {
                if let snapShotDocuments = querySnapShot?.documents {
                    for doc in snapShotDocuments {
                        // print(doc.data())      //Print message in console
                        //Adding Data in local Message String
                        let data = doc.data()
                        if let messageBody = data[K.FStore.bodyField] as? String,
                            let messageSender = data[K.FStore.senderField] as? String {
                            
                            let newMessage = Message(sender: messageSender, body: messageBody)
                            self.messages.append(newMessage)
                            
                            DispatchQueue.main.async {
                                   self.tableView.reloadData()
                                let indexPath = IndexPath(row: self.messages.count - 1, section: 0)
                                self.tableView.scrollToRow(at: indexPath, at: .top, animated: false)
                            }
                        }
                    }
                }
            }
        }
        
    }
    
    @IBAction func sendPressed(_ sender: UIButton) {
        if let messageBody = messageTextfield.text,
            messageBody != "",
            let messageSender = Auth.auth().currentUser?.email {
            
            db.collection(K.FStore.collectionName).addDocument(data: ([
                K.FStore.senderField: messageSender,
                K.FStore.bodyField: messageBody,
                K.FStore.dateField: Date().timeIntervalSince1970
            ])) { (error) in
                    if let e = error {
                        print("There is an issue to saving data on firestore \(e)")
                    } else {
                        print("Your data stored saved successfuly")
                    }
            }
        }
        messageTextfield.text = ""
    }
    
    @IBAction func logoutButtonPressed(_ sender: UIBarButtonItem) {
        do{
            try Auth.auth().signOut()
            navigationController?.popToRootViewController(animated: true)
        } catch let signOutError as NSError {
            print("Sign out Error %@", signOutError)
        }
    }
    
}
extension ChatViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let message = messages[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: K.cellIdentifier, for: indexPath) as! MessageCell
        cell.label.text = message.body
        print("message.sender \(message.sender) - currentUserEmail \(Auth.auth().currentUser?.email!)")
        //This is a message from the current user.
        if message.sender == Auth.auth().currentUser?.email! {
            cell.leftImageView.isHidden = true
            cell.rightImageView.isHidden = false
            cell.messageBubble.backgroundColor = UIColor(named: K.BrandColors.lightPurple)
            cell.label.textColor = UIColor(named: K.BrandColors.purple)
        }  else        //This is a message from another sender.
        {
            cell.leftImageView.isHidden = false
            cell.rightImageView.isHidden = true
            cell.messageBubble.backgroundColor = UIColor(named: K.BrandColors.purple)
            cell.label.textColor = UIColor(named: K.BrandColors.lightPurple)
        }
        
        return cell
    }
        
}
