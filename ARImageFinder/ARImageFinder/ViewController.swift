//
//  ViewController.swift
//  ARImageFinder
//
//  Created by Dmitry on 09.06.2021.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {
  
  @IBOutlet var sceneView: ARSCNView!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // Set the view's delegate
    sceneView.delegate = self
    
    // Show statistics such as fps and timing information
    sceneView.showsStatistics = true
    
    sceneView.autoenablesDefaultLighting = true
    
    // Create a new scene
    //        let scene = SCNScene(named: "art.scnassets/ship.scn")!
    
    // Set the scene to the view
    //        sceneView.scene = scene
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    let referenceImages = ARReferenceImage.referenceImages(inGroupNamed: "AR Resources", bundle: nil)
    
    // Create a session configuration
    let configuration = ARWorldTrackingConfiguration()
    configuration.detectionImages = referenceImages
    
    // Run the view's session
    sceneView.session.run(configuration)
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    
    // Pause the view's session
    sceneView.session.pause()
  }
  
  // MARK: - ARSCNViewDelegate
  
  func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
    switch anchor {
    case let imageAnchor as ARImageAnchor:
      nodeAdded(node, for: imageAnchor)
    case let planeAnchor as ARPlaneAnchor:
      nodeAdded(node, for: planeAnchor)
    default:
      print("An anchor was discoveres, but it is not for planes or images")
    }
  }
  
  func nodeAdded(_ node: SCNNode, for imageAnchor: ARImageAnchor) {
    let referenceImage = imageAnchor.referenceImage
    
    let plane = SCNPlane(width: referenceImage.physicalSize.width, height: referenceImage.physicalSize.height)
    let planeNode = SCNNode(geometry: plane)
    planeNode.name = "plane"
    planeNode.opacity = 0.0
    planeNode.eulerAngles.x = -Float.pi / 2
    
    switch referenceImage.name {
    case "troyka":
      planeNode.geometry?.firstMaterial?.diffuse.contents = UIColor.red
      let shipScene = SCNScene(named: "art.scnassets/ship.scn")!
      guard let shipNode = shipScene.rootNode.childNode(withName: "ship", recursively: false) else { return }
      shipNode.scale = SCNVector3(0.07, 0.07, 0.07)
      shipNode.opacity = 0.0
      node.addChildNode(shipNode)
      shipNode.runAction(fadeInAction)
      print("Created node related to \"troyka.png\" image")
    case "eleсtro":
      planeNode.geometry?.firstMaterial?.diffuse.contents = UIColor.green
      let sphereNode = createSphere(0.02)
      node.addChildNode(sphereNode)
      sphereNode.runAction(fadeInAction)
      print("Created node related to \"electro.jpg\" image")
    default:
      planeNode.geometry?.firstMaterial?.diffuse.contents = UIColor.white
      print("Created node related to another image")
    }
    
    node.addChildNode(planeNode)
    planeNode.runAction(fadeOpacityAction)
  }
  
  func createSphere(_ radius: CGFloat) -> SCNNode {
    let sphere = SCNNode(geometry: SCNSphere(radius: radius))
    sphere.geometry?.firstMaterial?.lightingModel = .physicallyBased
    sphere.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
    sphere.opacity = 0.0
    sphere.position = SCNVector3(0.0, 0.02, 0.0)
    return sphere
  }
  
  func nodeAdded(_ node: SCNNode, for planeAnchor: ARPlaneAnchor) {
    
  }
  
  var fadeOpacityAction: SCNAction {
    return .sequence([.fadeOpacity(to: 0.5, duration: 2.0)])
  }
  
  var fadeInAction: SCNAction {
    return .sequence([.fadeIn(duration: 2.0)])
  }
  
  var waitRemoveAction: SCNAction {
    return .sequence([.fadeOut(duration: 2.0), .removeFromParentNode()])
  }
  
  func session(_ session: ARSession, didFailWithError error: Error) {
    // Present an error message to the user
    
  }
  
  func sessionWasInterrupted(_ session: ARSession) {
    // Inform the user that the session has been interrupted, for example, by presenting an overlay
    
  }
  
  func sessionInterruptionEnded(_ session: ARSession) {
    // Reset tracking and/or remove existing anchors if consistent tracking is required
    
  }
}
