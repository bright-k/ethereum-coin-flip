const path = require("path");

module.exports = {
  contracts_build_directory: path.join(__dirname, "client/src/contracts"),
  networks: {
    local: {
      host: "127.0.0.1",
      port: 7545,
      network_id: "5777"
    }
  },
  mocha: {
    
  },
  compilers: {
    solc: {
      version: "0.8.3"
    }
  }
};
