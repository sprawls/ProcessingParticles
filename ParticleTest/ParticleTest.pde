ArrayList<ParticleSystem> systems;
PImage image;

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
  curMillis = millis();
  loadImage();
}

void loadImage(){
  image = loadImage("level_3.png"); 
  image.resize(width,height);
}

void draw() {
  UpdateTime(); // Update Time
  image(image, 0, 0); // Load image
  background(0); // Clear screen

  for (ParticleSystem ps: systems) {
    ps.run();
  }
  if (systems.isEmpty()) {
    fill(255);
    textAlign(CENTER);
    text("click mouse to add particle systems", width/2, height/2);
  }
}

// Update all variables linked to time
void UpdateTime(){
  deltaTime =  (millis() - curMillis) / 1000;
  totalTime += deltaTime;
  curMillis = millis();
}

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



// An ArrayList is used to manage the list of Particles

class ParticleSystem {

  //Properties
  ArrayList<Particle> particles;    // An arraylist for all the particles
  PVector origin;                   // An origin point for where particles are birthed
  PVector orientation;              // Orientation in which particles are fired
  float dissipation = 0.2;          // Force of the dissipation of the particle. Small value mean particles are concentrated in a direction. Big value mean it is more spread.
  float spawnRate = 0.125;           // Spawn a particle every SpawnRate Seconds
  color psColor;
  float psSize;
  float psLifespan;
  
  //Variable
  float lastSpawnMillis = 0;

  ParticleSystem(int num, PVector v, PVector o) {
    particles = new ArrayList<Particle>();   // Initialize the arraylist
    origin = v.get();                        // Store the origin point
    orientation = o.get();
    psColor = color(20 + random(235),20 + random(235),20 + random(235));
    psSize = 15 + random(3);
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
  }

  void CheckParticleSpawn(){
    while(lastSpawnMillis+spawnRate < totalTime) {
      addParticle();
      lastSpawnMillis += spawnRate;
    }
  }

  void addParticle() {
    Particle p = new Particle(origin, getModifiedOrientation(dissipation), psColor, psSize, psLifespan);
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
  float startLifespan = 3;      //Maximum particle lifespan in seconds
  float startSize = 20;
  float endSize = 2;
  
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
  Particle(PVector l, PVector v, color sC, float sS, float sL) {
    velocity = v.get();
    location = l.get();
    updateAcceleration();
    startLifespan = sL;
    lifespan = startLifespan; 
    startColor = sC;
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