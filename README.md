Download the repo and open a terminal in that same directory where the root folder is and run "swift build" in the command line.
after donloading all the dependencies type "swift package generate-xcodeproj" to generate a xcode project so that it can be open and used with xcode.
Download and install CouchDB and make a table called "taskdb"

############# Fro this point later on it's only for letting know how the Document Design works in couchdb.######## 
Click on Design Document and make a new Design and name the _design/  as "priority"
Click to the newly made "priority" Design and make two new views where the index name will be high-priority and low-priority
and inside the view in MAP function write -

function (doc) {
  if(doc.priority == 'high') {
    if(doc.parent !== null) {
      emit(doc.parent,doc)
    }
  }
} 
note : for low-priority plz change the line to "doc.priority == 'low' "

of course dont forget to save 

