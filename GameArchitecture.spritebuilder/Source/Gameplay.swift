//
//  Gameplay.swift
//  GameArchitecture
//
//  Created by Varsha Ramakrishnan on 7/2/15.
//  Copyright (c) 2015 Apportable. All rights reserved.
//

import UIKit

class Gameplay: CCNode
{
    weak var character: CCSprite!
    weak var gamePhysicsNode: CCPhysicsNode!
    weak var contentNode: CCPhysicsNode!
    weak var scoreLabel: CCLabelTTF!
    var jumped = false
    var runningSpeed: Int = 400
    var levelNumber = 1
    var score: Int = 0
    {
        didSet
        {
            scoreLabel.string = "\(score)"
        }
    }
    
    
    func didLoadFromCCB()
    {
        gamePhysicsNode.collisionDelegate = self
    }

    override func onEnter()
    {
        super.onEnter()
        
        let level = CCBReader.load("Levels/Level\(levelNumber)") as! Level
        gamePhysicsNode.addChild(level)
        runningSpeed = level.runSpeed2
        
        let follow = CCActionFollow(target: character, worldBoundary: gamePhysicsNode.boundingBox())
        contentNode.position = follow.currentOffset()
        contentNode.runAction(follow)
    }
    
    override func onEnterTransitionDidFinish()
    {
        super.onEnterTransitionDidFinish()
        self.userInteractionEnabled = true
    }
    
    override func touchBegan(touch: CCTouch!, withEvent event: CCTouchEvent!)
    {
        // only runs if character is colliding with another physics object (eg. ground)
        character.physicsBody.eachCollisionPair { (pair) -> Void in
            if !self.jumped
            {
                self.character.physicsBody.applyImpulse(CGPoint(x: 0, y: 2000))
                self.jumped = true
                
                NSTimer.scheduledTimerWithTimeInterval(0.3, target: self, selector: Selector("resetJump"), userInfo: nil, repeats: false)
            }
        }
    }
    
    func resetJump()
    {
        jumped = false
    }
    
    override func fixedUpdate(delta: CCTime)
    {
        character.physicsBody.velocity = CGPoint(x: CGFloat(runningSpeed), y: character.physicsBody.velocity.y)
    }
    
    func ccPhysicsCollisionBegin(pair: CCPhysicsCollisionPair!, hero: CCNode!, flag: CCNode!) -> Bool
    {
        paused = true
        let popup = CCBReader.load("WinPopup", owner: self) as! WinPopup
        popup.positionType = CCPositionType(xUnit: .Normalized, yUnit: .Normalized, corner: .BottomLeft)
        popup.position = CGPoint(x: 0.5, y: 0.5)
        
        parent.addChild(popup)
        
        return true
    }
    
    func ccPhysicsCollisionBegin(pair: CCPhysicsCollisionPair!, hero: CCNode!, star: Star!) -> Bool
    {
        score++
        gamePhysicsNode.space.addPostStepBlock({ () -> Void in
            self.starRemoved(star)
            }, key: star)
        return true
    }
    
    func starRemoved(star: Star)
    {
        // load particle effect
        let explosion = CCBReader.load("StarExplosion") as! CCParticleSystem
        // make the particle effect clean itself up, once it is completed
        explosion.autoRemoveOnFinish = true;
        // place the particle effect on the seals position
        explosion.position = star.position;
        // add the particle effect to the same node the seal is on
        star.parent.addChild(explosion)
        // finally, remove the seal from the level
        star.removeFromParent()
    }
    
    func loadNextLevel()
    {
        levelNumber++
        loadLevel()
    }
    
    func loadLevel()
    {
        let gameplay = CCBReader.load("Gameplay") as! Gameplay
        gameplay.levelNumber = levelNumber
        
        let scene = CCScene()
        scene.addChild(gameplay)
        
        let transition = CCTransition(fadeWithDuration: 0.8)
        CCDirector.sharedDirector().presentScene(scene, withTransition: transition)
    }
    
    override func update(delta: CCTime)
    {
        if CGRectGetMaxY(character.boundingBox()) < CGRectGetMinY(gamePhysicsNode.boundingBox())
        {
            println("HOW DO YOU EXPECT TO OUTRUN HIM WHEN HES ALREADY THERE")
            gameOver()
        }
    }
    
    func gameOver()
    {
        loadLevel()
    }
}
