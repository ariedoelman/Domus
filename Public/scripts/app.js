
// Create a new WebSocket.
var socket;

window.onload = function() {

  socket = new WebSocket(wsUri);

  // Handle any errors that occur.
  socket.onerror = function(error) {
    console.log('WebSocket Error: ' + error);
  };


  // Show a connected message when the WebSocket is opened.
  socket.onopen = function(event) {
    console.log('WebSocket opened!');
  };


  // Show a disconnected message when the WebSocket is closed.
  socket.onclose = function(event) {
    console.log('WebSocket closed!');
  };

  // Handle messages sent by the server.
  socket.onmessage = function(event) {
    var message = event.data;
    console.log('Received message: '+message);
    var idValue = message.split('=', 2);
    var fieldId = idValue[0];
    var fieldValue = idValue[1];
    var field = document.getElementById(fieldId);
    if (field) {
      field.innerHTML = fieldValue;
    } else {
      console.log('Unknown id: '+fieldName);
    }
  };

  
};

function stopMotors() {
  socket.send("motorcontrol=stop");
}

function controlMotors(leftgearid, leftdirectionid, rightgearid, rightdirectionid) {
  socket.send("motorcontrol=start"
              + "\nleftgear="+document.getElementById(leftgearid).value
              +"\nleftdirection="+document.getElementById(leftdirectionid).value
              + "\nrightgear="+document.getElementById(rightgearid).value
              +"\nrightdirection="+document.getElementById(rightdirectionid).value
              );
}
