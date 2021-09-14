const Astro_ERC20_Token = artifacts.require("Astro_ERC20_Token");

module.exports = function (deployer) {
  deployer.deploy(Astro_ERC20_Token);
};
