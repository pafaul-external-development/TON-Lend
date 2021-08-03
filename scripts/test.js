async function main() {
    let locklift = await require('./initialize_locklift')('./l.conf.js', 'local');
    console.log('a');
}

main();