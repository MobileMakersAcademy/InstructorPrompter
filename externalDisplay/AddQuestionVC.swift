//
//  AddQuestionVC.swift
//  externalDisplay
//
//  Created by Kevin McQuown on 7/17/14.
//  Copyright (c) 2014 Mobile Makers. All rights reserved.
//

import UIKit
import CloudKit

class AddQuestionVC : UIViewController
{

    var tableView :UITableView!
    var questions : [CKRecord]!

    var publicDatabase = CKContainer.defaultContainer().publicCloudDatabase
    @IBOutlet var textView: UITextView

    @IBAction func cancelButtonTapped(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    func largestOrderCount(records : [CKRecord]) -> Int
    {
        var count = 0
        for record in records
        {
            if count < record.objectForKey("order") as Int
            {
                count = record.objectForKey("order") as Int
            }
        }
        return count
    }

    @IBAction func doneButtonTapped(sender: AnyObject) {

        var record = CKRecord(recordType: "Message")
        record.setObject(textView.text, forKey: "message")
        record.setObject(0, forKey: "repeatQuestion")
        record.setObject(0, forKey: "showQuestion")
        record.setObject(1, forKey: "isQuestion")
        record.setObject(largestOrderCount(questions) + 1, forKey: "order")
        publicDatabase.saveRecord(record, completionHandler: ({record,error in
            if error
            {
                dispatch_async(dispatch_get_main_queue(), {
                    var alert = UIAlertController(title: "Save Error", message: error.localizedDescription, preferredStyle: .Alert)
                    var okAction = UIAlertAction(title: "Dang it!", style: .Default, handler: nil)
                    alert.addAction(okAction)
                    self.presentViewController(alert, animated: true, completion: nil)
                    })
            }
            else
            {
                reloadTableViewOnMainThread(self.tableView)
                self.dismissViewControllerAnimated(true, completion: nil)
            }
            }))
    }
    
}
