// Librerias a usar
import java.io.*; // for the loadPathFilenames() function
import processing.opengl.*;
import processing.video.*; // para windows
import codeanticode.gsvideo.*; // para linux
import jp.nyatla.nyar4psg.*;
import javax.swing.*;
import java.util.*;
import saito.objloader.*;
import qrcodeprocessing.*;


PImage imgFondo, imgFondoError;


//Variables



//dimensiones de la pantalla
int winWidth=1920, winHeight=1080; //Cambia Dimensiones de la ventana
//int winWidth=1366, winHeight=768; //Cambia Dimensiones de la ventana

// dimensiones de la camara
int capWidth = 640, capHeight = 480;
// the dimensions at which the AR will take place.
int arWidth = 640;
int arHeight = 480; //480 360

PFont fuente;        //Tipo de fuente
int fontSize = 160;
PImage imgCaptada; //Imagen final
PImage imgNueva;
String mensaje = "";

String nombreArchivo = "data/captura/captura_ar.jpg";

// Make sure to change both the camPara and the patternPath String to where the files are on YOUR computer
// the full path to the camera_para.dat file
String camPara = "camera_para.dat";
// the full path to the .patt pattern files

//Patrones
String proyectPath = sketchPath("/home/fzzio/sketchbook/proyectos/MiProRA/");
String patronesPath = proyectPath + "data/patts";
String imagenesPath = proyectPath + "data/img";
String videosPath = proyectPath + "data/video";
String objetos3DPath = proyectPath + "data/3d";



float ry;
int numPixels;

//Capture videoC; // para windows
GSCapture videoC; // para linux
PImage video; // en esta variable mostramos el video invertido

int numMarkers = 6;
int numColores = 6;
int numFondos = 6;
int numObjetos = 6;
int numVideos = 2;

color trackColorA;
float aTrackR, aTrackG, aTrackB;
int posXInicialA;

/********CHROMA KEY********/
int keyColor = 0xff000000; /*009933*/
int keyR = (keyColor >> 16) & 0xFF;
int keyG = (keyColor >> 8) & 0xFF;
int keyB = keyColor & 0xFF;
int thresh = 60; // tolerance of


//********NYARTOOL ********
MultiMarker nya;
float displayScale;
color[] colors = new color[numColores];
float[] scaler = new float[numColores];

PImage[] imgFondos = new PImage[numFondos];
PImage[] imgObjetos = new PImage[numObjetos];
Movie[] videosArr = new Movie[numVideos];


float mS = 0.2;

void setup() {
  // inicializacion de los fondos que se mostraran
  ///imgFondo = loadImage("fondos/fondo-3.jpg");
  ///imgFondoError = loadImage("fondos/fondo-1.jpg");
  //Imagenes
  //imgFondo = loadImage("img/fondo.png");
  
  // configuracion de la camara  
  size(winWidth, winHeight, P3D);
  //size(winWidth,winHeight,OPENGL);//tamaños de la pantalla
  frameRate(90);// para mejorar la velocidad de la imagen por cuadro  o 30
  
  //fuente = createFont("fonts/the-mocking-bird.ttf", fontSize, true);
  fuente = createFont("Arial", fontSize, true);
  
  // Marcador de Nyartoolkit
  nya = new MultiMarker(this, arWidth, arHeight, camPara, NyAR4PsgConfig.CONFIG_PSG);
  // set the delay after which a lost marker is no longer displayed. by default set to something higher, but here manually set to immediate.
  nya.setLostDelay(1);
  
  
  
  
  //Cargamos los contenidos
  cargarColores();
  cargarPatrones();
  cargarImagenes();
  //cargarVideos();
  
  
  // to correct for the scale difference between the AR detection coordinates and the size at which the result is displayed
  displayScale = (float) winWidth / arWidth;
  
  
  //video = new Capture(this,capWidth,capHeight,15); // para windows
  videoC = new GSCapture(this, capWidth, capHeight, "/dev/video1"); // para linux
  //videoC = new GSCapture(this, capWidth, capHeight, "/dev/video1"); // segunda webcam
  videoC.start();
  
  println("\nResoluciones soportadas por la webcam");
  int[][] res = videoC.resolutions();
  for (int i = 0; i < res.length; i++) {
    println(res[i][0] + "x" + res[i][1]);
  }
  
  println("\nFramerates soportados por la camara");
  String[] fps = videoC.framerates();
  for (int i = 0; i < fps.length; i++) {
    println(fps[i]);
  }
  
  video = createImage(videoC.width, videoC.height, RGB);
  numPixels = videoC.width * videoC.height;
  
}

public void dibujarColoresDetectados(){
  float worldRecord1 = 500, worldRecord2 = 500;
  int closestX1 = 0, closestX2 = 0;
  int closestY1 = 0, closestY2 = 0;
  
  for(int x = 0; x < video.width; x ++ ) {
    for(int y = 0; y < video.height; y ++ ) {
      int loc = x + y*video.width;

      // Obtenemos los datos para el color actual
      color colorActual = video.pixels[loc];
      float actR = red(colorActual);
      float actG = green(colorActual);
      float actB = blue(colorActual);
      
      //Comparamos con los colores detectados en A con distancia Euclidiana
      float dA = dist(actR, actG, actB, aTrackR, aTrackG, aTrackB);
        
      
      if (dA < worldRecord1) {
        worldRecord1 = dA;
        closestX1 = x;
        closestY1 = y;
      }
    }
  }
  
  if (worldRecord1 < 10) { 
    // Draw a circle at the tracked pixel
    fill(trackColorA);
    strokeWeight(4.0);
    stroke(0);
    ellipse(closestX1,closestY1,20,20);
    posXInicialA = closestX1;
  }
  

}



void draw()
{
   // Cargamos datos de la camara
  if (videoC.available()) {
    background(0);
    videoC.read();
    
    loadPixels();
    videoC.loadPixels();
    video = mirrorImage(videoC);
    
    //PImage nueva = mergeImagenesInColor2(video, color(169, 209, 132 ), 10); //Cambia tolerancia al croma
    PImage nueva = mergeImagenesInColor2(video, color(0, 255, 0 ), 200); //Cambia tolerancia al croma
    
    
    
    
    hint(DISABLE_DEPTH_TEST); // variables de Nayrtoolkit
      //image(video, (winWidth - capWidth)/2 , (winHeight - capHeight)/2  );
      image(nueva, 0, 0, winWidth, winHeight);
    hint(ENABLE_DEPTH_TEST);
    
    PImage cSmall = video.get();
    cSmall.resize(arWidth, arHeight);
    nya.detect(cSmall); // detect markers in the image
    
    //drawMarkers(); // draw the coordinates of the detected markers (2D)
    //drawBoxes();
    
    //dibujarElementos();
    
    //dibujarColoresDetectados();
    
    
  }
}

public PImage mergeImagenesInColor2(  PImage main, int color_cambiar, int tolerance) {
  PImage merged = createImage(  main.width, main.height, ARGB );       
  merged.loadPixels();
  main.loadPixels();

  for (  int i = 0 ; i < merged.pixels.length ; i++ ) {
    float r =  red(   main.pixels[ i  ] ) ;
    float g =  green( main.pixels[  i  ]  );
    float b =  blue(  main.pixels[  i  ]);

    float dr =  red(   color_cambiar ) ;
    float dg =  green( color_cambiar  );
    float db =  blue(  color_cambiar  );

    float distancia = dist(r, g, b, dr, dg, db);
    float distancia2 = dist(  r, g, b, 4, 255, 0  );

    if ( distancia > tolerance ) {
      merged.pixels[i] = main.pixels[i] ;
    }
  }
  merged.updatePixels();
  return merged ;
}

void mousePressed(){
   //keyPressed();
   //if(key == '1'){
     int loc = mouseX + mouseY*video.width;
      trackColorA = video.pixels[loc];
      aTrackR = red(trackColorA);
      aTrackG = green(trackColorA);
      aTrackB = blue(trackColorA);
      mensaje = "Calibrando color para Jugador A: [" + aTrackR + ", " + aTrackG + ", " + aTrackB + "].";
   //}
}
public void keyPressed() {
  switch (key) {
    case 'p': saveFrame(); break;
  }
}
void stop(){
  // Stop the GSVideo webcam capture
  videoC.stop();
  // Stop the sketch
  this.stop();
}

public void cargarColores(){
  for (int i=0; i<colors.length; i++){ 
    // random color, always at a transparency of 160
    colors[i] = color(random(255), random(255), random(255), 160);
  }
  for (int i=0; i<scaler.length; i++){
    // scaled at half to double size
    scaler[i] = random(0.5, 1.9);
  }
}


public void cargarPatrones(){
  nya.addARMarker(patronesPath + "/" + "ftt01-diez.pat", 80);
  nya.addARMarker(patronesPath + "/" + "ftt01-gol.pat", 80);
  nya.addARMarker(patronesPath + "/" + "ftt01-flechas.pat", 80);
  nya.addARMarker(patronesPath + "/" + "ftt01-escuadra.pat", 80);
  nya.addARMarker(patronesPath + "/" + "ftt01-pinzas.pat", 80); 
  nya.addARMarker(patronesPath + "/" + "ftt01-triangulos.pat", 80);
  //nya.addARMarker(patronesPath + "/" + "ftt01-cuadrados.pat", 80);
}


public void cargarImagenes(){

  imgFondos[0] = loadImage(imagenesPath + "/fondos/" + "fondo_cocinamadera.jpg");
  imgFondos[1] = loadImage(imagenesPath + "/fondos/" + "fondo_Carretera.jpg");
  imgFondos[2] = loadImage(imagenesPath + "/fondos/" + "fondo_chimborazo.jpg");
  imgFondos[3] = loadImage(imagenesPath + "/fondos/" + "luces_ok.jpg");
  imgFondos[4] = loadImage(imagenesPath + "/fondos/" + "fondo_energia.png");
  imgFondos[5] = loadImage(imagenesPath + "/fondos/" + "fondo_energia2.jpg");  

  imgObjetos[0] = loadImage(imagenesPath + "/objetos/" + "banana.png");
  imgObjetos[1] = loadImage(imagenesPath + "/objetos/" + "llantas_colores.png");
  imgObjetos[2] = loadImage(imagenesPath + "/objetos/" + "poncho.png");
  imgObjetos[3] = loadImage(imagenesPath + "/objetos/" + "optimus.png");
  imgObjetos[4] = loadImage(imagenesPath + "/objetos/" + "sombrero.png");
  imgObjetos[5] = loadImage(imagenesPath + "/objetos/" + "rosas.png");
}

public void cargarVideos(){
  videosArr[0] = new Movie(this, videosPath + "/" + "carros_industria.mp4");
  videosArr[1] = new Movie(this, videosPath + "/" + "engrane.mp4");
  
  videosArr[0].loop(); videosArr[0].pause(); videosArr[0].volume(0);
  videosArr[1].loop(); videosArr[1].pause(); videosArr[1].volume(0);  
}

PImage mirrorImage(PImage source){
  // Create new storage for the result RGB image 
  
  PImage response = createImage(source.width, source.height, RGB);
  
  // Load the pixels data from the source and destination images
  
  source.loadPixels();
  
  response.loadPixels();  
    
  // Walk thru each pixel of the source image
  
  for (int x=0; x<source.width; x++) 
  {
    for (int y=0; y<source.height; y++) 
    {
      // Calculate the inverted X (loc) for the current X
      
      int loc = (source.width - x - 1) + y * source.width;

      // Get the color (brightness for B/W images) for 
      // the inverted-X pixel
      
      color c = source.pixels[loc];
      
      // Store the inverted-X pixel color information 
      // on the destination image
      
      response.pixels[x + y * source.width] = c;
    }
  }
  
  // Return the result image with the pixels inverted
  // over the x axis 
  
  return response;
}

public void dibujarElementos(){
  
  nya.setARPerspective();
  textAlign(CENTER, CENTER);
  //scale(displayScale);
  for (int i=0; i < numMarkers; i++ ) {
    if ((!nya.isExistMarker(i))) {
      continue;
    }
    //Dibuja el Fondo
    pushMatrix();
      background(imgFondos[i]);
    popMatrix();
    
    //Dibuja el elemento
    pushMatrix();
      setMatrix(nya.getMarkerMatrix(i));

      //Dibuja la caja
      pushMatrix();
        scale(1, 1, 0.10);
        //scale(scaler[i]);
        translate(0, 0, 20);
        lights();
        stroke(0);
        fill(colors[i]);
        box(80);
        noLights();
      popMatrix();

      //Dibuja el objeto
      pushMatrix();
        loadPixels();        
          scale(1, -1);
          translate(0, 0, 10.1);
          image(imgObjetos[i], -60, -60, 120, 120);
        updatePixels();
       popMatrix();
    popMatrix();


  }
  perspective();
  
  
}

public void dibujarVideo(Movie video, int indiceMarker, int indiceColor){
    pushMatrix();
      setMatrix(nya.getMarkerMatrix(indiceMarker));
      pushMatrix();
        scale(1, 1, 0.10);
        //scale(scaler[indiceColor]);
        translate(0, 0, 20);
        lights();
        stroke(0);
        fill(colors[indiceColor]);
        box(80);
        noLights();
      popMatrix();
      pushMatrix();
        loadPixels();        
          scale(1, -1);
          translate(0, 0, 10.1);

          image(video, -60, -60, 120, 120);
          
        updatePixels();
       popMatrix();
    popMatrix();
}

// Called every time a new frame is available to read
void movieEvent(Movie m) {
  m.read();
}
