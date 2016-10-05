//
//  ViewController.swift
//  Top Songs JSON
//
//  Created by Tywin Lannister on 05/10/16.
//  Copyright © 2016 Training. All rights reserved.
//

import UIKit

class ViewController: UITableViewController, URLSessionDelegate, URLSessionDataDelegate, URLSessionDownloadDelegate {
    
    var session : URLSession?
    var songsArray = [Song]()
    
    var downloading = false
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return songsArray.count }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "songCell", for: indexPath)
        
        let mySong = songsArray[indexPath.row]
        cell.textLabel?.text = mySong.title;
        cell.textLabel?.font = UIFont.systemFont(ofSize: 10.0)
        if let myImage = mySong.image {
            cell.imageView?.image = myImage
        } else {
            cell.imageView?.image = UIImage(named: "cd.jpeg")
        }
        
        return cell }
    
    func fetchJsonFeed ()
    {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        songsArray = [Song]()
        
        let myURL = URL(string: "https://itunes.apple.com/gb/rss/topalbums/limit=50/json")
        let task = session!.dataTask(with: myURL!) {
            (data, response, error) -> Void in
            do {
                let jsonFeed =
                    try JSONSerialization.jsonObject(with: data!,
                            options: JSONSerialization.ReadingOptions.mutableContainers)
                        as! Dictionary<String,AnyObject>
                        print(jsonFeed)
                let songFeed = jsonFeed["feed"] as! Dictionary<String,AnyObject>?
                let songList = songFeed?["entry"] as! Array<AnyObject>?
                for song in songList! {
                    let titleEntry = song["title"] as! Dictionary<String, AnyObject>
                    let title = titleEntry["label"] as! String?
                    let allImages = song["im:image"]  as? [AnyObject]
                    let myImageDetails = allImages![0] as? Dictionary<String, AnyObject>
                    let myImageURL = myImageDetails!["label"] as? String
                    self.songsArray.append(Song(title: title!, image: nil, imageURL: myImageURL, taskIdentifier: nil))
                }
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
                self.fetchImages()
                
                
            } catch let error{
                print(error)
            }
    }
        task.resume()
    }
    
    func fetchImages ()
    {
        for song in songsArray {
            var mySong = song
            let myImageURL = URL(string: song.imageURL!)
            if let sessionDownloadTask = session?.downloadTask(with: myImageURL!) {
                    mySong.taskIdentifier = sessionDownloadTask.taskIdentifier
                let index =  songsArray.index(where: {$0.title == mySong.title})
                songsArray[index!] = mySong
                sessionDownloadTask.resume()
            }
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?)    {
        print("Session")
        let index =  songsArray.index(where: {$0.taskIdentifier == task.taskIdentifier})
        if error == nil {
            print("task \(index) finished!")
        }
        else{
            print("Error: \(error)")
        }
         checkForRemainingTasks()
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let index =  songsArray.index(where: {$0.taskIdentifier == downloadTask.taskIdentifier})
        if let image = try? UIImage(data: Data(contentsOf: location) ) {
            var mySong = songsArray[index!]
            mySong.image = image
            songsArray[index!] = mySong
        }
        DispatchQueue.main.async() {
            self.tableView.reloadData()
        }
    }

    func refreshJsonFeed () {
        if !downloading {
            downloading = true
            fetchJsonFeed()
        }
    }
    
    func checkForRemainingTasks ()
    {
        session?.getTasksWithCompletionHandler({ (dataTasks, uploadTasks, downloadTasks) -> Void in
            if downloadTasks.count == 0 {
                DispatchQueue.main.async() {
                    self.refreshControl!.endRefreshing()
                    self.downloading = false
                }
            } })
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        refreshControl!.addTarget(self, action: #selector(ViewController.fetchJsonFeed), for: .valueChanged)
        
        let sessionConfig = URLSessionConfiguration.default
        session = URLSession(configuration: sessionConfig, delegate: self, delegateQueue: nil)
        downloading = true
        fetchJsonFeed()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

