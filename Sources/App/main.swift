import Vapor
import Socks

let drop = Droplet()

//let serverHost: String = drop.config["servers", "default", "host"]!.string!
//let serverPort: UInt = drop.config["servers", "default", "port"]!.uint!
//let serverAddress: InternetAddress = InternetAddress(hostname: serverHost, port: Port(serverPort))

if drop.environment == .development {
  (drop.view as? LeafRenderer)?.stem.cache = nil
}

drop.get { req in
    return try drop.view.make("welcome", [
    	"message": drop.localization[req.lang, "welcome", "title"]
    ])
}

var textIOConnector = TextIOConnector()
let wsController = WebsocketController(inputHandler: textIOConnector)
wsController.addRoutes(to: drop)

if #available(OSX 10.12, *) {
  let domusController = DomusController(outputHandler: textIOConnector)
  textIOConnector.connect(inputSource: domusController, outputDestination: wsController)
  domusController.addRoutes(to: drop)
} else {
  // Fallback on earlier versions
  fatalError("@available did not work out well")
}

drop.run()
