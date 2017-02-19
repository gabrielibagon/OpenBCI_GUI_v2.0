
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
//    Created by: Gabriel Ibagon, Januar y 2017
//
///////////////////////////////////////////////////////////////////////////////


NetworkingData networkingData;
class W_networking extends Widget {

  /* NavBar Dropdown Menu variables */
  int protocolMode = 0;
  /* Widget Dropdown Menu variables */
  int dataTypeMode1;//type of data to send in stream1
  int dataTypeMode2;//type of data to send in stream2
  int dataTypeMode3;//type of data to send in stream3
  String filtered1 = "NO";
  String filtered2 = "NO";
  String filtered3 = "NO";


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



  /**
   * @description Constructor for Networking Widget
   * @param `_parent` {PApplet} - The OpenBCI GUI application.
   * @constructor
   */
  W_networking(PApplet _parent){

    super(_parent);
    init();//initialize UI of the Widget
    Stream stream1=null;
    Stream stream2=null;
    Stream stream3=null;
    networkingData = new NetworkingData();
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

    /* Data type textfield **TEMPORARY WORKAROUND** */
    createTextFields("datatype_stream1","TimeSeries");
    createTextFields("datatype_stream2","None");
    createTextFields("datatype_stream3","None");

    /* Filter Buttons */
    // createRadioButtons("filter1");
    // createRadioButtons("filter2");
    // createRadioButtons("filter3");

    createTextFields("filter1","NO");
    createTextFields("filter2","NO");
    createTextFields("filter3","NO");


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
  // //
  // //   /**
  // // * @description Loops through the data handling aspects of widget at
  // // *   application refresh rate.
  // // */
  void update(){
    super.update();

    if (isSending && isRunning){
      /* update data */
      networkingData.collectData();
      if(protocolMode==2){
          if(stream1!=null){
            stream1.run();
          }
          if(stream2!=null){
            stream2.run();
          }
          if(stream3!=null){
            stream3.run();
          }
        }
      }
    }

    /**
  * @description Loops through the UI aspects of widget at
  *   application refresh rate.
  */
  void draw(){
    if(!wm.widgets.get(4).isActive){
      println("HIDE OSELF");
    }
    super.draw();
    showCP5();
    pushStyle();
    startButton.draw();

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
    popStyle();

  }
  //
  //
  // /**
  // * @description Used to initalize the filter on/off radio buttons.
  //  * @param `name` {String} - identifier of the radio button
  // */
  // void createRadioButtons(String name){
  //   cp5_networking.addRadioButton(name)
  //       .setId(Integer.parseInt(name.substring(name.length()-1)))
  //       .setSize(10,10)
  //       .setColorForeground(color(120))
  //       .setColorActive(color(184,220,105))
  //       .setColorLabel(color(0))
  //       .setItemsPerRow(2)
  //       .setSpacingColumn(20)
  //       .addItem("On",1)
  //       .addItem("Off",2)
  //       .activate(1)
  //       .setVisible(false)
  //       ;
  // }
  //
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
  //
  // /**
  //  * @description Sets textfields for protocol parameters as visible/invisible,
  //  *    depending on what protocol is currently set.
  //  */
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

    cp5_networking.get(Textfield.class, "filter1").setVisible(true);
    cp5_networking.get(Textfield.class, "filter2").setVisible(true);
    cp5_networking.get(Textfield.class, "filter3").setVisible(true);
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

    /* TEMPORARY DATA TYPE TEXTFIELD */
    cp5_networking.get(Textfield.class, "datatype_stream1").setVisible(true);
    cp5_networking.get(Textfield.class, "datatype_stream2").setVisible(true);
    cp5_networking.get(Textfield.class, "datatype_stream3").setVisible(true);

  }

  void stopNetworkingWidget(){
    turnOffNetworking();
    cp5_networking.get(RadioButton.class, "filter1").setVisible(false);
    cp5_networking.get(RadioButton.class, "filter2").setVisible(false);
    cp5_networking.get(RadioButton.class, "filter3").setVisible(false);
    cp5_networking.get(Textfield.class, "osc_ip1").setVisible(false);
    cp5_networking.get(Textfield.class, "osc_port1").setVisible(false);
    cp5_networking.get(Textfield.class, "osc_address1").setVisible(false);
    cp5_networking.get(Textfield.class, "osc_ip2").setVisible(false);
    cp5_networking.get(Textfield.class, "osc_port2").setVisible(false);
    cp5_networking.get(Textfield.class, "osc_address2").setVisible(false);
    cp5_networking.get(Textfield.class, "osc_ip3").setVisible(false);
    cp5_networking.get(Textfield.class, "osc_port3").setVisible(false);
    cp5_networking.get(Textfield.class, "osc_address3").setVisible(false);
    cp5_networking.get(Textfield.class, "udp_ip1").setVisible(false);
    cp5_networking.get(Textfield.class, "udp_port1").setVisible(false);
    cp5_networking.get(Textfield.class, "udp_ip2").setVisible(false);
    cp5_networking.get(Textfield.class, "udp_port2").setVisible(false);
    cp5_networking.get(Textfield.class, "udp_ip3").setVisible(false);
    cp5_networking.get(Textfield.class, "udp_port3").setVisible(false);
    cp5_networking.get(Textfield.class, "lsl_name1").setVisible(false);
    cp5_networking.get(Textfield.class, "lsl_name2").setVisible(false);
    cp5_networking.get(Textfield.class, "lsl_name3").setVisible(false);

    /* TEMPORARY DATA TYPE TEXTFIELD */
    cp5_networking.get(Textfield.class, "datatype_stream1").setVisible(false);
    cp5_networking.get(Textfield.class, "datatype_stream2").setVisible(false);
    cp5_networking.get(Textfield.class, "datatype_stream3").setVisible(false);
  }



  void setFilters(){
    filtered1 = cp5_networking.get(Textfield.class, "filter1").getText();
    filtered2 = cp5_networking.get(Textfield.class, "filter2").getText();
    filtered3 = cp5_networking.get(Textfield.class, "filter3").getText();
    if (stream1!=null){
      if(filtered1.equals("NO")){
        stream1.filtered=false;
      }else{
        stream1.filtered=true;
      }
    }
    if (stream2!=null){
      if(filtered2.equals("NO")){
        stream2.filtered=false;
      }else{
        stream2.filtered=true;
      }
    }
    if (stream3!=null){
      if(filtered3.equals("NO")){
        stream3.filtered=false;
      }else{
        stream3.filtered=true;
      }
    }
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
    cp5_networking.get(Textfield.class, "filter1").setPosition(column1, buttonRow);
    cp5_networking.get(Textfield.class, "filter2").setPosition(column2, buttonRow);
    cp5_networking.get(Textfield.class, "filter3").setPosition(column3, buttonRow);
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

    /* TEMPORARY DATATYPE TEXTFIELD */
    cp5_networking.get(Textfield.class, "datatype_stream1").setPosition(column1, row1);
    cp5_networking.get(Textfield.class, "datatype_stream2").setPosition(column2, row1);
    cp5_networking.get(Textfield.class, "datatype_stream3").setPosition(column3, row1);

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
        initializeStreams();
        startStreams();
        setFilters();
      }else{
        isSending = false;
        startButton.setColorNotPressed(color(184,220,105));
        startButton.setString("Start");
        stopStreams();
        stream1=null;
        stream2=null;
        stream3=null;
      }
    }
    startButton.setIsActive(false);

  }

  void initializeStreams(){
    String ip;
    int port;
    String address;
    String name;
    /* Get datatype Menu item for each stream*/
    // int s1=(int)cp5_networking.get(ScrollableList.class, "datatype1").getValue();
    // int s2=(int)cp5_networking.get(ScrollableList.class, "datatype2").getValue();
    // int s3=(int)cp5_networking.get(ScrollableList.class, "datatype3").getValue();

    /* TEMPORARY DATA TYPE WORKARAOUND */
    println("INITIALIZING STREAMS");
    String temp_s1 = cp5_networking.get(Textfield.class, "datatype_stream1").getText();
    String temp_s2 = cp5_networking.get(Textfield.class, "datatype_stream2").getText();
    String temp_s3 = cp5_networking.get(Textfield.class, "datatype_stream3").getText();
    String s1 = temp_s1;
    String s2 = temp_s2;
    String s3 = temp_s3;
    /* Check if each stream is None*/
    if(!s1.equals("None")){
      println("Initializing Stream 1:");
      /*collect values */
      if(protocolMode==0){
        println("OSC");
        ip = cp5_networking.get(Textfield.class, "osc_ip1").getText();
        port = Integer.parseInt(cp5_networking.get(Textfield.class, "osc_port1").getText());
        address = cp5_networking.get(Textfield.class, "osc_address1").getText();
        stream1 = new Stream(ip,port,address,s1);
      }else if(protocolMode==1){
        ip = cp5_networking.get(Textfield.class, "udp_ip1").getText();
        port = Integer.parseInt(cp5_networking.get(Textfield.class, "udp_port1").getText());
        stream1 = new Stream(ip,port,s1);
      }
    }
    if(!s2.equals("None")){
      println("Initializing Stream 2:");
      if(protocolMode==0){
        println("OSC");
        ip = cp5_networking.get(Textfield.class, "osc_ip2").getText();
        port = Integer.parseInt(cp5_networking.get(Textfield.class, "osc_port2").getText());
        address = cp5_networking.get(Textfield.class, "osc_address2").getText();
        stream2 = new Stream(ip,port,address,s2);
      }else if(protocolMode==1){
        ip = cp5_networking.get(Textfield.class, "udp_ip2").getText();
        port = Integer.parseInt(cp5_networking.get(Textfield.class, "udp_port2").getText());
        stream2 = new Stream(ip,port,s2);
      }
    }
    if(!s3.equals("None")){
      if(protocolMode==0){
        ip = cp5_networking.get(Textfield.class, "osc_ip2").getText();
        port = Integer.parseInt(cp5_networking.get(Textfield.class, "osc_port2").getText());
        address = cp5_networking.get(Textfield.class, "osc_address2").getText();
        stream3 = new Stream(ip,port,address,s3);
      }else if(protocolMode==1){
        ip = cp5_networking.get(Textfield.class, "udp_ip2").getText();
        port = Integer.parseInt(cp5_networking.get(Textfield.class, "udp_port2").getText());
        stream3 = new Stream(ip,port,s3);
      }
    }

  }

  public void startStreams(){
    if (stream1!=null){
      stream1.start();
    }
    if (stream2!=null){
      stream2.start();
    }
    if (stream3!=null){
      stream3.start();
    }
  }
  public void stopStreams(){
    if (stream1!=null){
      stream1.quit();
    }
    if (stream2!=null){
      stream2.quit();
    }
    if (stream3!=null){
      stream3.quit();
    }
  }

  /**
   * @description Turns off a running network when protocol is switched from menu.
   *    Network status and initialization vars set to 0, Button set to "Start".
   */
  public void turnOffNetworking(){
    startButton.setColorNotPressed(color(184,220,105));
    startButton.setString("Start");
    initialized = false;
    isSending = false;
    stopStreams();
  }
  //

  // /**
  //  * @description Initializes the callback function for the cp5_networking instance
  //  *
  //  */
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

class Stream extends Thread{
  /* Threading parameters */
  boolean isSending;
  int bufferLen;

  String streamType;
  String dataType;
  UDP udp;
  OscP5 osc;
  NetAddress netaddress;
  OscMessage msg;

  LSL.StreamInfo info_data;
  LSL.StreamOutlet outlet_data;
  LSL.StreamInfo info_aux;
  LSL.StreamOutlet outlet_aux;

  String ip;
  int port;
  String address;
  String name;
  String type;

  Boolean filtered;

  String stream_id;

  float[] dataArray;
  int numChan=8;

  Stream(String ip, int port, String address, String dataType){
    /* Network Objects */
    isSending = false;
    this.streamType = "OSC";
    this.dataType = dataType;
    this.ip = ip;
    this.port = port;
    this.address = address;
    dataArray = new float[numChan];
  }
  Stream(String ip, int port, String dataType){
    isSending = false;
    this.streamType = "UDP";
    this.dataType = dataType;
    this.dataType = dataType;
    this.ip = ip;
    this.port = port;
    dataArray = new float[numChan];
  }

  void start(){
    super.start();
    isSending = true;

  }

  void run(){
    initializeNetwork();
    float[][] data = null;
    println(dataType);
    while(isSending){
      if (isSending && isRunning){
        /* Check for new data */
        // openBCI.get_isNewDataPacketAvailable() ||
        if (newSynthData || openBCI.get_isNewDataPacketAvailable()){
          if (dataType.equals("TimeSeries")){
            if(filtered){
              data = networkingData.filteredTS;
            }else{
              data = networkingData.rawTS;
            }
          }else if (dataType.equals("FFT")){
            data = networkingData.filteredFFT;
          }
          try{
            sendData(data);
          }catch (NullPointerException e){
            println(e);
          }

        }
      }
    }
  }
  void initializeNetwork(){
    if (streamType.equals("OSC")){
      this.osc = new OscP5(this,12000);
      netaddress = new NetAddress(ip,port);
      msg = new OscMessage(this.address);

    }else if (streamType.equals("UDP")){
      this.udp = new UDP(this);
      udp.setBuffer(1024);
      udp.log(false);
    }else if (streamType.equals("LSL")){
      println(name);
      println(nchan);
      println(stream_id);
      println(openBCI.get_fs_Hz());
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
  }

  void quit(){
    isSending = false;
    if (streamType.equals("OSC")){
      osc.stop();
    }else if (streamType.equals("UDP")){
      udp.close();
    }else if (streamType.equals("LSL")){
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
  void sendData(float[][] dataToSend){
    bufferLen = dataToSend[0].length;
    if (streamType=="OSC"){
      if(dataType.equals("TimeSeries")){
        for(int i=0;i<bufferLen;i++){
          msg.clearArguments();
          for(int j=0;j<numChan;j++){
            msg.add(dataToSend[j][i]);
          }
          osc.send(msg,netaddress);
        }
      }else if (dataType.equals("FFT")){
        msg.clearArguments();
        for(int j=0;j<numChan;j++){
          msg.add(j);
          msg.add(dataToSend[j]);
          osc.send(msg,netaddress);
        }
      }
    }else if (streamType=="UDP"){
      if(dataType.equals("TimeSeries")){
        for(int i=0;i<bufferLen;i++){
          String msg;
          StringBuilder sb = new StringBuilder();
          for(int j=0;j<numChan;j++){
            sb.append(Float.toString(dataToSend[j][i]));
          }
          msg = sb.toString();
          udp.send(msg,ip,port);
        }
      }else if (dataType.equals("FFT")){
        String msg;
        StringBuilder sb = new StringBuilder();
        for(int j=0;j<numChan;j++){
          sb.append(Arrays.toString(dataToSend[j]));
          msg = sb.toString();
          udp.send(msg,ip,port);
        }
      }
    }else if (streamType=="LSL"){
      if(dataType.equals("TimeSeries")){
        for(int i=0;i<bufferLen;i++){
          for(int j=0;j<numChan;j++){
            dataArray[j] = dataToSend[j][i];
          }
          outlet_data.push_sample(dataArray);
        }
      }
    }
  }
}
//
// class StreamLSL{
//   boolean isSending;
//   int bufferLen;
//
//   String streamType;
//   String dataType;
//
//   LSL.StreamInfo info_data;
//   LSL.StreamOutlet outlet_data;
//   LSL.StreamInfo info_aux;
//   LSL.StreamOutlet outlet_aux;
//
//   String ip;
//   int port;
//   String address;
//   String name;
//   String type;
//
//   Boolean filtered;
//
//   String stream_id;
//
//   float[] dataArray;
//   int numChan=8;
//
//   StreamLSL(String name, String dataType){
//     isSending = false;
//     this.streamType = "LSL";
//     this.dataType = dataType;
//     this.name = name;
//     String stream_id;
//     this.stream_id = name + "_id";
//     dataArray = new float[numChan];
//   }
//
//   void start(){
//     isSending = true;
//   }
//
//   void run(){
//     initializeNetwork();
//     float[][] data = null;
//     println(dataType);
//     if (isSending && isRunning){
//       /* Check for new data */
//       // openBCI.get_isNewDataPacketAvailable() ||
//       if (newSynthData || openBCI.get_isNewDataPacketAvailable()){
//         if (dataType.equals("TimeSeries")){
//           if(filtered){
//             data = networkingData.filteredTS;
//           }else{
//             data = networkingData.rawTS;
//           }
//         }else if (dataType.equals("FFT")){
//           data = networkingData.filteredFFT;
//         }
//         try{
//           sendData(data);
//
//         }catch (NullPointerException e){
//           println(e);
//         }
//
//       }
//     }
//   }
//
//   void initializeNetwork(){
//     if (streamType.equals("OSC")){
//       this.osc = new OscP5(this,12000);
//       netaddress = new NetAddress(ip,port);
//     }else if (streamType.equals("UDP")){
//       this.udp = new UDP(this);
//       udp.setBuffer(1024);
//       udp.log(false);
//     }else if (streamType.equals("LSL")){
//       println(name);
//       println(nchan);
//       println(stream_id);
//       println(openBCI.get_fs_Hz());
//       info_data = new LSL.StreamInfo(
//                             name,
//                             "EEG",
//                             nchan,
//                             openBCI.get_fs_Hz(),
//                             LSL.ChannelFormat.float32,
//                             stream_id
//                           );
//       outlet_data = new LSL.StreamOutlet(info_data);
//     }
//   }
//
//   void quit(){
//     isSending = false;
//     if (streamType.equals("OSC")){
//       osc.stop();
//     }else if (streamType.equals("UDP")){
//       udp.close();
//     }else if (streamType.equals("LSL")){
//     }
//   }
//
//   /**
//    * @description Send data through the selected protocol
//    * @param `dataToSend` {Object} - Data to be sent over the network, either a
//    *  float[] object or float[][] object
//    *
//    * NOTE: Consider replacing "Object" parameter with an interface that can handle
//    *  multiple types.
//    */
//   void sendData(float[][] dataToSend){
//     int bufferLen = dataToSend[0].length;
//     if (streamType=="OSC"){
//       if(dataType.equals("TimeSeries")){
//         OscMessage msg;
//         for(int i=0;i<bufferLen;i++){
//           msg = new OscMessage(address);
//           for(int j=0;j<numChan;j++){
//             msg.add(dataToSend[j][i]);
//           }
//           osc.send(msg,netaddress);
//         }
//       }else if (dataType.equals("FFT")){
//         for(int j=0;j<numChan;j++){
//           OscMessage msg = new OscMessage(address);
//           msg.add(j);
//           msg.add(dataToSend[j]);
//           osc.send(msg,netaddress);
//         }
//       }
//     }else if (streamType=="UDP"){
//       if(dataType.equals("TimeSeries")){
//         for(int i=0;i<bufferLen;i++){
//           String msg;
//           StringBuilder sb = new StringBuilder();
//           for(int j=0;j<numChan;j++){
//             sb.append(Float.toString(dataToSend[j][i]));
//           }
//           msg = sb.toString();
//           udp.send(msg,ip,port);
//         }
//       }else if (dataType.equals("FFT")){
//         String msg;
//         StringBuilder sb = new StringBuilder();
//         for(int j=0;j<numChan;j++){
//           sb.append(Arrays.toString(dataToSend[j]));
//           msg = sb.toString();
//           udp.send(msg,ip,port);
//         }
//       }
//     }else if (streamType=="LSL"){
//       if(dataType.equals("TimeSeries")){
//         for(int i=0;i<bufferLen;i++){
//           for(int j=0;j<numChan;j++){
//             dataArray[j] = dataToSend[j][i];
//           }
//           outlet_data.push_sample(dataArray);
//         }
//       }
//     }
//   }
// }


class NetworkingData{
  float[][] rawTS;
  float[][] filteredTS;
  float[][] filteredFFT;
  int start = dataBuffY_filtY_uV[0].length-11;
  int end = dataBuffY_filtY_uV[0].length-1;
  int bufferSize = end-start;

  int numChan = 8; // MAKE THIS DETECTED
  int numBins = 125; // MAKE THIS DETECTED

  NetworkingData(){
    this.rawTS = new float[numChan][bufferSize];
    this.filteredTS = new float[numChan][bufferSize];
    this.filteredFFT = new float[numChan][numBins];
  }

  void collectData(){
    for (int chan=0;chan<numChan;chan++){
      this.rawTS[chan] = yLittleBuff_uV[chan];
    }
    for (int chan=0;chan<numChan;chan++){
      this.filteredTS[chan] = Arrays.copyOfRange(dataBuffY_filtY_uV[chan],start,end);
    }
    for (int i=0;i<numChan;i++){
      for (int j=0;j<125;j++){
        this.filteredFFT[i][j] = fftBuff[i].getBand(j);
      }
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
