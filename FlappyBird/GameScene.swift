//
//  GameScene.swift
//  FlappyBird
//
//  Created by ICHIRO KAWATA on 2018/07/08.
//  Copyright © 2018年 ICHIRO KAWATA. All rights reserved.
//

import SpriteKit
import AVFoundation

class GameScene: SKScene, SKPhysicsContactDelegate, AVAudioPlayerDelegate {
    
    var scrollNode:SKNode!
    var wallNode:SKNode!
    var bird:SKSpriteNode!
    var item:SKSpriteNode!
    
    var audioPlayer:AVAudioPlayer!
    var audioPlayer2:AVAudioPlayer!
    
    //衝突判定カテゴリーの追加
    let birdCategory: UInt32 = 1 << 0       // 0...00001
    let groundCategory: UInt32 = 1 << 1     // 0...00010
    let wallCategory: UInt32 = 1 << 2       // 0...00100
    let scoreCategory: UInt32 = 1 << 3      // 0...01000
    let itemCategory: UInt32 = 1 << 4       // 0...10000
    
    //スコア
    var score = 0
    var itemScore = 0
    var scoreLabelNode:SKLabelNode!
    var bestScoreLabelNode:SKLabelNode!
    var itemScoreLabelNode:SKLabelNode!
    let userDefaults:UserDefaults = UserDefaults.standard    // 追加
    
    
    // SKView上にシーンが表示されたときに呼ばれるメソッド
    override func didMove(to view: SKView) {
        // 背景色を設定
        backgroundColor = UIColor(red: 0.15, green: 0.75, blue: 0.90, alpha: 1)
        
        //スクロールするスプライトの親ノード
        scrollNode = SKNode()
        addChild(scrollNode)
        
        // 壁用のノード
        wallNode = SKNode()
        scrollNode.addChild(wallNode)
        
        // 各種スプライトを生成する処理をメソッドに分割
        setupGround()
        setupCloud()
        setupWall()
        setupBird()
        
        setupScoreLabel()
        
        //y方面に重力を設定
        physicsWorld.gravity = CGVector(dx: 0.0, dy: -4.0)
        //衝突時に呼び出されるデリゲート
        physicsWorld.contactDelegate = self
        
        //サウンド関連
        let audioPath = Bundle.main.path(forResource: "getitem", ofType:"mp3")!
        let audioUrl = URL(fileURLWithPath: audioPath)
        
        let audioPath2 = Bundle.main.path(forResource: "BGM", ofType:"mp3")!
        let audioUrl2 = URL(fileURLWithPath: audioPath2)
        
        // auido を再生するプレイヤーを作成する
        var audioError:NSError?
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: audioUrl)
        } catch let error as NSError {
            audioError = error
            audioPlayer = nil
        }
        
        var audioError2:NSError?
        do {
            audioPlayer2 = try AVAudioPlayer(contentsOf: audioUrl2)
        } catch let error as NSError {
            audioError2 = error
            audioPlayer2 = nil
        }
        
        // エラーが起きたとき
        if let error = audioError {
            print("Error \(error.localizedDescription)")
        }
        if let error = audioError2 {
            print("Error\(error.localizedDescription)")
        }
        
        audioPlayer.delegate = self
        audioPlayer.prepareToPlay()
        
        audioPlayer2.delegate = self
        audioPlayer2.numberOfLoops = -1
        audioPlayer2.prepareToPlay()
        
        //BGM再生
        audioPlayer2.play()
    }
    func setupGround(){
        // 地面の画像を読み込む
        let groundTexture = SKTexture(imageNamed: "ground")
        groundTexture.filteringMode = .nearest
        
        //必要な枚数を計算
        let needNumber = Int(self.frame.size.width / groundTexture.size().width) + 2
        
        //スクロールするアクションを作成
        //左方向に画像一枚分スクロールさせるアクション
        let moveGround = SKAction.moveBy(x: -groundTexture.size().width , y: 0, duration: 5.0)
        
        // 元の位置に戻すアクション
        let resetGround = SKAction.moveBy(x: groundTexture.size().width, y: 0, duration: 0.0)
        
        // 左にスクロール->元の位置->左にスクロールと無限に繰り替えるアクション
        let repeatScrollGround = SKAction.repeatForever(SKAction.sequence([moveGround, resetGround]))
        
        // groundのスプライとを配置する。
        for i in 0..<needNumber {
            let Sprite = SKSpriteNode(texture: groundTexture)
            
            // スプライトの表示する位置を指定する
            Sprite.position = CGPoint(
                x: groundTexture.size().width * (CGFloat(i) + 0.5),
                y: groundTexture.size().height * 0.5
            )
            
            // スプライトにアクションを設定する
            Sprite.run(repeatScrollGround)
            
            // スプライトに物理演算を設定する
            Sprite.physicsBody = SKPhysicsBody(rectangleOf: groundTexture.size())
            
            // 衝突の時に動かないように設定する
            Sprite.physicsBody?.isDynamic = false
            
            // カテゴリー設定
            Sprite.physicsBody?.categoryBitMask = groundCategory
            
            //スプライトを追加する
            scrollNode.addChild(Sprite)
        }
    }
    
    func setupCloud(){
        // 雲の画像を読み込む
        let cloudTexture = SKTexture(imageNamed: "cloud")
        cloudTexture.filteringMode = .nearest
        
        // 必要な枚数を計算
        let needCloudNumber = Int(self.frame.size.width / cloudTexture.size().width) + 2
        
        // スクロールするアクションを作成
        // 左方向に画像一枚分スクロールさせるアクション
        let moveCloud = SKAction.moveBy(x: -cloudTexture.size().width , y: 0, duration: 20.0)
        
        // 元の位置に戻すアクション
        let resetCloud = SKAction.moveBy(x: cloudTexture.size().width, y: 0, duration: 0.0)
        
        // 左にスクロール->元の位置->左にスクロールと無限に繰り替えるアクション
        let repeatScrollCloud = SKAction.repeatForever(SKAction.sequence([moveCloud, resetCloud]))
        
        // スプライトを配置する
        for i in 0..<needCloudNumber {
            let sprite = SKSpriteNode(texture: cloudTexture)
            sprite.zPosition = -100 // 一番後ろになるようにする
            
            // スプライトの表示する位置を指定する
            sprite.position = CGPoint(
                x: cloudTexture.size().width * (CGFloat(i) + 0.5),
                y: self.size.height - cloudTexture.size().height * 0.5
            )
            
            // スプライトにアニメーションを設定する
            sprite.run(repeatScrollCloud)
            
            // スプライトを追加する
            scrollNode.addChild(sprite)
        }
    }
    func setupWall(){
        // 壁の画像を読み込む
        let wallTexture = SKTexture(imageNamed: "wall")
        wallTexture.filteringMode = .linear
        
        // 移動する距離を計算
        let movingDistance = CGFloat(self.frame.size.width + wallTexture.size().width) * 2
        
        // 画面外まで移動するアクションを作成
        let moveWall = SKAction.moveBy(x: -movingDistance, y: 0, duration:8.0)
        
        // 自身を取り除くアクションを作成
        let removeWall = SKAction.removeFromParent()
        
        // 2つのアニメーションを順に実行するアクションを作成
        let wallAnimation = SKAction.sequence([moveWall, removeWall])
        
        // 壁を生成するアクションを作成
        let createWallAnimation = SKAction.run({
            // 壁関連のノードを乗せるノードを作成
            let wall = SKNode()
            wall.position = CGPoint(x: self.frame.size.width + wallTexture.size().width / 2, y: 0.0)
            wall.zPosition = -50.0 // 雲より手前、地面より奥
            
            // 画面のY軸の中央値
            let center_y = self.frame.size.height / 2
            // 壁のY座標を上下ランダムにさせるときの最大値
            let random_y_range = self.frame.size.height / 4
            // 下の壁のY軸の下限
            let under_wall_lowest_y = UInt32( center_y - wallTexture.size().height / 2 -  random_y_range / 2)
            // 1〜random_y_rangeまでのランダムな整数を生成
            let random_y = arc4random_uniform( UInt32(random_y_range) )
            // Y軸の下限にランダムな値を足して、下の壁のY座標を決定
            let under_wall_y = CGFloat(under_wall_lowest_y + random_y)
            
            
            // キャラが通り抜ける隙間の長さ
            let slit_length = self.frame.size.height / 6
            
            // 下側の壁を作成
            let under = SKSpriteNode(texture: wallTexture)
            under.position = CGPoint(x: 0.0, y: under_wall_y)
            
            // スプライトに物理演算を設定する
            under.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())
            //設定したカテゴリーに追加
            under.physicsBody?.categoryBitMask = self.wallCategory
            
            // 衝突の時に動かないように設定する
            under.physicsBody?.isDynamic = false
            
            wall.addChild(under)
            
            // 上側の壁を作成
            let upper = SKSpriteNode(texture: wallTexture)
            upper.position = CGPoint(x: 0.0, y: under_wall_y + wallTexture.size().height + slit_length)
            
            // スプライトに物理演算を設定する
            upper.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())
            //設定したカテゴリーに追加
            upper.physicsBody?.categoryBitMask = self.wallCategory
            
            // 衝突の時に動かないように設定する
            upper.physicsBody?.isDynamic = false
            
            wall.addChild(upper)
            
            //壁同士の間のノード（スコアアップ用）
            let scoreNode = SKNode()
            scoreNode.position = CGPoint(x: upper.size.width + self.bird.size.width / 2, y: self.frame.height / 2.0)
            scoreNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: upper.size.width, height: self.frame.size.height))
            scoreNode.physicsBody?.isDynamic = false
            scoreNode.physicsBody?.categoryBitMask = self.scoreCategory
            scoreNode.physicsBody?.contactTestBitMask = self.birdCategory  //birdCategoryとの衝突を判定
            
            wall.addChild(scoreNode)
            
            //アイテムの生成用にsetupitemを作成していましたが、下の壁の高さを利用してアイテムのy座標を決定したい都合上アイテムより先に壁を出現させる必要があり、簡単化のためsetupwall内でアイテムを生成します。
            //アイテム画像読み込み
            let itemTexture = SKTexture(imageNamed: "item")
            itemTexture.filteringMode = .linear
            
            
            //テクスチャを指定してスプライト作成
            let itemSprite = SKSpriteNode(texture: itemTexture)
            
            //新たなランダム値を作成
            let random_y_range2 = self.frame.size.height / 3
            let random_y2 = arc4random_uniform( UInt32(random_y_range2) )
            
            //アイテムの座標の下限
            
            let item_y_lowest = UInt32(self.frame.size.height) / 12
            
            //下の壁の高さ
            let underwall_top = UInt32(under_wall_y) + UInt32(wallTexture.size().height / 2)
            
            // アイテムのY座標を決定
            let item_y = underwall_top - item_y_lowest + random_y2
            
            //スプライトの表示位置を指定
            itemSprite.position = CGPoint(
                x: self.frame.size.width / 4,
                y: CGFloat(item_y)
            )
            
            //アイテムのスプライトに物理演算を設定
            itemSprite.physicsBody = SKPhysicsBody(circleOfRadius: itemSprite.size.height / 3.0)
            itemSprite.physicsBody?.categoryBitMask = self.itemCategory
            itemSprite.physicsBody?.contactTestBitMask = self.birdCategory  //birdCategoryとの衝突を判定
            
            //重力の影響を無効化、衝突時に動かない
            itemSprite.physicsBody?.isDynamic = false
            
            
            wall.addChild(itemSprite)
            
            wall.run(wallAnimation)
            
            self.wallNode.addChild(wall)
        })
        
        // 次の壁作成までの待ち時間のアクションを作成
        let waitAnimation = SKAction.wait(forDuration: 2)
        
        // 壁を作成->待ち時間->壁を作成を無限に繰り替えるアクションを作成
        let repeatForeverAnimation = SKAction.repeatForever(SKAction.sequence([createWallAnimation, waitAnimation]))
        
        wallNode.run(repeatForeverAnimation)
    }
    func setupBird() {
        // 鳥の画像を2種類読み込む
        let birdTextureA = SKTexture(imageNamed: "bird_a")
        birdTextureA.filteringMode = .linear
        let birdTextureB = SKTexture(imageNamed: "bird_b")
        birdTextureB.filteringMode = .linear
        
        // 2種類のテクスチャを交互に変更するアニメーションを作成
        let texuresAnimation = SKAction.animate(with: [birdTextureA, birdTextureB], timePerFrame: 0.2)
        let flap = SKAction.repeatForever(texuresAnimation)
        
        // スプライトを作成
        bird = SKSpriteNode(texture: birdTextureA)
        bird.position = CGPoint(x: self.frame.size.width * 0.2, y:self.frame.size.height * 0.7)
        
        // 物理演算を設定
        bird.physicsBody = SKPhysicsBody(circleOfRadius: bird.size.height / 2.0)
        
        //衝突時に回転させない
        bird.physicsBody?.allowsRotation = false
        
        // 衝突のカテゴリー設定
        bird.physicsBody?.categoryBitMask = birdCategory    // ←カテゴリーを設定追加
        bird.physicsBody?.collisionBitMask = groundCategory | wallCategory    // ←当たった時に跳ね返る相手を設定
        bird.physicsBody?.contactTestBitMask = groundCategory | wallCategory    // 代入値との衝突を判定
        
        // アニメーションを設定
        bird.run(flap)
        
        // スプライトを追加する  鳥はスクロールしないからbirdに追加
        addChild(bird)
    }
    
    // 画面をタップした時に呼ばれる
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if scrollNode.speed > 0{
            // 鳥の速度をゼロにする
            bird.physicsBody?.velocity = CGVector.zero
            
            // 鳥に縦方向の力を与える
            bird.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 15))
        }else if bird.speed == 0 {
            restart()
        }
    }
    
    // SKPhysicsContactDelegateのメソッド。衝突したときに呼ばれる
    func didBegin(_ contact: SKPhysicsContact) {
        // ゲームオーバーのときは何もしない
        if scrollNode.speed <= 0 {
            return
        }
        
        if (contact.bodyA.categoryBitMask & scoreCategory) == scoreCategory || (contact.bodyB.categoryBitMask & scoreCategory) == scoreCategory {
            // スコア用の物体と衝突した
            print("ScoreUp")
            score += 1
            scoreLabelNode.text = "Score:\(score)"  //表示に反映
            
            //ベストスコアか確認
            var bestScore = userDefaults.integer(forKey: "BEST")  //最初にはデフォルトで０が入っている。
            if score > bestScore{
                bestScore = score
                bestScoreLabelNode.text = "Best Score:\(bestScore)" //先に表示に反映
                userDefaults.set(bestScore, forKey: "BEST") //スコア更新
                userDefaults.synchronize()  //ユーザーデフォルトに即座に保存
            }
        }else if (contact.bodyA.categoryBitMask & itemCategory) == itemCategory ||      (contact.bodyB.categoryBitMask & itemCategory) == itemCategory{
            //アイテムと衝突した
            print("itemScoreUp")
            itemScore += 1
            itemScoreLabelNode.text = "ItemScore:\(itemScore)"  //表示に反映
            audioPlayer.play()     //音を鳴らす
           
            if (contact.bodyA.categoryBitMask & itemCategory) == itemCategory{
                contact.bodyA.node?.removeFromParent()
            }
            else if (contact.bodyB.categoryBitMask & itemCategory) == itemCategory{
                contact.bodyB.node?.removeFromParent()
            }
        }else {
            // 壁か地面と衝突した
            print("GameOver")
            
            // スクロールを停止させる
            scrollNode.speed = 0
            
            bird.physicsBody?.collisionBitMask = groundCategory
            
            let roll = SKAction.rotate(byAngle: CGFloat(Double.pi) * CGFloat(bird.position.y) * 0.01, duration:1)
            bird.run(roll, completion:{  //completion 要求が完了した後に実行される処理を設定。今回はスピードを０に。
                self.bird.speed = 0
            })
        }
    }
    //リスタート処理
    func restart() {
        score = 0
        scoreLabelNode.text = String("Score:\(score)")
        
        itemScore = 0
        itemScoreLabelNode.text = String("ItemScore:\(itemScore)")
        
        bird.position = CGPoint(x: self.frame.size.width * 0.2, y:self.frame.size.height * 0.7)
        bird.physicsBody?.velocity = CGVector.zero    //落ちた時点でもう止まってるから今回のアプリではあまり意味ないけど
        bird.physicsBody?.collisionBitMask = groundCategory | wallCategory
        bird.zRotation = 0.0
        
        wallNode.removeAllChildren()
        
        bird.speed = 1   //鳥のアニメーションの速度　つまり羽ばたき速度
        scrollNode.speed = 1
    }
    //スコア表示
    func setupScoreLabel(){
        score = 0
        scoreLabelNode = SKLabelNode()
        scoreLabelNode.fontColor = UIColor.black
        scoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 60)
        scoreLabelNode.zPosition = 100 // 一番手前に表示する
        scoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        scoreLabelNode.text = "Score:\(score)"
        self.addChild(scoreLabelNode)
        
        bestScoreLabelNode = SKLabelNode()
        bestScoreLabelNode.fontColor = UIColor.black
        bestScoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 90)
        bestScoreLabelNode.zPosition = 100 // 一番手前に表示する
        bestScoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        
        let bestScore = userDefaults.integer(forKey: "BEST")
        bestScoreLabelNode.text = "Best Score:\(bestScore)"
        self.addChild(bestScoreLabelNode)
        
        itemScore = 0
        itemScoreLabelNode = SKLabelNode()
        itemScoreLabelNode.fontColor = UIColor.black
        itemScoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 120)
        itemScoreLabelNode.zPosition = 100 // 一番手前に表示する
        itemScoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        itemScoreLabelNode.text = "ItemScore:\(itemScore)"
        self.addChild(itemScoreLabelNode)
    }
}
