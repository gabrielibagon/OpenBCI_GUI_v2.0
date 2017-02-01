
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
// Immediate importance:
// 1. make sure that the correct data is being sent
//    a. raw
//    b. filtered
// 2. make sure the data is being sent synchronously
// 3. make sure TS, FFT, and both can be sent...
//    a. TS (check!)
//    b. FFT 
//    c. both
// 4. make sure works for live and recorded
// 5. make sure it works for all numChans (be very careful about variable sf)
//
// - set numChan and numBins based on some global variables
// - fix FFT buffer/latency issue
// - find a way to send unfiltered FFT
// - check if a channel instead of sending inactive array
// - allow user to select which channels to send
// - add lots of error checking and warnings
// - test for latency issues
// - test if you can parse all messages
// - possible to send TS and FFT at the same time?
// - get args to change when user does
// - Test test test test test!

class W_networking extends Widget {

  /* NavBar Dropdown Menu variables */
  int protocolMode = 0;
  /* Widget Dropdown Menu variables */
  int dataTypeMode1;//type of data to send in stream1
  int dataTypeMode2;//type of data to send in stream2
  int dataTypeMode3;//type of data to send in stream3
  int filtered1 = 0;//raw (0) vs filtered (1) for stream1
  int filtered2 = 0;//raw (0) vs filtered (1) for stream1
  int filtered3 = 0;//raw (0) vs filtered (1) for stream1


  /* Widget variables */
  Button startButton;
  Boolean isSending = false;
  Boolean newData = false;
  Boolean initialized = false;
  Boolean osc_visible=true;
  Boolean udp_visible=false;
  Boolean lsl_visible=false;

  int numChan = 8;
  int numBins = 125;
  Boolean[] activeChans = new Boolean[numChan];
  CallbackListener net_cb;
  ControlP5 cp5_networking;

  /* Widget grid */
  int column0;
  int column1;
  int column2;
  int column3;
  int row0;
  int row1;
  int row2;
  int row3;
  int row4;
  int row5;

  /* Stream Objects */
  Stream stream1;
  Stream stream2;
  Stream stream3;

  /* Network Parameters */
  String ip1;
  String ip2;
  String ip3;
  int port1;
  int port2;
  int port3;
  String address1;
  String address2;
  String address3;
  String data_stream1;
  String data_stream2;
  String data_stream3;

  String data_stream_id;
  String aux_stream_id; 
  float[][] tsDataToSend = new float[numChan][10]; 
  float[][] fftDataToSend = new float[numChan][numBins];


  /**
   * @description Constructor for Networking Widget
   * @param `_parent` {PApplet} - The OpenBCI GUI application.
   * @constructor
   */
  W_networking(PApplet _parent){

    super(_parent);
    init();//initialize UI of the Widget
  }

  /**
  * @description Used to initalize the UI elements of the widget.
  */
  void init(){

    /* networking specific CP5 instance */
    cp5_networking = new ControlP5(pApplet);
    callback_init();//initialize CP5 callback

    /* Dropdowns */
    // format -> addDropDown(name,callback_function, options, arg passed)
    addDropdown("Protocol", "Protocol", 
      Arrays.asList("OSC", "UDP", "LSL"), protocolMode);

    /* Data type list */
    createDataTypeLists("datatype1");
    createDataTypeLists("datatype2");
    createDataTypeLists("datatype3");

    /* Filter Buttons */
    createRadioButtons("filter1");
    createRadioButtons("filter2");
    createRadioButtons("filter3");

    /* Textfields */
    // format -> createTextFields(name, default_text, x0, y0)
    // OSC
    createTextFields("osc_ip1","localhost");
    createTextFields("osc_port1","12345");
    createTextFields("osc_address1","/openbci");
    createTextFields("osc_ip2","localhost");
    createTextFields("osc_port2","12345");
    createTextFields("osc_address2","/openbci");
    createTextFields("osc_ip3","localhost");
    createTextFields("osc_port3","12345");
    createTextFields("osc_address3","/openbci");

    // UDP
    createTextFields("udp_ip1","localhost");
    createTextFields("udp_port1","12345");
    createTextFields("udp_ip2","localhost");
    createTextFields("udp_port2","12345");
    createTextFields("udp_ip3","localhost");
    createTextFields("udp_port3","12345");
    // LSL
    createTextFields("lsl_name1","obci_eeg");
    createTextFields("lsl_name2","obci_aux");
    createTextFields("lsl_name3","obci_marker");

    /* Start Button */
    // format -> Button(x0, y0, width, height, text, fontsize);
    startButton = new Button(x+w/2-100,y+h-40,200,20,"Start",14);
    startButton.setFont(p4,14);        
    startButton.setColorNotPressed(color(184,220,105));

  }

  /**
  * @description Used to initalize the filter on/off radio buttons.
   * @param `name` {String} - identifier of the radio button
  */
  void createRadioButtons(String name){
    cp5_networking.addRadioButton(name)
        .setSize(10,10)
        .setColorForeground(color(120))
        .setColorActive(color(184,220,105))
        .setColorLabel(color(0))
        .setItemsPerRow(2)
        .setSpacingColumn(20)
        .addItem("On",1)
        .addItem("Off",2)
        .activate(1)
        .setVisible(false)
        ;
  }

  /**
  * @description Used to initalize the datatype dropdowns.
   * @param `name` {String} - identifier of the radio button
  */
  void createDataTypeLists(String name){
    CColor dropdownColors = new CColor();
    dropdownColors.setActive((int)color(150, 170, 200)); //bg color of box when pressed
    dropdownColors.setForeground((int)color(125)); //when hovering over any box (primary or dropdown)
    dropdownColors.setBackground((int)color(255)); //bg color of boxes (including primary)
    dropdownColors.setCaptionLabel((int)color(1, 18, 41)); //color of text in primary box
    dropdownColors.setValueLabel((int)color(100)); //color of text in all dropdown boxes

    ArrayList<String> dataTypes = new ArrayList<String>();
    dataTypes.add("None");
    dataTypes.add("EEG");
    dataTypes.add("FFT");
    dataTypes.add("Widget");
    println(dataTypes);
    cp5_networking.addScrollableList(name)
      .setSize(80,20)
      .setOpen(false)
      .setColor(dropdownColors)
      .setBarHeight(20) //height of top/primary bar
      .setItemHeight(20) //height of all item/dropdown bars
      .addItems(dataTypes)
      .setVisible(false)
      ;
    cp5_networking.getController(name)
      .getCaptionLabel() //the caption label is the text object in the primary bar
      .toUpperCase(false)
      .setText("test")
      .setFont(h4)
      .setSize(14)
      .getStyle() //need to grab style before affecting the paddingTop
      .setPaddingTop(4)
      ;
    cp5_networking.getController(name)
      .getValueLabel() //the value label is connected to the text objects in the dropdown item bars
      .toUpperCase(false) //DO NOT AUTOSET TO UPPERCASE!!!
      .setText("test 1 2 3")
      .setFont(h5)
      .setSize(12) //set the font size of the item bars to 14pt
      .getStyle() //need to grab style before affecting the paddingTop
      .setPaddingTop(3) //4-pixel vertical offset to center text
      ;
    pushStyle();
    noStroke();
    textFont(h5);
    textSize(12);
    textAlign(CENTER, BOTTOM);
    fill(bgColor);


    textAlign(RIGHT, TOP);
    cp5_networking.draw();
    popStyle();
  }

  /**
  * @description Loops through the data handling aspects of widget at
  *   application refresh rate. 
  */
  void update(){
    super.update();
    setFilters();

    if (isSending && isRunning){

      /* If not initialized, initialize the network */
      if (dataTypeMode1!=-1){
        if(!initialized){
         // initializeNetwork();
        }
      }else if (dataTypeMode2!=-1){

      }


      /* Collect data into variables */
      // TEMPORARY WORKAROUND
      float[][] rawTs = collectData(0);
      float[][] filteredTS = collectData(1);
      float[][] filteredFFT = collectData(2);


      /*Send data through appropriate stream */
      /* Stream 1 */


      // datatypeMode1 = cp5_networking.get(ScrollableList.class, "datatype1").getValue();


      // float[] tempToSend = new float[8];
      // for(int i=0;i<10;i++){
      //   for (int j=0;j<numChan;j++){
      //     tempToSend[j] = toSend[j][i];
      //   }
      //   sendData(tempToSend);

      // }
      // sendData(toSend);
    }
  }


  void setFilters(){
    filtered1 = (int)cp5_networking.get(RadioButton.class, "filter1").getValue();
    filtered2 = (int)cp5_networking.get(RadioButton.class, "filter2").getValue();
    filtered3 = (int)cp5_networking.get(RadioButton.class, "filter3").getValue();
  }

  /**
  * @description Checks to see if new data has arrived
  *
  */
  Boolean checkForData(){
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
    }
    return false;
  }


  float[][] collectData(int temp){
    if(temp==0){
      int start = dataBuffY_filtY_uV[0].length-11;
      int end = dataBuffY_filtY_uV[0].length-1;
      for (int chan=0;chan<numChan;chan++){
        tsDataToSend[chan] = Arrays.copyOfRange(dataBuffY_filtY_uV[chan],start,end);
      }
      return tsDataToSend;
    }else if (temp==1){
    /* Time series */
      for (int chan=0;chan<numChan;chan++){
        tsDataToSend[chan] = yLittleBuff_uV[chan];
      }
      return tsDataToSend;
    }else{
      for (int i=0;i<numChan;i++){
        for (int j=0;j<125;j++){
          fftDataToSend[i][j] = fftBuff[i].getBand(j);
        }
      }
      return fftDataToSend;
    }
  }



  /**
  * @description Loops through the UI aspects of widget at
  *   application refresh rate. 
  */
  void draw(){
    super.draw();
    showCP5();
    pushStyle();                  // Begin style
    startButton.draw();           // draw button
    dtDropdown_update("datatype1");
    dtDropdown_update("datatype2");
    dtDropdown_update("datatype3");

    textAlign(LEFT,CENTER);       // Positions the header text
    fill(0,0,0);                  // Background fill: white
    textFont(h1,20);
    text("Stream 1",column1,row0);
    text("Stream 2",column2,row0);
    text("Stream 3",column3,row0);
    text("Data Type", column0,row1);
    // OSC
    if(protocolMode == 0){
      textFont(f4,40);
      text("OSC", x+10,y+h/8);
      textFont(h1,20);
      text("IP", column0,row2);
      text("Port", column0,row3);
      text("Address",column0,row4);
      text("Filter",column0,row5);
    // UDP
    } else if (protocolMode == 1){
      textFont(f4,48);
      text("UDP", x+10,y+h/8);
      textFont(h1,20);
      text("IP", column0,row2);
      text("Port", column0,row3);
      text("Filter",column0,row4);      
    // LSL
    } else if (protocolMode == 2){
      textFont(f4,48);
      text("LSL", x+10,y+h/8);
      textFont(h1,20);
      text("Name", column0,row2);
      text("Type", column0,row3);
      text("Filter",column0,row4);      
    }

    // cp5_networking.draw();
    popStyle();

  }

  /**
  * @description Redraws screen when resized
  *
  */
  void screenResized(){
    super.screenResized(); //calls the parent screenResized() method of Widget
    int buttonRow=5;
    column0 = x+w/20;
    column1 = x+3*w/10;
    column2 = x+5*w/10;
    column3 = x+7*w/10;
    row0 = y+h/4;
    row1 = y+4*h/10;
    row2 = y+5*h/10;
    row3 = y+6*h/10;
    row4 = y+7*h/10;
    row5 = y+8*h/10;

    startButton.setPos(x + w/2 -100, y + h - 40 );
    cp5_networking.get(ScrollableList.class, "datatype1").setPosition(column1,row1);
    cp5_networking.get(ScrollableList.class, "datatype2").setPosition(column2,row1);
    cp5_networking.get(ScrollableList.class, "datatype3").setPosition(column3,row1);


    row2=row2-7;
    row3=row3-7;
    row4=row4-7;

    if (protocolMode==0){
      buttonRow = row5;
    }else if (protocolMode==1){
      buttonRow = row4;
    }else if (protocolMode==2){
      buttonRow = row4;
    }
    cp5_networking.get(RadioButton.class, "filter1").setPosition(column2, buttonRow);
    cp5_networking.get(RadioButton.class, "filter2").setPosition(column2, buttonRow);
    cp5_networking.get(RadioButton.class, "filter3").setPosition(column1, buttonRow);
    cp5_networking.get(Textfield.class, "osc_ip1").setPosition(column1, row2);
    cp5_networking.get(Textfield.class, "osc_port1").setPosition(column1, row3);
    cp5_networking.get(Textfield.class, "osc_address1").setPosition(column1, row4);
    cp5_networking.get(Textfield.class, "osc_ip2").setPosition(column2, row2);
    cp5_networking.get(Textfield.class, "osc_port2").setPosition(column2, row3);
    cp5_networking.get(Textfield.class, "osc_address2").setPosition(column2, row4);
    cp5_networking.get(Textfield.class, "osc_ip3").setPosition(column3, row2);
    cp5_networking.get(Textfield.class, "osc_port3").setPosition(column3, row3);
    cp5_networking.get(Textfield.class, "osc_address3").setPosition(column3, row4);        
    cp5_networking.get(Textfield.class, "udp_ip1").setPosition(column1, row2);
    cp5_networking.get(Textfield.class, "udp_port1").setPosition(column1, row3);
    cp5_networking.get(Textfield.class, "udp_ip2").setPosition(column2, row2);
    cp5_networking.get(Textfield.class, "udp_port2").setPosition(column2, row3);
    cp5_networking.get(Textfield.class, "udp_ip3").setPosition(column3, row2);
    cp5_networking.get(Textfield.class, "udp_port3").setPosition(column3, row3);
    cp5_networking.get(Textfield.class, "lsl_name1").setPosition(column1, row2);
    cp5_networking.get(Textfield.class, "lsl_name2").setPosition(column2, row2);
    cp5_networking.get(Textfield.class, "lsl_name3").setPosition(column3, row2);
  }

  void mousePressed(){
    super.mousePressed();

    if(startButton.isMouseHere()){
      startButton.setIsActive(true);
    }
 
  }

  void mouseReleased(){
    super.mouseReleased();
 
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
  void createTextFields(String name, String default_text){
    cp5_networking.addTextfield(name)
      .align(10,100,10,100)                   // Alignment
      .setSize(80,20)                         // Size of textfield
      .setFont(f2)
      .setFocus(false)                        // Deselects textfield
      .setColor(color(26,26,26))
      .setColorBackground(color(255,255,255)) // text field bg color
      .setColorValueLabel(color(0,0,0))       // text color
      .setColorForeground(color(26,26,26))    // border color when not selected
      .setColorActive(isSelected_color)       // border color when selected
      .setColorCursor(color(26,26,26))
      .setText(default_text)                  // Default text in the field
      .setCaptionLabel("")                    // Remove caption label
      .onDoublePress(net_cb)                  // Clear on double click
      .setVisible(false)                      // Initially hidden
      .setAutoClear(true)                     // Autoclear
      ;
  }

  /**
   * @description Sets textfields for protocol parameters as visible/invisible,
   *    depending on what protocol is currently set.
   */
  void showCP5(){
    osc_visible=false;
    udp_visible=false;
    lsl_visible=false;

    if(protocolMode == 0){
      osc_visible = true;
    }else if(protocolMode == 1){
      udp_visible = true;
    }else if(protocolMode==2){
      lsl_visible = true;
    }
    int buttonRow=5;
    if (protocolMode==0){
      buttonRow = row5;
    }else if (protocolMode==1){
      buttonRow = row4;
    }else if (protocolMode==2){
      buttonRow = row4;
    }
    cp5_networking.get(RadioButton.class, "filter1").setPosition(column2, buttonRow);
    cp5_networking.get(RadioButton.class, "filter2").setPosition(column2, buttonRow);
    cp5_networking.get(RadioButton.class, "filter3").setPosition(column1, buttonRow);
    cp5_networking.get(RadioButton.class, "filter1").setVisible(true);
    cp5_networking.get(RadioButton.class, "filter2").setVisible(true);
    cp5_networking.get(RadioButton.class, "filter3").setVisible(true);
    cp5_networking.get(ScrollableList.class, "datatype1").setVisible(true);
    cp5_networking.get(ScrollableList.class, "datatype2").setVisible(true);
    cp5_networking.get(ScrollableList.class, "datatype3").setVisible(true);
    cp5_networking.get(Textfield.class, "osc_ip1").setVisible(osc_visible);
    cp5_networking.get(Textfield.class, "osc_port1").setVisible(osc_visible);
    cp5_networking.get(Textfield.class, "osc_address1").setVisible(osc_visible);
    cp5_networking.get(Textfield.class, "osc_ip2").setVisible(osc_visible);
    cp5_networking.get(Textfield.class, "osc_port2").setVisible(osc_visible);
    cp5_networking.get(Textfield.class, "osc_address2").setVisible(osc_visible);
    cp5_networking.get(Textfield.class, "osc_ip3").setVisible(osc_visible);
    cp5_networking.get(Textfield.class, "osc_port3").setVisible(osc_visible);
    cp5_networking.get(Textfield.class, "osc_address3").setVisible(osc_visible);            
    cp5_networking.get(Textfield.class, "udp_ip1").setVisible(udp_visible);
    cp5_networking.get(Textfield.class, "udp_port1").setVisible(udp_visible);
    cp5_networking.get(Textfield.class, "udp_ip2").setVisible(udp_visible);
    cp5_networking.get(Textfield.class, "udp_port2").setVisible(udp_visible);
    cp5_networking.get(Textfield.class, "udp_ip3").setVisible(udp_visible);
    cp5_networking.get(Textfield.class, "udp_port3").setVisible(udp_visible);
    cp5_networking.get(Textfield.class, "lsl_name1").setVisible(lsl_visible);
    cp5_networking.get(Textfield.class, "lsl_name2").setVisible(lsl_visible);
    cp5_networking.get(Textfield.class, "lsl_name3").setVisible(lsl_visible);
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

  void dtDropdown_update(String name){
    if(cp5_networking.get(ScrollableList.class, name).isOpen()){
      if(!cp5_networking.getController(name).isMouseOver()){
        // println("2");
        cp5_networking.get(ScrollableList.class, name).close();
      }
    }
    if(dropdownsShouldBeClosed){ //this if takes care of the scenario where you select the same widget that is active...
    } else{
      if(!cp5_networking.get(ScrollableList.class, name).isOpen()){
        if(cp5_networking.getController(name).isMouseOver()){
          cp5_networking.get(ScrollableList.class, name).open();
        }
      }
    }
    cp5_networking.getController(name)
      .getCaptionLabel()
      .setText("this")
      ;

  }

  /**
   * @description Initializes the callback function for the cp5_networking instance
   *
   */
  void callback_init(){
    net_cb = new CallbackListener() { //used by ControlP5 to clear text field on double-click
      public void controlEvent(CallbackEvent theEvent) {
        if (cp5_networking.isMouseOver(cp5_networking.get(Textfield.class, "osc_ip1"))){
            cp5_networking.get(Textfield.class, "osc_ip1").clear();
        }else if (cp5_networking.isMouseOver(cp5_networking.get(Textfield.class, "osc_port1"))){
            cp5_networking.get(Textfield.class, "osc_port1").clear();
        }else if (cp5_networking.isMouseOver(cp5_networking.get(Textfield.class, "osc_address1"))){
            cp5_networking.get(Textfield.class, "osc_address1").clear();
        }else if (cp5_networking.isMouseOver(cp5_networking.get(Textfield.class, "osc_ip2"))){
            cp5_networking.get(Textfield.class, "osc_ip2").clear();
        }else if (cp5_networking.isMouseOver(cp5_networking.get(Textfield.class, "osc_port2"))){
            cp5_networking.get(Textfield.class, "osc_port2").clear();
        }else if (cp5_networking.isMouseOver(cp5_networking.get(Textfield.class, "osc_address2"))){
            cp5_networking.get(Textfield.class, "osc_address2").clear();
        }else if (cp5_networking.isMouseOver(cp5_networking.get(Textfield.class, "osc_ip3"))){
            cp5_networking.get(Textfield.class, "osc_ip3").clear();
        }else if (cp5_networking.isMouseOver(cp5_networking.get(Textfield.class, "osc_port3"))){
            cp5_networking.get(Textfield.class, "osc_port3").clear();
        }else if (cp5_networking.isMouseOver(cp5_networking.get(Textfield.class, "osc_address3"))){
            cp5_networking.get(Textfield.class, "osc_address3").clear();
        }else if (cp5_networking.isMouseOver(cp5_networking.get(Textfield.class, "udp_ip1"))){
            cp5_networking.get(Textfield.class, "udp_ip1").clear();
        }else if (cp5_networking.isMouseOver(cp5_networking.get(Textfield.class, "udp_port1"))){
            cp5_networking.get(Textfield.class, "udp_port1").clear();
        }else if (cp5_networking.isMouseOver(cp5_networking.get(Textfield.class, "udp_ip2"))){
            cp5_networking.get(Textfield.class, "udp_ip2").clear();
        }else if (cp5_networking.isMouseOver(cp5_networking.get(Textfield.class, "udp_port2"))){
            cp5_networking.get(Textfield.class, "udp_port2").clear();
        }else if (cp5_networking.isMouseOver(cp5_networking.get(Textfield.class, "udp_ip3"))){
            cp5_networking.get(Textfield.class, "udp_ip3").clear();
        }else if (cp5_networking.isMouseOver(cp5_networking.get(Textfield.class, "udp_port3"))){
            cp5_networking.get(Textfield.class, "udp_port3").clear();
        }else if (cp5_networking.isMouseOver(cp5_networking.get(Textfield.class, "lsl_name1"))){
            cp5_networking.get(Textfield.class, "lsl_name1").clear();
        }else if (cp5_networking.isMouseOver(cp5_networking.get(Textfield.class, "lsl_name2"))){
            cp5_networking.get(Textfield.class, "lsl_name2").clear();
        }else if (cp5_networking.isMouseOver(cp5_networking.get(Textfield.class, "lsl_name3"))){
            cp5_networking.get(Textfield.class, "lsl_name3").clear();
        }
      }  
    };
  }
}

class Stream{
  String streamType;


  UDP udp;

  OscP5 osc;
  NetAddress netaddress;

  LSL.StreamInfo info_data;
  LSL.StreamOutlet outlet_data;
  LSL.StreamInfo info_aux;
  LSL.StreamOutlet outlet_aux;

  String ip;
  int port;
  String address;
  String name;
  String type;

  String stream_id;

  int numChan=8;


  Stream(String ip, int port, String address){
      /* Network Objects */

    streamType = "OSC";
    ip = ip;
    port = port;
    address = address;

    initializeStream(ip,port,address);

  }
  Stream(String ip, int port){
    streamType = "UDP";
    initializeStream(ip,port);

  }
  Stream(String name,String type){
    streamType = "LSL";
    String stream_id;
    initializeStream(name,type);
  }

  void initializeStream(String ip, int port, String address){
    /* Instantiate OSC objects*/                  
    osc = new OscP5(this,12000);
    netaddress = new NetAddress(ip,port);

  }

  void initializeStream(String ip, int port){    
    /* Instantiate UDP objects */
    udp = new UDP(this);
    udp.setBuffer(1024);
    udp.log(false);
  }
  void initializeStream(String name,String type){
    stream_id = name + "_id";
    
    /* Instantiate LSL objects */
    info_data = new LSL.StreamInfo(
                          name, 
                          "EEG", 
                          nchan, 
                          openBCI.get_fs_Hz(), 
                          LSL.ChannelFormat.float32, 
                          stream_id
                        );
    outlet_data = new LSL.StreamOutlet(info_data);
  }


  /**
   * @description Send data through the selected protocol
   * @param `dataToSend` {Object} - Data to be sent over the network, either a
   *  float[] object or float[][] object
   * 
   * NOTE: Consider replacing "Object" parameter with an interface that can handle
   *  multiple types.
   */
  void sendData(float[] dataToSend){
    /*OSC*/
    if (streamType=="OSC"){
      OscMessage msg = new OscMessage(this.address);
      /* Send time series */
      msg.add(dataToSend);
      osc.send(msg,netaddress);
    }else if (streamType=="UDP"){
      /* UDP */
      String msg;
      msg = Arrays.toString(dataToSend);
      udp.send(msg,ip,port);
    }else if (streamType=="LSL"){
      outlet_data.push_sample(dataToSend);
    }
  }

  void sendData(float[][] dataToSend){
    if (streamType=="OSC"){
      OscMessage msg = new OscMessage(address);
      for(int i=0;i<numChan;i++){
        msg.add(dataToSend[i]);
      }
      osc.send(msg,netaddress);
    }else if (streamType=="UDP"){
      String msg;
      StringBuilder sb = new StringBuilder();
      for(int i=0;i<numChan;i++){
        sb.append(Arrays.toString(dataToSend[i]));
      }
      msg = sb.toString();
      udp.send(msg,ip,port);
    }else if (streamType=="LSL"){
       // outlet_data.push_sample(dataToSend);
    }
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
  w_networking.protocolMode = protocolIndex;
  w_networking.showCP5();
  closeAllDropdowns();
}