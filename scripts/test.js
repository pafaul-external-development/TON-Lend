async function main() {
    let locklift = await require('./initializeLocklift')('./l.conf.js', 'local');
    console.log('a');
}

main();