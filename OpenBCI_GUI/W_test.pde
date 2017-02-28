
////////////////////////////////////////////////////
//
//          TEST WIDGET FOR NETWORKING
//
///////////////////////////////////////////////////,

class W_test extends Widget {

  //to see all core variables/methods of the Widget class, refer to Widget.pde
  //put your custom variables here...
  Button widgetTemplateButton;

  /* NETWORKING */
  Boolean networkingEnabled;
  String customData;
  Boolean newData;
  // Custom dataTypes
  String dataTypeName1;


  W_test(PApplet _parent){
    super(_parent); //calls the parent CONSTRUCTOR method of Widget (DON'T REMOVE)
    networkingConfiguration();
    this.networkingEnabled = true;
    this.newData = false;

    widgetTemplateButton = new Button (x + w/2, y + h/2, 200, navHeight, "Send a Greeting!", 12);
    widgetTemplateButton.setFont(p4, 14);
  }

  void update(){
    super.update(); //calls the parent update() method of Widget (DON'T REMOVE)

    //put your code here...


  }



  void draw(){
    super.draw(); //calls the parent draw() method of Widget (DON'T REMOVE)

    //put your code here... //remember to refer to x,y,w,h which are the positioning variables of the Widget class
    pushStyle();

    widgetTemplateButton.draw();

    popStyle();

  }

  void screenResized(){
    super.screenResized(); //calls the parent screenResized() method of Widget (DON'T REMOVE)

    //put your code here...
    widgetTemplateButton.setPos(x + w/2 - widgetTemplateButton.but_dx/2, y + h/2 - widgetTemplateButton.but_dy/2);


  }

  void mousePressed(){
    super.mousePressed(); //calls the parent mousePressed() method of Widget (DON'T REMOVE)

    //put your code here...
    if(widgetTemplateButton.isMouseHere()){
      widgetTemplateButton.setIsActive(true);
    }

  }

  void mouseReleased(){
    super.mouseReleased(); //calls the parent mouseReleased() method of Widget (DON'T REMOVE)

    //put your code here...
    if(widgetTemplateButton.isActive && widgetTemplateButton.isMouseHere()){
      if(this.networkingEnabled){
        networkSend("hi");
      }
    }
    widgetTemplateButton.setIsActive(false);

  }

  /* NETWORKING */

  void networkingConfiguration(){
    this.networkingEnabled = true;
    this.dataTypeName1 = "Greeting";
  }

  /* Output data to network
  * Format your data in a way that can be sent through a network, and then place
  * that data in the variable "this.dataToSend". Then set this.newData to true.
  *
  /* Return data that should be pushed through the network */
  void networkSend(String message){
    /* Insert your custom data processing functions here! */
    /* Prepare data to be sent to OSC network */
    /* When data is ready, store in this.customData */
    this.customData = message;
    setDataFlag(true); //Let the network know that new data is available at the end of the function!
  }
  Boolean checkNewData(){
    return this.newData;
  }
  void setDataFlag(Boolean b){
    this.newData = b;
  }
  String getDataToSend(){
    return this.customData;
  }

};
