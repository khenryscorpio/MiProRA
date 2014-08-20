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
String proyectPath = sketchPath("/home/henry/sketchbook/proyectos/AlbumGolesEC/");
String patronesPath = proyectPath + "data/patts";
String imagenesPath = proyectPath + "data/img";
String videosPath = proyectPath + "data/video";
String objetos3DPath = proyectPath + "data/3d";



float ry;
int numPixels;

//Capture videoC; // para windows
GSCapture videoC; // para linux
PImage video; // en esta variable mostramos el video invertido

int numColores = 5;
int numBalones = 12;
int numJugadores = 8;
int numCamisetas = 32;
int numBarras = 29;
int numVideos = 4;
int numObetos3D = 1;

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

PImage[] imgBalones = new PImage[numBalones];
PImage[] imgJugadores = new PImage[numJugadores];
PImage[] imgCamisetas = new PImage[numCamisetas];
PImage[] imgBarras = new PImage[numBarras];
Movie[] videosArr = new Movie[numVideos];
Movie videosMascotas;
PShape[] objetos3DArr = new PShape[numObetos3D];


float mS = 0.2;

void setup() {
  // inicializacion de los fondos que se mostraran
  ///imgFondo = loadImage("fondos/fondo-3.jpg");
  ///imgFondoError = loadImage("fondos/fondo-1.jpg");
  //Imagenes
imgFondo = loadImage("img/fondo.png");
  
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
  cargarVideos();
  
  
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
    
    /********CHROMA KEY********/
    //background(0xffff0000);
    background(imgFondo);
    loadPixels();    
    videoC.loadPixels(); // Make the pixels of video available    

    for (int i = 0; i < numPixels; i++) { // For each pixel in the video frame...
      // Fetch the current color in that location
      color currColor = videoC.pixels[i];
      int currR = (currColor >> 16) & 0xFF;
      int currG = (currColor >> 8) & 0xFF;
      int currB = currColor & 0xFF;

      // Compute the difference of the red, green, and blue values
      int diffR = abs(currR - keyR);
      int diffG = abs(currG - keyG);
      int diffB = abs(currB - keyB);

      // Render the pixels wich are not the close to the keyColor to the screen

      if((diffR + diffG + diffB)> thresh){
        pixels[i] = videoC.pixels[i];      
      } 
    }
    
    hint(DISABLE_DEPTH_TEST); // variables de Nayrtoolkit
      //image(video, (winWidth - capWidth)/2 , (winHeight - capHeight)/2  );
      image(video, 0, 0, winWidth, winHeight);
    hint(ENABLE_DEPTH_TEST);
    
    PImage cSmall = video.get();
    cSmall.resize(arWidth, arHeight);
    nya.detect(cSmall); // detect markers in the image
    
    //drawMarkers(); // draw the coordinates of the detected markers (2D)
    //drawBoxes();
    
    dibujarElementos();
    
    dibujarColoresDetectados();
    
    
  }
}
void mousePressed(){
   keyPressed();
   if(key == '1'){
     int loc = mouseX + mouseY*video.width;
      trackColorA = video.pixels[loc];
      aTrackR = red(trackColorA);
      aTrackG = green(trackColorA);
      aTrackB = blue(trackColorA);
      mensaje = "Calibrando color para Jugador A: [" + aTrackR + ", " + aTrackG + ", " + aTrackB + "].";
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
  // Cargamos las imagenes de los Balones
  imgBalones[0] = loadImage(imagenesPath + "/balones/" + "1970-mexico.png");
  imgBalones[1] = loadImage(imagenesPath + "/balones/" + "1974-westGermany.png");
  imgBalones[2] = loadImage(imagenesPath + "/balones/" + "1978-argentina.png");
  imgBalones[3] = loadImage(imagenesPath + "/balones/" + "1982-spain.png");
  imgBalones[4] = loadImage(imagenesPath + "/balones/" + "1986-mexico.png");
  imgBalones[5] = loadImage(imagenesPath + "/balones/" + "1990-italy.png");
  imgBalones[6] = loadImage(imagenesPath + "/balones/" + "1994-usa.png");
  imgBalones[7] = loadImage(imagenesPath + "/balones/" + "1998-france.png");
  imgBalones[8] = loadImage(imagenesPath + "/balones/" + "2002-japan.png");
  imgBalones[9] = loadImage(imagenesPath + "/balones/" + "2006-alemania.png");
  imgBalones[10] = loadImage(imagenesPath + "/balones/" + "2010-southAfrica.png");
  imgBalones[11] = loadImage(imagenesPath + "/balones/" + "2014-brazil.png");
  
  //Cargamos las imagenes de los jugadores
  imgJugadores[0] = loadImage(imagenesPath + "/jugadores/" + "beckenbauer.jpg");
  imgJugadores[1] = loadImage(imagenesPath + "/jugadores/" + "cruyff.jpg");
  imgJugadores[2] = loadImage(imagenesPath + "/jugadores/" + "distefano.jpg");
  imgJugadores[3] = loadImage(imagenesPath + "/jugadores/" + "eusebio.jpg");
  imgJugadores[4] = loadImage(imagenesPath + "/jugadores/" + "maradona.jpg");
  imgJugadores[5] = loadImage(imagenesPath + "/jugadores/" + "pele.jpg");
  imgJugadores[6] = loadImage(imagenesPath + "/jugadores/" + "ronaldo.jpg");
  imgJugadores[7] = loadImage(imagenesPath + "/jugadores/" + "zidane.jpg");
  
  //cargamos imagenes
  imgCamisetas[0] = loadImage(imagenesPath + "/camisetas/" + "ALEMANIA.jpg");
  imgCamisetas[1] = loadImage(imagenesPath + "/camisetas/" + "AUSTRALIA.jpg");
  imgCamisetas[2] = loadImage(imagenesPath + "/camisetas/" + "BRASIL.jpg");
  imgCamisetas[3] = loadImage(imagenesPath + "/camisetas/" + "COLOMBIA.jpg");
  imgCamisetas[4] = loadImage(imagenesPath + "/camisetas/" + "COSTARICA.jpg");
  imgCamisetas[5] = loadImage(imagenesPath + "/camisetas/" + "ESPANA.jpg");
  imgCamisetas[6] = loadImage(imagenesPath + "/camisetas/" + "GHANA.jpg");
  imgCamisetas[7] = loadImage(imagenesPath + "/camisetas/" + "HOLANDA.jpg");
  imgCamisetas[8] = loadImage(imagenesPath + "/camisetas/" + "IRAN.jpg");
  imgCamisetas[9] = loadImage(imagenesPath + "/camisetas/" + "MEXICO.jpg");
  imgCamisetas[10] = loadImage(imagenesPath + "/camisetas/" + "RUSIA.jpg");
  imgCamisetas[11] = loadImage(imagenesPath + "/camisetas/" + "ARGELIA.jpg");
  imgCamisetas[12] = loadImage(imagenesPath + "/camisetas/" + "BELGICA.jpg");
  imgCamisetas[13] = loadImage(imagenesPath + "/camisetas/" + "CAMERUN.jpg");
  imgCamisetas[14] = loadImage(imagenesPath + "/camisetas/" + "COREA.jpg");
  imgCamisetas[15] = loadImage(imagenesPath + "/camisetas/" + "CROACIA.jpg");
  imgCamisetas[16] = loadImage(imagenesPath + "/camisetas/" + "ESTADOSUNIDOS.jpg");
  imgCamisetas[17] = loadImage(imagenesPath + "/camisetas/" + "GHANA.jpg");
  imgCamisetas[18] = loadImage(imagenesPath + "/camisetas/" + "HONDURAS.jpg");
  imgCamisetas[19] = loadImage(imagenesPath + "/camisetas/" + "ITALIA.jpg");
  imgCamisetas[20] = loadImage(imagenesPath + "/camisetas/" + "NIGERIA.jpg");
  imgCamisetas[21] = loadImage(imagenesPath + "/camisetas/" + "SUIZA.jpg");
  imgCamisetas[22] = loadImage(imagenesPath + "/camisetas/" + "ARGENTINA.jpg");
  imgCamisetas[23] = loadImage(imagenesPath + "/camisetas/" + "bosnia.jpg");
  imgCamisetas[24] = loadImage(imagenesPath + "/camisetas/" + "CHILE.jpg");
  imgCamisetas[25] = loadImage(imagenesPath + "/camisetas/" + "COSTA-MARFIL-Copy.jpg");
  imgCamisetas[26] = loadImage(imagenesPath + "/camisetas/" + "ecuador.jpg");
  imgCamisetas[27] = loadImage(imagenesPath + "/camisetas/" + "FRANCIA.jpg");
  imgCamisetas[28] = loadImage(imagenesPath + "/camisetas/" + "GRECIA.jpg");
  imgCamisetas[29] = loadImage(imagenesPath + "/camisetas/" + "INGLATERRA.jpg");
  imgCamisetas[30] = loadImage(imagenesPath + "/camisetas/" + "JAPON.jpg");
  imgCamisetas[31] = loadImage(imagenesPath + "/camisetas/" + "PORTUGAL.jpg");
  
  imgBarras[0] = loadImage(imagenesPath + "/barras/" + "Ajax.jpg");
  imgBarras[1] = loadImage(imagenesPath + "/barras/" + "AtlJuventus.jpg");
  imgBarras[2] = loadImage(imagenesPath + "/barras/" + "BarcelonaSC.jpg");
  imgBarras[3] = loadImage(imagenesPath + "/barras/" + "Borussia.jpg");
  imgBarras[4] = loadImage(imagenesPath + "/barras/" + "Corinthians.jpg");
  imgBarras[5] = loadImage(imagenesPath + "/barras/" + "Galatasaray.jpg");
  imgBarras[6] = loadImage(imagenesPath + "/barras/" + "Inter.jpg");
  imgBarras[7] = loadImage(imagenesPath + "/barras/" + "Lorenzo.jpg");
  imgBarras[8] = loadImage(imagenesPath + "/barras/" + "Milan.jpg");
  imgBarras[9] = loadImage(imagenesPath + "/barras/" + "Penarol.jpg");
  imgBarras[10] = loadImage(imagenesPath + "/barras/" + "America.jpg");
  imgBarras[11] = loadImage(imagenesPath + "/barras/" + "AtlMadrid.jpg");
  imgBarras[12] = loadImage(imagenesPath + "/barras/" + "Bayern.jpg");
  imgBarras[13] = loadImage(imagenesPath + "/barras/" + "Celtic.jpg");
  imgBarras[14] = loadImage(imagenesPath + "/barras/" + "Cruz.jpg");
  imgBarras[15] = loadImage(imagenesPath + "/barras/" + "Independiente.jpg");
  imgBarras[16] = loadImage(imagenesPath + "/barras/" + "Juventus.jpg");
  imgBarras[17] = loadImage(imagenesPath + "/barras/" + "Montevideo.jpg");
  imgBarras[18] = loadImage(imagenesPath + "/barras/" + "Racing.jpg");
  imgBarras[19] = loadImage(imagenesPath + "/barras/" + "Arsenal.jpg");
  imgBarras[20] = loadImage(imagenesPath + "/barras/" + "Barcelona.jpg");
  imgBarras[21] = loadImage(imagenesPath + "/barras/" + "Boca.jpg");
  imgBarras[22] = loadImage(imagenesPath + "/barras/" + "Cerro.jpg");
  imgBarras[23] = loadImage(imagenesPath + "/barras/" + "Flamengo.jpg");
  imgBarras[24] = loadImage(imagenesPath + "/barras/" + "IndependientesantaFe.jpg");
  imgBarras[25] = loadImage(imagenesPath + "/barras/" + "Liverpool.jpg");
  imgBarras[26] = loadImage(imagenesPath + "/barras/" + "Manchester.jpg");
  imgBarras[27] = loadImage(imagenesPath + "/barras/" + "Olimpia.jpg");
  imgBarras[28] = loadImage(imagenesPath + "/barras/" + "river.jpg");
}

public void cargarVideos(){
  videosArr[0] = new Movie(this, videosPath + "/" + "balones.mp4");
  videosArr[1] = new Movie(this, videosPath + "/" + "kaviedes.mp4");
  videosArr[2] = new Movie(this, videosPath + "/" + "maradona-mano.mp4");
  videosArr[3] = new Movie(this, videosPath + "/" + "primer-mundial.mp4");
  
  videosMascotas = new Movie(this, videosPath + "/" + "mascotas.mp4");
  
  videosArr[0].loop(); videosArr[0].pause(); videosArr[0].volume(0);
  videosArr[1].loop(); videosArr[1].pause(); videosArr[1].volume(0);
  videosArr[2].loop(); videosArr[2].pause(); videosArr[2].volume(0);
  videosArr[3].loop(); videosArr[3].pause(); videosArr[3].volume(0);
  videosMascotas.loop(); videosMascotas.pause(); videosMascotas.volume(0);
  
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
  //nya.setARPerspective();
  //scale(displayScale);
    
  
  if ((!nya.isExistMarker(0)) && (!nya.isExistMarker(1)) && (!nya.isExistMarker(2)) && (!nya.isExistMarker(3)) && (!nya.isExistMarker(4)) ){
      println("no nada");
      
      //pausar videos
      for(int i=0; i<numVideos; i++){
          //videosArr[i].pause();
        
      }
      
      return;
  }
  
  // Para la hoja A, Balones
  if(nya.isExistMarker(0)){
    //println("Balones"  + floor( minute()%numBalones ) );
    int indiceImagen = floor( minute()%numBalones ) ;
    int indiceColor = floor( minute()%numColores );
    dibujarImagen(imgBalones[indiceImagen], 0 , indiceColor);
  }
  
  
  // Para la hoja B, Jugadores
  if(nya.isExistMarker(1)){
    //println("Jugadores");
    int indiceImagen = floor( minute()%numJugadores ) ;
    int indiceColor = floor( minute()%numColores );
    dibujarImagen(imgJugadores[indiceImagen], 1 , indiceColor);
  }
  
  // Para la hoja C, Jugadores
  if(nya.isExistMarker(2)){
    //println("camisetas");
    int indiceImagen = floor( minute()%numCamisetas ) ;
    int indiceColor = floor( minute()%numCamisetas );
    dibujarImagen(imgCamisetas[indiceImagen], 2 , indiceColor);
  }
  
  // Para la hoja C, Jugadores
  if(nya.isExistMarker(3)){
    //println("camisetas");
    int indiceImagen = floor( minute()%numBarras ) ;
    int indiceColor = floor( minute()%numBarras );
    dibujarImagen(imgBarras[indiceImagen], 3 , indiceColor);
  }
  
  
  // Para la hoja C, Videos
  int indiceVideo = floor( minute()%numVideos ) ;
    int indiceColor = floor( minute()%numColores );
  if(nya.isExistMarker(4)){
    //println("Videos");
    //println("Videos" + indiceVideo);
    if (videosArr[indiceVideo].available() == true) {
      videosArr[indiceVideo].play();
    }
     dibujarVideo(videosArr[indiceVideo], 4 , (floor( minute()%numColores )) );   
  }else{   
    //videosArr[indiceVideo].pause();
  }
  
  /*// Para la hoja D, Jugadas
  if(nya.isExistMarker(3)){
    println("Jugadas");
  }*/
  
  // Para la hoja E, Mascotas
  if(nya.isExistMarker(5)){
    println("Mascotas");
   
    if (videosMascotas.available() == true) {
      videosMascotas.play();
    }
     dibujarVideo(videosMascotas, 5 , (floor( minute()%numColores )) );
  }
  
  

  perspective();
}

public void dibujarImagen(PImage imagen, int indiceMarker, int indiceColor){
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

          image(imagen, -140, -80, 200, 200);
          
        updatePixels();
       popMatrix();
    popMatrix();
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
