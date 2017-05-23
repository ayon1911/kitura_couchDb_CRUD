import Kitura
import HeliumLogger
import SwiftyJSON
import CouchDB

//taskObject which takes the data from the database and ready to use for ur app

struct Task {
    var title: String
    
    func serialize() -> [String:Any] {
        return ["title": self.title]
    }
}

HeliumLogger.use()

//Connect To The CouchDb Database
let connectionProperties = ConnectionProperties(host: "localhost", port: 5984, secured: false)
let client = CouchDBClient(connectionProperties: connectionProperties)

let database = client.database("taskdb")

let router = Router()
router.post(middleware: BodyParser())
router.delete(middleware: BodyParser())
router.put(middleware: BodyParser())

//posting data in the database
router.post("task") { request, response, next in
    
    defer { next() }
    //making a request body to send data to the database
    guard let body = request.body,
            let json = body.asJSON,
            let title = json["title"].string
        
    else {
        try response.status(.badRequest).end()
        return
    }
    
    //creating a document for the database where the key is title
    database.create(JSON(["title": title])) { id, revision, doc, error in
        if let id = id {
            response.status(.OK).send(json: ["id": id])
        } else {
            response.status(.internalServerError).send(json: ["message": "Error inserting document"])
        }
    }
}

//Getting the data from the database
router.get("task") { request, response, next in
    
    //Lets create an empty array which will hold these values from the task Obejct 
    var taskArray = [Task]()
    
    //retrieing the document from the database
    database.retrieveAll(includeDocuments: true, callback: { (doc: JSON?, err: Error?) in
        if err != nil {
            response.status(.internalServerError).send(json: ["message": "Could not retriev the data "])
        } else {
            //where we can into the documents collections and load the documents
            if let docs = doc {
                for document in docs["rows"].arrayValue {
                    let title = document["doc"]["title"].stringValue
                    let task = Task(title: title)
                    taskArray.append(task)
                }
                
                response.send(json: taskArray.map { $0.serialize()})
            }
        }
    })
    
    next()
}

//Deleting from database
router.delete("task") { request, response, next in
    
    defer { next() }
    
    guard let body = request.body,
        let json = body.asJSON,
        let id = json["id"].string,
        let revId = json["rev"].string
    else {
        try response.status(.badRequest).send(json: ["message": "Body missing"])
        return
    }
    
    database.delete(id, rev: revId, callback: { (err: Error?) in
        
        if err != nil {
            response.status(.internalServerError).send(json: ["error": "Unable to delete the record"])
        } else {
            response.status(.OK).send(json: ["Success": true])
        }
    })
}

//Updating the data or records inside the database

router.put("task") { request, response, next in
    
    defer { next() }
    guard let body = request.body,
        let json = body.asJSON,
        let id = json["id"].string,
        let revId = json["rev"].string,
        let title = json["title"].string
    else {
        try response.status(.badRequest).end()
        return
    }
    
    database.update(id, rev: revId, document: JSON(["title": title]), callback: { (rev: String?, doc: JSON?, error: Error?) in
        if error != nil {
            response.status(.internalServerError).send("Opps ! Not able to update")
        } else {
            response.status(.OK).send(json: ["success": "True"])
        }
    })
}

//Filtering records using custom CouchDB views--
//localhost:8090/task/high - for filter high priority values of whatever
//localhost:8090/task/low -  for filter high priority values of whatever
router.get("/task/:priority") { request, response, next in
    
    defer { next() }
    
    guard let priority = request.parameters["priority"] else {
        try response.status(.badRequest).end()
        return
    }
    
    //in the database make a new view from Design Document and name it to "priority" and make two view called high,low-priority respectively
    database.queryByView("\(priority)-priority", ofDesign: "priority", usingParameters: [], callback: { (doc:JSON?, error: Error?) in
        
        var tasks = [Task]()
        
        if error != nil {
            response.status(.internalServerError).send("Something Went Wrong!!!")
        } else if let docs = doc {
            
            for documents in docs["rows"].arrayValue {
                
                let title = documents["value"]["title"].stringValue
                
                let task = Task(title: title)
                tasks.append(task)
            }
        }
        
        response.send(json: tasks.map {$0.serialize()} )
    })
}

Kitura.addHTTPServer(onPort: 8090, with: router)
Kitura.run()
