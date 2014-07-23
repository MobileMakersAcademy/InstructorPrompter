//
//  ViewController.swift
//  externalDisplay
//
//  Created by Kevin McQuown on 7/14/14.
//  Copyright (c) 2014 Mobile Makers. All rights reserved.
//

import UIKit
import CloudKit

let recordType = "Message"
class myAction : UIAlertAction{
    var tag : Int?
}
let timeInterval = 1.0

class QuestionCell : UITableViewCell
{
    @IBOutlet weak var questionLabel: UILabel!

}
func reloadTableViewOnMainThread(tableView:UITableView) {
    dispatch_async(dispatch_get_main_queue(), {
        tableView.reloadData()
    })
}

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, ActionsViewControllerProtocol {

    var externalWindow :UIWindow!
    var externalDisplay : UIScreen!
    var externalController : ExternalController!
    var showQuestions = false
    var repeatQuestionOn = false

    var timer : NSTimer!
    var publicDatabase = CKContainer.defaultContainer().publicCloudDatabase
    var questions : [CKRecord] = Array()
    var questionsForTable : [CKRecord] = Array()

    @IBOutlet var micOnSwitch: UISwitch!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var micOffSwitch: UISwitch!
    @IBOutlet var repeatQuestionSwitch: UISwitch!
    @IBOutlet var showQuestionSwitch: UISwitch!
    @IBOutlet weak var showRepeatComment: UISwitch!
    @IBOutlet weak var selectActionButton: UIButton!

    var log = ""

    @IBAction func actionButtonTapped(sender: AnyObject) {
    }

    func timerFired(theTimer : NSTimer)
    {
        queryDB()
    }

    func filterJustQuestions() ->[CKRecord]
    {
        var results = [CKRecord]()
        for record in questions
        {
            if record.objectForKey("isQuestion") as Int == 1
            {
                results.append(record)
            }
        }
        return results
    }

    @IBAction func editButtonTapped(sender: AnyObject) {
        self.tableView.editing = !self.tableView.editing
    }

    override func prepareForSegue(segue: UIStoryboardSegue!, sender: AnyObject!)
    {
        if segue.identifier == "fromAddButton"
        {
            var destVC = segue.destinationViewController as AddQuestionVC
            destVC.tableView = tableView
            destVC.questions = questionsForTable
            destVC.currentQuestionIndexPath = self.tableView.indexPathForSelectedRow()
        }
        if segue.identifier == "fromTableViewCell"
        {
            var destVC = segue.destinationViewController as AddQuestionVC
            destVC.tableView = tableView
            destVC.questions = questionsForTable
            destVC.currentQuestionIndexPath = self.tableView.indexPathForSelectedRow()
        }
        if segue.identifier == "popOver"
        {
            var destVC = segue.destinationViewController as ActionsViewController
            destVC.delegate = self
        }
    }

    func wantsQuestionRepeated(records : [CKRecord]) -> Bool
    {
        for record in records
        {
            if record.objectForKey("repeatQuestion") as Int == 1
            {
                return true;
            }
        }
        return false;
    }

    func showRepeatComment(records : [CKRecord]) -> Bool{
        for record in records
        {
            if record.objectForKey("repeatQuestion") as Int == 5
            {
                return true
            }
        }
        return false
    }

    func wantsMicOn(records : [CKRecord]) -> Bool
    {
        for record in records
        {
            if record.objectForKey("repeatQuestion") as Int == 2
            {
                return true;
            }
        }
        return false;
    }
    func wantsMicOff(records : [CKRecord]) -> Bool
    {
        for record in records
        {
            if record.objectForKey("repeatQuestion") as Int == 3
            {
                return true;
            }
        }
        return false;
    }
    func shouldShowQuestions(records : [CKRecord]) -> Bool
    {
        for record in records
        {
            if record.objectForKey("repeatQuestion") as Int == 4
            {
                return true;
            }
        }
        return false;
    }
    func numberOfPendingQuestions(records : [CKRecord]) -> Int
    {
        var count = 0
        for record in records
        {
            if record.objectForKey("isQuestion") as Int == 1
            {
                ++count
            }
        }
        return count
    }

    func showQuestion(records : [CKRecord]) -> CKRecord?
    {
        for record in records
        {
            if record.objectForKey("isQuestion") as Int == 1
            {
                return record
            }
        }
        return nil
    }
    func getControlRecord() -> CKRecord?
    {
        for record in questions
        {
            if record.objectForKey("isQuestion") as Int == 0
            {
                return record
            }
        }
        return nil
    }

    func showErrorMessageAlert(error : NSError)
    {
        dispatch_async(dispatch_get_main_queue(), {
            var alert = UIAlertController(title: "Save Error", message: error.localizedDescription, preferredStyle: .Alert)
            var okAction = UIAlertAction(title: "Dang it!", style: .Default, handler: nil)
            alert.addAction(okAction)
            self.presentViewController(alert, animated: true, completion: nil)
        })
    }

    func updateData(records : [CKRecord])
    {
        dispatch_async(dispatch_get_main_queue(), {
//            self.showQuestionSwitch.on = false
//            self.micOffSwitch.on = false
//            self.micOnSwitch.on = false
//            self.showQuestionSwitch.on = false
//            self.showRepeatComment.on = false
            self.selectActionButton.setTitle("Action", forState: .Normal)

            if let controlRecord = self.getControlRecord()
            {
                switch controlRecord.objectForKey("repeatQuestion") as Int
                    {
                case 1:
                    self.selectActionButton.setTitle("Repeat Question", forState: .Normal)
                case 2:
                    self.selectActionButton.setTitle("Mic On", forState: .Normal)
                case 3:
                    self.selectActionButton.setTitle("Mic Off", forState: .Normal)
                case 4:
                    self.selectActionButton.setTitle("Showing Questions", forState: .Normal)
                case 5:
                    self.selectActionButton.setTitle("Repeat Comment", forState: .Normal)
                default:
                    self.selectActionButton.setTitle("Action", forState: .Normal)
                }
            }
        })
        var foundChange = false
        if records.count != questions.count
        {
            foundChange = true
        }
        else
        {
            var dictionaryOfNetworkRecords :Dictionary <String,CKRecord> = Dictionary()

            for record in records
            {
                dictionaryOfNetworkRecords[record.recordID.recordName] = record
            }
            for record in questions
            {
                if let networkRecord = dictionaryOfNetworkRecords[record.recordID.recordName]
                {
                    if networkRecord.recordChangeTag != record.recordChangeTag
                    {
                        foundChange = true
                        break;
                    }
                }
            }
        }
        if foundChange
        {
            self.questions = records
            self.questionsForTable = filterJustQuestions()
            self.questionsForTable.sort({record1, record2 in
                let value1 = record1.objectForKey("order") as Int
                let value2 = record2.objectForKey("order") as Int
                return value1 < value2
            })

            reloadTableViewOnMainThread(self.tableView)
        }
    }

    func choiceMade(theChoice: String)
    {
        switch theChoice
            {
        case "Repeat Question" :
                setControlRecordWithValue(1)
        case "Repeat Comment" :
            setControlRecordWithValue(5)
        case "Mic On" :
            setControlRecordWithValue(2)
        case "Mic Off" :
            setControlRecordWithValue(3)
        case "Show Questions" :
            setControlRecordWithValue(4)
        default:
            setControlRecordWithValue(0)
        }
    }
    func setControlRecordWithValue(value : Int)
    {
        var controlRecord = getControlRecord()
        if controlRecord
        {
            controlRecord!.setObject(value, forKey: "repeatQuestion")
        }
        else
        {
            controlRecord = CKRecord(recordType: recordType)
            controlRecord!.setObject("", forKey: "message")
            controlRecord!.setObject(value, forKey: "repeatQuestion")
            controlRecord!.setObject(0, forKey: "showQuestion")
            controlRecord!.setObject(0, forKey: "isQuestion")
            controlRecord!.setObject(0, forKey: "order")
        }
        publicDatabase.saveRecord(controlRecord, completionHandler: ({record, error in
            if error
            {
                self.showErrorMessageAlert(error)
            }
        }))
    }

    func queryDB()
    {
        var pred = NSPredicate(value: true)
        var query = CKQuery(recordType: "Message", predicate: pred)
        publicDatabase.performQuery(query, inZoneWithID: nil, completionHandler: ({records, error in
            if error
            {
                println(error.localizedDescription)
                self.addText(error.localizedDescription)
            }
            else
            {
                self.updateData(records as [CKRecord])
                dispatch_async(dispatch_get_main_queue(),{
                    if self.externalController
                    {
                        self.externalController.view.backgroundColor = UIColor.blackColor()
                        if self.wantsQuestionRepeated(records as [CKRecord])
                        {
                            self.externalController.messageArea.text = "Repeat Question"
                            self.externalController.view.backgroundColor = UIColor.redColor()
                        }
                        else if self.wantsMicOn(records as [CKRecord])
                        {
                            self.externalController.messageArea.text = "Turn Mic On"
                            self.externalController.view.backgroundColor = UIColor.redColor()
                        }
                        else if self.showRepeatComment (records as [CKRecord])
                        {
                            self.externalController.messageArea.text = "Repeat Comment"
                            self.externalController.view.backgroundColor = UIColor.greenColor()
                        }
                        else if self.wantsMicOff(records as [CKRecord])
                        {
                            self.externalController.messageArea.text = "Turn Mic Off"
                            self.externalController.view.backgroundColor = UIColor.redColor()
                        }
                        else
                        {
                            var questionToShow = self.showQuestion(self.questionsForTable)
                            if questionToShow && self.shouldShowQuestions(records as [CKRecord])
                            {
                                self.externalController.messageArea.text = questionToShow!.objectForKey("message") as String
                            }
                            else
                            {
                                var numberOfQuestions = self.numberOfPendingQuestions(records as [CKRecord])
                                switch numberOfQuestions {
                                case 0:
                                    self.externalController.messageArea.text = ""
                                case 1:
                                    self.externalController.messageArea.text = String(numberOfQuestions) + " Question Pending"
                                default:
                                    self.externalController.messageArea.text = String(numberOfQuestions) + " Questions Pending"
                                }
                            }
                        }
                    }
                })
            }
        }))
    }

    func tableView(tableView: UITableView!, moveRowAtIndexPath sourceIndexPath: NSIndexPath!, toIndexPath destinationIndexPath: NSIndexPath!)
    {
        println(sourceIndexPath.row)
        println(destinationIndexPath.row)

        let record = questionsForTable[sourceIndexPath.row]
        questionsForTable.removeAtIndex(sourceIndexPath.row)
        questionsForTable.insert(record, atIndex: destinationIndexPath.row)

        var count = 0
        for record in questionsForTable
        {
            record.setObject(count, forKey: "order")
            ++count
        }
        var saveOp = CKModifyRecordsOperation()
        saveOp.recordsToSave = questionsForTable
        saveOp.savePolicy = .AllKeys
        saveOp.perRecordCompletionBlock = {record, error in

        };
        saveOp.modifyRecordsCompletionBlock = {savedRecords, deletedRecordIDs, error in
            if error
            {
                self.showErrorMessageAlert(error)
            }
            else
            {
                reloadTableViewOnMainThread(self.tableView)
            }
        }
        publicDatabase.addOperation(saveOp)
    }

    func tableView(tableView: UITableView!, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath!)
    {
        if editingStyle == .Delete
        {
            let recordToDelete = questionsForTable[indexPath.row];
            publicDatabase.deleteRecordWithID(recordToDelete.recordID, completionHandler: ({recordID, error in
                if error
                {
                    self.showErrorMessageAlert(error)
                }
                else
                {
                }
            }))
        }
    }
    func tableView(tableView: UITableView!, numberOfRowsInSection section: Int) -> Int
    {
        return questionsForTable.count
    }

    func tableView(tableView: UITableView!, cellForRowAtIndexPath indexPath: NSIndexPath!) -> UITableViewCell!
    {
        let cell = tableView.dequeueReusableCellWithIdentifier("QuestionCell") as QuestionCell
        cell.questionLabel.text = questionsForTable[indexPath.row].objectForKey("message") as String
        return cell
    }

    func addText(text: String)
    {
        log = log + text + "\n"
    }

    func attachExternalDisplayIfPresent()
    {
        if UIScreen.screens().count > 1
        {
            self.externalDisplay = UIScreen.screens()[1] as? UIScreen
            var supportedModes = self.externalDisplay!.availableModes as [UIScreenMode]
            var alert = UIAlertController(title:nil, message: nil, preferredStyle: .ActionSheet)
            var cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
            alert.addAction(cancelAction)
            for i in 0 ..< supportedModes.count
            {
                var mode = supportedModes[i] as UIScreenMode
                var modeString = String(Int(mode.size.width)) + " x " + String(Int(mode.size.height))
                var modeAction = myAction(title: modeString, style: .Default, {action in
                    var theAction = action as myAction
                    dispatch_async(dispatch_get_main_queue(), {
                        self.addText("Enabling Second Display")
                        self.externalDisplay!.currentMode = supportedModes[theAction.tag!]
                        self.externalWindow = UIWindow(frame: self.externalDisplay!.bounds)
                        self.externalWindow!.screen = self.externalDisplay!

                        self.externalController = self.storyboard.instantiateViewControllerWithIdentifier("ExternalController") as ExternalController
                        self.externalWindow.rootViewController = self.externalController

                        self.externalWindow.makeKeyAndVisible()
                        })
                    })
                modeAction.tag = i
                alert.addAction(modeAction)
            }
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }

    override func viewDidAppear(animated: Bool)
    {
        super.viewDidAppear(true)

        timer = NSTimer.scheduledTimerWithTimeInterval(timeInterval, target: self, selector: "timerFired:", userInfo: nil, repeats: true)


    }
    override func viewDidLoad() {
        super.viewDidLoad()

        attachExternalDisplayIfPresent()

        var notification = NSNotificationCenter.defaultCenter().addObserverForName(UIScreenDidConnectNotification, object: nil, queue:NSOperationQueue.mainQueue(), usingBlock: ({notication in
            self.attachExternalDisplayIfPresent()
        }))
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

