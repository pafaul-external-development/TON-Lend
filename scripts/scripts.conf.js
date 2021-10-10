/**
 * @typedef ScriptConfiguration
 * @type {Object}
 * 
 * @property {String} network
 * @property {String} buildDirectory
 * @property {String} pathToLockliftConfig
 * @property {String} deployedContractsDir
 */

/**
 * @type {ScriptConfiguration}
 */
const configuration = {
    network: 'local',
    buildDirectory: './build/',
    pathToLockliftConfig: './scripts/l.conf.js',
    deployedContractsDir: './deployed/'
}

module.exports = configuration;