import java.awt.AWTException;
import java.awt.Robot;
import java.awt.event.InputEvent;
import java.awt.event.KeyEvent;
import processing.video.*;
import gab.opencv.*;

Robot robot;



int camWidth = 320;
int camHeight = 240;
int numPixels;
int[] previousFrame;
PImage diffFrame;
Capture video;

int xSegments = 5;
int ySegments = 5;
int segmentWidth = camWidth/xSegments;
int segmentHeight = camHeight/ySegments;

int keys[] = {
  KeyEvent.VK_A, 
  KeyEvent.VK_B, 
  KeyEvent.VK_C, 
  KeyEvent.VK_D, 
  KeyEvent.VK_E, 
  KeyEvent.VK_F, 
  KeyEvent.VK_G, 
  KeyEvent.VK_H, 
  KeyEvent.VK_I, 
  KeyEvent.VK_J, 
  KeyEvent.VK_K, 
  KeyEvent.VK_L, 
  KeyEvent.VK_M, 
  KeyEvent.VK_N, 
  KeyEvent.VK_O, 
  KeyEvent.VK_P, 
  KeyEvent.VK_Q, 
  KeyEvent.VK_R, 
  KeyEvent.VK_S, 
  KeyEvent.VK_T, 
  KeyEvent.VK_U, 
  KeyEvent.VK_V, 
  KeyEvent.VK_W, 
  KeyEvent.VK_X, 
  KeyEvent.VK_Y, 
  KeyEvent.VK_Z
};

boolean robotEnable = false;

ArrayList<Rectangle> rects;


void setup() {
  size(320, 240);
  background(50);
  rects = new ArrayList<Rectangle>();

  video = new Capture(this, camWidth, camHeight);
  video.start(); 
  numPixels = video.width * video.height;
  previousFrame = new int[numPixels];
  diffFrame = createImage(video.width, video.height, RGB);
  diffFrame.loadPixels();

  try { 
    robot = new Robot();
  } 
  catch (AWTException e) {
    e.printStackTrace();
    exit();
  }
  for (int i = 0; i < xSegments; i++) {
    for (int j = 0; j < ySegments; j++) {
      Rectangle rectTemp = new Rectangle(segmentWidth*i, segmentHeight*j, segmentWidth, segmentHeight);
      rectTemp.fillColor = 255;
      rectTemp.strokeColor = 255;
      rects.add(rectTemp);
    }
  }

  link("https://www.patatap.com/");
}

void draw() {
  if (video.available()) {
    video.read(); // Read the new frame from the camera
    video.loadPixels(); // Make its pixels[] array available
    diffFrame = createImage(video.width, video.height, RGB);

    int movementSum = 0; // Amount of movement in the frame
    for (int i = 0; i < numPixels; i++) { // For each pixel in the video frame...
      color currColor = video.pixels[i];
      color prevColor = previousFrame[i];
      // Extract the red, green, and blue components from current pixel
      int currR = (currColor >> 16) & 0xFF; // Like red(), but faster
      int currG = (currColor >> 8) & 0xFF;
      int currB = currColor & 0xFF;
      // Extract red, green, and blue components from previous pixel
      int prevR = (prevColor >> 16) & 0xFF;
      int prevG = (prevColor >> 8) & 0xFF;
      int prevB = prevColor & 0xFF;
      // Compute the difference of the red, green, and blue values
      int diffR = abs(currR - prevR);
      int diffG = abs(currG - prevG);
      int diffB = abs(currB - prevB);
      // Add these differences to the running tally
      movementSum += diffR + diffG + diffB;
      // Render the difference image to the screen
      diffFrame.pixels[i] = color(diffR*15, diffG*15, diffB*15);

      previousFrame[i] = currColor;
    }
    // To prevent flicker from frames that are all black (no movement),
    // only update the screen if the image has changed.
    if (movementSum > 0) {
      diffFrame.updatePixels();
      // println(movementSum); // Print the total amount of movement to the console
    }
  }


  for (int i = 0; i < rects.size(); i++) {
    Rectangle rectTemp = rects.get(i);
    color fillColor = extractColorFromImage(diffFrame.get((int)rectTemp.x, (int)rectTemp.y, (int)rectTemp.w, (int)rectTemp.h));

    int currR = (fillColor >> 16) & 0xFF; // Like red(), but faster
    int currG = (fillColor >> 8) & 0xFF;
    int currB = fillColor & 0xFF;
    int c = currR+currG+currB;
    boolean pressKey = false;
    if (c < 240) {
      rectTemp.fillColor = 0;
    } else {
      if (rectTemp.fillColor == 0) {
        pressKey = true;
      }
      rectTemp.fillColor = 255;
    }

    if (pressKey) {
      robot.delay(25);
      robot.keyPress(keys[i]);
      robot.keyRelease(keys[i]);
    }
    pressKey = false;
    rectTemp.render();
  }
}

color extractColorFromImage(PImage img) {
  img.loadPixels();
  int r = 0, g = 0, b = 0;
  for (int i=0; i<img.pixels.length; i++) {
    color c = img.pixels[i];
    r += c>>16&0xFF;
    g += c>>8&0xFF;
    b += c&0xFF;
  }
  r /= img.pixels.length;
  g /= img.pixels.length;
  b /= img.pixels.length;

  return color(r, g, b);
}

public class Rectangle {

  float x;
  float y;
  float w;
  float h;

  float cx;
  float cy;

  float strokeColor;
  float fillColor; 

  Rectangle(float _x, float _y, float _w, float _h) {
    x = _x;
    y = _y;
    w = _w;
    h = _h;

    cx = x+w/2;
    cy = y+h/2;
  }

  boolean contains(float inX, float inY) {
    if ((inX > x) && (inX < x+w) && (inY <y+h) && (inY > y)) {
      return true;
    } else {
      return false;
    }
  }

  void render() {
    rectMode(CORNER);
    fill(fillColor);
    rect(x, y, w, h);
  }
}