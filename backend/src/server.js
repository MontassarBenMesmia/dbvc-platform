const { createApp } = require('./app');

const port = Number(process.env.PORT || 8080);
const app = createApp();

app.listen(port, '0.0.0.0', () => {
  console.log(`DBVC API listening on port ${port}`);
});
