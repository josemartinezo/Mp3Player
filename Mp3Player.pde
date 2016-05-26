import controlP5.*;
import ddf.minim.*;
import ddf.minim.analysis.*;
import ddf.minim.effects.*;
import java.util.*;
import java.net.InetAddress;
import javax.swing.*;
import javax.swing.filechooser.FileFilter;
import javax.swing.filechooser.FileNameExtensionFilter;
import org.elasticsearch.action.admin.indices.exists.indices.IndicesExistsResponse;
import org.elasticsearch.action.admin.cluster.health.ClusterHealthResponse;
import org.elasticsearch.action.index.IndexRequest;
import org.elasticsearch.action.index.IndexResponse;
import org.elasticsearch.action.search.SearchResponse;
import org.elasticsearch.action.search.SearchType;
import org.elasticsearch.client.Client;
import org.elasticsearch.common.settings.Settings;
import org.elasticsearch.node.Node;
import org.elasticsearch.node.NodeBuilder;

// Constantes para referir al nombre del indice y el tipo
static String INDEX_NAME = "canciones";
static String DOC_TYPE = "cancion";
String path="";
ControlP5 cp5;
ScrollableList list;

Client client;
Node node;

void setup() {
  background(0);
  fill(0);
  img = loadImage("boton.jpg");
  img2= loadImage("boton2.jpg");
  img3=loadImage("boton3.jpg");
  img4=loadImage("boton4.jpg");
  img5=loadImage("boton5.jpg");
  btn = new ControlP5(this);
  btn.addButton("Play").setValue(0).setSize(20, 15).setImage(img).setPosition(170, height-85);
  btn=new ControlP5(this);
  btn.addButton("Stop").setValue(0).setSize(20, 15).setImage(img3).setPosition(205, height-85);
  btn=new ControlP5(this);
  btn.addButton("Pause").setValue(0).setSize(20, 15).setImage(img2).setPosition(135, height-85);
  btn=new ControlP5(this);
  btn.addButton("Subir").setValue(0).setSize(20, 15).setImage(img4).setPosition(100, height-85);
  btn=new ControlP5(this);
  btn.addButton("Bajar").setValue(0).setSize(20, 15).setImage(img5).setPosition(100, height-45);
  //btn= new ControlP5(this);
  //btn.addButton("Sele").setPosition(width/2-245, height-20).setSize(20, 15);
  sli=new ControlP5(this);
  sli.addSlider("Hp").setPosition(20, height-95).setSize(12, 80).setRange(1000, 14000).setValue(1000).setNumberOfTickMarks(30);
  //sli=new ControlP5(this);
  sli.addSlider("Lp").setPosition(45, height-95).setSize(12, 80).setRange(3000, 20000).setValue(3000).setNumberOfTickMarks(30);
  //sli=new ControlP5(this);
  sli.addSlider("Bp").setPosition(70, height-95).setSize(12, 80).setRange(100, 1000).setValue(100).setNumberOfTickMarks(30);
  sli.getController("Hp").getValueLabel().align(ControlP5.RIGHT, ControlP5.BOTTOM_OUTSIDE).setPaddingY(100);
  sli.getController("Lp").getValueLabel().align(ControlP5.RIGHT, ControlP5.BOTTOM_OUTSIDE).setPaddingY(100);
  sli.getController("Bp").getValueLabel().align(ControlP5.RIGHT, ControlP5.BOTTOM_OUTSIDE).setPaddingY(100);
  //println(" "+file.sampleRate()+" HZ");
  minim = new Minim(this);
  // |||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||


  size(500, 400);
  cp5 = new ControlP5(this);

  // Configuracion basica para ElasticSearch en local
  Settings.Builder settings = Settings.settingsBuilder();
  // Esta carpeta se encontrara dentro de la carpeta del Processing
  settings.put("path.data", "esdata");
  settings.put("path.home", "/");
  settings.put("http.enabled", false);
  settings.put("index.number_of_replicas", 0);
  settings.put("index.number_of_shards", 1);

  // Inicializacion del nodo de ElasticSearch
  node = NodeBuilder.nodeBuilder()
    .settings(settings)
    .clusterName("mycluster")
    .data(true)
    .local(true)
    .node();

  // Instancia de cliente de conexion al nodo de ElasticSearch
  client = node.client();

  // Esperamos a que el nodo este correctamente inicializado
  ClusterHealthResponse r = client.admin().cluster().prepareHealth().setWaitForGreenStatus().get();
  println(r);

  // Revisamos que nuestro indice (base de datos) exista
  IndicesExistsResponse ier = client.admin().indices().prepareExists(INDEX_NAME).get();
  if (!ier.isExists()) {
    // En caso contrario, se crea el indice
    client.admin().indices().prepareCreate(INDEX_NAME).get();
  }

  // Agregamos a la vista un boton de importacion de archivos
  cp5.addButton("importFiles")
    .setPosition(125,height-40)
    .setSize(100, 10)
    .setLabel("Importar archivos");

  // Agregamos a la vista una lista scrollable que mostrara las canciones
  list = cp5.addScrollableList("playlist")
    .setPosition(0, 0)
    .setSize(500, 100)
    .setBarHeight(20)
    .setItemHeight(20)
    .setType(ScrollableList.LIST);

  // Cargamos los archivos de la base de datos
  loadFiles();
}

void draw() {
  background(0, 170, 255);
  if (selec) {
    highpass.setFreq(Hp);
    lowpass.setFreq(Lp);
    bandpass.setFreq(Bp);
    fill(0);
    //stroke(0);
    rect(0, 300, width, 100);
    //  background(255);
    //fft.forward(song.mix);
    textSize(13);
    fill(0, 170, 255);
    text("Titulo: "+meta.title(), width-250, height-70);
    text("Autor: "+meta.author(), width-250, height-40);
    fill(0);
    for ( int i = 0; i < song.bufferSize() - 1; i++ )
    {
      float x1 = map(i, 0, song.bufferSize(), 0, width);
      float x2 = map(i+1, 0, song.bufferSize(), 0, width);
      line(x1, height/6 - song.left.get(i)*50, x2, height/6 - song.left.get(i+1)*50);
      line(x1, 3*height/6 - song.right.get(i)*50, x2, 3*height/6 - song.right.get(i+1)*50);
    }
  }
}

void importFiles() {
  // Selector de archivos
  JFileChooser jfc = new JFileChooser();
  // Agregamos filtro para seleccionar solo archivos .mp3
  jfc.setFileFilter(new FileNameExtensionFilter("MP3 File", "mp3"));
  // Se permite seleccionar multiples archivos a la vez
  jfc.setMultiSelectionEnabled(true);
  // Abre el dialogo de seleccion
  jfc.showOpenDialog(null);

  // Iteramos los archivos seleccionados
  for (File f : jfc.getSelectedFiles()) {
    // Si el archivo ya existe en el indice, se ignora
    GetResponse response = client.prepareGet(INDEX_NAME, DOC_TYPE, f.getAbsolutePath()).setRefresh(true).execute().actionGet();
    if (response.isExists()) {
      continue;
    }

    // Cargamos el archivo en la libreria minim para extrar los metadatos
    Minim minim = new Minim(this);
    AudioPlayer song = minim.loadFile(f.getAbsolutePath());
    AudioMetaData meta = song.getMetaData();

    // Almacenamos los metadatos en un hashmap
    Map<String, Object> doc = new HashMap<String, Object>();
    doc.put("author", meta.author());
    doc.put("title", meta.title());
    doc.put("path", f.getAbsolutePath());

    try {
      // Le decimos a ElasticSearch que guarde e indexe el objeto
      client.prepareIndex(INDEX_NAME, DOC_TYPE, f.getAbsolutePath())
        .setSource(doc)
        .execute()
        .actionGet();

      // Agregamos el archivo a la lista
      addItem(doc);
    } 
    catch(Exception e) {
      e.printStackTrace();
    }
  }
}

// Al hacer click en algun elemento de la lista, se ejecuta este metodo
void playlist(int n) {
  //println(list.getItem(n));
  Map<String, Object> value =(Map<String, Object>)list.getItem(n).get("value");
  println (value.get("path"));
  path=(value.get("path").toString());
  s=true;
  pla();
}

void loadFiles() {
  try {
    // Buscamos todos los documentos en el indice
    SearchResponse response = client.prepareSearch(INDEX_NAME).execute().actionGet();

    // Se itera los resultados
    for (SearchHit hit : response.getHits().getHits()) {
      // Cada resultado lo agregamos a la lista
      addItem(hit.getSource());
    }
  } 
  catch(Exception e) {
    e.printStackTrace();
  }
}

// Metodo auxiliar para no repetir codigo
void addItem(Map<String, Object> doc) {
  // Se agrega a la lista. El primer argumento es el texto a desplegar en la lista, el segundo es el objeto que queremos que almacene
  list.addItem(doc.get("author") + " - " + doc.get("title"), doc);
}