//
//  main.swift
//  PerfectTemplate
//
//  Created by Kyle Jessup on 2015-11-05.
//	Copyright (C) 2015 PerfectlySoft, Inc.
//
//===----------------------------------------------------------------------===//
//
// This source file is part of the Perfect.org open source project
//
// Copyright (c) 2015 - 2016 PerfectlySoft Inc. and the Perfect project authors
// Licensed under Apache License v2.0
//
// See http://perfect.org/licensing.html for license information
//
//===----------------------------------------------------------------------===//
//

import PerfectLib
import PerfectHTTP
import PerfectHTTPServer
import Foundation

var baseFolderURL: URL?

for argument in CommandLine.arguments.dropFirst() {
    let path = NSString(string: argument).expandingTildeInPath
    baseFolderURL = URL(fileURLWithPath: path)
}
guard let baseFolderURL = baseFolderURL else {
    print("Missing basefolder")
    exit(-1)
}


// Create server object.
let server = HTTPServer()

server.serverPort = 8090

var routes = Routes()
var routeHandler = RouteHandler(baseFolderURL: baseFolderURL)
routeHandler.parseAll()

routes.add(method: .get, uri: "/", handler: routeHandler.homeHandler)
routes.add(method: .get, uri: "/reset", handler: routeHandler.resetHandler)
routes.add(method: .get, uri: "/teststats", handler: routeHandler.testStatsHandler)
routes.add(method: .get, uri: "/status", handler: routeHandler.statusHandler)
routes.add(method: .get, uri: "/lastresult", handler: routeHandler.lastResultHandler)
routes.add(method: .get, uri: "/parse", handler: routeHandler.parseHandler) 
routes.add(method: .get, uri: "/details/{runplist}", handler: routeHandler.runHandler)
routes.add(method: .get, uri: "/details/{runplist}/{suitename}", handler: routeHandler.suiteHandler)
routes.add(method: .get, uri: "/details/{runplist}/{suitename}/{testname}", handler: routeHandler.testHandler)
routes.add(method: .get, uri: "/details/{runplist}/{suitename}/{testname}/{actionuuid}", handler: routeHandler.testActionHandler)
routes.add(method: .get, uri: "/coverage/{runplist}", handler: routeHandler.coverageHomeHandler)
routes.add(method: .get, uri: "/coverage/{runplist}/{filepath}", handler: routeHandler.coverageFileHandler)
routes.add(method: .get, uri: "/diagnostic_report/{runplist}/{suitename}/{testname}", handler: routeHandler.diagnosticReportHandler)

routes.add(method: .get, uri: "/static/**", handler: {
    request, response in
    
    request.path = request.urlVariables[routeTrailingWildcardKey] ?? "" // get the portion of the request path which was matched by the wildcard
    StaticFileHandler(documentRoot: baseFolderURL.path).handleRequest(request: request, response: response)
})

// Add our routes.
server.addRoutes(routes)

do {
    // Launch the HTTP server
    try server.start()
} catch PerfectError.networkError(let err, let msg) {
    print("Network error thrown: \(err) \(msg)")
}
