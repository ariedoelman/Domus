import Vapor

let drop = Droplet()

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

let domusController = DomusController(outputHandler: textIOConnector)
textIOConnector.connect(inputSource: domusController, outputDestination: wsController)
domusController.addRoutes(to: drop)

drop.run()
