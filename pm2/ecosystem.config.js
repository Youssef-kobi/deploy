module.exports = {
  apps : [{
    name: "myapp",
    script: "app.js",
    watch: true,
    env: {
        "PORT": 3000,
        "NODE_ENV": "development"
    },
    env_production: {
        "NODE_ENV": "production"
    }
  }]
};
