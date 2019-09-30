//
//  ViewController.swift
//  ARKit3Hackaton-ARInvader
//
//  Created by drama on 2019/09/28.
//  Copyright © 2019 1901drama. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import MultipeerConnectivity

class ViewController: UIViewController, ARSCNViewDelegate,ARSessionDelegate,SCNPhysicsContactDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate {

    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet var scoreLabel: UILabel!
    @IBOutlet var ImageView: UIImageView!
    @IBOutlet var WIN: UILabel!
    
    var myPeerID:MCPeerID!
    var participantID: MCPeerID!
    private var mpsession: MCSession!
    private var serviceAdvertiser: MCNearbyServiceAdvertiser!
    private var serviceBrowser: MCNearbyServiceBrowser!
    static let serviceType = "arkit-hack"
    
    let device = MTLCreateSystemDefaultDevice()!
    var imageMode = false
    var image: UIImage = UIImage(named: "particle/bokeh_square.png")!
    
    var touchFlg = true
    var score = 0

    let generator_light = UIImpactFeedbackGenerator(style: .light)
    let generator_heavy = UIImpactFeedbackGenerator(style: .heavy)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        myPeerID = MCPeerID(displayName: UIDevice.current.name)
        initMultipeerSession(receivedDataHandler: receivedData)
        
        scoreLabel.text = String(score)
        
        sceneView.delegate = self
        sceneView.session.delegate = self
        sceneView.scene = SCNScene()
        sceneView.scene.physicsWorld.contactDelegate = self

        let configuration = ARWorldTrackingConfiguration()
        
        if ARBodyTrackingConfiguration.isSupported == true {
            configuration.frameSemantics = .personSegmentationWithDepth
        }
        configuration.isCollaborationEnabled = true
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration)
        
        //
        let coachingOverlay = ARCoachingOverlayView()
        coachingOverlay.session = sceneView.session
        coachingOverlay.translatesAutoresizingMaskIntoConstraints = false
        coachingOverlay.activatesAutomatically = true
        coachingOverlay.goal = .horizontalPlane
        //coachingOverlay.delegate = self
        sceneView.addSubview(coachingOverlay)
        
        NSLayoutConstraint.activate([
            coachingOverlay.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            coachingOverlay.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            coachingOverlay.widthAnchor.constraint(equalTo: view.widthAnchor),
            coachingOverlay.heightAnchor.constraint(equalTo: view.heightAnchor)
        ])
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if touchFlg == true {
             touchFlg = false
            
            guard let touch = touches.first else {return}
            let pos = touch.location(in: sceneView)
            let results = sceneView.hitTest(pos, types: .existingPlaneUsingExtent)
            if !results.isEmpty {
                let hitTestResult = results.first!
                let anchor = ARAnchor(name: "invader", transform: hitTestResult.worldTransform)
                sceneView.session.add(anchor: anchor)
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.touchFlg = true
            }
        }
    }
    
    @IBAction func Photoset(_ sender: Any) {
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
                let pickerView = UIImagePickerController()
                pickerView.sourceType = .photoLibrary
                pickerView.delegate = self
                pickerView.modalPresentationStyle = .overFullScreen
                self.present(pickerView, animated: true, completion: nil)
                imageMode = true
            }
        }
        
            func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info:  [UIImagePickerController.InfoKey: Any]) {
                picker.dismiss(animated: true, completion: nil)
                self.image = info[.originalImage] as! UIImage
            }
        
            func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
                picker.dismiss(animated: true, completion: nil)
            }
    
    
    
    
    
    
    @IBAction func TouchButton(_ sender: Any) {
 
        //let sphereGeometry = SCNSphere(radius: CGFloat(0.2))
            let sphereGeometry = SCNBox(width: 0.07, height: 0.07, length: 0.07, chamferRadius: 0.001)
            sphereGeometry.firstMaterial?.diffuse.contents = UIColor.white
            //sphereGeometry.firstMaterial?.transparency = 1
            sphereGeometry.firstMaterial?.writesToDepthBuffer = false
            let sphereNode = SCNNode(geometry: sphereGeometry)
            
            let shape = SCNPhysicsShape(geometry: sphereGeometry, options: nil)
            let SphereBody = SCNPhysicsBody(type: .dynamic,shape: shape)
            SphereBody.categoryBitMask = 2
            SphereBody.contactTestBitMask = 1
            SphereBody.collisionBitMask = 0
            SphereBody.isAffectedByGravity = false
            sphereNode.physicsBody = SphereBody
            
            guard let camera = sceneView.pointOfView else { return }
            sphereNode.position = camera.position
            //sphereNode.renderingOrder = -1

            let targetPosCamera = SCNVector3Make(0, 0, -4)
            let target = camera.convertPosition(targetPosCamera, to: nil)
            let action = SCNAction.move(to: target, duration: 1.5)
            sphereNode.name = "attack"
            sceneView.scene.rootNode.addChildNode(sphereNode)
            sphereNode.runAction(action)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                sphereNode.removeFromParentNode()
            }

    }
    
    
    // MARK: - Delegate

    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if anchor.name == "invader" {
            //自分が追加した場合は、invaderAで表示
            if anchor.sessionIdentifier == self.sceneView.session.identifier {
                
                if imageMode == false {
                    guard let scene = SCNScene(named: "invaderA.scn",inDirectory: "art.scnassets") else { return }
                    let sceneNode = (scene.rootNode.childNode(withName: "invaderA", recursively: false))!
                    
                    if let camera = sceneView.pointOfView {
                        sceneNode.eulerAngles.x = 90
                        sceneNode.eulerAngles.y = camera.eulerAngles.y
                    }
                    sceneNode.name = "invader"
                    node.addChildNode(sceneNode)
                    
                    guard let camera2 = sceneView.pointOfView else { return }
                    let targetPosCamera = SCNVector3Make(0, 0, -3)
                    let target = camera2.convertPosition(targetPosCamera, to: nil)
                    let action = SCNAction.move(to: SCNVector3(target.x,0,target.z), duration: 3)
                    sceneNode.runAction(action)
                    
                } else {
                    let sceneNode = SCNNode()
                    let scale = CGFloat(0.5)
                    let geometry = SCNBox(
                        width: image.size.width * scale / image.size.height,
                                    height: scale,
                                    length: 0.00000001,
                                    chamferRadius: 0.0
                    )
                    geometry.firstMaterial?.diffuse.contents = self.image
                    sceneNode.geometry = geometry
                    
                    if let camera = sceneView.pointOfView {
                        sceneNode.eulerAngles.x = 90
                        sceneNode.eulerAngles.y = camera.eulerAngles.y
                    }
                    sceneNode.name = "invader"
                    node.addChildNode(sceneNode)
                    
                    guard let camera2 = sceneView.pointOfView else { return }
                    let targetPosCamera = SCNVector3Make(0, 0, -3)
                    let target = camera2.convertPosition(targetPosCamera, to: nil)
                    let action = SCNAction.move(to: SCNVector3(target.x,0,target.z), duration: 3)
                    sceneNode.runAction(action)
                    
                }
                                
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    self.sceneView.session.remove(anchor: anchor)
                }
                
            //相手が追加した場合は、invaderBで表示
            } else {
                guard let scene = SCNScene(named: "invaderB.scn",inDirectory: "art.scnassets") else { return }
                let sceneNode = (scene.rootNode.childNode(withName: "invaderB", recursively: false))!
                
                let cylinder = SCNCylinder(radius: 1, height: 1)
                let shape = SCNPhysicsShape(geometry: cylinder, options: nil)
                let invaderBody = SCNPhysicsBody(type: .static,shape: shape)
                invaderBody.categoryBitMask = 1
                invaderBody.contactTestBitMask = 2
                invaderBody.collisionBitMask = 2
                invaderBody.isAffectedByGravity = false
                sceneNode.physicsBody = invaderBody
                
                if let camera = sceneView.pointOfView {
                    sceneNode.eulerAngles.x = 90
                    sceneNode.eulerAngles.y = camera.eulerAngles.y
                    
                    let action = SCNAction.move(to: camera.position, duration: 3)
                    sceneNode.runAction(action)
                }
                
                node.addChildNode(sceneNode)
            }
        }
        

        if anchor is ARParticipantAnchor {
            guard let scene = SCNScene(named: "invaderC.scn",inDirectory: "art.scnassets") else { return }
            let participantNode = (scene.rootNode.childNode(withName: "invaderC", recursively: false))!
            participantNode.name = "participant"
            
            let cylinder = SCNCylinder(radius: 0.1, height: 0.05)
            let shape = SCNPhysicsShape(geometry: cylinder, options: nil)
            let participantBody = SCNPhysicsBody(type: .static,shape: shape)
            participantBody.categoryBitMask = 1
            participantBody.contactTestBitMask = 2
            participantBody.collisionBitMask = 2
            participantBody.isAffectedByGravity = false
            participantNode.physicsBody = participantBody
            node.addChildNode(participantNode)
        }
        
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
         let planeGeometry = ARSCNPlaneGeometry(device: device)!
         planeGeometry.update(from: planeAnchor.geometry)
         planeAnchor.addPlaneNode(on: node, geometry: planeGeometry, contents: UIColor.black.withAlphaComponent(0.95))
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        if let planeGeometry = planeAnchor.findShapedPlaneNode(on: node)?.geometry as? ARSCNPlaneGeometry {
            planeGeometry.update(from: planeAnchor.geometry)
        }
        planeAnchor.updatePlaneNode(on: node)
    }
    
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        if let anchor = anchors.first as? ARParticipantAnchor {
            let transform = anchor.transform
            // transfromを使って相手の位置を反映など
        }
    }
    
    func session(_ session: ARSession, didOutputCollaborationData data:ARSession.CollaborationData) {
        if let collaborationDataEncoded = try? NSKeyedArchiver.archivedData(withRootObject: data, requiringSecureCoding: true){
            self.sendToAllPeers(collaborationDataEncoded)
        }
    }

    func receivedData(_ data:Data, from peer: MCPeerID) {
        if let collaborationData = try? NSKeyedUnarchiver.unarchivedObject(ofClass: ARSession.CollaborationData.self, from: data){
            self.sceneView.session.update(with: collaborationData)
        }
    }
    
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
    
        let firstNode = contact.nodeA //invader
        let secondNode = contact.nodeB //attack
        print("=== ATACK === :",firstNode,secondNode)
        
        self.Burn(firstNode,color:UIColor.green,size: CGFloat(0.001))
        self.generator_heavy.impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            firstNode.removeFromParentNode();
            secondNode.removeFromParentNode();
        }
        
        score = score + 1
        scoreLabel.text = String(score)
        if score >= 100 {
            WIN.isHidden = false
        }

        if (firstNode.name == "participant" && secondNode.name == "attack") ||
            (secondNode.name == "attack" && firstNode.name == "participant") {
            DispatchQueue.main.async {
                self.Burn(firstNode,color: UIColor.red,size: CGFloat(0.002))
                self.score = self.score - 10
            }
        }
    }
    
    func Burn(_ node:SCNNode,color:UIColor,size:CGFloat){
        let burnNode = SCNNode()
        burnNode.position = node.position
        sceneView.scene.rootNode.addChildNode(burnNode)

        let particle = SCNParticleSystem(named: "particle/bokeh_square.scnp", inDirectory: "")!
        let box = SCNBox(width: CGFloat(size), height: CGFloat(size), length: CGFloat(size), chamferRadius: 0)
        particle.emitterShape = box
        particle.particleColor = color
        let particleShapePosition = particle.emitterShape?.boundingSphere.center
        burnNode.pivot = SCNMatrix4MakeTranslation(particleShapePosition!.x, particleShapePosition!.y, 0)
        burnNode.addParticleSystem(particle)
        
        let scaleAction = SCNAction.scale(by: 1, duration: 0.2)
        let fadeAction = SCNAction.fadeOut(duration: 0.5)
        let groupAction = SCNAction.group([ scaleAction,fadeAction ])
        burnNode.runAction(groupAction)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            burnNode.removeFromParentNode();
        }
    }
    
}

// MARK: - MultipeerConnectivity

extension ViewController: MCSessionDelegate, MCNearbyServiceBrowserDelegate, MCNearbyServiceAdvertiserDelegate{
    
    func initMultipeerSession(receivedDataHandler: @escaping (Data, MCPeerID) -> Void ) {
        mpsession = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: MCEncryptionPreference.none)
        mpsession.delegate = self
        serviceAdvertiser = MCNearbyServiceAdvertiser(peer: myPeerID, discoveryInfo: nil, serviceType: ViewController.serviceType)
        serviceAdvertiser.delegate = self
        serviceAdvertiser.startAdvertisingPeer()
        serviceBrowser = MCNearbyServiceBrowser(peer: myPeerID, serviceType: ViewController.serviceType)
        serviceBrowser.delegate = self
        serviceBrowser.startBrowsingForPeers()
    }
    
    func sendToAllPeers(_ data: Data) {
         do {
            try mpsession.send(data, toPeers: mpsession.connectedPeers, with: .reliable)
         } catch {
            print("*** error sending data to peers: \(error.localizedDescription)")
        }
     }
    
    var connectedPeers: [MCPeerID] {
        return mpsession.connectedPeers
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        receivedData(data, from: peerID)
    }
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case .notConnected:
            print("*** estate: \(state)")
        case .connected:
            print("*** estate: \(state)")
            self.participantID = peerID
        case .connecting:
            print("*** estate: \(state)")
        @unknown default:
            fatalError()
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
    }
    
    func session(_ session: MCSession, didReceiveCertificate certificate: [Any]?, fromPeer peerID: MCPeerID, certificateHandler: @escaping (Bool) -> Void) {
        certificateHandler(true)
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
    }
    
    public func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        browser.invitePeer(peerID, to: mpsession, withContext: nil, timeout: 10)
    }
    
    public func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        invitationHandler(true, self.mpsession)
    }
    
}
