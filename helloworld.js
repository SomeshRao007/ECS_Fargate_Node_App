const http = require('node:http');

const listener = function (request, response) {
   const currentDate = new Date();
   const dateTimeString = currentDate.toLocaleString();

   response.writeHead(200, {'Content-Type': 'text/html'});
   response.end(`
     <h2 style="text-align: center;">Hello World this is screencast 2 lets see </h2>
     <p style="text-align: center;">Current Date and Time: ${dateTimeString}</p>
   `);
};

const server = http.createServer(listener);
server.listen(3000);

// To print the message
console.log('Server running at http://<public_ip>:3000/');
