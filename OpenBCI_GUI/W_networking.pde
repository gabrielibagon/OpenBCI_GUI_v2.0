
////////////////////////////////////////////////////
//
//    W_networking.pde (Networking Widget)
//    
//    This widget provides networking capabilities in the OpenBCI GUI. The networking protocols can be used for outputting data 
//    from the OpenBCI GUI to other programs, or it can be used to input data from other programs into the GUI.
//
//    The protocols included are: UDP, OSC, LSL, and Serial
//     
//
//    Created by: Gabriel Ibagon, January 2017
//
///////////////////////////////////////////////////

class W_networking extends Widget {

  //to see all core variables/methods of the Widget class, refer to Widget.pde
  //put your custom variables here...
  Button startButton;
  ControlP5 cp5_networking;
  int protocolMode = 0;
  int sendReceiveMode = 0;
  int dataTypeMode = 0;
  int filteredMode = 0;
  int status = 0;
  int initialized = 0;
  String statusText;
  int sampleNumber;
  Boolean newData;
  //Network Objects
  OscP5 osc;
  NetAddress netaddress;
  UDP udp;
  LSL.StreamInfo info_data;
  LSL.StreamOutlet outlet_data;
  LSL.StreamInfo info_aux;
  LSL.StreamOutlet outlet_aux;
  //Network parameters
  String ip;
  int port;
  String address;
  String data_stream;
  String aux_stream; 
  String data_stream_id;
  String aux_stream_id; 
  float[] dataToSend; 
  W_networking(PApplet _parent){

    super(_parent); //calls the parent CONSTRUCTOR method of Widget (DON'T REMOVE)
    
    println(x,y);
    println(x0,y0);

    // Dropdowns
    addDropdown("Protocol", "Protocol", Arrays.asList("OSC", "UDP", "LSL", "Serial"), protocolMode);
    addDropdown("SendReceive", "S/R", Arrays.asList("Send", "Receive"), sendReceiveMode);
    addDropdown("DataType", "Data Type", Arrays.asList("TimeSer", "FFT"), dataTypeMode);
    addDropdown("Filter", "Raw/Filt", Arrays.asList("Raw","Filtered"), filteredMode);
    
    // Textfields
    
    createTextFields("osc_ip","localhost",x+w/2, y+h/2);
    createTextFields("osc_port","12345",x+w/2, y+h/2+35);
    createTextFields("osc_address","/openbci",x+w/2, y+h/2+70);

    createTextFields("udp_ip","localhost",x+w/2, y+h/2);
    createTextFields("udp_port","12345",x+w/2, y+h/2+35);

    createTextFields("lsl_data","openbci_eeg",x+w/2, y+h/2);
    createTextFields("lsl_aux","openbci_aux",x+w/2, y+h/2+35);

    // Start/Stop Button 
    startButton = new Button(x+w/2-100,y+h-40,200,20,"Start",14);
    startButton.setFont(p4,14);        
    startButton.setColorNotPressed(color(184,220,105));
  }
  void update(){
    super.update(); //calls the parent update() method of Widget (DON'T REMOVE)
   //  if(sampleNumber != dataPacketBuff[0].sampleIndex){
	  //   newData = true;
	  //   sampleNumber = dataPacketBuff[0].sampleIndex;
	  // }else{
	  // 	newData=false;
	  // }
    newData=true;
    
    if(status==1 && isRunning && newData){
      //Collect data to send
      if(dataTypeMode==0){
        if(filteredMode==0){
          dataToSend = dataProcessing.data_std_uV;
        }else if(filteredMode==1){
          //find out how to send unfiltered data...
        }
      }else if (dataTypeMode==1){
        //figure out how to send FFT data...
        if(filteredMode==0){
          //send filtered FFT
        }else if(filteredMode==1){
          //send unfiltered FFT
        }
      }      
      // Send data through network
      /* OSC */
      if(protocolMode==0){
        if(initialized==0){
          //initialize OSC
          ip = cp5.get(Textfield.class, "osc_ip").getText();
          port = Integer.parseInt(cp5.get(Textfield.class, "osc_port").getText());
          address = cp5.get(Textfield.class, "osc_address").getText();
          
          osc = new OscP5(this,12000);
          netaddress = new NetAddress(ip,port);
          initialized=1;
        }
        OscMessage msg = new OscMessage(address);
        msg.add(dataToSend);
        osc.send(msg,netaddress);

        
      /* UDP */
      }else if (protocolMode==1){
        if(initialized==0){
          //initialize UDP
          
          //ip = cp5.get(Textfield.class, "udp_ip").getText();
          //port = cp5.get(Textfield.class, "udp_port").getText();
          
          ip = "localhost";
          port = 12345;
          //
          udp = new UDP(this);
          udp.setBuffer(1024);
          udp.log(false);
          initialized=1;
        }
        String msg = Arrays.toString(dataToSend);
        udp.send(msg,ip,port);

      /* LSL */
      }else if (protocolMode==2){
      	if(initialized==0){
	        //Initailize LSL
	        //data_stream = cp5.get(Textfield.class, "lsl_data").getText();
	        //aux_stream = cp5.get(Textfield.class, "lsl_aux").getText();

	        /* Temporary */
	        data_stream = "openbci_data";
	        aux_stream = "openbci_aux";
	        /* Temporary */
	        
	        data_stream_id = data_stream + "_id";
	        aux_stream_id = aux_stream + "_id";
	        
	        //Set up LSL streams
	        info_data = new LSL.StreamInfo(data_stream, "EEG", nchan, openBCI.get_fs_Hz(), LSL.ChannelFormat.float32, data_stream_id);
	        outlet_data = new LSL.StreamOutlet(info_data);
	        info_aux = new LSL.StreamInfo("aux_stream", "AUX", 3, openBCI.get_fs_Hz(), LSL.ChannelFormat.float32, aux_stream_id);
	        outlet_aux = new LSL.StreamOutlet(info_aux);
          println("NOT HERE");
          initialized=1;
	      }

        /* push in chunks instead */
	      outlet_data.push_sample(dataToSend);
	      outlet_aux.push_sample(dataToSend);
      }else if (protocolMode==3){
      //serial stuff
      }
    }
  }

  void draw(){
    super.draw(); //calls the parent draw() method of Widget (DON'T REMOVE)

    //put your code here... //remember to refer to x,y,w,h which are the positioning variables of the Widget class
    pushStyle();
  
    
    startButton.draw();

    
    textAlign(LEFT,CENTER);
    fill(0,0,0);
    if(status==0){
      statusText = "Not Active";
    }else if(status==1){
      statusText = "Active";
    }
    // OSC
    if(protocolMode == 0){
      textFont(f4,48);
      text("OSC", x+10,y+h/8);
      textFont(h1,20);
      text("IP", x+w/6,y+h/3);
      text("Port", x+w/6, y+h/3+35);
      text("Address", x+w/6,y+h/3+70);
      text("Status:",x+w/6, y+h/3+105);
      text(statusText,x+w/2, y+h/3+105);
    } else if (protocolMode == 1){
      textFont(f4,48);
      text("UDP", x+10,y+h/8);
      textFont(h1,20);
      text("IP", x+w/6,y+h/3);
      text("Port", x+w/6, y+h/3+35);
      text("Status:",x+w/6, y+h/3+70);
      text(statusText,x+w/2, y+h/3+70);
    } else if (protocolMode == 2){
      textFont(f4,48);
      text("LSL", x+10,y+h/8);
      textFont(h1,20);
      text("Data Stream", x+w/6,y+h/3);
      text("Aux Stream", x+w/6, y+h/3+35);
      text("Status:",x+w/6, y+h/3+70);
      text(statusText,x+w/2, y+h/3+70);
    } else if (protocolMode == 3){
      text("Serial", x+10,y+h/8);
      textFont(h1,20);
      text("Status:",x+w/6, y+h/3+105);
      text(statusText,x+w/2, y+h/3+105);
    }
    drawTextFields();
    popStyle();

  }

  void screenResized(){
    super.screenResized(); //calls the parent screenResized() method of Widget (DON'T REMOVE)

    //put your code here...
    startButton.setPos(x + w/2 -100, y + h - 40 );
   

  }

  void mousePressed(){
    super.mousePressed(); //calls the parent mousePressed() method of Widget (DON'T REMOVE)

    //put your code here...
    if(startButton.isMouseHere()){
      startButton.setIsActive(true);
    }
 
  }

  void mouseReleased(){
    super.mouseReleased(); //calls the parent mouseReleased() method of Widget (DON'T REMOVE)
 
    //put your code here...
    if(startButton.isActive && startButton.isMouseHere()){
      if(status==0){
        status = 1;
        startButton.setColorNotPressed(color(224, 56, 45));
        startButton.setString("Stop");
      }else{
        status = 0;
        startButton.setColorNotPressed(color(184,220,105));
        startButton.setString("Start");
      }
    }
    startButton.setIsActive(false);
 
  }

  void createTextFields(String name, String default_text, int _x, int _y){
    cp5_widget.addTextfield(name)
      .setPosition(_x,_y)
      .setSize(100,26)
      .setFocus(false)
      .setColor(color(26,26,26))
      .setColorBackground(color(0,0,0)) // text field bg color
      .setColorValueLabel(color(0,0,0))  // text color
      .setColorForeground(isSelected_color)  // border color when not selected
      .setColorActive(isSelected_color)  // border color when selected
      .setColorCursor(color(26,26,26))
      .setText(default_text)
      .align(5, 10, 20, 40)
      .setCaptionLabel("")
      .setText(default_text)
      .setFont(f2)
      // .onDoublePress(net_cb)
      .setVisible(false)
      .setAutoClear(true)
      ;
  }

  void drawTextFields(){
    if(protocolMode == 0){
      cp5_widget.get(Textfield.class, "osc_ip").setVisible(true);
      cp5_widget.get(Textfield.class, "osc_port").setVisible(true);
      cp5_widget.get(Textfield.class, "osc_address").setVisible(true);
      cp5_widget.get(Textfield.class, "udp_ip").setVisible(false);
      cp5_widget.get(Textfield.class, "udp_port").setVisible(false);
      cp5_widget.get(Textfield.class, "lsl_data").setVisible(false);
      cp5_widget.get(Textfield.class, "lsl_aux").setVisible(false);
    }else if(protocolMode == 1){
      cp5_widget.get(Textfield.class, "osc_ip").setVisible(false);
      cp5_widget.get(Textfield.class, "osc_port").setVisible(false);
      cp5_widget.get(Textfield.class, "osc_address").setVisible(false);
      cp5_widget.get(Textfield.class, "udp_ip").setVisible(true);
      cp5_widget.get(Textfield.class, "udp_port").setVisible(true);
      cp5_widget.get(Textfield.class, "lsl_data").setVisible(false);
      cp5_widget.get(Textfield.class, "lsl_aux").setVisible(false);
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

}

// CallbackListener net_cb = new CallbackListener() { //used by ControlP5 to clear text field on double-click
//   public void controlEvent(CallbackEvent theEvent) {
//     if (cp5_widget.isMouseOver(cp5.get(Textfield.class, "fileName"))){
//       println("CallbackListener: controlEvent: clearing");
//       cp5_widget.get(Textfield.class, "fileName").clear();
//     } else if (cp5_widget.isMouseOver(cp5_widget.get(Textfield.class, "fileNameGanglion"))){
//       println("CallbackListener: controlEvent: clearing");
//       cp5_widget.get(Textfield.class, "fileNameGanglion").clear();
//     } else if (cp5_widget.isMouseOver(cp5_widget.get(Textfield.class, "udp_ip"))){
//       println("CallbackListener: controlEvent: clearing");
//       cp5_widget.get(Textfield.class, "udp_ip").clear();
//     } else if (cp5_widget.isMouseOver(cp5_widget.get(Textfield.class, "udp_port"))){
//       println("CallbackListener: controlEvent: clearing");
//       cp5_widget.get(Textfield.class, "udp_port").clear();
//     } else if (cp5_widget.isMouseOver(cp5_widget.get(Textfield.class, "osc_ip"))){
//       println("CallbackListener: controlEvent: clearing");
//       cp5_widget.get(Textfield.class, "osc_ip").clear();
//     } else if (cp5_widget.isMouseOver(cp5_widget.get(Textfield.class, "osc_address"))){
//       println("CallbackListener: controlEvent: clearing");
//       cp5_widget.get(Textfield.class, "osc_address").clear();
//     } else if (cp5_widget.isMouseOver(cp5_widget.get(Textfield.class, "lsl_data"))){
//       println("CallbackListener: controlEvent: clearing");
//       cp5_widget.get(Textfield.class, "lsl_data").clear();
//     } else if (cp5_widget.isMouseOver(cp5_widget.get(Textfield.class, "lsl_aux"))){
//       println("CallbackListener: controlEvent: clearing");
//       cp5_widget.get(Textfield.class, "lsl_aux").clear();
//     }
//   }
// };

void Protocol(int n){
  println("Item " + (n+1) + " selected from Dropdown 1");
  if(w_networking.initialized==1){
    w_networking.initialized=0;
  }
  w_networking.status=0;
  w_networking.startButton.setColorNotPressed(color(184,220,105));
  w_networking.startButton.setString("Start");
  w_networking.protocolMode = n;
  closeAllDropdowns();
}

void SendReceive(int n){
  println("Item " + (n+1) + " selected from Dropdown 1");
  w_networking.sendReceiveMode = n;
  closeAllDropdowns();
}

void DataType(int n){
  println("Item " + (n+1) + " selected from Dropdown 1");
  w_networking.dataTypeMode = n;
  closeAllDropdowns();
}

void Filter(int n){
  println("Item " + (n+1) + " selected from Dropdown 1");
  w_networking.filteredMode = n;
  closeAllDropdowns();
}
