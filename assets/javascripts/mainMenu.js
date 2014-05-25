
BasicGame.MainMenu = function (game) {

  this.music = null;
  this.playButton = null;

};

BasicGame.MainMenu.prototype = {

  create: function () {

    //  We've already preloaded our assets, so let's kick right into the Main Menu itself.
    //  Here all we're doing is playing some music and adding a picture and button
    //  Naturally I expect you to do something significantly better :)

    this.add.sprite(0, 0, 'titlepage');

    this.loadingText = this.add.text(510, 520, "Press Z or tap/click game to start", { font: "24px monospace", fill: "#fff" , align: "center"});
    this.loadingText.anchor.setTo(0.5, 0.5);
    this.aboutText = this.add.text(510, 590, "Press Q or tap/click this blurb to share\nor learn more about this game\n(including how to make it)", { font: "18px monospace", fill: "#fff" , align: "center"});
    this.aboutText.anchor.setTo(0.5, 0.5);
    this.aboutText.inputEnabled = true;
    this.aboutText.events.onInputDown.add(function() {
      this.disableGame = true;
      window.location = "./about.html";
    }, this);
    this.add.text(510, 680, "image assets Copyright (c) 2002 Ari Feldman\nsound assets Copyright (c) 2012 dklon", { font: "16px monospace", fill: "#fff", align: "center"}).anchor.setTo(0.5, 0.5);

  },

  update: function () {
    if (!this.disableGame && (this.input.keyboard.isDown(Phaser.Keyboard.Z) || this.input.activePointer.isDown)) {
      this.startGame();
    }
    if (this.input.keyboard.isDown(Phaser.Keyboard.Q)) {
      window.location = "./about.html";
    }
    //  Do some nice funky main menu effect here

  },

  startGame: function (pointer) {

    //  Ok, the Play Button has been clicked or touched, so let's stop the music (otherwise it'll carry on playing)
    //  And start the actual game
    this.state.start('Game');

  }

};
