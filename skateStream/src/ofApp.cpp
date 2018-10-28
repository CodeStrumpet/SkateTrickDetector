#include <string.h>
#include <strstream>
#include "ofApp.h"

//--------------------------------------------------------------
void ofApp::setup(){
    camWidth = 640;  // try to grab at this size.
    camHeight = 480;
    ofSetFrameRate(30);
    
    //get back a list of devices.
    vector<ofVideoDevice> devices = vidGrabber.listDevices();
    
    for(size_t i = 0; i < devices.size(); i++){
        if(devices[i].bAvailable){
            //log the device
            ofLogNotice() << devices[i].id << ": " << devices[i].deviceName;
        }else{
            //log the device and note it as unavailable
            ofLogNotice() << devices[i].id << ": " << devices[i].deviceName << " - unavailable ";
        }
    }
    
    vidGrabber.setDeviceID(0);
    vidGrabber.setDesiredFrameRate(30);
    vidGrabber.initGrabber(camWidth, camHeight);
    
    ofSetVerticalSync(true);
    
    udpConnection.Create();
    udpConnection.SetEnableBroadcast(true);
    udpConnection.BindMcast((char *)"0.0.0.0", portNo);
    udpConnection.SetNonBlocking(true);
}

// trim from end (in place)
static inline void rtrim(std::string &s) {
    s.erase(std::find_if(s.rbegin(), s.rend(), [](int ch) {
        return !std::isspace(ch);
    }).base(), s.end());
}


//--------------------------------------------------------------
void ofApp::update(){
    static float lasttime=0;
    vidGrabber.update();
    
    // Get UDP messages from accelerometer
    char udpMessage[100000];
    int nmsg=0;
    while (true) {
        udpConnection.Receive(udpMessage,100000);
        string message=udpMessage;
        if (message == "") {
            if (nmsg>0)
                printf("[x%d]\n",nmsg);
            break;
        }
        if (nmsg==0)
            printf("Got msg: %s ",message.c_str());
        nmsg++;
        std::stringstream ss(message);
        std::string token;
        std::vector<string> tokens;
        
        while (std::getline(ss, token, ',')) {
            tokens.push_back(token);
        }
        
        // Split out time
        float time=stof(tokens[0]);
        string tag=tokens.back();
        rtrim(tag);
        printf("time=%f,tag=%s\n",time,tag.c_str());
        if (time-lasttime > 5) {
            // Paused
            printf("Paused\n");
            if (imuFD!=NULL)
                fclose(imuFD);
        }
        lasttime=time;
        // Write to file
        if (imuFD==NULL) {
            auto t = std::time(nullptr);
            auto tm = *std::localtime(&t);
            std::ostringstream oss;
            oss << std::put_time(&tm, "%Y%m%d_%H%M%S");
            
            string imuFileName="imu_"+tag+"_"+oss.str()+".csv";
            printf("New file: %s\n", imuFileName.c_str());
            imuFD=std::fopen(imuFileName.c_str(),"w");
        }
        fprintf(imuFD,"%s\n",message.c_str());
    }
}

//--------------------------------------------------------------
void ofApp::draw(){
    ofBackground(100, 100, 100);

    ofSetHexColor(0xffffff);
    vidGrabber.draw(20, 20);
    vidGrabber.draw(20+camWidth+20, 20);
}


//--------------------------------------------------------------
void ofApp::keyPressed(int key){
    // in fullscreen mode, on a pc at least, the
    // first time video settings the come up
    // they come up *under* the fullscreen window
    // use alt-tab to navigate to the settings
    // window. we are working on a fix for this...
    
    // Video settings no longer works in 10.7
    // You'll need to compile with the 10.6 SDK for this
    // For Xcode 4.4 and greater, see this forum post on instructions on installing the SDK
    // http://forum.openframeworks.cc/index.php?topic=10343
    if(key == 's' || key == 'S'){
        vidGrabber.videoSettings();
    }
}

//--------------------------------------------------------------
void ofApp::keyReleased(int key){

}

//--------------------------------------------------------------
void ofApp::mouseMoved(int x, int y ){

}

//--------------------------------------------------------------
void ofApp::mouseDragged(int x, int y, int button){

}

//--------------------------------------------------------------
void ofApp::mousePressed(int x, int y, int button){

}

//--------------------------------------------------------------
void ofApp::mouseReleased(int x, int y, int button){

}

//--------------------------------------------------------------
void ofApp::mouseEntered(int x, int y){

}

//--------------------------------------------------------------
void ofApp::mouseExited(int x, int y){

}

//--------------------------------------------------------------
void ofApp::windowResized(int w, int h){

}

//--------------------------------------------------------------
void ofApp::gotMessage(ofMessage msg){

}

//--------------------------------------------------------------
void ofApp::dragEvent(ofDragInfo dragInfo){ 

}
