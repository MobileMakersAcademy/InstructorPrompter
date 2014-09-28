//
//  ActionsViewController.swift
//  externalDisplay
//
//  Created by Kevin McQuown on 7/22/14.
//  Copyright (c) 2014 Mobile Makers. All rights reserved.
//

import UIKit

protocol ActionsViewControllerProtocol
{
    func choiceMade(theChoice:String)
}

class ActionsViewController: UITableViewController {

    var choices = ["Repeat Question","Repeat Comment","Show Questions","Mic On","Mic Off","Clear"]
    var delegate : ActionsViewControllerProtocol?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.preferredContentSize = CGSizeMake(320, 300)
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
     
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return choices.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        var cell = tableView.dequeueReusableCellWithIdentifier("actionCell") as UITableViewCell
        cell.textLabel!.text = choices[indexPath.row] as String
        return cell
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        self.delegate?.choiceMade(choices[indexPath.row])
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue!, sender: AnyObject!) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
