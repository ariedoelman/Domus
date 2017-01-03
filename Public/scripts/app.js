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
    var field = document.getElementById(message);
    if (field) {
      field.innerHTML = 'Received data!'
    } else {
      console.log('Unknown id: '+message);
    }
  };

  
};

