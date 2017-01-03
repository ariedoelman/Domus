window.onload = function() {

  // Create a new WebSocket.
  var socket = new WebSocket(wsUri);


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

