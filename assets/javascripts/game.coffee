class BasicGame.Game
  constructor: (game) ->
  PLAYER_SPEED: 300
  create: ->
    @sea = @add.tileSprite(0, 0, 1024, 768, "sea")
    @player = @add.sprite(400, 650, "player")
    @player.anchor.setTo 0.5, 0.5
    @player.animations.add "fly", [0, 1, 2], 20, true
    @player.animations.add "ghost", [3, 0, 3, 1], 20, true
    @player.play "fly"
    @game.physics.enable @player, Phaser.Physics.ARCADE
    @player.body.collideWorldBounds = true
    @player.body.setSize 20, 20, 0, -5

    @weaponPower = 0
    @weaponType = 0

    prepEnemies = [
      {
        key: "greenEnemy"
        count: 50
      }
      {
        key: "whiteEnemy"
        count: 20
      }
      {
        key: "boss"
        count: 1
      }
    ]
    @enemies = []
    for i in [0..2]
      enemyGroup = @add.group()
      enemyGroup.enableBody = true
      enemyGroup.physicsBodyType = Phaser.Physics.ARCADE
      enemyGroup.createMultiple prepEnemies[i]["count"], prepEnemies[i]["key"], 0, false
      enemyGroup.setAll "anchor.x", 0.5
      enemyGroup.setAll "anchor.y", 0.5
      enemyGroup.setAll "outOfBoundsKill", true
      enemyGroup.setAll "checkWorldBounds", true
      enemyGroup.forEach (enemy) ->
        enemy.animations.add "fly", [
          0
          1
          2
        ], 20, true
        enemy.animations.add "hit", [
          3
          1
          3
          2
        ], 20, false
        enemy.events.onAnimationComplete.add ((e) ->
          e.play "fly"
          return
        ), this
        return

      @enemies.push enemyGroup
    @nextEnemy = [0, 0]
    @spawnRate = [1000, null]
    @killCount = [0, 0]
    @wave = 1
    @boss = null
    @bullets = @add.group()
    @bullets.enableBody = true
    @bullets.physicsBodyType = Phaser.Physics.ARCADE
    @bullets.createMultiple 200, "bullet", 0, false
    @bullets.setAll "anchor.x", 0.5
    @bullets.setAll "anchor.y", 0.5
    @bullets.setAll "outOfBoundsKill", true
    @bullets.setAll "checkWorldBounds", true
    @nextFire = 0
    @enemyBullets = @add.group()
    @enemyBullets.enableBody = true
    @enemyBullets.physicsBodyType = Phaser.Physics.ARCADE
    @enemyBullets.createMultiple 200, "enemyBullet", 0, false
    @enemyBullets.setAll "anchor.x", 0.5
    @enemyBullets.setAll "anchor.y", 0.5
    @enemyBullets.setAll "outOfBoundsKill", true
    @enemyBullets.setAll "checkWorldBounds", true

    @powerUps = []
    for i in [1..2]
      enemyGroup = @add.group()
      enemyGroup.enableBody = true
      enemyGroup.physicsBodyType = Phaser.Physics.ARCADE
      enemyGroup.createMultiple 20, "pow#{i}", 0, false
      enemyGroup.setAll "anchor.x", 0.5
      enemyGroup.setAll "anchor.y", 0.5
      enemyGroup.setAll "outOfBoundsKill", true
      enemyGroup.setAll "checkWorldBounds", true
      @powerUps.push enemyGroup

    @explosions = @add.group()
    @explosions.enableBody = true
    @explosions.physicsBodyType = Phaser.Physics.ARCADE
    @explosions.createMultiple 100, "explosion", 0, false
    @explosions.setAll "anchor.x", 0.5
    @explosions.setAll "anchor.y", 0.5
    @explosions.forEach (explosion) ->
      explosion.animations.add "boom"
      return

    @lives = @add.group()
    
    for i in [0..2]
      life = @lives.create(924 + (30 * i), 30, "player")
      life.scale.setTo 0.5, 0.5
      life.anchor.setTo 0.5, 0.5

    @cursors = @input.keyboard.createCursorKeys()
    @instructions = @add.text(510, 600, "Use Arrow Keys to Move, Press Z to Fire\n" + "Tapping/clicking does both",
      font: "20px monospace"
      fill: "#fff"
      align: "center"
    )
    @instructions.anchor.setTo 0.5, 0.5
    @instExpire = @time.now + 10000
    @score = 0
    @scoreText = @add.text(510, 30, "" + @score,
      font: "20px monospace"
      fill: "#fff"
      align: "center"
    )
    @scoreText.anchor.setTo 0.5, 0.5

    @enemyDeathSFX = @add.audio('enemyDeath')
    @enemyFireSFX = @add.audio('enemyFire')
    @playerDeathSFX = @add.audio('playerDeath')
    @playeFireSFX = @add.audio('playerFire')
    @pickupSFX = @add.audio('pickup')
    return

  update: ->
    @sea.tilePosition.y += 0.2
    
    for i in [0, 1]
      @physics.arcade.overlap @bullets, @enemies[i], @enemyHit, null, this
      @physics.arcade.overlap @player, @enemies[i], @playerHit, null, this
      @physics.arcade.overlap @player, @powerUps[i], @playerPowerUp, null, this
      
    @physics.arcade.overlap @bullets, @enemies[2], @enemyHit, null, this  if @boss and @boss.form > 1
    @physics.arcade.overlap @player, @enemyBullets, @playerHit, null, this
    @checkWave()
    @changeBossBehavior()  if @boss
    @spawnEnemies()
    @enemyFire()
    @processPlayerInput()
    if @ghostUntil and @ghostUntil < @time.now
      @ghostUntil = null
      @player.play "fly"
    @instructions.destroy()  if @instructions.exists and @time.now > @instExpire
    if @showReturn and @time.now > @showReturn
      @returnText = @add.text(512, 600, "Press Z or Tap Game to go back to Main Menu",
        font: "16px sans-serif"
        fill: "#fff"
      ).anchor.setTo(0.5, 0.5)
      @showReturn = null
    return

  checkWave: ->
    if @wave is 1 and @score >= 2000
      @wave = 2
      @spawnRate = [800, 2500]
    else if @wave is 2 and @score >= 5000
      @wave = 3
      @spawnRate = [600, 2000]
    else if @wave is 3 and @score >= 10000
      @wave = 4
      @spawnRate = [500, 1500]
    else if @wave is 4 and @score >= 17500
      @wave = 5
      @spawnRate = [200, 1000]
    else if @wave is 5 and @score >= 25000
      @wave = 6
      @spawnRate = [750, null]
      @spawnBoss()
    return

  spawnBoss: ->
    @boss = @enemies[2].getFirstExists(false)
    @boss.reset 512, 0
    @boss.form = 1
    @boss.body.velocity.y = 15
    @boss.play "fly"
    return

  changeBossBehavior: ->
    if @boss.form is 1 and @boss.y > 80
      @boss.form = 2
      @boss.health = 1000
      @boss.body.velocity.y = 0
      @boss.body.velocity.x = 200
      @boss.body.bounce.setTo 1, 1
      @boss.body.collideWorldBounds = true
      @boss.nextFire = 0
    return

  enemyFire: ->
    @enemies[1].forEachAlive ((enemy) ->
      if @time.now > enemy.nextFire and @enemyBullets.countDead() > 0
        @spawnEnemyBullet enemy.x, enemy.y
        @enemyFireSFX.play()
        enemy.nextFire = @time.now + 1900
      return
    ), this
    if @boss and @boss.alive and @boss.form > 1 and @time.now > @boss.nextFire
      @enemyFireSFX.play()
      switch
        when @boss.health > 750
          if @boss.form is 2
            @boss.body.velocity.x *= 0.9
            @boss.form = 3
          @spawnEnemyBullet @boss.x - 20, @boss.y + 20
          @spawnEnemyBullet @boss.x + 20, @boss.y + 20
          @spawnEnemyBullet @boss.x - 40, @boss.y + 20
          @spawnEnemyBullet @boss.x + 40, @boss.y + 20
          @boss.nextFire = @time.now + 1000
        when @boss.health > 500
          if @boss.form is 3
            @boss.body.velocity.x *= 0.8
            @boss.form = 4
          @spawnEnemyBullet @boss.x - 20, @boss.y + 20
          @spawnEnemyBullet @boss.x + 20, @boss.y + 20
          @spawnEnemyBullet @boss.x - 30, @boss.y + 20
          @spawnEnemyBullet @boss.x + 30, @boss.y + 20
          @spawnEnemyBullet @boss.x - 40, @boss.y + 20
          @spawnEnemyBullet @boss.x + 40, @boss.y + 20
          @boss.nextFire = @time.now + 700
        when @boss.health > 250
          if @boss.form is 4
            @boss.body.velocity.x *= 0.7
            @boss.form = 5
          @spawnEnemyBullet @boss.x - 20, @boss.y + 20
          @spawnEnemyBullet @boss.x + 20, @boss.y + 20
          @spawnEnemyBulletToXY @boss.x - 30, @boss.y + 20, @player.x - 100, @player.y
          @spawnEnemyBulletToXY @boss.x + 30, @boss.y + 20, @player.x + 100, @player.y
          @spawnEnemyBulletToXY @boss.x - 40, @boss.y + 20, @player.x - 200, @player.y
          @spawnEnemyBulletToXY @boss.x + 40, @boss.y + 20, @player.x + 200, @player.y
          @boss.nextFire = @time.now + 700
        else
          for i in [0..12]
            @spawnEnemyBulletToAngle @boss.x + 30 - (i * 5), @boss.y + 20, (30 + (i*10))
          @boss.nextFire = @time.now + 700
    return

  spawnEnemyBullet: (x, y) ->
    return if @enemyBullets.countDead() is 0
    bullet = @enemyBullets.getFirstExists(false)
    bullet.reset x, y
    @physics.arcade.moveToObject bullet, @player, 150
    return

  spawnEnemyBulletToXY: (x, y, targetX, targetY) ->
    return if @enemyBullets.countDead() is 0
    bullet = @enemyBullets.getFirstExists(false)
    bullet.reset x, y
    @physics.arcade.moveToXY bullet, targetX, targetY, 150
    return

  spawnEnemyBulletToAngle: (x, y, angle) ->
    return if @enemyBullets.countDead() is 0
    bullet = @enemyBullets.getFirstExists(false)
    bullet.reset x, y
    @game.physics.arcade.velocityFromAngle(angle, 150, bullet.body.velocity)
    return

  spawnEnemies: ->
    for i in [0, 1]
      if @spawnRate[i] and @nextEnemy[i] < @time.now and @enemies[i].countDead() > 0
        @nextEnemy[i] = @time.now + @spawnRate[i]
        enemy = @enemies[i].getFirstExists(false)
        if i is 0
          enemy.reset @rnd.integerInRange(20, 1004), 0
          enemy.body.velocity.y = @rnd.integerInRange(30, 60)
          enemy.health = 2
        else
          enemy.reset @rnd.integerInRange(20, 1004), 0
          target = @rnd.integerInRange(20, 1004)
          enemy.rotation = @physics.arcade.moveToXY(enemy, target, 768, @rnd.integerInRange(30, 80)) - Math.PI / 2
          enemy.health = 5
          enemy.nextFire = 0
        enemy.play "fly"
    return

  processPlayerInput: ->
    @player.body.velocity.x = 0
    @player.body.velocity.y = 0
    if @cursors.left.isDown
      @player.body.velocity.x = -@PLAYER_SPEED
    else @player.body.velocity.x = @PLAYER_SPEED  if @cursors.right.isDown
    if @cursors.up.isDown
      @player.body.velocity.y = -@PLAYER_SPEED
    else @player.body.velocity.y = @PLAYER_SPEED  if @cursors.down.isDown
    @game.physics.arcade.moveToPointer @player, @PLAYER_SPEED  if @game.input.activePointer.isDown and @game.physics.arcade.distanceToPointer(@player) > 15
    if @input.keyboard.isDown(Phaser.Keyboard.Z) or @input.activePointer.isDown
      if @returnText
        @quitGame()
      else
        @fire()
    return

  fire: ->
    if @player.alive and @nextFire < @time.now
      @nextFire = @time.now + 100
      @playeFireSFX.play()
      switch @weaponType
        when 0
          if @bullets.countDead() > 0
            bullet = @bullets.getFirstExists(false)
            bullet.reset @player.x, @player.y - 20
            bullet.body.velocity.y = -500
        when 1
          @fireSpread()
        when 2
          @fireFocused()

    return

  fireSpread: ->
    for i in [1..@weaponPower]
      if @bullets.countDead() > 1
        bullet = @bullets.getFirstExists(false)
        bullet.reset @player.x + (4 + i * 6), @player.y - 20
        @game.physics.arcade.velocityFromAngle(-95 + i * 10, 500, bullet.body.velocity)
        bullet = @bullets.getFirstExists(false)
        bullet.reset @player.x - (4 + i * 6), @player.y - 20
        @game.physics.arcade.velocityFromAngle(-85 - i * 10, 500, bullet.body.velocity)

  fireFocused: ->
    for i in [0...@weaponPower]
      if @bullets.countDead() > 1
        bullet = @bullets.getFirstExists(false)
        bullet.reset @player.x - (3 + i * 5), @player.y - 20
        bullet.body.velocity.y = -500
        bullet = @bullets.getFirstExists(false)
        bullet.reset @player.x + (3 + i * 5), @player.y - 20
        bullet.body.velocity.y = -500


  enemyHit: (bullet, enemy) ->
    bullet.kill()
    @damageEnemy enemy, 1
    return

  playerHit: (player, enemy) ->
    return  if @ghostUntil and @ghostUntil > @time.now
    @damageEnemy enemy, 5
    @playerDeathSFX.play()
    life = @lives.getFirstAlive()
    if life
      life.kill()
      @ghostUntil = @time.now + 3000
      @player.play "ghost"
      @weaponPower = 0
      @weaponType = 0
    else
      @explode player
      player.kill()
      @displayEnd false
    return

  playerPowerUp: (player, powerUp) ->
    @pickupSFX.play()
    @score += 100
    powType = parseInt(powerUp.key.slice(3))
    # console.log powType
    if powType isnt @weaponType
      @weaponType = powType
      @weaponPower = 1
    else
      @weaponPower += 1 if @weaponPower < 5
    powerUp.kill()

  damageEnemy: (enemy, damage) ->
    enemy.damage damage
    if enemy.alive
      enemy.play "hit"
    else
      @explode enemy
      @enemyDeathSFX.play()
      if enemy.key is "greenEnemy"
        @score += 100
        @killCount[0]++
        @spawnPowerUp(0.3, enemy)
      else if enemy.key is "whiteEnemy"
        @score += 200
        @killCount[1]++
        @spawnPowerUp(0.5, enemy)
      else if enemy.key is "boss"
        @score += 20000
        @displayEnd true
      @scoreText.text = @score
    return

  explode: (sprite) ->
    explosion = @explosions.getFirstExists(false)
    if explosion
      explosion.reset sprite.x, sprite.y
      explosion.play "boom", 15, false, true
      explosion.body.velocity.x = sprite.body.velocity.x
      explosion.body.velocity.y = sprite.body.velocity.y
    return

  spawnPowerUp: (chance, body) ->
    return if @weaponPower >= 5 and @rnd.frac() > 0.1
    if @rnd.frac() < chance
      @pow = @rnd.integerInRange(0, 1)
      if @powerUps[@pow].countDead() > 0
        powerUp = @powerUps[@pow].getFirstExists(false)
        powerUp.reset(body.x, body.y)
        powerUp.body.velocity.y = 20

  render: ->

  displayEnd: (win) ->
    msg = (if win then "You Win!!!" else "Game Over!")
    @add.text(510, 150, msg,
      font: "72px 'Army Wide',serif"
      fill: "#fff"
    ).anchor.setTo 0.5, 0

    @add.text(530, 250, "Your kills:",
      font: "28px 'Army Wide',serif"
      fill: "#fff"
    ).anchor.setTo 0.5, 0
    @add.sprite(480, 310, 'greenEnemy').anchor.setTo 0, 0
    @add.text(530, 320, "x   #{@killCount[0]}",
      font: "16px 'Army Wide',serif"
      fill: "#fff"
    ).anchor.setTo 0, 0
    @add.sprite(480, 360, 'whiteEnemy').anchor.setTo 0, 0
    @add.text(530, 370, "x   #{@killCount[1]}",
      font: "16px 'Army Wide',serif"
      fill: "#fff"
    ).anchor.setTo 0, 0
    if win
      @add.sprite(450, 420, 'boss').anchor.setTo 0, 0
      @add.text(560, 460, "x   1",
        font: "16px 'Army Wide',serif"
        fill: "#fff"
      ).anchor.setTo 0, 0
      @scoreText.text = @score
      @enemies[0].destroy()
      @enemies[1].destroy()
      @enemyBullets.destroy()
    @showReturn = @time.now + 2000
    return

  quitGame: (pointer) ->
    
    #  Here you should destroy anything you no longer need.
    #  Stop music, delete sprites, purge caches, free resources, all that good stuff.
    @returnText = null
    @scoreText.text = this.score
    @enemies[0].destroy()
    @enemies[1].destroy()
    @bullets.destroy()
    @enemyBullets.destroy()
    
    
    #  Then let's go back to the main menu.
    @state.start "MainMenu"
    return
