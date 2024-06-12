const express = require('express');
const app = express();
const port = 3000;

app.get('/', (req, res) => {
  // Accessing the injected secrets
  const username = process.env.USERNAME || 'NOT-CONFIGURED';
  const password = process.env.PASSWORD || 'NOT-CONFIGURED';

  res.send(`Username: ${username}, Password: ${password}`);
});

app.listen(port, () => {
  console.log(`App listening at http://localhost:${port}`);
}); 
