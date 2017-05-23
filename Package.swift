// swift-tools-version:3.1

import PackageDescription

let package = Package(
    name: "couchDBIntegration",
	dependencies: [
		.Package(url: "https://github.com/IBM-Swift/Kitura", majorVersion: 1, minor: 7),
		.Package(url: "https://github.com/IBM-Swift/HeliumLogger", majorVersion: 1, minor: 7),
		.Package(url: "https://github.com/IBM-Swift/Kitura-CouchDB.git", majorVersion: 1, minor: 7)

	]
)
