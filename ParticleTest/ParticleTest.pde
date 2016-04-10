ArrayList<ParticleSystem> systems;
GameManager manager;
PImage image;
PFont font;

//Inputs
boolean mouseHeldLeft = false;
boolean mouseHeldRight = false;

//Time
float totalTime = 0;
float deltaTime = 0;
float curMillis = 0;

void setup() {
  size(640, 360);
  systems = new ArrayList<ParticleSystem>();
  manager = new GameManager();
  curMillis = millis();
  loadBackgroundImage("level_1.png");
  loadFont();
}

void loadBackgroundImage(String filepath){
  image = loadImage(filepath); 
  image.resize(width,height);
}
void loadFont(){
  font = createFont("font_0.ttf", 24);
  textFont(font);
  textAlign(CENTER, CENTER); 
}

void draw() {
  updateTime(); // Update Time
  image(image, 0, 0); // Load image
  background(0); // Clear screen

  //Update Particles
  for (ParticleSystem ps: systems) {
    ps.run();
  }
  //Update Manager
  manager.update();
  //Show help text on screen
  showScreenText();

}

void showScreenText(){
    if (systems.isEmpty()) {
      fill(255);
      textAlign(CENTER);
      if(manager.currentLevel == 1) {
        textSize(48);
        text("Type The Shape", width/2, height/4 + 25);
        textSize(24);
        text("Click left mouse to add particle systems", width/2, height/2 + 50);
        text("Hold mouse buttons to alter particles", width/2, height/2 + 75);
      } else if(manager.currentLevel > manager.levels) {
        textSize(48);
        text("", width/2, height/4 + 25); //End game text
      } else {
        textSize(48);
        text("Shape " + manager.currentLevel, width/2, height/4 + 25);
      }
    } else if(manager.currentText == "") {
      fill(255);
      textSize(18);
      text("Type the shape. Press enter to submit. Press delete to restart.", width/2, height - 20);
    }
}

// Update all variables linked to time
void updateTime(){
  deltaTime =  (millis() - curMillis) / 1000;
  totalTime += deltaTime;
  curMillis = millis();
}

// Check inputs
void mousePressed() {
  if(mouseButton == LEFT) {
      systems.add(new ParticleSystem(1, new PVector(mouseX, mouseY), (new PVector((width/2)-mouseX,(height/2)-mouseY)).normalize()));
      mouseHeldLeft = true;
  } else {
       mouseHeldRight = true;
  }
}

void mouseReleased(){
    if(mouseButton == LEFT) {
      mouseHeldLeft = false;
    } else {
      mouseHeldRight = false;
    }
}

void keyPressed() {
  if (keyCode == ENTER) {
    manager.CheckLevelCompletion();
  } else if(keyCode == DELETE) {
    manager.RestartLevel();
  } else if(keyCode == BACKSPACE) {
    if(manager.currentText.length() > 0) manager.currentText = manager.currentText.substring(0,  manager.currentText.length() - 1); 
  } else if (keyCode != SHIFT && keyCode != CONTROL && keyCode != ALT) {
    manager.currentText += key;
  }
}

class GameManager {
  //Properties
  int levels = 4;
  
  //Variables
  String currentText = "";
  int currentLevel = 1;
  
  //Constructor
  GameManager(){
     currentLevel = 1;
     currentText = "";
  }
  
  void update(){
    if(!systems.isEmpty()){
      fill(200);
      textSize(150);
      text(currentText, width/2, height/2+35);
    }
  }
  
  void CheckLevelCompletion(){
    println(currentText);
    currentText = currentText.toLowerCase();
    println(currentText);
    switch(currentLevel) {
      case(1) : 
        if(currentText.equals("triangle") || currentText.equals("triangles")) LoadLevel(currentLevel+1);
        else currentText = "";
        break;
      case(2) : 
        if(currentText.equals("circle") || currentText.equals("circles") || currentText.equals("round") || currentText.equals("rounds") || currentText.equals("cercle") || currentText.equals("cercles")) LoadLevel(currentLevel+1);
        else currentText = "";
        break;
      case(3) : 
        if(currentText.equals("star") || currentText.equals("stars") || currentText.equals("etoile") || currentText.equals("etoiles") || currentText.equals("étoile") || currentText.equals("étoiles")) LoadLevel(currentLevel+1);
        else currentText = "";
        break;
      case(4) : 
        if(currentText.equals("heart") || currentText.equals("hearts") || currentText.equals("coeur") || currentText.equals("coeurs") || currentText.equals("<3")) LoadLevel(currentLevel+1);
        else currentText = "";
        break;
      default : 
        currentText = "";
        break;
    }
  }
  
  void LoadLevel(int lvl){
    currentLevel = lvl;
    
    String newImagePath;
    if(currentLevel <= levels) {
      newImagePath = "level_" + currentLevel + ".png";
    } else {
      newImagePath = "level_end.png";
    }
    loadBackgroundImage(newImagePath);
    //Clear particls nad text
    RestartLevel();
  }
  
  //Clear particle and test on screen
  void RestartLevel() {
    systems = new ArrayList<ParticleSystem>();
    currentText = "";
  }
  
}

// An ArrayList is used to manage the list of Particles

class ParticleSystem {

  //Properties
  ArrayList<Particle> particles;    // An arraylist for all the particles
  PVector origin;                   // An origin point for where particles are birthed
  PVector orientation;              // Orientation in which particles are fired
  float dissipation = 0.2;          // Force of the dissipation of the particle. Small value mean particles are concentrated in a direction. Big value mean it is more spread.
  float spawnRate = 0.135;           // Spawn a particle every SpawnRate Seconds
  color psColor;
  float psSize;
  float psLifespan;
  float reticuleSizeMin = 5;
  float reticuleSizeMax = 20;
  float reticuleSizeRate = 15;
  float reticuleRotationRate = PI/80;
  //Variable
  float lastSpawnMillis = 0;
  float curReticuleSize = 4;
  boolean reticuleShrinking = false;
  float curReticuleRotation = 0;

  ParticleSystem(int num, PVector v, PVector o) {
    particles = new ArrayList<Particle>();   // Initialize the arraylist
    origin = v.get();                        // Store the origin point
    orientation = o.get();
    psSize = 25 + random(3);
    psLifespan = 3.5;
    for (int i = 0; i < num; i++) {
      addParticle();    // Add "num" amount of particles to the arraylist
    }
    lastSpawnMillis = millis()/1000;
  }


  void run() {
    CheckParticleSpawn();
    // Cycle through the ArrayList backwards, because we are deleting while iterating
    for (int i = particles.size()-1; i >= 0; i--) {
      Particle p = particles.get(i);
      p.run();
      if (p.isDead()) {
        particles.remove(i);
      }
    }
    //Reticule to show particle system position
    if(reticuleShrinking) {
      curReticuleSize -= reticuleSizeRate * deltaTime;
      if(curReticuleSize < reticuleSizeMin) reticuleShrinking = false;
    } else {
      curReticuleSize += reticuleSizeRate * deltaTime;
      if(curReticuleSize > reticuleSizeMax) reticuleShrinking = true;
    }
    curReticuleRotation += reticuleRotationRate;
    //println(curReticuleSize);
    stroke(255,255,255,150);
    fill(0,0,0,0);
    pushMatrix();
    
    translate(origin.x,origin.y);
    rotate(curReticuleRotation);
    rect(0 - (curReticuleSize/2),0 - (curReticuleSize/2),curReticuleSize,curReticuleSize);
    popMatrix();
    
  }

  void CheckParticleSpawn(){
    while(lastSpawnMillis+spawnRate < totalTime) {
      addParticle();
      lastSpawnMillis += spawnRate;
    }
  }

  void addParticle() {
    Particle p = new Particle(origin, getModifiedOrientation(dissipation), psSize, psLifespan);
    particles.add(p);
  }

  void addParticle(Particle p) {
    particles.add(p);
  }
  
  PVector getModifiedOrientation(float factor){
    PVector modOri = orientation.normalize();
    modOri = new PVector( modOri.x * (1 + random(-factor,factor)), 
                          modOri.y * (1 + random(-factor,factor)));
    return modOri;
  }

  // A method to test if the particle system still has particles
  boolean dead() {
    return particles.isEmpty();
  }
}


// A simple Particle class

class Particle {
  //Properties
  PVector location;
  PVector velocity;
  PVector acceleration;
  color startColor =  color(255,255,255,255);  //Color at max lifespan
  color endColor =  color(0,0,0,50);//Color on when lifespan is 0
  float startLifespan = 2.8;      //Maximum particle lifespan in seconds
  float startSize = 30;
  float endSize = 5;
  
  //Variables 
  float lifespan;    //current lifespan left in seconds
  color curColor;    //current color based on lifespan
  float curSize;

  //Particle Constructors
  Particle(PVector l, PVector v) {
      velocity = v.get();
      location = l.get();
      lifespan = startLifespan; 
      updateAcceleration();
  }  
  Particle(PVector l, PVector v, float sS, float sL) {
    velocity = v.get();
    location = l.get();
    updateAcceleration();
    startLifespan = sL;
    lifespan = startLifespan;
    startSize = sS;
  }

  void run() {
    updateAcceleration();
    update();
    display();
  }
  
  void updateAcceleration(){
    acceleration = (new PVector(mouseX - location.x,mouseY - location.y)).normalize();
    if(mouseHeldLeft) acceleration.mult(0.05);
    else if(mouseHeldRight) acceleration.mult(-0.05);
    else acceleration.mult(0.01);
  }

  // Method to update location
  void update() {
    velocity.add(acceleration);
    move();
    calculateProperties();
    lifespan -= deltaTime;
  }
  
  // Method that moves the particle and handle screen edges collisions
  void move() {
    location.add(velocity);
    //Check bounds X Axis 
    if(location.x < 0) {
      location.x = 0;
      velocity.x = -velocity.x;
    } else if(location.x > width) {
      location.x = width;
      velocity.x = -velocity.x;
    }
    //Check bounds Y Axis 
    if(location.y < 0) {
      location.y = 0;
      velocity.y = -velocity.y;
    } else if(location.y > height) {
      location.y = height;
      velocity.y = -velocity.y;
    }
  }
  
  //Calculate the properties that depend on lifespan (color, size, etc)
  void calculateProperties(){
    float step =  1-(lifespan/startLifespan);
    GetImageColor();
    curColor = lerpColor(startColor, endColor, step);
    curSize = lerp(startSize, endSize, step);
  }

  // Get color of the background image
  void GetImageColor(){
     startColor = image.get((int)location.x, (int)location.y); 
  }

  // Method to display
  void display() {
    stroke(curColor);
    fill(curColor);
    ellipse(location.x,location.y,curSize,curSize);
  }

  // Is the particle still useful?
  boolean isDead() {
    return (lifespan < 0.0);
  }

}