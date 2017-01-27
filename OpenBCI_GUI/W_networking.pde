
///////////////////////////////////////////////////////////////////////////////
//
//    W_networking.pde (Networking Widget)
//    
//    This widget provides networking capabilities in the OpenBCI GUI. 
//    The networking protocols can be used for outputting data 
//    from the OpenBCI GUI to any program that can receive UDP, OSC,
//    or LSL input, such as Matlab, MaxMSP, Python, C/C++, etc.
//
//    The protocols included are: UDP, OSC, and LSL.
//     
//
//    Created by: Gabriel Ibagon, January 2017
//
///////////////////////////////////////////////////////////////////////////////



// TODOS 
//
// - set numChan and numBins based on some global variables
// - find a way to send unfiltered FFT
// - check if a channel instead of sending inactive array
// - allow user to select which channels to send (UI is left)
// - add lots of error checking and warnings
// - test for latency issues
// - test if you can parse all messages



// - Test test test test test!

class W_networking extends Widget {

  /* Dropdown Menu variables */
  public int protocolMode = 0;
  public int filteredMode = 0;
  public int sendReceiveMode = 0;
  public int dataTypeMode = 0;

  /* Widget variables */
  private Button startButton;
  private ControlP5 cp5_networking;
  private String statusText;
  public int[] channelArray;
  public Boolean filtered = true;
  private Boolean isSending = false;
  private Boolean newData = false;
  private Boolean initialized = false;
  private int sampleNumber = 0;
  private int numChan = 8;
  private int numBins = 125;
  private String[] activeChans = new String[numChan];

  /* Network Objects */
  private OscP5 osc;
  private NetAddress netaddress;
  private UDP udp;
  private LSL.StreamInfo info_data;
  private LSL.StreamOutlet outlet_data;
  private LSL.StreamInfo info_aux;
  private LSL.StreamOutlet outlet_aux;

  /* Network Parameters */
  private String ip;
  private int port;
  private String address;
  private String data_stream;
  private String aux_stream; 
  private String data_stream_id;
  private String aux_stream_id; 
  private float[] tsDataToSend = new float[numChan]; 
  private float[][] fftDataToSend = new float[numChan][numBins];


  /**
   * @description Constructor for Networking Widget
   * @param `_parent` {PApplet} - The OpenBCI GUI application.
   * @constructor
   */
  W_networking(PApplet _parent){

    super(_parent);
    init();// initialize UI of the Widget

  }

  /**
  * @description Used to initalize the UI elements of the widget.
  */
  void init(){

    /* Dropdowns */
    // format -> addDropDown(name,callback_function, options, arg passed)
    addDropdown("Protocol", "Protocol", 
      Arrays.asList("OSC", "UDP", "LSL", "Serial"), protocolMode);
    addDropdown("SendReceive", "S/R", 
      Arrays.asList("Send", "Receive"), sendReceiveMode);
    addDropdown("DataType", "Data Type", 
      Arrays.asList("TimeSer", "FFT"), dataTypeMode);
    addDropdown("Filter", "Raw/Filt", 
      Arrays.asList("Raw","Filtered"), filteredMode);
    

    /* Textfields */
    // format -> createTextFields(name, default_text, x0, y0)

    // OSC
    createTextFields("osc_ip","localhost",x+w/2, y+h/2);
    createTextFields("osc_port","12345",x+w/2, y+h/2+35);
    createTextFields("osc_address","/openbci",x+w/2, y+h/2+70);
    // UDP
    createTextFields("udp_ip","localhost",x+w/2, y+h/2);
    createTextFields("udp_port","12345",x+w/2, y+h/2+35);
    // LSL
    createTextFields("lsl_data","openbci_eeg",x+w/2, y+h/2);
    createTextFields("lsl_aux","openbci_aux",x+w/2, y+h/2+35);
    //General
    //check if channels are active, create string

    for(int i = 0;i<8;i++){
      if(isChannelActive(i)){
        activeChans[i] = true;
      }
    }
    // createTextFields("channels",activeChans,x+w/2,y+h/2+200);

    showTextFields();

    /* Start Button */
    // format -> Button(x0, y0, width, height, text, fontsize);
    startButton = new Button(x+w/2-100,y+h-40,200,20,"Start",14);
    startButton.setFont(p4,14);        
    startButton.setColorNotPressed(color(184,220,105));

  }


  /**
  * @description Loops through the data handling aspects of widget at
  *   application refresh rate. 
  */
  void update(){
    super.update();
    updateChannelOptions();
    if (isSending && isRunning){
      if (checkForData()){
        toSend = collectData();
        sendData(toSend);
      }
    }
  }

  void updateChannelOptions(){
    for(int i = 0;i<8;i++){
      if(isChannelActive(i)){
        activeChans[i] = true;
      }
    }
    //WRITE INTO CHANNEL OPTIONS BOX (HOWEVER THIS IS STRUCTURED)
  }

  void checkForData(){
    /* Test to see if new data points have arrived */
    switch (eegDataSource) {
      case (DATASOURCE_NORMAL_W_AUX):
        break;
      case (DATASOURCE_GANGLION):
        break;
      case (DATASOURCE_PLAYBACKFILE):
      case (DATASOURCE_SYNTHETIC): 
        if (newSynthData){
          return true;
        }else{
          return false;
        }
        break;
    }
  }

  void collectData(){

    /* Collect the data from global variables */
    if (newData){
      if(dataTypeMode==0){
        /* time series*/
        if(filtered){
          for (int chan=0;chan<numChan;chan++){
            tsDataToSend[chan] = dataBuffY_filtY_uV[chan][0];
          }
        }else{
        /* Time series */
          if(dataTypeMode==0){
            for (int chan=0;chan<8;chan++){
              tsDataToSend[chan] = yLittleBuff_uV[chan][0];
            }
          }
        }
        return tsDataToSend;

      /* FFT data */
      }else{
        if(filtered){
          for (int i=0;i<numChan;i++){
            for (int j=0;j<125;j++){
              fftDataToSend[i][j] = fftBuff[i].getBand(j);
            }
          }
        }else{
          // NO UNFILTERED FFT EXISTS!
          println("Nooo");
        }
        return fftDataToSend;
      }
    }
  }
  /**
   * @description Send data through the selected protocol
   * @param `dataToSend` {Object} - Data to be sent over the network, either a
   *  float[] object or float[][] object
   * 
   * NOTE: Consider replacing "Object" parameter with an interface that can handle
   *  multiple types.
   */
  void sendData(Object dataToSend){
    /*OSC*/
    if(protocolMode==0){
      /* Initialize OSC */        
      if(!initialized){
        /* Get OSC parameters*/        
        ip = cp5.get(Textfield.class, "osc_ip").getText();
        port = Integer.parseInt(cp5.get(Textfield.class, "osc_port").getText());
        address = cp5.get(Textfield.class, "osc_address").getText();
        /* Instantiate OSC objects*/                  
        osc = new OscP5(this,12000);
        netaddress = new NetAddress(ip,port);
        initialized=true;
      }
      /* Send message as object */
      OscMessage msg = new OscMessage(address);

      /* Send time series */
      if(dataTypeMode==0){
        msg.add((float[])dataToSend);
      /* Send FFT */
      }else if(dataTypeMode==1){
        float[][] tempDataToSend = (float[][])dataToSend;
        for(int i=0;i<numChan;i++){
          msg.add(tempDataToSend[i]);
        }
      }
      osc.send(msg,netaddress);
    
    /* UDP */
    }else if (protocolMode==1){

      /* Initialize UDP */
      if(!initialized){
        
        /* Get UDP parameters */
        ip = cp5.get(Textfield.class, "udp_ip").getText();
        port = Integer.parseInt(cp5.get(Textfield.class, "udp_port").getText());
        
        /* Instantiate UDP objects */
        udp = new UDP(this);
        udp.setBuffer(1024);
        udp.log(false);
        initialized=true;
      }

      /* Send sample as string through UDP */
      String msg;
      if(dataTypeMode==0){
        msg = Arrays.toString((float[])dataToSend);
      }else{
        float[][] tempDataToSend = (float[][])dataToSend;
        StringBuilder sb = new StringBuilder();
        for(int i=0;i<numChan;i++){
          sb.append(Arrays.toString(tempDataToSend[i]));
        }
        msg = sb.toString();
      }
      udp.send(msg,ip,port);

    /* LSL */
    }else if (protocolMode==2){
      
      /* Initialize LSL */
      if(!initialized){

        /* Get LSL parameters */
        data_stream = cp5.get(Textfield.class, "lsl_data").getText();
        aux_stream = cp5.get(Textfield.class, "lsl_aux").getText();
        data_stream_id = data_stream + "_id";
        aux_stream_id = aux_stream + "_id";
        
        /* Instantiate LSL objects */
        info_data = new LSL.StreamInfo(
                              data_stream, 
                              "EEG", 
                              nchan, 
                              openBCI.get_fs_Hz(), 
                              LSL.ChannelFormat.float32, 
                              data_stream_id
                            );
        outlet_data = new LSL.StreamOutlet(info_data);
        info_aux = new LSL.StreamInfo(
                              aux_stream_id, 
                              "AUX", 
                              3, 
                              openBCI.get_fs_Hz(), 
                              LSL.ChannelFormat.float32, 
                              aux_stream_id);
        outlet_aux = new LSL.StreamOutlet(info_aux);
        initialized=true;
      }
      /* Push sample through LSL */
      if(dataTypeMode==0){
        outlet_data.push_sample((float[])dataToSend);
      }else{
        outlet_data.push_sample((float[])dataToSend);
      }
    }
  }

  /**
  * @description Loops through the UI aspects of widget at
  *   application refresh rate. 
  */
  void draw(){
    super.draw();

    pushStyle();                  // Begin style
    startButton.draw();           // draw button
    
    textAlign(LEFT,CENTER);       // Positions the header text
    int title_x0 = x+w/6;         // x0 position of parameter title
    fill(0,0,0);                  // Background fill: white
    
    /* Sets currenct status text */
    if(!isSending){
      statusText = "Not Active";
    }else{
      statusText = "Active";
    }

    // OSC
    if(protocolMode == 0){
      textFont(f4,48);
      text("OSC", x+10,y+h/8);
      textFont(h1,20);
      text("IP", title_x0,y+h/3);
      text("Port", title_x0, y+h/3+35);
      text("Address",title_x0,y+h/3+70);
      text("Status:",title_x0, y+h/3+105);
      text(statusText,x+w/2, y+h/3+105);
    // UDP
    } else if (protocolMode == 1){
      textFont(f4,48);
      text("UDP", x+10,y+h/8);
      textFont(h1,20);
      text("IP", title_x0,y+h/3);
      text("Port", title_x0, y+h/3+35);
      text("Status:",title_x0, y+h/3+70);
      text(statusText, x+w/2, y+h/3+70);
    // LSL
    } else if (protocolMode == 2){
      textFont(f4,48);
      text("LSL", x+10,y+h/8);
      textFont(h1,20);
      text("Data Stream", title_x0,y+h/3);
      text("Aux Stream", title_x0, y+h/3+35);
      text("Status:", title_x0, y+h/3+70);
      text(statusText, x+w/2, y+h/3+70);
    } else if (protocolMode == 3){
      text("Serial", x+10,y+h/8);
      textFont(h1,20);
      text("Status:", title_x0, y+h/3+105);
      text(statusText, x+w/2, y+h/3+105);
    }
    popStyle();

  }

  void screenResized(){
    super.screenResized(); //calls the parent screenResized() method of Widget

    startButton.setPos(x + w/2 -100, y + h - 40 );

    cp5_widget.get(Textfield.class, "osc_ip").setPosition(x+w/2, y+h/3);
    cp5_widget.get(Textfield.class, "osc_port").setPosition(x+w/2, y+h/3+35);
    cp5_widget.get(Textfield.class, "osc_address").setPosition(x+w/2, y+h/3+70);
    cp5_widget.get(Textfield.class, "udp_ip").setPosition(x+w/2, y+h/3);
    cp5_widget.get(Textfield.class, "udp_port").setPosition(x+w/2, y+h/3+35);
    cp5_widget.get(Textfield.class, "lsl_data").setPosition(x+w/2, y+h/3);
    cp5_widget.get(Textfield.class, "lsl_aux").setPosition(x+w/2, y+h/3+35);  

  }

  void mousePressed(){
    super.mousePressed(); //calls the parent mousePressed() method of Widget

    if(startButton.isMouseHere()){
      startButton.setIsActive(true);
    }
 
  }

  void mouseReleased(){
    super.mouseReleased(); //calls the parent mouseReleased() method of Widget (DON'T REMOVE)
 
    //put your code here...
    if(startButton.isActive && startButton.isMouseHere()){
      if(!isSending){
        isSending = true;
        startButton.setColorNotPressed(color(224, 56, 45));
        startButton.setString("Stop");
      }else{
        isSending = false;
        startButton.setColorNotPressed(color(184,220,105));
        startButton.setString("Start");
      }
    }
    startButton.setIsActive(false);
 
  }

  /**
   * @description Creates a textfield that can be used to set a parameter
   *  for a protocol
   */
  void createTextFields(String name, String default_text, int _x, int _y){
    cp5_widget.addTextfield(name)
      .setPosition(_x,_y)                    // Position of textfield on canvas
      .align(5, 10, 20, 40)                  // Alignment (?)
      .setSize(100,26)                       // Size of textfield
      .setFocus(false)                       // Deselects textfield
      .setColor(color(26,26,26))             // Textfield Color
      .setColorBackground(color(0,0,0))      // TextField Background Color
      .setColorValueLabel(color(0,0,0))      // Font color
      .setColorForeground(isSelected_color)  // Border color when unselected
      .setColorActive(isSelected_color)      // Border color when selected
      .setColorCursor(color(26,26,26))       // Cursor color when over field
      .setText(default_text)                 // Default text in the field
      .setFont(f2)                           // Text font
      .setCaptionLabel("")                   // Remove caption label
      // .onDoublePress(net_cb)              // Clear on double click (?)
      .setVisible(false)                     // Initially hidden
      .setAutoClear(true)                    // Autoclear (?)
      ;
  }

  /**
   * @description Sets textfields for protocol parameters as visible/invisible,
   *    depending on what protocol is currently set.
   */
  void showTextFields(){

    /* OSC set */
    if(protocolMode == 0){
      cp5_widget.get(Textfield.class, "osc_ip").setVisible(true);
      cp5_widget.get(Textfield.class, "osc_port").setVisible(true);
      cp5_widget.get(Textfield.class, "osc_address").setVisible(true);
      cp5_widget.get(Textfield.class, "udp_ip").setVisible(false);
      cp5_widget.get(Textfield.class, "udp_port").setVisible(false);
      cp5_widget.get(Textfield.class, "lsl_data").setVisible(false);
      cp5_widget.get(Textfield.class, "lsl_aux").setVisible(false);
    /* UDP set */
    }else if(protocolMode == 1){
      cp5_widget.get(Textfield.class, "osc_ip").setVisible(false);
      cp5_widget.get(Textfield.class, "osc_port").setVisible(false);
      cp5_widget.get(Textfield.class, "osc_address").setVisible(false);
      cp5_widget.get(Textfield.class, "udp_ip").setVisible(true);
      cp5_widget.get(Textfield.class, "udp_port").setVisible(true);
      cp5_widget.get(Textfield.class, "lsl_data").setVisible(false);
      cp5_widget.get(Textfield.class, "lsl_aux").setVisible(false);
    /* LSL set */    
    }else if(protocolMode == 2){
      cp5_widget.get(Textfield.class, "osc_ip").setVisible(false);
      cp5_widget.get(Textfield.class, "osc_port").setVisible(false);
      cp5_widget.get(Textfield.class, "osc_address").setVisible(false);
      cp5_widget.get(Textfield.class, "udp_ip").setVisible(false);
      cp5_widget.get(Textfield.class, "udp_port").setVisible(true);
      cp5_widget.get(Textfield.class, "lsl_data").setVisible(true);
      cp5_widget.get(Textfield.class, "lsl_aux").setVisible(true);  
    }

  }

  /**
   * @description Turns off a running network when protocol is switched from menu.
   *    Network status and initialization vars set to 0, Button set to "Start". 
   */
  public void turnOffNetworking(){
    startButton.setColorNotPressed(color(184,220,105));
    startButton.setString("Start");
    initialized=false;
    isSending = false;
  }

}

/* Dropdown Menu Callback Functions */
/**
 * @description Sets the selected protocol mode from the widget's dropdown menu
 * @param `protocolIndex` {int} - Index of protocol item selected in menu
 */
void Protocol(int protocolIndex){
  println("Item " + (protocolIndex+1) + " selected from Dropdown 1");
  w_networking.turnOffNetworking();
  w_networking.showTextFields();
  w_networking.protocolMode = protocolIndex;
  closeAllDropdowns();
}

/**
 * @description Sets the selected send/receive mode from the widget's 
 *  dropdown menu.
 * @param `sendReceiveIndex` {int} - Index of send/receive mode selected in 
 *  menu.
 */
void SendReceive(int sendReceiveIndex){
  println("Item " + (sendReceiveIndex+1) + " selected from Dropdown 1");
  w_networking.sendReceiveMode = sendReceiveIndex;
  closeAllDropdowns();
}

/**
 * @description Sets the selected datatype mode from the widget's dropdown 
 *  menu.
 * @param `dataTypeIndex` {int} - Index of protocol item selected in menu
 */
void DataType(int dataTypeIndex){
  println("Item " + (dataTypeIndex+1) + " selected from Dropdown 1");
  w_networking.dataTypeMode = dataTypeIndex;
  closeAllDropdowns();
}

/**
 * @description Sets the selected filter mode from the widget's dropdown 
 *  menu.
 * @param `filterIndex` {int} - Index of protocol item selected in menu
 */
void Filter(int filterIndex){
  println("Item " + (filterIndex+1) + " selected from Dropdown 1");
  if(filterIndex==0){
    w_networking.filtered = false;
  }else{
    w_networking.filtered = true;
  }
  closeAllDropdowns();
}
