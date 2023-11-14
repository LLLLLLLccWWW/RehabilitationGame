import processing.serial.*;
Serial port;

PFont chineseFont; // 創建中文字體變數
float accelerationX = 0;
float accelerationY = 0;
float unit = 0.25; // 單位（每0.25為一個單位）
boolean pressureSensorPressed = false; // 追蹤壓力感測器是否被按下
float pressureSensorValue = 0; // 初始化壓力感測器數值

import processing.core.*;
import processing.sound.*;
import processing.data.*;
import java.util.Map;
import javax.swing.JTextField;
import javax.swing.JOptionPane;
HashMap<Character, Boolean> keys;
String gameState = "startPage";

SoundFile bgMusic;
SoundFile pressMusic;
SoundFile timesupMusic;
SoundFile gameMusic;
SoundFile hrgameMusic;
SoundFile hitMusic;

// start
PImage startImage;
int ButtonX = 300;
int ButtonY = 400;
int buttonWidth = 200;
int buttonHeight = 50;
boolean gameStarted = false;

// degree
int easyButtonX = 300;
int easyButtonY = 300;
int easybuttonWidth = 200;
int easybuttonHeight = 50;

int middleButtonX = 300;
int middleButtonY = 400;
int middlebuttonWidth = 200;
int middlebuttonHeight = 50;

int hardButtonX = 300;
int hardButtonY = 500;
int hardbuttonWidth = 200;
int hardbuttonHeight = 50;

// game
int score = 0; // 分數
int moleX, moleY; // 地鼠的座標
boolean moleVisible = false; // 地鼠是否可見
PImage moleImage;
PImage bgImage;
PImage hmImage;
PImage holeImage;
PImage sqImage;
PImage crImage;
PImage deImage;
PImage hrholeImage;

// 地洞
int numHoles = 6;
int[] holeX = {100, 300, 500, 100, 300, 500};
int[] holeY = {150, 150, 150, 350, 350, 350};
int holeSize = 150;  // 地洞大小

int easyHoles = 3;
int[] easyholeX = {100, 300, 500};
int[] easyholeY = {200, 200, 200};
int easyholeSize = 150;  // 地洞大小

int moleWidth = 80;
int moleHeight = 80;

int fButtonX = 10;
int fButtonY = 500;
int fbuttonWidth = 100;
int fbuttonHeight = 50;

int sButtonX = 700;
int sButtonY = 500;
int sbuttonWidth = 100;
int sbuttonHeight = 50;

int saveButtonX = 345;
int saveButtonY = 500;
int savebuttonWidth = 100;
int savebuttonHeight = 50;

boolean gamePaused = false;

color buttoncolor;
color buttonMcolor;
color buttonColor;

color stbuttoncolor;
PFont myFont;

// 時間
int timer = 60;

// Table
Table EasyscoreTable;
Table MiddlescoreTable;
Table HardscoreTable;
int i = 1;

String playerName = "";
boolean nameEntered = false;
boolean scoreSaved = false;
boolean saveScoreTriggered = false;
boolean saveButtonVisible = false;
boolean saveButtonEnabled = true;

String getPlayerName() {
  // 提示玩家輸入名字
  JTextField playerNameField = new JTextField();
  Object[] message = {"請輸入你的名字:", playerNameField};
  JOptionPane.showConfirmDialog(null, message, "輸入名字", JOptionPane.OK_CANCEL_OPTION);

  return playerNameField.getText();
}

void setup() {
  port = new Serial(this, "COM3", 9600); // 根據您的Arduino串口端口和波特率設定

  size(800, 600);
  startImage = loadImage("../startImg.jpg");
  startImage.resize(width, height);

  playerName = getPlayerName();

  //音效
  bgMusic = new SoundFile(this, "Mario Bros -Remix(Chill Trap).mp3");
  pressMusic = new SoundFile(this, "computer-processing-sound-effects-short-click-select-03-122132.mp3");
  timesupMusic = new SoundFile(this, "Super Mario Bros. Level Complete Soundtrack - Sound Effect for editing.mp3");
  gameMusic = new SoundFile(this, "Super Mario Bros. Music - Underwater (Hurry).mp3");
  hrgameMusic = new SoundFile(this, "Super Mario Bros (NES) Music - Castle Theme.mp3");
  hitMusic = new SoundFile(this, "sm64_enemy_down_1.wav");

  gameMusic.amp(0.2);
  hrgameMusic.amp(0.2);
  bgMusic.amp(0.5);

  moleImage = loadImage("../mole.png");
  bgImage = loadImage("../bg.jpg");
  hmImage = loadImage("../hammer.png");
  holeImage = loadImage("../hole.png");
  sqImage = loadImage("../sq.png");
  crImage = loadImage("../circle.png");
  deImage = loadImage("../Degree of difficulty.jpg");
  hrholeImage = loadImage("../hardhole.png");

  //初始化地鼠的位置（與第一個地洞一致）
  moleX = holeX[0];
  moleY = holeY[0];

  moleX = easyholeX[0];
  moleY = easyholeY[0];

  frameRate(30);
  moleImage.resize(moleWidth, moleHeight);
  bgImage.resize(width, height);
  hmImage.resize(150, 150);
  holeImage.resize(200, 200);
  sqImage.resize(140, 100);
  crImage.resize(100, 100);
  stbuttoncolor = color(100, 100, 100);
  buttoncolor = color(100, 100, 100);
  buttonMcolor = color(100, 100, 100);
  buttonColor = color(100, 100, 100);
  deImage.resize(width, height);
  hrholeImage.resize(200, 200);
  noStroke();
  bgMusic.loop();

  // 存檔(Easy)
  EasyscoreTable = new Table();
  EasyscoreTable.addColumn("Inning");
  EasyscoreTable.addColumn("Date");
  EasyscoreTable.addColumn("Name");
  EasyscoreTable.addColumn("Score");

  // 存檔(Middle)
  MiddlescoreTable = new Table();
  MiddlescoreTable.addColumn("Inning");
  MiddlescoreTable.addColumn("Date");
  MiddlescoreTable.addColumn("Name");
  MiddlescoreTable.addColumn("Score");

  // 存檔(Hard)
  HardscoreTable = new Table();
  HardscoreTable.addColumn("Inning");
  HardscoreTable.addColumn("Date");
  HardscoreTable.addColumn("Name");
  HardscoreTable.addColumn("Score");

  //輸入法
  surface.setAlwaysOnTop(true);
  PFont font = createFont("Arial", 32);
  textFont(font);

  keys = new HashMap<Character, Boolean>();
}

void draw() {
  //讀取從Arduino發送過來的加速度數據
  while (port.available() > 0) {
    String data = port.readStringUntil('\n');
    if (data != null) {
      String[] values = split(data, ',');
      if (values.length == 3) {
        // 四捨五入加速度數值到最接近的0.25的倍數
        accelerationX = round(float(values[0]) / unit) * unit;
        accelerationY = round(float(values[1]) / unit) * unit;
        //accelerationX = float(values[0]);
        //accelerationY = float(values[1]);
        pressureSensorValue = float(values[2]); // 更新壓力感測器數值
      }
    }
  }
  //更新位置
  float maxSpeed = 100; // 最大速度
  float speedX = map(abs(accelerationX), 0, 1, 0, maxSpeed);
  float speedY = map(abs(accelerationY), 0, 1, 0, maxSpeed);

  if (accelerationX < 0) {
    speedX = -speedX; // X軸小於0向左移動
  }
  if (accelerationY > 0) {
    speedY = -speedY; // Y軸小於0向下移動
  }

  mouseX += speedX;
  mouseY += speedY;

  background(startImage);
  if (gameState.equals("startPage")) {
    background(startImage);
    textSize(16);
    text("pressure: " + pressureSensorValue, 70, 100);
    text("mouseX: " + mouseX, 70, 120);
    text("mouseY: " + mouseY, 70, 140);
    text("accelerationX: " + accelerationX, 70, 160);
    text("accelerationY: " + accelerationY, 70, 180);
    
    // 製作按鈕
    fill(stbuttoncolor);
    rect(ButtonX, ButtonY, buttonWidth, buttonHeight);
    fill(255);
    textSize(20);
    textAlign(CENTER, CENTER);
    text("Press to start~", ButtonX + buttonWidth / 2, ButtonY + buttonHeight / 2);
    noStroke();

    if (mouseX >= ButtonX && mouseX <= ButtonX + buttonWidth && mouseY >= ButtonY && mouseY <= ButtonY + buttonHeight) {
      cursor(HAND);  // 當鼠標在按鈕範圍內時，將鼠標設置為手形
      stbuttoncolor = color(0, 100, 100);
    } else {
      cursor(ARROW);  // 在其他地方時，恢復鼠標為箭頭形狀
      stbuttoncolor = color(100, 100, 100);
    }
  } else if (gameState.equals("degreeSelection")) {
    background(deImage);

    // 製作按鈕
    fill(buttoncolor);
    rect(easyButtonX, easyButtonY, easybuttonWidth, easybuttonHeight);
    fill(255);
    textSize(20);
    textAlign(CENTER, CENTER);
    text("Easy", easyButtonX + easybuttonWidth / 2, easyButtonY + easybuttonHeight / 2);

    fill(buttonMcolor);
    rect(middleButtonX, middleButtonY, middlebuttonWidth, middlebuttonHeight);
    fill(255);
    textSize(20);
    textAlign(CENTER, CENTER);
    text("middle", middleButtonX + middlebuttonWidth / 2, middleButtonY + middlebuttonHeight / 2);

    fill(buttonColor);
    rect(hardButtonX, hardButtonY, hardbuttonWidth, hardbuttonHeight);
    fill(255);
    textSize(20);
    textAlign(CENTER, CENTER);
    text("Hard", hardButtonX + hardbuttonWidth / 2, hardButtonY + hardbuttonHeight / 2);

    if (mouseX >= easyButtonX && mouseX <= easyButtonX + easybuttonWidth && mouseY >= easyButtonY && mouseY <= easyButtonY + easybuttonHeight) {
      cursor(HAND);  // 當鼠標在按鈕範圍內時，將鼠標設置為手形
      buttoncolor = color(0, 20, 100);
    } else if (mouseX >= middleButtonX && mouseX <= middleButtonX + middlebuttonWidth && mouseY >= middleButtonY && mouseY <= middleButtonY + middlebuttonHeight) {
      cursor(HAND);  // 當鼠標在按鈕範圍內時，將鼠標設置為手形
      buttonMcolor = color(0, 127, 0);
    } else if (mouseX >= hardButtonX && mouseX <= hardButtonX + hardbuttonWidth && mouseY >= hardButtonY && mouseY <= hardButtonY + hardbuttonHeight) {
      cursor(HAND);  // 當鼠標在按鈕範圍內時，將鼠標設置為手形
      buttonColor = color(127, 0, 0);
    } else {
      cursor(ARROW);  // 在其他地方時，恢復鼠標為箭頭形狀
      buttoncolor = color(100, 100, 100);
      buttonMcolor = color(100, 100, 100);
      buttonColor = color(100, 100, 100);
    }
  } else if (gameState.equals("easyGame")) {
    background(bgImage);
    //textSize(16);
    //text("pressure: " + pressureSensorValue, 70, 100);
    //text("mouseX: " + mouseX, 70, 120);
    //text("mouseY: " + mouseY, 70, 140);
    //text("accelerationX: " + accelerationX, 70, 160);
    //text("accelerationY: " + accelerationY, 70, 180);
    
    // 畫按鈕
    image(crImage, fButtonX, fButtonY);
    fill(255);
    textSize(20);
    textAlign(CENTER, CENTER);
    if (timer > 0) {
      text("Pause", fButtonX + crImage.width / 2, fButtonY + crImage.height / 2);
    } else {
      text("Again", fButtonX + crImage.width / 2, fButtonY + crImage.height / 2);
    }
    // 畫按鈕(回首頁)
    image(crImage, sButtonX, sButtonY);

    fill(255);
    textSize(20);
    textAlign(CENTER, CENTER);
    text("回首頁", sButtonX + crImage.width / 2, sButtonY + crImage.height / 2);

    // 畫地洞
    for (int i = 0; i < easyHoles; i++) {
      image(holeImage, easyholeX[i], easyholeY[i]);
    }
    if (!gamePaused && timer > 0) {
      if (!gameMusic.isPlaying()) {
        gameMusic.play();
      }
      // 控制地鼠的顯示
      if (frameCount % 30 ==  0) { // 每隔30幀顯示地鼠
        moleVisible = true;
        timer--;
        // 隨機選擇一個地洞的位置作為地鼠的初始位置
        int randomHoleIndex = int(random(easyHoles));
        moleX = easyholeX[randomHoleIndex] + easyholeSize / 2 - moleWidth / 2 + 30;
        moleY = easyholeY[randomHoleIndex] + easyholeSize / 2 - moleHeight / 2 - 30;
      }

      if (moleVisible) {
        // 地鼠圖片
        image(moleImage, moleX, moleY);
      }

      // 檢測鼠標是否在按鈕範圍內
      if (mouseX >=  fButtonX && mouseX <=  fButtonX + crImage.width && mouseY >=  crImage.height && mouseY <=  fButtonY + crImage.height ||
        mouseX >=  sButtonX && mouseX <=  sButtonX + crImage.width && mouseY >=  crImage.height && mouseY <=  sButtonY + crImage.height ) {
        cursor(HAND);  // 當鼠標在按鈕範圍內時，將鼠標設置為手形
      } else {
        cursor(ARROW);  // 在其他地方時，恢復鼠標為箭頭形狀
      }
    }

    // 檢查是否在按鈕範圍內並且壓力值小於1300
    if (moleVisible && 
      mouseX > moleX - 50 && mouseX < moleX + moleImage.width + 50 &&
      mouseY> moleY - 50 && mouseY < moleY + moleImage.height + 50 && 
      pressureSensorValue < 1300) {
      mousePressed = true;
      if (mousePressed) {
        mousePressed = false;
        println("按鈕被按下！", pressureSensorValue);
        moleVisible = false;
        score +=1;
        hitMusic.play();
        // 重新設定地鼠位置
        int randomHoleIndex = int(random(easyHoles));
        moleX = easyholeX[randomHoleIndex] - easyholeSize / 2 + moleWidth / 2;
        moleY = easyholeY[randomHoleIndex] - easyholeSize / 2 + moleHeight / 2;
      }
    } else if (timer ==  0) {
      fill(0);
      textSize(48);
      text("Time's Up!!!!!", 400, 50);
      stroke(255, 0, 0);
      gameMusic.stop();
      if (!timesupMusic.isPlaying()) {
        timesupMusic.play();
      }
      if (mouseX >=  fButtonX && mouseX <=  fButtonX + crImage.width && mouseY >=  crImage.height && mouseY <=  fButtonY + crImage.height ||
        mouseX >=  sButtonX && mouseX <=  sButtonX + crImage.width && mouseY >=  crImage.height && mouseY <=  sButtonY + crImage.height ||
        mouseX >=  saveButtonX && mouseX <=  saveButtonX + crImage.width && mouseY >=  crImage.height && mouseY <=  saveButtonY + crImage.height) {
        cursor(HAND);  // 當鼠標在按鈕範圍內時，將鼠標設置為手形
      } else {
        cursor(ARROW);  // 在其他地方時，恢復鼠標為箭頭形狀
      }
      image(crImage, saveButtonX, saveButtonY);
      fill(255);
      textSize(20);
      textAlign(CENTER, CENTER);
      text("save", saveButtonX + crImage.width / 2, saveButtonY + crImage.height / 2);
    }

    // 暫停狀態
    else if (gamePaused) {
      fill(0);
      textSize(48);
      text("Paused!!", 400, 50);
      stroke(255, 0, 0);
      if (mouseX >=  fButtonX && mouseX <=  fButtonX + crImage.width && mouseY >=  crImage.height && mouseY <=  fButtonY + crImage.height ||
        mouseX >=  sButtonX && mouseX <=  sButtonX + crImage.width && mouseY >=  crImage.height && mouseY <=  sButtonY + crImage.height) {
        cursor(HAND);  // 當鼠標在按鈕範圍內時，將鼠標設置為手形
      } else {
        cursor(ARROW);  // 在其他地方時，恢復鼠標為箭頭形狀
      }
    }

    // 錘子
    float hammerX = mouseX - 50;
    float hammerY = mouseY - 50;
    
    // 確保鼠標在視窗範圍內
    mouseX = constrain(mouseX, 50, 700 ); // width 是窗口宽度
    mouseY = constrain(mouseY, 50, 550 ); // height 是窗口高度
    
    // 確保 hammerX 和 hammerY 在視窗範圍內
    hammerX = constrain(hammerX, 0, width - hmImage.width); // width 是窗口宽度
    hammerY = constrain(hammerY, 0, height - hmImage.height); // height 是窗口高度
    image(hmImage, hammerX, hammerY);

    // 顯示分數
    fill(0);
    image(sqImage, 0, 5);
    myFont = createFont("Bold", 28);
    textFont(myFont);
    text("score:" + score, 55, 30);

    // 顯示時間
    fill(0);
    image(sqImage, 675, 5);
    myFont = createFont("Bold", 28);
    textFont(myFont);
    text("time:" + timer, 730, 30);
  } else if (gameState.equals("middleGame")) {
    background(bgImage);
    //textSize(16);
    //text("pressure: " + pressureSensorValue, 70, 100);
    //text("mouseX: " + mouseX, 70, 120);
    //text("mouseY: " + mouseY, 70, 140);
    //text("accelerationX: " + accelerationX, 70, 160);
    //text("accelerationY: " + accelerationY, 70, 180);

    // 畫按鈕
    image(crImage, fButtonX, fButtonY);
    fill(255);
    textSize(20);
    textAlign(CENTER, CENTER);
    if (timer > 0) {
      text("Pause", fButtonX + crImage.width / 2, fButtonY + crImage.height / 2);
    } else {
      text("Again", fButtonX + crImage.width / 2, fButtonY + crImage.height / 2);
    }

    // 畫按鈕(回首頁)
    image(crImage, sButtonX, sButtonY);

    fill(255);
    textSize(20);
    textAlign(CENTER, CENTER);
    text("回首頁", sButtonX + crImage.width / 2, sButtonY + crImage.height / 2);

    // 畫地洞
    for (int i = 0; i < numHoles; i++) {
      image(holeImage, holeX[i], holeY[i]);
    }
    if (!gamePaused && timer > 0) {
      if (!gameMusic.isPlaying()) {
        gameMusic.play();
      }

      // 控制地鼠的顯示
      if (frameCount % 23 ==  0) { // 每隔30幀顯示地鼠
        moleVisible = true;
        timer--;
        // 隨機選擇一個地洞的位置作為地鼠的初始位置
        int randomHoleIndex = int(random(numHoles));
        moleX = holeX[randomHoleIndex] + holeSize / 2 - moleWidth / 2 + 30;
        moleY = holeY[randomHoleIndex] + holeSize / 2 - moleHeight / 2 - 30;
      }

      if (moleVisible) {
        // 地鼠圖片
        image(moleImage, moleX, moleY);
      }
      // 檢測鼠標是否在按鈕範圍內
      if (mouseX >=  fButtonX && mouseX <=  fButtonX + crImage.width && mouseY >=  crImage.height && mouseY <=  fButtonY + crImage.height ||
        mouseX >=  sButtonX && mouseX <=  sButtonX + crImage.width && mouseY >=  crImage.height && mouseY <=  sButtonY + crImage.height) {
        cursor(HAND);  // 當鼠標在按鈕範圍內時，將鼠標設置為手形
      } else {
        cursor(ARROW);  // 在其他地方時，恢復鼠標為箭頭形狀
      }
    }

    // 檢查是否在按鈕範圍內並且壓力值小於1300
    if (moleVisible && 
      mouseX > moleX - 50 && mouseX < moleX + moleImage.width + 50 &&
      mouseY> moleY - 50 && mouseY < moleY + moleImage.height + 50 && 
      pressureSensorValue < 1300) {
      mousePressed = true;
      if (mousePressed) {
        mousePressed = false;
        println("按鈕被按下！", pressureSensorValue);
        moleVisible = false;
        score +=1;
        hitMusic.play();

        // 重新設定地鼠位置
        int randomHoleIndex = int(random(easyHoles));
        moleX = easyholeX[randomHoleIndex] - easyholeSize / 2 + moleWidth / 2;
        moleY = easyholeY[randomHoleIndex] - easyholeSize / 2 + moleHeight / 2;
      }
    } else if (timer ==  0) {
      fill(0);
      textSize(48);
      text("Time's Up!!!!!", 400, 50);
      stroke(255, 0, 0);
      gameMusic.stop();
      if (!timesupMusic.isPlaying()) {
        timesupMusic.play();
      }

      if (mouseX >=  fButtonX && mouseX <=  fButtonX + crImage.width && mouseY >=  crImage.height && mouseY <=  fButtonY + crImage.height ||
        mouseX >=  sButtonX && mouseX <=  sButtonX + crImage.width && mouseY >=  crImage.height && mouseY <=  sButtonY + crImage.height ||
        mouseX >=  saveButtonX && mouseX <=  saveButtonX + crImage.width && mouseY >=  crImage.height && mouseY <=  saveButtonY + crImage.height) {
        cursor(HAND);  // 當鼠標在按鈕範圍內時，將鼠標設置為手形
      } else {
        cursor(ARROW);  // 在其他地方時，恢復鼠標為箭頭形狀
      }
      image(crImage, saveButtonX, saveButtonY);
      fill(255);
      textSize(20);
      textAlign(CENTER, CENTER);
      text("save", saveButtonX + crImage.width / 2, saveButtonY + crImage.height / 2);
    }

    //暫停狀態
    else if (gamePaused) {
      fill(0);
      textSize(48);
      text("Paused!!", 400, 50);
      stroke(255, 0, 0);
      if (mouseX >=  fButtonX && mouseX <=  fButtonX + crImage.width && mouseY >=  crImage.height && mouseY <=  fButtonY + crImage.height ||
        mouseX >=  sButtonX && mouseX <=  sButtonX + crImage.width && mouseY >=  crImage.height && mouseY <=  sButtonY + crImage.height) {
        cursor(HAND);  // 當鼠標在按鈕範圍內時，將鼠標設置為手形
      } else {
        cursor(ARROW);  // 在其他地方時，恢復鼠標為箭頭形狀
      }
    }

    // 錘子
    float hammerX = mouseX - 50;
    float hammerY = mouseY - 50;

    // 確保鼠標在視窗範圍內
    mouseX = constrain(mouseX, 50, 700 ); // width 是窗口宽度
    mouseY = constrain(mouseY, 50, 550 ); // height 是窗口高度

    // 確保 hammerX 和 hammerY 在視窗範圍內
    hammerX = constrain(hammerX, 0, width - hmImage.width); // width 是窗口宽度
    hammerY = constrain(hammerY, 0, height - hmImage.height); // height 是窗口高度
    image(hmImage, hammerX, hammerY);

    // 顯示分數
    fill(0);
    image(sqImage, 0, 5);
    myFont = createFont("Bold", 28);
    textFont(myFont);
    text("score:" + score, 55, 30);

    // 顯示時間
    fill(0);
    image(sqImage, 675, 5);
    myFont = createFont("Bold", 28);
    textFont(myFont);
    text("time:" + timer, 730, 30);
  } else if (gameState.equals("hardGame")) {
    background(bgImage);
    //textSize(16);
    //text("pressure: " + pressureSensorValue, 70, 100);
    //text("mouseX: " + mouseX, 70, 120);
    //text("mouseY: " + mouseY, 70, 140);
    //text("accelerationX: " + accelerationX, 70, 160);
    //text("accelerationY: " + accelerationY, 70, 180);
    
    // 畫按鈕
    image(crImage, fButtonX, fButtonY);
    fill(255);
    textSize(20);
    textAlign(CENTER, CENTER);
    if (timer > 0) {
      text("Pause", fButtonX + crImage.width / 2, fButtonY + crImage.height / 2);
    } else {
      text("Again", fButtonX + crImage.width / 2, fButtonY + crImage.height / 2);
    }

    // 畫按鈕(回首頁)
    image(crImage, sButtonX, sButtonY);

    fill(255);
    textSize(20);
    textAlign(CENTER, CENTER);
    text("回首頁", sButtonX + crImage.width / 2, sButtonY + crImage.height / 2);

    // 畫地洞
    for (int i = 0; i < numHoles; i++) {
      image(hrholeImage, holeX[i], holeY[i]);
    }
    if (!gamePaused && timer > 0) {
      if (!hrgameMusic.isPlaying()) {
        hrgameMusic.play();
      }
      // 控制地鼠的顯示
      if (timer <=  60 && timer >=  40) {
        if (frameCount % 30 == 0) { // 每隔30幀顯示地鼠
          moleVisible = true;
          timer--;
          // 隨機選擇一個地洞的位置作為地鼠的初始位置
          int randomHoleIndex = int(random(numHoles));
          moleX = holeX[randomHoleIndex] + holeSize / 2 - moleWidth / 2 + 30;
          moleY = holeY[randomHoleIndex] + holeSize / 2 - moleHeight / 2 - 30;
        }

        if (moleVisible) {
          // 地鼠圖片
          image(moleImage, moleX, moleY);
        }

        // 檢測鼠標是否在按鈕範圍內
        if (mouseX >=  fButtonX && mouseX <=  fButtonX + crImage.width && mouseY >=  crImage.height && mouseY <=  fButtonY + crImage.height ||
          mouseX >=  sButtonX && mouseX <=  sButtonX + crImage.width && mouseY >=  crImage.height && mouseY <=  sButtonY + crImage.height) {
          cursor(HAND);  // 當鼠標在按鈕範圍內時，將鼠標設置為手形
        } else {
          cursor(ARROW);  // 在其他地方時，恢復鼠標為箭頭形狀
        }
      } else if (timer < 40 && timer >=  20) {
        if (frameCount % 20 == 0) { // 每隔20幀顯示地鼠
          moleVisible = true;
          timer--;

          // 隨機選擇一個地洞的位置作為地鼠的初始位置
          int randomHoleIndex = int(random(numHoles));
          moleX = holeX[randomHoleIndex] + holeSize / 2 - moleWidth / 2 + 30;
          moleY = holeY[randomHoleIndex] + holeSize / 2 - moleHeight / 2 - 30;
        }

        if (moleVisible) {
          // 地鼠圖片
          image(moleImage, moleX, moleY);
        }

        // 檢測鼠標是否在按鈕範圍內
        if (mouseX >=  fButtonX && mouseX <=  fButtonX + crImage.width && mouseY >=  crImage.height && mouseY <=  fButtonY + crImage.height ||
          mouseX >=  sButtonX && mouseX <=  sButtonX + crImage.width && mouseY >=  crImage.height && mouseY <=  sButtonY + crImage.height) {
          cursor(HAND);  // 當鼠標在按鈕範圍內時，將鼠標設置為手形
        } else {
          cursor(ARROW);  // 在其他地方時，恢復鼠標為箭頭形狀
        }
      } else if (timer < 20 &&  timer >=  0) {
        if (frameCount % 18 == 0) { // 每隔18幀顯示地鼠
          moleVisible = true;
          timer--;
          // 隨機選擇一個地洞的位置作為地鼠的初始位置
          int randomHoleIndex = int(random(numHoles));
          moleX = holeX[randomHoleIndex] + holeSize / 2 - moleWidth / 2 + 30;
          moleY = holeY[randomHoleIndex] + holeSize / 2 - moleHeight / 2 - 30;
        }

        if (moleVisible) {
          // 地鼠圖片
          image(moleImage, moleX, moleY);
        }

        // 檢測鼠標是否在按鈕範圍內
        if (mouseX >=  fButtonX && mouseX <=  fButtonX + crImage.width && mouseY >=  crImage.height && mouseY <=  fButtonY + crImage.height ||
          mouseX >=  sButtonX && mouseX <=  sButtonX + crImage.width && mouseY >=  crImage.height && mouseY <=  sButtonY + crImage.height) {
          cursor(HAND);  // 當鼠標在按鈕範圍內時，將鼠標設置為手形
        } else {
          cursor(ARROW);  // 在其他地方時，恢復鼠標為箭頭形狀
        }
      }
    }

    // 檢查是否在按鈕範圍內並且壓力值小於1300
    if (moleVisible && 
      mouseX > moleX - 50 && mouseX < moleX + moleImage.width + 50 &&
      mouseY> moleY - 50 && mouseY < moleY + moleImage.height + 50 && 
      pressureSensorValue < 1300) {
      mousePressed = true;
      if (mousePressed) {
        mousePressed = false;
        println("按鈕被按下！", pressureSensorValue);
        moleVisible = false;
        score +=1;
        hitMusic.play();

        // 重新設定地鼠位置
        int randomHoleIndex = int(random(easyHoles));
        moleX = easyholeX[randomHoleIndex] - easyholeSize / 2 + moleWidth / 2;
        moleY = easyholeY[randomHoleIndex] - easyholeSize / 2 + moleHeight / 2;
      }
    } else if (timer ==  0) {
      fill(0);
      textSize(48);
      text("Time's Up!!!!!", 400, 50);
      stroke(255, 0, 0);
      if (mouseX >=  fButtonX && mouseX <=  fButtonX + crImage.width && mouseY >=  crImage.height && mouseY <=  fButtonY + crImage.height ||
        mouseX >=  sButtonX && mouseX <=  sButtonX + crImage.width && mouseY >=  crImage.height && mouseY <=  sButtonY + crImage.height ||
        mouseX >=  saveButtonX && mouseX <=  saveButtonX + crImage.width && mouseY >=  crImage.height && mouseY <=  saveButtonY + crImage.height) {
        cursor(HAND);  // 當鼠標在按鈕範圍內時，將鼠標設置為手形
      } else {
        cursor(ARROW);  // 在其他地方時，恢復鼠標為箭頭形狀
      }
      hrgameMusic.stop();
      if (!timesupMusic.isPlaying()) {
        timesupMusic.play();
      }

      image(crImage, saveButtonX, saveButtonY);
      fill(255);
      textSize(20);
      textAlign(CENTER, CENTER);
      text("save", saveButtonX + crImage.width / 2, saveButtonY + crImage.height / 2);
    }

    //暫停狀態
    else if (gamePaused) {
      fill(0);
      textSize(48);
      text("Paused!!", 400, 50);
      stroke(255, 0, 0);
      if (mouseX >=  fButtonX && mouseX <=  fButtonX + crImage.width && mouseY >=  crImage.height && mouseY <=  fButtonY + crImage.height ||
        mouseX >=  sButtonX && mouseX <=  sButtonX + crImage.width && mouseY >=  crImage.height && mouseY <=  sButtonY + crImage.height) {
        cursor(HAND);  // 當鼠標在按鈕範圍內時，將鼠標設置為手形
      } else {
        cursor(ARROW);  // 在其他地方時，恢復鼠標為箭頭形狀
      }
    }

    // 錘子
    float hammerX = mouseX - 50;
    float hammerY = mouseY - 50;

    // 確保鼠標在視窗範圍內
    mouseX = constrain(mouseX, 50, 700 ); // width 是窗口宽度
    mouseY = constrain(mouseY, 50, 550 ); // height 是窗口高度

    // 確保 hammerX 和 hammerY 在視窗範圍內
    hammerX = constrain(hammerX, 0, width - hmImage.width); // width 是窗口宽度
    hammerY = constrain(hammerY, 0, height - hmImage.height); // height 是窗口高度
    image(hmImage, hammerX, hammerY);

    // 顯示分數
    fill(0);
    image(sqImage, 0, 5);
    myFont = createFont("Bold", 28);
    textFont(myFont);
    text("score:" + score, 55, 30);

    // 顯示時間
    fill(0);
    image(sqImage, 675, 5);
    myFont = createFont("Bold", 28);
    textFont(myFont);
    text("time:" + timer, 730, 30);
  }
}

void mouseClicked() {
  if (gameState.equals("startPage")) {
    if (mouseX >= ButtonX && mouseX <= ButtonX + buttonWidth && mouseY >= ButtonY && mouseY <= ButtonY + buttonHeight) {
      score = 0;
      timer = 60;
      pressMusic.play();
      gameMusic.stop();
      hrgameMusic.stop();
      gameState = "degreeSelection";  // 切換到難易度選擇頁面
    }
  } else if (gameState.equals("degreeSelection")) {
    if (mouseX >= easyButtonX && mouseX <= easyButtonX + easybuttonWidth && mouseY >= easyButtonY && mouseY <= easyButtonY + easybuttonHeight) {
      bgMusic.stop();
      pressMusic.play();
      gameState = "easyGame";
    } else if (mouseX >= middleButtonX && mouseX <= middleButtonX + middlebuttonWidth && mouseY >= middleButtonY && mouseY <= middleButtonY + middlebuttonHeight) {
      bgMusic.stop();
      pressMusic.play();
      gameState = "middleGame";
    } else if (mouseX >= hardButtonX && mouseX <= hardButtonX + hardbuttonWidth && mouseY >= hardButtonY && mouseY <= hardButtonY + hardbuttonHeight) {
      bgMusic.stop();
      pressMusic.play();
      gameState = "hardGame";
    }
  } else if (gameState.equals("easyGame")) {
    // 檢查是否點擊到地鼠
    if (!gamePaused && timer > 0) {
      if (moleVisible && 
        mouseX > moleX - 50 && mouseX < moleX + moleImage.width + 50 &&
        mouseY > moleY - 50 && mouseY < moleY + moleImage.height + 50) {
          println("按鈕被按下！");
          moleVisible = false;
          score += 1;
          hitMusic.play();
          // 重新設定地鼠位置
          int randomHoleIndex = int(random(easyHoles));
          moleX = easyholeX[randomHoleIndex] - easyholeSize / 2 + moleWidth / 2;
          moleY = easyholeY[randomHoleIndex] - easyholeSize / 2 + moleHeight / 2;
      }
    }
    if (mouseX >=  fButtonX && mouseX <=  fButtonX + fbuttonWidth && mouseY >=  fButtonY && mouseY <=  fButtonY + fbuttonHeight) {
      if (timer ==  0) {
        //重新開始
        score = 0;
        timer = 60;
        pressMusic.play();
        gameMusic.stop();
        hrgameMusic.stop();
        timesupMusic.stop();
      } else {
        gamePaused = !gamePaused;
        pressMusic.play();
        gameMusic.pause();
      }
    }
    if (mouseX >=  sButtonX && mouseX <=  sButtonX + sbuttonWidth && mouseY >=  sButtonY && mouseY <=  sButtonY + sbuttonHeight) {
      gameState = "startPage";
      gameMusic.stop();
      hrgameMusic.stop();
      timesupMusic.stop();
      pressMusic.play();
      bgMusic.loop();
      score = 0;
      timer = 60;
      gamePaused = false;
    }
    if (mouseX >=  saveButtonX && mouseX <=  saveButtonX + savebuttonWidth && mouseY >=  saveButtonY && mouseY <=  saveButtonY + savebuttonHeight) {
      if (timer ==  0) {
        saveEasyScore(score, playerName);
      }
    }
  } else if (gameState.equals("middleGame")) {
    // 檢查是否點擊到地鼠
    if (!gamePaused && timer > 0) {
      if (moleVisible && 
        mouseX > moleX - 50 && mouseX < moleX + moleImage.width + 50 &&
        mouseY > moleY - 50 && mouseY < moleY + moleImage.height + 50) {
        println("按鈕被按下！");
        moleVisible = false;
        score +=1;
        hitMusic.play();
        // 重新設定地鼠位置
        int randomHoleIndex = int(random(numHoles));
        moleX = holeX[randomHoleIndex] - holeSize / 2 + moleWidth / 2;
        moleY = holeY[randomHoleIndex] - holeSize / 2 + moleHeight / 2;
      }
    }

    if (mouseX >=  fButtonX && mouseX <=  fButtonX + fbuttonWidth && mouseY >=  fButtonY && mouseY <=  fButtonY + fbuttonHeight) {
      if (timer ==  0) {
        //重新開始
        score = 0;
        timer = 60;
        pressMusic.play();
        gameMusic.stop();
        hrgameMusic.stop();
        timesupMusic.stop();
      } else {
        gamePaused = !gamePaused;
        pressMusic.play();
        gameMusic.pause();
      }
    }
    if (mouseX >=  sButtonX && mouseX <=  sButtonX + sbuttonWidth && mouseY >=  sButtonY && mouseY <=  sButtonY + sbuttonHeight) {
      gameState = "startPage";
      gameMusic.stop();
      hrgameMusic.stop();
      timesupMusic.stop();
      pressMusic.play();
      bgMusic.loop();
      score = 0;
      timer = 60;
      gamePaused = false;
    }
    if (mouseX >=  saveButtonX && mouseX <=  saveButtonX + savebuttonWidth && mouseY >=  saveButtonY && mouseY <=  saveButtonY + savebuttonHeight) {
      if (timer ==  0) {
        saveMiddleScore(score, playerName);
      }
    }
  } else if (gameState.equals("hardGame")) {
    // 檢查是否點擊到地鼠
    if (!gamePaused && timer > 0) {
      if (moleVisible && 
        mouseX > moleX - 50 && mouseX < moleX + moleImage.width + 50 &&
        mouseY > moleY - 50 && mouseY < moleY + moleImage.height + 50) {
        moleVisible = false;
        score +=1;
        hitMusic.play();
        // 重新設定地鼠位置
        int randomHoleIndex = int(random(numHoles));
        moleX = holeX[randomHoleIndex] - holeSize / 2 + moleWidth / 2;
        moleY = holeY[randomHoleIndex] - holeSize / 2 + moleHeight / 2;
      }
    }
    if (mouseX >=  fButtonX && mouseX <=  fButtonX + fbuttonWidth && mouseY >=  fButtonY && mouseY <=  fButtonY + fbuttonHeight) {
      if (timer ==  0) {
        //重新開始
        score = 0;
        timer = 60;
        pressMusic.play();
        gameMusic.stop();
        hrgameMusic.stop();
        timesupMusic.stop();
      } else {
        gamePaused = !gamePaused;
        pressMusic.play();
        hrgameMusic.pause();
      }
    }
    if (mouseX >=  sButtonX && mouseX <=  sButtonX + sbuttonWidth && mouseY >=  sButtonY && mouseY <=  sButtonY + sbuttonHeight) {
      gameState = "startPage";
      gameMusic.stop();
      hrgameMusic.stop();
      timesupMusic.stop();
      pressMusic.play();
      bgMusic.loop();
      gamePaused = false;
      score = 0;
      timer = 60;
    }
    if (mouseX >=  saveButtonX && mouseX <=  saveButtonX + savebuttonWidth && mouseY >=  saveButtonY && mouseY <=  saveButtonY + savebuttonHeight) {
      if (timer ==  0) {
        saveHardScore(score, playerName);
      }
    }
  }
}

void mousePressed() {
  //防止點擊事件的冒泡，以避免錘子被畫在地鼠下方
  if (gameState.equals("easyGame") ||  gameState.equals("middleGame") ||  gameState.equals("hardGame"))
    if (moleVisible && mouseX > moleX && mouseX < moleX + moleImage.width &&
      mouseY> moleY && mouseY < moleY + moleImage.height)
    {
      return;
    }
}

void saveEasyScore(int finalScore, String playerName) {
  if (finalScore > 0 && playerName != null && !playerName.isEmpty()) {
    String filename = "C:/Users/Wei/Desktop/gameEX/gamefinal/Easy level.csv";
    if (new File(filename).exists()) {
      EasyscoreTable = loadTable(filename, "header");
    } else {
      saveTable(EasyscoreTable, filename);
    }
    int lastInning = 1;
    String timestamp = nf(year(), 4) + "-" + nf(month(), 2) + "-" + nf(day(), 2) + " " +nf(hour(), 2) + ":" + nf(minute(), 2) + ":" + nf(second(), 2);
    if (EasyscoreTable.getRowCount() > 0) {
      TableRow lastRow = EasyscoreTable.getRow(EasyscoreTable.getRowCount() - 1);
      lastInning = lastRow.getInt("Inning") + 1;
    }
    TableRow newRow = EasyscoreTable.addRow();
    newRow.setInt("Inning", lastInning);
    newRow.setString("Date", timestamp);
    newRow.setString("Name", playerName);
    newRow.setInt("Score", score);

    // 儲存更新後的CSV文件
    saveTable(EasyscoreTable, filename);
  }
}

void saveMiddleScore(int finalScore, String playerName) {
  if (finalScore > 0 && playerName != null && !playerName.isEmpty()) {
    String filename = "C:/Users/Wei/Desktop/gameEX/gamefinal/Middle level.csv";
    if (new File(filename).exists()) {
      MiddlescoreTable = loadTable(filename, "header");
    } else {
      saveTable(MiddlescoreTable, filename);
    }
    int lastInning = 1;
    String timestamp = nf(year(), 4) + "-" + nf(month(), 2) + "-" + nf(day(), 2) + " " +nf(hour(), 2) + ":" + nf(minute(), 2) + ":" + nf(second(), 2);
    if (MiddlescoreTable.getRowCount() > 0) {
      TableRow lastRow = MiddlescoreTable.getRow(MiddlescoreTable.getRowCount() - 1);
      lastInning = lastRow.getInt("Inning") + 1;
    }
    TableRow newRow = MiddlescoreTable.addRow();
    newRow.setInt("Inning", lastInning);
    newRow.setString("Date", timestamp);
    newRow.setString("Name", playerName);
    newRow.setInt("Score", score);

    // 儲存更新後的CSV文件
    saveTable(MiddlescoreTable, filename);
  }
}

void saveHardScore(int finalScore, String playerName) {
  if (finalScore > 0 && playerName != null && !playerName.isEmpty()) {
    String filename = "C:/Users/Wei/Desktop/gameEX/gamefinal/Hard level.csv";
    if (new File(filename).exists()) {
      HardscoreTable = loadTable(filename, "header");
    } else {
      saveTable(HardscoreTable, filename);
    }
    int lastInning = 1;
    String timestamp = nf(year(), 4) + "-" + nf(month(), 2) + "-" + nf(day(), 2) + " " +nf(hour(), 2) + ":" + nf(minute(), 2) + ":" + nf(second(), 2);
    if (HardscoreTable.getRowCount() > 0) {
      TableRow lastRow = HardscoreTable.getRow(HardscoreTable.getRowCount() - 1);
      lastInning = lastRow.getInt("Inning") + 1;
    }
    TableRow newRow = HardscoreTable.addRow();
    newRow.setInt("Inning", lastInning);
    newRow.setString("Date", timestamp);
    newRow.setString("Name", playerName);
    newRow.setInt("Score", score);

    // 儲存更新後的CSV文件
    saveTable(HardscoreTable, filename);
  }
}
