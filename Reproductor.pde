float value=1;
PImage img, img2, img3, img4, img5;
boolean selec, s=false;
int Hp, Lp, Bp,bands=512;
//float [] spectrum =new float [bands];
ControlP5 btn, sli;
Minim minim;
AudioPlayer song;
AudioMetaData meta;
HighPassSP highpass;
LowPassSP lowpass;
BandPass bandpass;
void pla() {
 if (s) {
   //minim.stop();
   song = minim.loadFile(path, 1024);
   meta = song.getMetaData();
   //fft = new FFT(song.bufferSize(), song.sampleRate());
   highpass = new HighPassSP(300, song.sampleRate());
   song.addEffect(highpass);
   lowpass = new LowPassSP(300, song.sampleRate());
   song.addEffect(lowpass);
   bandpass = new BandPass(300, 300, song.sampleRate());
   song.addEffect(bandpass);
   highpass.setFreq(Hp);
   lowpass.setFreq(Lp);
   bandpass.setFreq(Bp);
   selec=true;
 }
}
//void archivoseleccionado(File selection) {

//  if (selection != null) {
//    minim.stop();
//    song = minim.loadFile(selection.getAbsolutePath(), 1024);
//    meta = song.getMetaData();
//    //fft = new FFT(song.bufferSize(), song.sampleRate());
//    highpass = new HighPassSP(300, song.sampleRate());
//    song.addEffect(highpass);
//    lowpass = new LowPassSP(300, song.sampleRate());
//    song.addEffect(lowpass);
//    bandpass = new BandPass(300, 300, song.sampleRate());
//    song.addEffect(bandpass);
//    selec = true;
//  } else {
//    selec = false;
//    if (song != null) {
//      selec = true;
//    }
//    println("Window was closed or the user hit cancel. ");
//  }
//}

public void Sele() {
  selec=false;
  selectInput("Selecciona un archivo: ", "archivoseleccionado");
}
public void Play() {
  song.play();
  println("Play");
}
public void Stop() {
  song.pause();
  song.rewind();
  println("Stop");
  selec=false;
  s=false;
}
public void Pause() {
  song.pause();
  println("Pause");
}
public void Subir() {
  value=value+2;
  song.setGain(value);
  println("Subir");
}
public void Bajar() {
  value=value-2;
  song.setGain(value);
  println("Bajar");
}