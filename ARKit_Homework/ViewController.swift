import UIKit
import ARKit
import SceneKit

struct CollisionCategory: OptionSet {
    let rawValue: Int
    static let missileCategory = CollisionCategory(rawValue: 1 << 0)
    static let targetCategory = CollisionCategory(rawValue: 1 << 1)
    static let otherCategory = CollisionCategory(rawValue: 1 << 2)
}

class ViewController: UIViewController, ARSCNViewDelegate, SCNPhysicsContactDelegate {
    @IBOutlet weak var whiteButton: UIButton!
    @IBOutlet weak var redButton: UIButton!
    @IBOutlet weak var greenButton: UIButton!
    @IBOutlet weak var sceneView: ARSCNView!
    
    @IBAction func whiteButton(_ sender: Any) {
        fireMissile(type: "whiteBall")
    }
    
    @IBAction func redButton(_ sender: Any) {
        fireMissile(type: "redBall")
    }
    
    @IBAction func greenButton(_ sender: Any) {
        fireMissile(type: "greenBall")
    }
    
    func getUserVector() -> (SCNVector3, SCNVector3) {
        if let frame = self.sceneView.session.currentFrame {
            let mat = SCNMatrix4(frame.camera.transform)
            let dir = SCNVector3(-1 * mat.m31, -1 * mat.m32, -1 * mat.m33)
            let pos = SCNVector3(mat.m41, mat.m42, mat.m43)
            return (dir, pos)
        }
        return (SCNVector3(0, 0, -1), SCNVector3(0, 0, -0.2))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        whiteButton.layer.cornerRadius = whiteButton.frame.size.height / 2
        redButton.layer.cornerRadius = redButton.frame.size.height / 2
        greenButton.layer.cornerRadius = greenButton.frame.size.height / 2
        sceneView.delegate = self
        sceneView.scene.physicsWorld.contactDelegate = self
        addTargetNodes()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let configuration = ARWorldTrackingConfiguration()
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()        
    }
    
    func addTargetNodes() {
        
        for index in 1...100 {
            var node = SCNNode()
            
            if (index % 2 == 0) {
                createNode(node: &node, path: "art.scnassets/whiteCube.dae", name: "whiteCube", scale: SCNVector3(0.3, 0.3, 0.3))
            } else {
                if (index % 3 == 0) {
                    createNode(node: &node, path: "art.scnassets/redCube.dae", name: "redCube", scale: SCNVector3(0.3, 0.3, 0.3))
                } else {
                    createNode(node: &node, path: "art.scnassets/greenCube.dae", name: "greenCube", scale: SCNVector3(0.3, 0.3, 0.3))
                }
            }

            node.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
            node.physicsBody?.isAffectedByGravity = false
            node.position = SCNVector3 (randomFloat(min: -10, max: 10), randomFloat(min: -4, max: 5), randomFloat(min: -10, max: 10))
            let action: SCNAction = SCNAction.rotate(by: .pi, around: SCNVector3(0, 1, 0), duration: 1.0)
            let forever = SCNAction.repeatForever(action)
            node.runAction(forever)
            node.physicsBody?.categoryBitMask = CollisionCategory.targetCategory.rawValue
            node.physicsBody?.contactTestBitMask = CollisionCategory.missileCategory.rawValue
            sceneView.scene.rootNode.addChildNode(node)
        }
    }
    
    func createMissile(type: String) -> SCNNode {
        var node = SCNNode()
        
        switch type {
        case "whiteBall":
            createNode(node: &node, path: "art.scnassets/whiteBall.dae", name: "whiteBall", scale: SCNVector3(0.05, 0.05, 0.05))
        case "redBall" :
            createNode(node: &node, path: "art.scnassets/redBall.dae", name: "redBall", scale: SCNVector3(0.05, 0.05, 0.05))
        case "greenBall" :
            createNode(node: &node, path: "art.scnassets/greenBall.dae", name: "greenBall", scale: SCNVector3(0.05, 0.05, 0.5))
        default:
            node = SCNNode()
        }
        
        node.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        node.physicsBody?.isAffectedByGravity = false
        node.physicsBody?.categoryBitMask = CollisionCategory.missileCategory.rawValue
        node.physicsBody?.collisionBitMask = CollisionCategory.targetCategory.rawValue
        return node
    }
    
    func fireMissile(type: String) {
        var node = SCNNode()
        node = createMissile(type: type)
        let (direction, position) = self.getUserVector()
        node.position = position
        var nodeDirection = SCNVector3()
        
        switch type {
        case "whiteBall":
            forceNode(node: &node, nodeDirection: &nodeDirection, direction: direction)
        case "redBall":
            forceNode(node: &node, nodeDirection: &nodeDirection, direction: direction)
        case "greenBall":
            forceNode(node: &node, nodeDirection: &nodeDirection, direction: direction)
        default:
            nodeDirection = direction
        }
        
        node.physicsBody?.applyForce(nodeDirection, asImpulse: true)
        sceneView.scene.rootNode.addChildNode(node)
    }
    
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        let nameA = contact.nodeA.name!
        let nameB = contact.nodeB.name!
        print("** Столкновение " + nameA + " попал в " + nameB)
 
        if contact.nodeA.physicsBody?.categoryBitMask == CollisionCategory.targetCategory.rawValue || contact.nodeB.physicsBody?.categoryBitMask == CollisionCategory.targetCategory.rawValue {
            DispatchQueue.main.async {
                               contact.nodeA.removeFromParentNode()
                               contact.nodeB.removeFromParentNode()
            }
        }
    }
}

extension ViewController {
    
    func createNode ( node: inout SCNNode, path: String, name: String, scale: SCNVector3) -> SCNNode {
        
        let scene = SCNScene(named: path)
        node = (scene?.rootNode.childNode(withName: name, recursively: true)!)!
        node.scale = SCNVector3(0.3, 0.3, 0.3)
        node.name = name
        
        return node
        
    }

    func forceNode (node: inout SCNNode, nodeDirection: inout SCNVector3, direction: SCNVector3) -> SCNNode {
        nodeDirection = SCNVector3(direction.x * 4, direction.y * 4, direction.z * 4)
        node.physicsBody?.applyForce(nodeDirection, at: SCNVector3(0.1, 0, 0), asImpulse: true)
        return node
    }
    
       func colorMatching (nameA: String, nameB: String, color: String) -> Bool {
           if nameA.contains(color) && nameB.contains(color) {
               return true
           } else {
               return false
           }
       }

    func randomFloat(min: Float, max: Float) -> Float {
        return (Float(arc4random()) / 0xFFFFFFFF ) * (max - min) + min
    }
}
